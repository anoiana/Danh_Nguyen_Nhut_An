// models/payment.model.js
const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    booking_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'Booking',
    },
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User', // VNPAY return might not always have user_id immediately visible, so removing 'required' is safer for now
    },
    amount: {
      type: Number,
      required: true,
    },
    currency: {
      type: String,
      default: 'vnd',
    },
    status: {
      type: String,
      enum: ['pending', 'succeeded', 'failed', 'refunded'],
      default: 'pending',
    },

    // --- [UPDATED] GATEWAY INFO ---
    gateway: {
      type: String,
      enum: ['vnpay'], // Only VNPAY now
      default: 'vnpay',
    },

    // Replaces stripe_payment_intent_id
    // Stores the transaction number from VNPAY for reconciliation
    gateway_transaction_id: {
      type: String,
    },

    // --- REFUND INFO ---
    amount_refunded: {
      type: Number,
      default: 0
    },
    refunded_at: {
      type: Date
    },

    transaction_date: {
      type: Date,
      default: Date.now
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', paymentSchema);