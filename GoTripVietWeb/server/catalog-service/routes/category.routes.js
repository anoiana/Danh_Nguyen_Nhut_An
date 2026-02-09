// routes/category.routes.js
const express = require("express");
const router = express.Router();
const categoryController = require("../controllers/category.controller");
const authMiddleware = require("../middleware/auth.middleware");
const checkRole = require("../middleware/checkRole.middleware");

// --- Partner Routes ---
router.post(
  "/request",
  authMiddleware,
  checkRole(["partner", "admin"]),
  categoryController.requestCategory
);

// --- [MỚI] MANAGEMENT ROUTE ---
// Đặt trước router.get('/')
router.get(
  "/manage",
  authMiddleware,
  checkRole(["admin", "partner"]),
  categoryController.getAllCategories
);

// --- Public Routes ---
router.get("/", categoryController.getAllCategories);
router.get("/:idOrSlug", categoryController.getCategoryByIdOrSlug);

// --- Admin Routes ---
router.post(
  "/",
  authMiddleware,
  checkRole(["admin"]),
  categoryController.createCategory
);

router.put(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  categoryController.updateCategory
);

router.delete(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  categoryController.deleteCategory
);

module.exports = router;