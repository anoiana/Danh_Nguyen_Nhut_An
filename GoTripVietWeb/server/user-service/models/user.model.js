// models/user.model.js
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password_hash: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      default: "",
    },
    phone: {
      type: String, // SĐT cá nhân
      default: "",
    },
    roles: {
      type: [String],
      enum: ["user", "admin", "partner", "support_staff"],
      default: ["user"],
    },
    status: {
      type: String,
      enum: ["ACTIVE", "LOCKED", "BANNED"],
      default: "ACTIVE",
    },
    
    // Sở thích (Dành cho User thường)
    preferences: {
      travel_style: String,
      interests: [String],
      companions: [String],
      budget_per_trip_usd: Number,
      pace: String,
      sustainability_priority: Boolean,
    },

    // --- [CẬP NHẬT] THÔNG TIN PARTNER ---
    partner_details: {
      // Thông tin hiển thị
      company_name: String,       // Tên thương hiệu/Công ty (VD: VietTravel)
      business_license: String,   // Mã số thuế / Giấy phép kinh doanh
      contact_phone: String,      // SĐT liên hệ công việc (Hotline)
      
      // Thông tin thanh toán (Admin chuyển khoản cho Partner vào đây)
      bank_account: {
        bank_name: String,        // VD: Vietcombank
        account_number: String,   // VD: 0123456789
        account_holder: String,   // VD: NGUYEN VAN A
      },

      // Trạng thái duyệt (Admin duyệt thì mới được đăng bài)
      is_approved: {
        type: Boolean,
        default: false, // Mặc định là FALSE (Chờ duyệt)
      },
      approved_at: {
        type: Date,
      }
    },

    // --- [MỚI] VÍ TIỀN (WALLET) ---
    // Lưu doanh thu của Partner (sau khi trừ 15% phí sàn)
    wallet_balance: {
      type: Number,
      default: 0,
      min: 0
    },

    passwordResetToken: String,
    passwordResetExpires: Date,
  },
  { timestamps: true }
);

// --- CÁC METHOD VÀ MIDDLEWARE GIỮ NGUYÊN ---

userSchema.methods.createPasswordResetToken = function () {
  const resetToken = crypto.randomBytes(32).toString("hex");
  this.passwordResetToken = crypto
    .createHash("sha256")
    .update(resetToken)
    .digest("hex");
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; 
  return resetToken;
};

userSchema.pre("save", async function (next) {
  if (!this.isModified("password_hash")) {
    return next();
  }
  try {
    const salt = await bcrypt.genSalt(10);
    this.password_hash = await bcrypt.hash(this.password_hash, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password_hash);
};

const User = mongoose.model("User", userSchema);
module.exports = User;