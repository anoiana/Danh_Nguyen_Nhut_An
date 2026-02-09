// controllers/booking.controller.js
const bookingService = require('../services/booking.service');

class BookingController {

  // --- 1. USER: CREATE BOOKING ---
  // Note: The logic to calculate start_date/end_date is handled inside bookingService.createBooking
  async createBooking(req, res) {
    try {
      const userId = req.user.id;
      // Get data from Frontend
      const { items, promotionCode, passengers, contactInfo } = req.body;
      const userAuthToken = req.headers['authorization'];

      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ message: '"items" array is required' });
      }

      // Call Service
      const result = await bookingService.createBooking({
        userId,
        items,
        promotionCode,
        userAuthToken,
        passengers,
        contactInfo
      });

      res.status(201).json(result);

    } catch (error) {
      console.error("Create Booking Error:", error.message);
      res.status(400).json({ message: error.message });
    }
  }

  // --- 2. USER: GET HISTORY & DETAILS ---
  async getMyBookings(req, res) {
    try {
      const userId = req.user.id;
      const bookings = await bookingService.getBookingsByUserId(userId);
      res.status(200).json(bookings);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async getBookingDetails(req, res) {
    try {
      const userId = req.user.id;
      const bookingId = req.params.id;
      const booking = await bookingService.getBookingDetails(bookingId, userId);
      res.status(200).json(booking);
    } catch (error) {
      if (error.message.startsWith('Forbidden')) return res.status(403).json({ message: error.message });
      if (error.message.startsWith('Booking not found')) return res.status(404).json({ message: error.message });
      res.status(500).json({ message: error.message });
    }
  }

  async cancelBooking(req, res) {
    try {
      const userId = req.user.id;
      const bookingId = req.params.id;
      const userAuthToken = req.headers['authorization'];
      const booking = await bookingService.cancelBooking(bookingId, userId, userAuthToken);
      res.status(200).json(booking);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // --- 3. PARTNER: MANAGE ORDERS (The logic you are working on) ---

  // Get list of orders for Partner
  async getPartnerBookings(req, res) {
    try {
      const partnerId = req.user.id;
      const userToken = req.headers['authorization']; // Needed to call Catalog Service to find my products

      const result = await bookingService.getPartnerBookings(partnerId, userToken, req.query);

      // Returns object { bookings, total, currentPage... }
      res.status(200).json(result);
    } catch (error) {
      console.error("Get Partner Bookings Error:", error.message);
      res.status(500).json({ message: error.message });
    }
  }

  // Get order detail for Partner (Bypasses owner check)
  async getPartnerBookingDetail(req, res) {
    try {
      const bookingId = req.params.id;
      const booking = await bookingService.getPartnerBookingDetail(bookingId);
      res.status(200).json(booking);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // --- 4. INTERNAL: PAYMENT WEBHOOK ---
  async confirmPaymentInternal(req, res) {
    try {
      const { bookingId, paymentInfo } = req.body;
      if (!bookingId) return res.status(400).json({ message: 'Missing bookingId' });

      console.log(`⚡ Booking Service received confirm for: ${bookingId}`);
      const updatedBooking = await bookingService.confirmBooking(bookingId, paymentInfo);
      res.status(200).json(updatedBooking);
    } catch (error) {
      console.error('Confirm Payment Error:', error.message);
      res.status(500).json({ message: error.message });
    }
  }

  // --- 5. ADMIN ---
  async adminGetAllBookings(req, res) {
    try {
      const result = await bookingService.getAllBookings(req.query);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async adminGetBookingsForUser(req, res) {
    try {
      const bookings = await bookingService.getBookingsByUserId(req.params.userId);
      res.status(200).json(bookings);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async adminCancelBooking(req, res) {
    try {
      const adminAuthToken = req.headers['authorization'];
      const bookingId = req.params.id;
      const booking = await bookingService.adminCancelBooking(bookingId, adminAuthToken);
      res.status(200).json(booking);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }
}

module.exports = new BookingController();