// models/product.model.js
const mongoose = require("mongoose");
const slugify = require("slugify");

const productSchema = new mongoose.Schema(
  {
    // --- 1. THÔNG TIN CHUNG ---
    product_code: {
      type: String,
      unique: true,
      uppercase: true,
      trim: true,
      index: true,
      required: false, // Để hệ thống tự sinh nếu không nhập
    },
    product_type: {
      type: String,
      default: "tour",
      enum: ["tour"],
    },
    partner_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // --- [QUAN TRỌNG] TRẠNG THÁI DUYỆT ---
    status: {
      type: String,
      enum: ["draft", "pending", "active", "rejected", "hidden"],
      default: "pending", // Mặc định chờ duyệt
      index: true,
    },
    // Lưu lý do từ chối (nếu có) để Partner biết đường sửa
    rejection_reason: {
      type: String,
      default: ""
    },

    location_ids: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Location",
      },
    ],
    title: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      unique: true,
      index: true,
    },
    description_short: String,
    description_long: String,
    images: [
      {
        url: { type: String, default: "" },
        public_id: { type: String, default: "" },
      },
    ],
    tags: [{ type: String }],

    category_ids: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Category",
      },
    ],

    sustainability_score: {
      type: Number,
      min: 0,
      max: 5,
      default: 3,
    },
    base_price: {
      type: Number,
      required: true,
      min: 0,
    },

    // --- 2. CHI TIẾT TOUR ---
    tour_details: {
      start_point: { type: String, trim: true, default: "Hồ Chí Minh" },
      departure_times: [{ type: Date }],

      // Lịch khởi hành cụ thể (Inventory)
      schedules: [{
        date: Date,
        stock: { type: Number, default: 0 },
        booked: { type: Number, default: 0 },
        price_override: Number
      }],

      duration_days: { type: Number },

      transport_type: {
        type: String,
        enum: ["Máy bay", "Xe du lịch", "Tàu hỏa", "Du thuyền", "Xe máy", "Tự túc"],
        default: "Xe du lịch",
      },

      hotel_rating: { type: Number, default: 0 },
      hotel_name: { type: String },

      itinerary: [
        {
          day: Number,
          title: String,
          details: String,
          meals: [String],
          accommodation: String,
        },
      ],

      trip_highlights: {
        attractions: String,
        cuisine: String,
        suitable_for: String,
        ideal_time: String,
      },

      policy_notes: [
        {
          title: String,
          content: String,
        },
      ],
    },
  },
  {
    timestamps: true,
    minimize: true,
  }
);

// Middleware xử lý Slug
productSchema.pre("save", function (next) {
  if (this.isModified("title")) {
    const title = this.title.replace(/Đ/g, "D").replace(/đ/g, "d");
    this.slug = slugify(title, { lower: true, strict: true });
  }
  next();
});

// Index
productSchema.index({ status: 1 });
productSchema.index({ base_price: 1 });
productSchema.index({ location_ids: 1 });
productSchema.index({ category_ids: 1 });
productSchema.index({ "tour_details.start_point": 1 });

module.exports = mongoose.model("Product", productSchema);