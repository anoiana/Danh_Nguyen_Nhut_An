// services/event.service.js
const Event = require("../models/event.model");
const axios = require("axios");
const mongoose = require("mongoose");
const InventoryItem = require("../models/inventory.model");

const CATALOG_BASE_URL =
  process.env.CATALOG_BASE_URL ||
  process.env.GATEWAY_URL ||
  "http://localhost:3000";

function slugify(str) {
  return String(str || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)+/g, "");
}

function validateDiscount(type, value) {
  const v = Number(value);
  if (!Number.isFinite(v)) throw new Error("Giá trị giảm không hợp lệ.");

  if (type === "percentage") {
    if (!(v > 0 && v < 100))
      throw new Error("Giảm theo % phải lớn hơn 0 và nhỏ hơn 100.");
  } else if (type === "fixed_amount") {
    if (!(v > 0)) throw new Error("Giảm số tiền phải lớn hơn 0.");
    if (v % 1000 !== 0)
      throw new Error("Giảm số tiền phải chia hết cho 1.000.");
  } else {
    throw new Error("Loại giảm giá không hợp lệ.");
  }
}

function validateYearlyRange(payload) {
  const sm = Number(payload.start_month);
  const sd = Number(payload.start_day);
  const em = Number(payload.end_month);
  const ed = Number(payload.end_day);

  if (![sm, sd, em, ed].every(Number.isFinite)) {
    throw new Error("Ngày bắt đầu/kết thúc không hợp lệ.");
  }
  if (sm < 1 || sm > 12 || em < 1 || em > 12) {
    throw new Error("Tháng phải nằm trong khoảng 1-12.");
  }
  if (sd < 1 || sd > 31 || ed < 1 || ed > 31) {
    throw new Error("Ngày phải nằm trong khoảng 1-31.");
  }
}

async function ensureUniqueSlug(baseSlug, excludeId = null) {
  let s = baseSlug || "event";
  let i = 0;

  while (true) {
    const q = { slug: s };
    if (excludeId) q._id = { $ne: excludeId };
    const exists = await Event.findOne(q).lean();
    if (!exists) return s;
    i += 1;
    s = `${baseSlug}-${i}`;
  }
}

// Kiểm tra event active dựa trên ngày hiện tại
function isInYearlyRange(now, sm, sd, em, ed) {
  const m = now.getMonth() + 1; // 1-12
  const d = now.getDate(); // 1-31

  const cur = m * 100 + d;
  const start = Number(sm) * 100 + Number(sd);
  const end = Number(em) * 100 + Number(ed);

  // range không băng qua năm (vd 3/10 -> 8/20)
  if (start <= end) return cur >= start && cur <= end;

  // range băng qua năm (vd 11/15 -> 2/10)
  return cur >= start || cur <= end;
}

async function fetchToursFromCatalogByIds(ids) {
  // thử endpoint /products?ids=csv
  try {
    const r = await axios.get(`${CATALOG_BASE_URL}/products`, {
      params: { ids: ids.join(",") },
    });

    const data = r.data;
    return (
      data?.products ||
      data?.data ||
      data?.items ||
      (Array.isArray(data) ? data : [])
    );
  } catch (e) {
    // fallback: gọi từng id
    const results = await Promise.all(
      ids.map(async (id) => {
        const rr = await axios.get(`${CATALOG_BASE_URL}/products/${id}`);
        return rr.data?.data || rr.data;
      })
    );
    return results.filter(Boolean);
  }
}

async function fetchToursFromCatalogDefault(limit = 12) {
  const r = await axios.get(`${CATALOG_BASE_URL}/products`, {
    params: { product_type: "tour", limit },
  });
  return r.data?.data || r.data?.items || r.data || [];
}

function isValidObjectId(x) {
  return mongoose.Types.ObjectId.isValid(String(x || ""));
}

function overlapsMonth(startMonth, endMonth, month) {
  // không wrap: 3 -> 6
  if (startMonth <= endMonth) return month >= startMonth && month <= endMonth;
  // wrap năm: 12 -> 1
  return month >= startMonth || month <= endMonth;
}

