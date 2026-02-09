// routes/inventory.routes.js
const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventory.controller');

// Import cả 2 middleware
const authMiddleware = require('../middleware/auth.middleware');
const checkRole = require('../middleware/checkRole.middleware');
const serviceAuthMiddleware = require('../middleware/serviceAuth.middleware'); // <-- [MỚI]

// --- Public Route (Cho Frontend) ---
router.get(
  '/product/:productId',
  inventoryController.getInventoryForProduct
);

// --- Admin/Partner Routes (Quản lý kho) ---
// (Các API này GIỮ NGUYÊN, BẮT BUỘC phải là Admin/Partner)
router.post(
  '/',
  authMiddleware, // Dùng middleware cũ
  checkRole(['admin', 'partner']),
  inventoryController.createInventory
);
router.put(
  '/:id',
  authMiddleware, // Dùng middleware cũ
  checkRole(['admin', 'partner']),
  inventoryController.updateInventory
);
router.delete(
  '/:id',
  authMiddleware, // Dùng middleware cũ
  checkRole(['admin', 'partner']),
  inventoryController.deleteInventory
);


// --- API NỘI BỘ (CHO BOOKING SERVICE) ---
// (SỬ DỤNG MIDDLEWARE MỚI)

// POST /inventory/check
router.post(
  '/check',
  serviceAuthMiddleware, // <-- THAY ĐỔI
  inventoryController.checkStock
);

// POST /inventory/reserve
router.post(
  '/reserve',
  serviceAuthMiddleware, // <-- THAY ĐỔI
  inventoryController.reserveStock
);

// POST /inventory/release
router.post(
  '/release',
  serviceAuthMiddleware, // <-- THAY ĐỔI
  inventoryController.releaseStock
);

router.get(
  '/internal/:id',
  // apiKeyAuth, // Uncomment nếu đã có middleware này bên Inventory
  inventoryController.getInventoryInternal
);

module.exports = router;