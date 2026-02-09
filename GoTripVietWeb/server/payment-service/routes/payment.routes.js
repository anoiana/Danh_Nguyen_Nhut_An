// routes/payment.routes.js
const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const authMiddleware = require('../middleware/auth.middleware');
const apiKeyAuth = require('../middleware/apiKey.middleware');
const checkRole = require('../middleware/checkRole.middleware');

// ==========================================
// 1. VNPAY API
// ==========================================

router.post(
  '/create-vnpay-url',
  // authMiddleware, // Uncomment if you want to force login to pay
  paymentController.createVNPayUrl
);

router.get('/vnpay-return', paymentController.vnpayReturn);


// ==========================================
// 2. PARTNER WALLET API (NEW)
// ==========================================

// Get Wallet Balance & Transaction History
router.get(
  '/wallet/me',
  authMiddleware, // Requires User Token
  paymentController.getMyWallet
);

// Request Payout (Withdrawal)
router.post(
  '/payout-request',
  authMiddleware, // Requires User Token
  paymentController.requestPayout
);


// ==========================================
// 3. INTERNAL API (Service-to-Service)
// ==========================================

// [NEW] Distribute Revenue (Called by Cron Job)
router.post(
  '/internal/distribute-revenue',
  apiKeyAuth, // Protected by Internal API Key
  paymentController.distributeRevenue
);

// Refund Payment
router.post(
  '/refund',
  apiKeyAuth,
  paymentController.refundPayment
);


// ==========================================
// 4. ADMIN API
// ==========================================

router.get(
  '/admin/all',
  authMiddleware,
  checkRole(['admin']),
  paymentController.adminGetAllPayments
);

router.get(
  '/booking/:bookingId',
  authMiddleware,
  checkRole(['admin']),
  paymentController.adminGetPaymentsForBooking
);

router.get(
  '/admin/stats',
  // authMiddleware,             // Uncomment khi muốn bảo vệ
  // checkRole(['admin']),       // Uncomment khi muốn bảo vệ
  paymentController.getSystemStats
);

module.exports = router;