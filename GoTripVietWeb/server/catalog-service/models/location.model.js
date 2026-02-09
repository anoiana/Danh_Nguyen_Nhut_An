// models/location.model.js
const mongoose = require("mongoose");
const slugify = require("slugify");

const locationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      unique: true,
      index: true,
    },
    country: {
      type: String,
      trim: true,
    },
    description: String,
    images: [
      {
        url: { type: String, required: true },
        public_id: { type: String, default: "" },
        _id: false,
      },
    ],
    tags: [{ type: String }],
    coordinates: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
    
    // --- [NEW] Fields for Request & Approve flow ---
    status: {
      type: String,
      enum: ["active", "pending", "rejected"],
      default: "active", // Admin creates active by default, API will override for partners
    },
    created_by: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null, // Null implies Admin/System created
    },
  },
  { timestamps: true }
);

// Automatic slug generation
locationSchema.pre("save", function (next) {
  if (this.isModified("name")) {
    const name = this.name.replace(/Đ/g, "D").replace(/đ/g, "d");
    this.slug = slugify(name, { lower: true, strict: true });
  }
  next();
});

locationSchema.index({ coordinates: "2dsphere" });

module.exports = mongoose.model("Location", locationSchema);