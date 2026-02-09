// services/product.service.js
const Product = require("../models/product.model");
const cloudinary = require("../config/cloudinary");
const mongoose = require("mongoose");
const slugify = require("slugify");

function normalizeImages(images) {
  if (!images) return [];
  if (typeof images === "string") {
    return images
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((url) => ({ url, public_id: "" }));
  }
  if (Array.isArray(images)) {
    return images
      .map((x) => (typeof x === "string" ? { url: x, public_id: "" } : x))
      .filter((x) => x?.url);
  }
  return [];
}

async function makeUniqueSlug(Model, base, excludeId = null) {
  let slug = base;
  let i = 1;
  const existsQuery = (s) =>
    excludeId ? { slug: s, _id: { $ne: excludeId } } : { slug: s };

  while (await Model.exists(existsQuery(slug))) {
    i += 1;
    slug = `${base}-${i}`;
  }
  return slug;
}

class ProductService {
  /**
   * Tạo sản phẩm (Xử lý status theo Role)
   */
  async createProduct(productData, partnerId, userRoles = []) {
    productData.partner_id = partnerId;

    // --- LOGIC STATUS ---
    // Nếu là Admin: Được quyền set status (mặc định active)
    // Nếu là Partner: Luôn luôn là 'pending' (bất kể gửi lên gì)
    if (userRoles.includes("admin")) {
      productData.status = productData.status || "active";
    } else {
      productData.status = "pending";
    }

    // Xử lý loại sản phẩm (Tour/Hotel...)
    const { product_type, tour_details } = productData;
    if (!product_type || product_type === "tour") {
      productData.hotel_details = undefined;
      productData.flight_details = undefined;
      productData.tour_details = tour_details;
    }

    // Tự tạo slug unique
    if (!productData.slug && productData.title) {
      const title = productData.title.replace(/Đ/g, "D").replace(/đ/g, "d");
      const base = slugify(title, { lower: true, strict: true });
      productData.slug = await makeUniqueSlug(Product, base);
    }

    const product = new Product(productData);
    await product.save();
    return product;
  }

  /**
   * Lấy danh sách (Public: chỉ Active; Partner: thấy hết của mình; Admin: thấy hết)
   */
  async getProducts(queryParams, userRoles = [], userId = null) {
    const {
      partner_id,
      page = 1,
      limit = 10,
      product_type,
      location_id,
      category_id,
      tags,
      keyword,
      min_price,
      max_price,
      start_point,
      date,
      transport,
      star_rating,
      status, // Admin/Partner filter status
    } = queryParams;

    let filter = {};

    // 1. Mặc định (Khách vãng lai): Chỉ xem ACTIVE
    filter.status = "active";

    const isAdmin = userRoles.includes("admin");

    // 2. Nếu có partner_id (Xem shop của ai đó)
    if (partner_id) {
      filter.partner_id = partner_id;

      // Nếu là chính chủ hoặc Admin -> Thấy hết (bỏ filter active mặc định)
      const isOwner = userId && userId.toString() === partner_id.toString();

      if (isOwner || isAdmin) {
        delete filter.status;
        if (status) filter.status = status; // Lọc theo status nếu muốn
      }
    }
    // 3. Nếu Admin đang xem danh sách tổng (Dashboard)
    else if (isAdmin) {
      delete filter.status; // Mặc định lấy hết
      if (status) filter.status = status; // Lọc theo dropdown của Admin
    }

    // --- CÁC BỘ LỌC KHÁC ---
    if (product_type) filter.product_type = product_type;
    if (location_id) filter.location_ids = { $in: [location_id] };
    if (category_id) filter.category_ids = { $in: [category_id] };
    if (tags) filter.tags = { $in: tags.split(",") };

    if (keyword) {
      const regex = new RegExp(keyword, "i");
      filter.$or = [
        { title: { $regex: regex } },
        { slug: { $regex: regex } },
        { product_code: { $regex: regex } },
        { "tour_details.start_point": { $regex: regex } },
      ];
    }

    if (min_price || max_price) {
      filter.base_price = {};
      if (min_price) filter.base_price.$gte = parseInt(min_price);
      if (max_price) filter.base_price.$lte = parseInt(max_price);
    }

    // Lọc theo thông tin Tour
    if (start_point && start_point !== "Tất cả") {
      filter["tour_details.start_point"] = { $regex: new RegExp(start_point, "i") };
    }

    if (transport && transport !== "Tất cả") {
      filter["tour_details.transport_type"] = transport;
    }

    if (star_rating) {
      filter["tour_details.hotel_rating"] = { $gte: parseInt(star_rating) };
    }

    if (date) {
      const searchDate = new Date(date);
      if (!isNaN(searchDate.getTime())) {
        const startOfDay = new Date(searchDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(searchDate);
        endOfDay.setHours(23, 59, 59, 999);

        filter["tour_details.departure_times"] = {
          $gte: startOfDay,
          $lte: endOfDay,
        };
      }
    }

    const skip = (page - 1) * limit;

    const products = await Product.find(filter)
      .select("+images") // Lấy cả ảnh
      .populate("location_ids", "name slug")
      .populate("category_ids", "name slug")
      .skip(skip)
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    const totalProducts = await Product.countDocuments(filter);

    return {
      products,
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalProducts / limit),
      totalProducts,
    };
  }

