// routes/promotion.routes.js
const express = require("express");
const router = express.Router();
const promotionController = require("../controllers/promotion.controller");
const authMiddleware = require("../middleware/auth.middleware");
const checkRole = require("../middleware/checkRole.middleware");

// --- Public Route (Cho Booking Service kiểm tra mã) ---
router.get("/public/active", promotionController.getActivePromotions);
router.get("/code/:code", promotionController.getPromotionByCode);

// --- Internal Routes (Service-to-Service) ---
router.post("/internal/redeem", promotionController.redeemPromotion);

// --- Admin Routes (Quản lý mã) ---
router.post(
  "/",
  authMiddleware,
  checkRole(["admin"]),
  promotionController.createPromotion
);

router.get(
  "/",
  authMiddleware,
  checkRole(["admin", "user"]),
  promotionController.getAllPromotions
);

router.put(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  promotionController.updatePromotion
);

router.delete(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  promotionController.deletePromotion
);

router.patch(
  "/:id/status",
  authMiddleware,
  checkRole(["admin"]),
  promotionController.toggleStatus
);

module.exports = router;
