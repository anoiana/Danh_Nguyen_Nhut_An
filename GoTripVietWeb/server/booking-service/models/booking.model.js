// server/payment-service/models/booking.model.js
const mongoose = require('mongoose');

// 1. Schema Hạng mục (Booking Item)
const bookingItemSchema = new mongoose.Schema({
  product_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  inventory_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'InventoryItem',
    required: true,
  },
  product_type: {
    type: String,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  unit_price: {
    type: Number,
    required: true,
  },
  snapshot: {
    title: { type: String, required: true },
    description_short: String,
    image: String,
    details_text: String,
  }
}, { _id: false });

// 2. Schema Thanh toán (Lịch sử giao dịch nhúng)
const paymentSchema = new mongoose.Schema({
  gateway: { type: String, required: true }, // 'vnpay', 'stripe', 'momo'
  gateway_transaction_id: { type: String, required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['pending', 'succeeded', 'failed'], required: true },
  timestamp: { type: Date, default: Date.now },
}, { _id: true });

// 3. SCHEMA CHÍNH: ĐƠN HÀNG
const bookingSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
      ref: 'User' // Thêm ref User để sau này populate nếu cần
    },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'cancelled', 'failed', 'completed'],
      default: 'pending',
      index: true,
    },

    payment_status: {
      type: String,
      enum: ['unpaid', 'paid', 'refunded'],
      default: 'unpaid'
    },

    pricing: {
      total_price_before_discount: { type: Number, required: true },
      discount_amount: { type: Number, default: 0 },
      final_price: { type: Number, required: true },
    },

    promotion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Promotion',
    },

    passengers: [
      {
        type: { type: String, enum: ['adult', 'child', 'toddler', 'infant'], required: true },
        fullName: { type: String, required: true },
        gender: { type: String, enum: ['Nam', 'Nữ', 'Khác'] },
        dateOfBirth: { type: Date },
      }
    ],

    items: [bookingItemSchema],
    payments: [paymentSchema],

    customer_details: {
      fullName: String,
      email: String,
      phone: String,
      address: String,
      note: String
    },
    
    start_date: { type: Date, required: true },
    end_date: { type: Date, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Booking', bookingSchema);