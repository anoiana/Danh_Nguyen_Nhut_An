// models/event.model.js
const mongoose = require("mongoose");

const EventSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, unique: true, index: true },

    description: { type: String, default: "" },

    // 1 ảnh (Cloudinary)
    image: {
      url: { type: String, default: "" },
      public_id: { type: String, default: "" },
    },

    // Giảm giá áp vào tour (để service khác đọc và tự áp vào price)
    discount_type: {
      type: String,
      enum: ["percentage", "fixed_amount"],
      required: true,
      default: "percentage",
    },
    discount_value: { type: Number, required: true, min: 0 },

    // Tạo event hằng năm: lưu theo tháng/ngày (không phụ thuộc năm)
    is_yearly: { type: Boolean, default: true },
    start_month: { type: Number, required: true, min: 1, max: 12 },
    start_day: { type: Number, required: true, min: 1, max: 31 },
    end_month: { type: Number, required: true, min: 1, max: 12 },
    end_day: { type: Number, required: true, min: 1, max: 31 },

    // phạm vi áp dụng
    applies_to_product_type: {
      type: String,
      enum: ["tour"],
      default: "tour",
    },
    apply_to_all_tours: { type: Boolean, default: true },
    tour_ids: { type: [String], default: [] }, // nếu apply_to_all_tours=false

    priority: { type: Number, default: 0 },
    is_active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Event", EventSchema);
