// services/category.service.js
const Category = require("../models/category.model");
const cloudinary = require("../config/cloudinary");
const mongoose = require("mongoose");

async function normalizeImage(img) {
  if (!img) return { url: "", public_id: "" };
  if (typeof img === "string") return { url: img, public_id: "" }; // tương thích dữ liệu cũ
  return {
    url: img.url || "",
    public_id: img.public_id || "",
  };
}

class CategoryService {
  async createCategory(data) {
    const category = new Category(data);
    return await category.save();
  }

  /**
   * Lấy danh sách hạng mục, có thể lọc theo cha
   * @param {object} query - Ví dụ: { parent: null } (lấy mục cha)
   * hoặc { parent: 'ID_CHA' } (lấy mục con)
   */
  async getAllCategories(query) {
    let filter = {};
    if (query.parent === "null") {
      filter.parent = null; // Lấy các hạng mục gốc
    } else if (query.parent) {
      filter.parent = query.parent; // Lấy con của 1 hạng mục
    }
    // Nếu không có query, lấy tất cả
    return await Category.find(filter).populate("parent", "name slug"); // Nối thông tin cha
  }

  async getCategoryByIdOrSlug(identifier) {
    const isObjectId = mongoose.Types.ObjectId.isValid(identifier);
    let category;

    if (isObjectId) {
      category = await Category.findById(identifier);
    } else {
      category = await Category.findOne({ slug: identifier });
    }

    if (!category) {
      throw new Error("Category not found");
    }
    return await category.populate("parent", "name slug");
  }

  async updateCategory(id, updateData) {
    const current = await Category.findById(id);
    if (!current) throw new Error("Category not found");

    const oldImg = await normalizeImage(current.image);
    const newImg = updateData.hasOwnProperty("image")
      ? await normalizeImage(updateData.image)
      : null;

    // Nếu client gửi image (có nghĩa muốn thay/xóa)
    if (newImg) {
      // xóa ảnh cũ trên cloudinary nếu:
      // - ảnh cũ có public_id
      // - và (ảnh mới không có public_id) hoặc (public_id mới khác)
      if (
        oldImg.public_id &&
        (!newImg.public_id || newImg.public_id !== oldImg.public_id)
      ) {
        await cloudinary.uploader.destroy(oldImg.public_id, {
          resource_type: "image",
          invalidate: true,
        });
      }
      // đảm bảo lưu đúng format object
      updateData.image = newImg;
    }

    const updated = await Category.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    return updated;
  }

  async deleteCategory(id) {
    const cat = await Category.findByIdAndDelete(id);
    if (!cat) throw new Error("Category not found");

    const img = await normalizeImage(cat.image);

    if (img.public_id) {
      await cloudinary.uploader.destroy(img.public_id, {
        resource_type: "image",
        invalidate: true,
      });
    }

    return { message: "Category deleted" };
  }
}

module.exports = new CategoryService();
