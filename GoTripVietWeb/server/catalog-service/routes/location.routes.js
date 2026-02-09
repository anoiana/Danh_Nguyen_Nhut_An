// routes/location.routes.js
const express = require('express');
const router = express.Router();
const locationController = require('../controllers/location.controller');
const authMiddleware = require('../middleware/auth.middleware');
const checkRole = require('../middleware/checkRole.middleware');

// --- Partner Routes ---
router.post(
  '/request',
  authMiddleware,
  checkRole(['partner', 'admin']),
  locationController.requestLocation
);

// --- [MỚI] MANAGEMENT ROUTE (Dành cho Admin & Partner xem danh sách đầy đủ) ---
// Route này PHẢI đặt trước router.get('/', ...)
router.get(
  '/manage',
  authMiddleware,
  checkRole(['admin', 'partner']),
  locationController.getAllLocations // Controller sẽ tự check req.user để trả về dữ liệu đúng
);

// --- Public Routes ---
// GET /locations (Dành cho khách vãng lai - Chỉ thấy Active)
router.get('/', locationController.getAllLocations);

// GET /locations/:idOrSlug
router.get('/:idOrSlug', locationController.getLocationByIdOrSlug);

// --- Admin Routes ---
router.post(
  '/',
  authMiddleware,
  checkRole(['admin']),
  locationController.createLocation
);

router.put(
  '/:id',
  authMiddleware,
  checkRole(['admin']),
  locationController.updateLocation
);

router.delete(
  '/:id',
  authMiddleware,
  checkRole(['admin']),
  locationController.deleteLocation
);

module.exports = router;