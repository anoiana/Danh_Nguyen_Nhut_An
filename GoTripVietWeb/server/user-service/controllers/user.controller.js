const userService = require("../services/user.service");
const {
  sendRegisterSuccessEmail,
  sendPartnerApprovedEmail,
} = require("../utils/mailer");
const User = require("../models/user.model");
class UserController {
  // Controller cho việc Đăng ký
  async register(req, res) {
    try {
      // 1. Lấy thêm role và partner_details
      const { email, password, fullName, role, partner_details } = req.body;

      // 2. Validate cơ bản
      if (!email || !password) {
        return res
          .status(400)
          .json({ message: "Email and password are required" });
      }

      // 3. Gọi Service
      const user = await userService.registerUser({
        email,
        password,
        fullName,
        role, // Truyền xuống service
        partner_details, // Truyền xuống service
      });

      // gửi mail sau khi tạo user thành công
      setImmediate(() => {
        sendRegisterSuccessEmail({ to: user.email, user }).catch((err) =>
          console.error("❌ Send register email failed:", err.message)
        );
      });

      res.status(201).json({ message: "User registered successfully", user });
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // Controller cho việc Đăng nhập
  async login(req, res) {
    try {
      // 1. Lấy dữ liệu
      const { email, password } = req.body;

      // 2. Validate
      if (!email || !password) {
        return res
          .status(400)
          .json({ message: "Email and password are required" });
      }
      
      // 3. Gọi Service
      const result = await userService.loginUser(email, password);

      // 4. Trả về token
      res.status(200).json(result);
    } catch (error) {
      // 5. Xử lý lỗi (sai pass, sai email)
      res.status(401).json({ message: error.message });
    }
  }

  // GET /users/me
  async getMyProfile(req, res) {
    try {
      // Lấy ID user từ middleware (auth.middleware.js)
      const userId = req.user.id;

      const user = await userService.getUserProfile(userId);
      res.status(200).json(user);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // PUT /users/me
  async updateMyProfile(req, res) {
    try {
      const userId = req.user.id;
      const { fullName, phone } = req.body;

      const updatedUser = await userService.updateUserProfile(userId, {
        fullName,
        phone,
      });
      res.status(200).json(updatedUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // PUT /users/me/preferences
  async updateMyPreferences(req, res) {
    try {
      const userId = req.user.id;
      // Lấy toàn bộ body (chứa các trường sở thích)
      const preferencesData = req.body;

      const updatedUser = await userService.updateUserPreferences(
        userId,
        preferencesData
      );
      res.status(200).json(updatedUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // POST /auth/forgot-password
  async forgotPassword(req, res) {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ message: "Email is required" });
      }

      await userService.forgotPassword(email);

      // Luôn trả về 200 (vì lý do bảo mật)
      res
        .status(200)
        .json({ message: "If user exists, a reset link has been sent" });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // POST /auth/reset-password
  async resetPassword(req, res) {
    try {
      // Token lấy từ URL query (ví dụ: /reset-password?token=...)
      const { token } = req.query;
      const { password } = req.body;

      if (!token || !password) {
        return res
          .status(400)
          .json({ message: "Token and new password are required" });
      }

      const result = await userService.resetPassword(token, password);
      res.status(200).json(result); // Trả về token login mới
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // GET /users
  async getAllUsers(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;

      const result = await userService.getAllUsers(page, limit);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // PUT /users/:id/role
  async updateUserRole(req, res) {
    try {
      const { id } = req.params; // ID của user cần sửa
      const { roles } = req.body; // Mảng roles mới

      if (!roles || !Array.isArray(roles)) {
        return res.status(400).json({ message: "Roles (array) are required" });
      }

      const updatedUser = await userService.updateUserRole(id, roles);
      res.status(200).json(updatedUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // GET /users/:id
  async getUserById(req, res) {
    try {
      const { id } = req.params;
      const user = await userService.getUserById(id);
      res.status(200).json(user);
    } catch (error) {
      // Nếu ID không đúng định dạng Mongo hoặc không tìm thấy
      res.status(404).json({ message: error.message });
    }
  }

  // PUT /users/:id
  async updateUserById(req, res) {
    try {
      const { id } = req.params;
      // Lấy fullName và phone từ body
      const updateData = {
        fullName: req.body.fullName,
        phone: req.body.phone,
      };

      const updatedUser = await userService.updateUserById(id, updateData);
      res.status(200).json(updatedUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // DELETE /users/:id
  async deleteUserById(req, res) {
    try {
      const { id } = req.params;
      const result = await userService.deleteUserById(id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // controllers/user.controller.js
  async updateUserStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!status)
        return res.status(400).json({ message: "status is required" });

      const updatedUser = await userService.updateUserStatus(id, status);
      res.status(200).json(updatedUser);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // user-service/controllers/user.controller.js
  async updateWalletInternal(req, res) {
    try {
      const { userId, amount } = req.body;

      if (!userId || amount === undefined) {
        return res.status(400).json({ message: "Thiếu userId hoặc amount" });
      }

      console.log(
        `💰 [User Service] Update Wallet: User ${userId} | Amount: ${amount}`
      );

      // Sử dụng model User đã import ở đầu file
      const user = await User.findByIdAndUpdate(
        userId,
        { $inc: { wallet_balance: Number(amount) } },
        { new: true, runValidators: true }
      );

      if (!user) {
        return res.status(404).json({ message: "Không tìm thấy User" });
      }

      console.log(`✅ Success! New Balance: ${user.wallet_balance}`);

      res.status(200).json({
        success: true,
        message: "Cập nhật ví thành công",
        newBalance: user.wallet_balance,
      });
    } catch (error) {
      console.error("❌ Lỗi update wallet:", error.message);
      res.status(500).json({ message: error.message });
    }
  }

  async approvePartner(req, res) {
    try {
      const partnerId = req.params.id; // Lấy ID partner cần duyệt từ URL
      const adminId = req.user.id; // Lấy ID admin đang thực hiện (để log nếu cần)

      // Gọi Service (đảm bảo bạn đã thêm hàm này bên user.service.js như đã bàn)
      const updatedUser = await userService.approvePartner(adminId, partnerId);

      setImmediate(() => {
        sendPartnerApprovedEmail({
          to: updatedUser.email,
          user: updatedUser,
        }).catch((err) =>
          console.error("Send approved email failed:", err.message)
        );
      });

      res.status(200).json({
        message: "Partner approved successfully",
        user: updatedUser,
      });
    } catch (error) {
      // Xử lý lỗi (ví dụ: User không phải partner, hoặc không tìm thấy)
      res.status(400).json({ message: error.message });
    }
  }
}

module.exports = new UserController();
