// routes/user.routes.js
const express = require("express");
const router = express.Router();
const userController = require("../controllers/user.controller");
const checkRole = require("../middleware/checkRole.middleware");

// --- QUAN TRỌNG: Import middleware ở đây ---
const authMiddleware = require("../middleware/auth.middleware");
const apiKeyAuth = require('../middleware/apiKey.middleware');
// --- CÁC TUYẾN ĐƯỜNG ĐƯỢC BẢO VỆ ---

// GET /users/me
// Gắn authMiddleware vào đây
router.get("/me", authMiddleware, userController.getMyProfile);

// PUT /users/me
router.put("/me", authMiddleware, userController.updateMyProfile);

// PUT /users/me/preferences
router.put(
  "/me/preferences",
  authMiddleware,
  userController.updateMyPreferences
);

// --- API DÀNH CHO ADMIN ---
// GET /users
// Bảo vệ 2 lớp: 1. Phải đăng nhập, 2. Phải là 'admin'
router.get(
  "/", // (Lưu ý: đường dẫn là '/' vì app.js đã gắn '/users')
  authMiddleware,
  checkRole(["admin"]), // Chỉ admin
  userController.getAllUsers
);

// PUT /users/:id/role
router.put(
  "/:id/role",
  authMiddleware,
  checkRole(["admin"]), // Chỉ admin
  userController.updateUserRole
);

// GET /users/:id (Lấy 1 user)
router.get(
  "/:id",
  authMiddleware,
  checkRole(["admin", "partner"]),
  userController.getUserById
);

// PUT /users/:id (Cập nhật 1 user)
router.put(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  userController.updateUserById
);

// DELETE /users/:id (Xóa 1 user)
router.delete(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  userController.deleteUserById
);

// routes/user.routes.js
router.put(
  "/:id/status",
  authMiddleware,
  checkRole(["admin"]),
  userController.updateUserStatus
);

router.post(
  '/internal/wallet/add',
  apiKeyAuth,
  userController.updateWalletInternal
);

router.patch(
  "/:id/approve",
  authMiddleware,        // 1. Phải đăng nhập
  checkRole(["admin"]),  // 2. Phải là Admin
  userController.approvePartner
);

router.post(
  '/internal/wallet/update',
  apiKeyAuth, // Bắt buộc phải có API Key nội bộ
  userController.updateWalletInternal
);

module.exports = router;
