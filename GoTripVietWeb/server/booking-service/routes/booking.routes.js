// routes/booking.routes.js
const express = require('express');
const router = express.Router();
// ✅ FIXED: Must import bookingController, NOT productController
const bookingController = require('../controllers/booking.controller');
const authMiddleware = require('../middleware/auth.middleware');
const checkRole = require('../middleware/checkRole.middleware');
const apiKeyAuth = require('../middleware/apiKey.middleware');

// --- [NEW] INTERNAL API (Service-to-Service) ---
// Payment Service calls this to confirm payment. Protected by API Key.
router.post(
  '/internal/confirm-payment',
  apiKeyAuth,
  bookingController.confirmPaymentInternal
);

// [DEBUG] Kiểm tra thông tin booking (tạm thời)
router.get(
  '/internal/debug/:id',
  apiKeyAuth,
  async (req, res) => {
    try {
      const Booking = require('../models/booking.model');
      const booking = await Booking.findById(req.params.id);
      if (!booking) return res.status(404).json({ message: 'Booking not found' });
      res.json({
        _id: booking._id,
        status: booking.status,
        pricing: booking.pricing,
        promotion_id: booking.promotion_id,
        start_date: booking.start_date,
        end_date: booking.end_date
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// -----------------------------------------------------
// AUTHENTICATED ROUTES (USER & PARTNER)
// -----------------------------------------------------
router.use(authMiddleware);

// --- [NEW] PARTNER ROUTES ---
// ⚠️ IMPORTANT: Place these BEFORE '/:id' to avoid conflicts

// 1. Get Partner's Order List
router.get(
  '/partner/me',
  checkRole(['partner', 'admin']),
  bookingController.getPartnerBookings
);

// 2. Get Partner's Order Detail (Bypasses User owner check)
router.get(
  '/partner/detail/:id',
  checkRole(['partner', 'admin']),
  bookingController.getPartnerBookingDetail
);

// --- USER ROUTES ---

// Create new booking
router.post('/', bookingController.createBooking);

// Get my booking history
router.get('/my-bookings', bookingController.getMyBookings);
router.get('/', bookingController.getMyBookings); // Root alias

// Get single booking detail
// ⚠️ This has a parameter :id, so keep it BELOW specific routes like /partner/me
router.get('/:id', bookingController.getBookingDetails);

// Cancel booking
router.post(
  '/:id/cancel',
  bookingController.cancelBooking
);

// -----------------------------------------------------
// ADMIN ROUTES
// -----------------------------------------------------

router.get(
  '/admin/all',
  checkRole(['admin']),
  bookingController.adminGetAllBookings
);

router.get(
  '/admin/user/:userId',
  checkRole(['admin']),
  bookingController.adminGetBookingsForUser
);

router.post(
  '/:id/admin/cancel',
  checkRole(['admin']),
  bookingController.adminCancelBooking
);

module.exports = router;