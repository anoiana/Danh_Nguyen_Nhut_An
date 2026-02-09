// payment-service/models/transaction.model.js
const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    partner_id: { type: mongoose.Schema.Types.ObjectId, required: false, index: true }, // ID của Partner (null cho giao dịch hệ thống như VOUCHER_COST)
    booking_id: { type: mongoose.Schema.Types.ObjectId, required: false }, // Link tới đơn hàng (nếu có)

    type: {
        type: String,
        enum: ['INCOME', 'WITHDRAWAL', 'REFUND', 'COMMISSION', 'VOUCHER_COST'],
        required: true
    },

    amount: { type: Number, required: true }, // Số tiền biến động (+ hoặc -)
    description: { type: String },

    status: {
        type: String,
        enum: ['PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'],
        default: 'PENDING'
    },

    // Snapshot số dư tại thời điểm giao dịch (để đối soát)
    balance_after: { type: Number }
}, { timestamps: true });

module.exports = mongoose.model('Transaction', transactionSchema);