module.exports = {
  async getAll() {
    // Admin thấy hết (kể cả ngưng)
    return Event.find({}).sort({ createdAt: -1 });
  },

  async getById(id) {
    const ev = await Event.findById(id);
    if (!ev) throw new Error("Không tìm thấy event.");
    return ev;
  },

  async create(payload) {
    validateYearlyRange(payload);
    validateDiscount(payload.discount_type, payload.discount_value);

    const baseSlug = slugify(payload.name);
    const slug = await ensureUniqueSlug(baseSlug);

    const ev = await Event.create({
      ...payload,
      slug,
      // normalize
      apply_to_all_tours: payload.apply_to_all_tours !== false,
      tour_ids: Array.isArray(payload.tour_ids) ? payload.tour_ids : [],
    });
    return ev;
  },

  async update(id, payload) {
    const ev = await Event.findById(id);
    if (!ev) throw new Error("Không tìm thấy event.");

    // validate nếu có field liên quan
    const nextDiscountType = payload.discount_type ?? ev.discount_type;
    const nextDiscountValue = payload.discount_value ?? ev.discount_value;
    validateDiscount(nextDiscountType, nextDiscountValue);

    const nextRange = {
      start_month: payload.start_month ?? ev.start_month,
      start_day: payload.start_day ?? ev.start_day,
      end_month: payload.end_month ?? ev.end_month,
      end_day: payload.end_day ?? ev.end_day,
    };
    validateYearlyRange(nextRange);

    if (payload.name && payload.name !== ev.name) {
      const baseSlug = slugify(payload.name);
      ev.slug = await ensureUniqueSlug(baseSlug, ev._id);
      ev.name = payload.name;
    }

    if (payload.description !== undefined) ev.description = payload.description;

    if (payload.image) ev.image = payload.image;

    ev.discount_type = nextDiscountType;
    ev.discount_value = Number(nextDiscountValue);

    ev.is_yearly = payload.is_yearly ?? ev.is_yearly;
    ev.start_month = Number(nextRange.start_month);
    ev.start_day = Number(nextRange.start_day);
    ev.end_month = Number(nextRange.end_month);
    ev.end_day = Number(nextRange.end_day);

    ev.applies_to_product_type =
      payload.applies_to_product_type ?? ev.applies_to_product_type;
    ev.apply_to_all_tours = payload.apply_to_all_tours ?? ev.apply_to_all_tours;
    ev.tour_ids = Array.isArray(payload.tour_ids)
      ? payload.tour_ids
      : ev.tour_ids;

    ev.priority = payload.priority ?? ev.priority;
    ev.is_active = payload.is_active ?? ev.is_active;

    await ev.save();
    return ev;
  },

  async deleteHard(id) {
    const deleted = await Event.findByIdAndDelete(id);
    if (!deleted) throw new Error("Không tìm thấy event.");
    return deleted;
  },

  async toggleStatus(id) {
    const ev = await Event.findById(id);
    if (!ev) throw new Error("Không tìm thấy event.");
    ev.is_active = !ev.is_active;
    await ev.save();
    return ev;
  },

  // Lấy danh sách sự kiện active cho public
  async getActivePublic() {
    const now = new Date();

    // Lấy tất cả event đang bật
    const rows = await Event.find({ is_active: true })
      .sort({ priority: -1, createdAt: -1 })
      .lean();

    // Lọc theo "đang hiệu lực" dựa trên tháng/ngày
    const activeNow = rows.filter((ev) => {
      // Nếu event yearly thì check theo start/end month/day
      if (ev.is_yearly) {
        return isInYearlyRange(
          now,
          ev.start_month,
          ev.start_day,
          ev.end_month,
          ev.end_day
        );
      }
      // Nếu sau này bạn có event không-yearly mà chưa có date range cụ thể,
      // tạm coi như active khi is_active=true
      return true;
    });

    return activeNow;
  },
  // Lấy chi tiết sự kiện public theo id hoặc slug
  async getPublicByIdOrSlug(idOrSlug) {
    const now = new Date();

    const q = isValidObjectId(idOrSlug)
      ? { _id: idOrSlug }
      : { slug: String(idOrSlug || "").trim() };

    const ev = await Event.findOne(q).lean();
    if (!ev) throw new Error("Không tìm thấy event.");

    if (!ev.is_active) throw new Error("Event không còn hoạt động.");

    // chỉ cho public xem event đang hiệu lực (yearly)
    if (ev.is_yearly) {
      const ok = isInYearlyRange(
        now,
        ev.start_month,
        ev.start_day,
        ev.end_month,
        ev.end_day
      );
      if (!ok) throw new Error("Event hiện chưa đến thời gian áp dụng.");
    }

    return ev;
  },
  // Lấy danh sách tour áp dụng sự kiện public theo id hoặc slug
  async getPublicTours(idOrSlug) {
    const ev = await this.getPublicByIdOrSlug(idOrSlug);

    // CHỈ lấy các tour "đang giảm thật" = inventory đã apply event này
    const productIds = await InventoryItem.distinct("product_id", {
      product_type: "tour",
      "applied_event.event_id": ev._id,
    });

    const ids = (productIds || []).map(String);
    if (!ids.length) return [];

    // Lấy thông tin tour từ catalog-service
    return fetchToursFromCatalogByIds(ids);
  },

  // PUBLIC: Lấy tất cả event trong tháng (dựa trên start/end month)
  // - Chỉ lấy is_active=true
  // - Nếu is_yearly=true: lọc theo tháng (vì yearly không phụ thuộc năm)
  // - Nếu sau này có non-yearly theo năm, bạn có thể mở rộng thêm
  async getPublicEventsInMonth(year, month) {
    if (!month || month < 1 || month > 12) {
      throw new Error("Month không hợp lệ (1-12).");
    }

    const rows = await Event.find({ is_active: true })
      .sort({ priority: -1, createdAt: -1 })
      .lean();

    const filtered = rows.filter((ev) => {
      const sm = Number(ev.start_month);
      const em = Number(ev.end_month);
      if (!sm || !em) return false;
      return overlapsMonth(sm, em, month);
    });

    // sort theo ngày bắt đầu trong năm cho đẹp
    filtered.sort((a, b) => {
      const aKey = (a.start_month || 0) * 100 + (a.start_day || 0);
      const bKey = (b.start_month || 0) * 100 + (b.start_day || 0);
      return aKey - bKey;
    });

    return filtered;
  },
};
