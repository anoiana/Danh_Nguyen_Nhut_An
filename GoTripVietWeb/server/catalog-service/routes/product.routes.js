// routes/product.routes.js
const express = require("express");
const router = express.Router();
const productController = require("../controllers/product.controller");
const authMiddleware = require("../middleware/auth.middleware");
const checkRole = require("../middleware/checkRole.middleware");
const apiKeyAuth = require("../middleware/apiKey.middleware");
// --- 1. Partner Routes (Phải đặt trước các route có tham số) ---
router.get(
  "/partner/me",
  authMiddleware,
  checkRole(["partner", "admin"]),
  productController.getMyProducts
);

// --- 2. Admin Management Routes ---
// Lấy danh sách quản lý (Admin xem hết status)
router.get(
  "/admin/manage",
  authMiddleware,
  checkRole(["admin"]),
  productController.getProductsAdmin
);

// Xem chi tiết tour (Admin/Partner xem full status, reason...)
router.get(
  "/admin/:idOrSlug",
  authMiddleware,
  checkRole(["admin", "partner"]),
  productController.getProductByIdOrSlugAdmin
);

// --- 3. Public Routes (Cho khách hàng) ---
// Lấy danh sách (Chỉ Active)
router.get("/", productController.getProducts);

// Lấy chi tiết (Chỉ Active)
// Lưu ý: Route này bắt mọi GET request còn lại, nên phải đặt sau các route cụ thể bên trên
router.get("/:idOrSlug", productController.getProductByIdOrSlug);

// --- 4. Protected Routes (Tác động dữ liệu) ---

// [NEW] Duyệt / Từ chối Tour (Chỉ Admin)
router.patch(
  "/:id/status",
  authMiddleware,
  checkRole(["admin"]),
  productController.updateProductStatus
);

// Tạo sản phẩm (Admin / Partner)
router.post(
  "/",
  authMiddleware,
  checkRole(["admin", "partner"]),
  productController.createProduct
);

// Cập nhật sản phẩm
router.put(
  "/:id",
  authMiddleware,
  checkRole(["admin", "partner"]),
  productController.updateProduct
);

// Xóa sản phẩm
router.delete(
  "/:id",
  authMiddleware,
  checkRole(["admin", "partner"]),
  productController.deleteProduct
);

// --- 5. Schedule Routes ---
router.post(
  "/:id/schedules",
  authMiddleware,
  checkRole(["partner", "admin"]),
  productController.addSchedule
);

router.delete(
  "/:id/schedules/:scheduleId",
  authMiddleware,
  checkRole(["partner", "admin"]),
  productController.removeSchedule
);

router.get(
  '/internal/:id',
  apiKeyAuth, // Middleware check khóa nội bộ
  productController.getProductInternal
);

module.exports = router;