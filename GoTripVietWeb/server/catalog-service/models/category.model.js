// models/category.model.js
const mongoose = require("mongoose");
const slugify = require("slugify");

const categorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    slug: {
      type: String,
      unique: true,
      index: true,
    },
    parent: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
      default: null,
    },
    description: String,
    image: {
      url: { type: String, default: "" },
      public_id: { type: String, default: "" },
      _id: false,
    },
    
    // --- [MỚI] Thêm trường Status và Created_by ---
    status: { 
      type: String, 
      enum: ['active', 'pending', 'rejected'], 
      default: 'active' // Admin tạo thì active luôn, Partner tạo thì pending (xử lý ở Controller)
    },
    created_by: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      default: null // Null nghĩa là Admin/System tạo
    }
  },
  { timestamps: true }
);

categorySchema.pre("save", function (next) {
  if (this.isModified("name")) {
    const name = this.name.replace(/Đ/g, "D").replace(/đ/g, "d");
    this.slug = slugify(name, { lower: true, strict: true });
  }
  next();
});

module.exports = mongoose.model("Category", categorySchema);