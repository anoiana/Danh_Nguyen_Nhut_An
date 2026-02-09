// models/promotion.model.js
const mongoose = require("mongoose");

const promotionSchema = new mongoose.Schema(
  {
    code: {
      // Mã giảm giá
      type: String,
      required: true,
      unique: true,
      uppercase: true,
    },
    type: {
      type: String,
      enum: ["percentage", "fixed_amount"],
      required: true,
    },
    value: {
      type: Number,
      required: true,
      min: 0,
    },
    description: String,
    total_quantity: {
      type: Number,
      required: true,
      min: 1,
    },
    used_quantity: {
      type: Number,
      default: 0,
      min: 0,
    },
    is_active: {
      type: Boolean,
      default: true,
    },
    rules: {
      valid_from: { type: Date },
      valid_to: { type: Date },
      applies_to_product_type: {
        type: String,
        enum: ["tour", "hotel", "flight"],
      },
      min_spend: { type: Number, default: 0 },
      // (Có thể thêm nhiều rules phức tạp hơn)
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Promotion", promotionSchema);