  /**
   * Cập nhật sản phẩm
   */
  async updateProduct(productId, updateData, partnerId, userRoles = []) {
    const product = await Product.findById(productId);
    if (!product) throw new Error("Product not found");

    // Check quyền
    const isAdmin = userRoles.includes("admin");
    const isOwner = product.partner_id && product.partner_id.toString() === partnerId;

    if (!isAdmin && !isOwner) {
      throw new Error("Forbidden: You do not own this product");
    }

    // --- LOGIC RESET STATUS ---
    // Nếu là Partner sửa -> Reset về 'pending' để duyệt lại
    if (!isAdmin) {
      updateData.status = "pending";
    }
    // Nếu Admin sửa -> status sẽ theo updateData (hoặc giữ nguyên)

    // Bảo vệ trường quan trọng
    delete updateData.partner_id;
    delete updateData.slug;

    // Xử lý ảnh (Cloudinary)
    if (Object.prototype.hasOwnProperty.call(updateData, "images")) {
      const oldPublicIds = normalizeImages(product.images).map(x => x.public_id).filter(Boolean);
      const newImgs = normalizeImages(updateData.images);
      const newPublicIds = newImgs.map(x => x.public_id).filter(Boolean);
      const removed = oldPublicIds.filter(pid => !newPublicIds.includes(pid));

      await Promise.all(removed.map(pid => cloudinary.uploader.destroy(pid, { resource_type: "image", invalidate: true })));
      updateData.images = newImgs;
    }

    // Update Slug nếu sửa Title
    if (updateData.title && updateData.title !== product.title) {
      const title = updateData.title.replace(/Đ/g, "D").replace(/đ/g, "d");
      const base = slugify(title, { lower: true, strict: true });
      product.slug = await makeUniqueSlug(Product, base, product._id);
    }

    // Merge data
    Object.assign(product, updateData);
    await product.save();
    return product;
  }

  /**
   * [NEW] Admin Duyệt/Từ chối Tour
   */
  async updateStatus(productId, status, reason = "") {
    const valid = ["active", "rejected", "pending", "hidden"];
    if (!valid.includes(status)) throw new Error("Invalid status");

    const update = { status };
    if (status === "rejected") {
      update.rejection_reason = reason;
    } else {
      update.rejection_reason = ""; // Xóa lý do nếu duyệt
    }

    const product = await Product.findByIdAndUpdate(productId, update, { new: true });
    if (!product) throw new Error("Product not found");
    return product;
  }

  /**
   * Lấy chi tiết Public (chỉ Active)
   */
  async getProductByIdOrSlug(idOrSlug) {
    const isObjectId = mongoose.Types.ObjectId.isValid(idOrSlug);
    const query = isObjectId ? { _id: idOrSlug } : { slug: idOrSlug };

    // Khách chỉ xem được Active
    query.status = 'active';

    const product = await Product.findOne(query)
      .populate("location_ids", "name slug country")
      .populate("category_ids", "name slug");

    if (!product) throw new Error("Product not found or not active");
    return product;
  }

  /**
   * Lấy chi tiết Admin/Partner (Xem full status)
   */
  async getProductByIdOrSlugAdmin(idOrSlug) {
    const isObjectId = mongoose.Types.ObjectId.isValid(idOrSlug);
    const query = isObjectId ? { _id: idOrSlug } : { slug: idOrSlug };

    const product = await Product.findOne(query)
      .populate("location_ids", "name slug country")
      .populate("category_ids", "name slug");

    if (!product) throw new Error("Product not found");
    return product;
  }

  // Xóa sản phẩm
  async deleteProduct(id) {
    const product = await Product.findById(id);
    if (!product) throw new Error("Product not found");

    const publicIds = normalizeImages(product.images)
      .map((x) => x.public_id)
      .filter(Boolean);

    await Promise.all(
      publicIds.map((pid) =>
        cloudinary.uploader.destroy(pid, {
          resource_type: "image",
          invalidate: true,
        })
      )
    );

    return await Product.findByIdAndDelete(id);
  }

  // --- SCHEDULES ---
  async addSchedule(productId, scheduleData, partnerId) {
    const product = await Product.findById(productId);
    if (!product) throw new Error("Product not found");

    // Check quyền (chỉ partner chủ sở hữu hoặc admin - logic controller gọi)
    // Ở service tạm check partnerId nếu được truyền vào
    if (partnerId && product.partner_id.toString() !== partnerId) {
      // Nếu cần check chặt chẽ hơn
    }

    if (!product.tour_details.schedules) {
      product.tour_details.schedules = [];
    }

    // Check trùng ngày
    const existingIndex = product.tour_details.schedules.findIndex(
      (s) => new Date(s.date).toDateString() === new Date(scheduleData.date).toDateString()
    );

    if (existingIndex > -1) {
      product.tour_details.schedules[existingIndex].stock = scheduleData.stock;
      if (scheduleData.price !== undefined) {
        product.tour_details.schedules[existingIndex].price_override = scheduleData.price;
      }
    } else {
      product.tour_details.schedules.push({
        date: scheduleData.date,
        stock: parseInt(scheduleData.stock),
        booked: 0,
        price_override: scheduleData.price || 0
      });
    }

    product.tour_details.schedules.sort((a, b) => new Date(a.date) - new Date(b.date));
    await product.save();
    return product;
  }

  async removeSchedule(productId, scheduleId, partnerId) {
    const product = await Product.findById(productId);
    if (!product) throw new Error("Product not found");

    // Filter remove
    product.tour_details.schedules = product.tour_details.schedules.filter(
      (s) => s._id.toString() !== scheduleId
    );

    await product.save();
    return product;
  }

  async getProductInternal(id) {
    const product = await Product.findById(id)
      .select("partner_id base_price title tour_details.duration_days");

    if (!product) throw new Error("Product not found");
    return product;
  }
}

module.exports = new ProductService();