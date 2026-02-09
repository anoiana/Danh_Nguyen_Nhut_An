// server/booking-service/cron/completedCheck.cron.js
const cron = require('node-cron');
const axios = require('axios');
const Booking = require('../models/booking.model');

// Config
const CATALOG_URL = process.env.CATALOG_SERVICE_URL || 'http://localhost:3001';
const PAYMENT_URL = process.env.PAYMENT_SERVICE_URL || 'http://localhost:3005';
const API_KEY = process.env.INTERNAL_API_KEY;

const checkAndCompleteBookings = async () => {
  console.log('⏰ [CRON] Đang quét các tour đã kết thúc...');

  try {
    const now = new Date();

    // 1. Tìm các booking 'confirmed' VÀ có end_date nhỏ hơn hiện tại
    const expiredBookings = await Booking.find({
      status: 'confirmed',
      end_date: { $lt: now }
    });

    if (expiredBookings.length === 0) {
      // console.log('ℹ️ Không có tour nào cần hoàn tất.');
      return;
    }

    console.log(`Đang xử lý ${expiredBookings.length} tour đã hoàn thành...`);

    // 2. Xử lý từng booking
    for (const booking of expiredBookings) {
      try {
        console.log(`⚡ Bắt đầu xử lý đơn: ${booking._id}`);

        // A. Cập nhật trạng thái
        booking.status = 'completed';
        await booking.save();

        // B. Chia tiền (Admin chịu phí giảm giá -> Tính trên GIÁ GỐC)
        const productId = booking.items[0].product_id;

        // Gọi Catalog Service để lấy Partner ID
        const productRes = await axios.get(`${CATALOG_URL}/products/internal/${productId}`, {
          headers: { 'x-api-key': API_KEY }
        });

        const partnerId = productRes.data.product?.partner_id || productRes.data.partner_id;

        if (partnerId) {
          // Gọi Payment Service để chia tiền
          // Lấy discount amount trực tiếp từ booking (hoặc tính nếu không có)
          const discountAmount = booking.pricing.discount_amount ||
            ((booking.pricing.total_price_before_discount || 0) - (booking.pricing.final_price || booking.pricing.total_price_before_discount || 0));

          console.log(`📊 Booking ${booking._id}: Giá gốc=${booking.pricing.total_price_before_discount}, Giá cuối=${booking.pricing.final_price}, Giảm giá=${discountAmount}`);

          await axios.post(
            `${PAYMENT_URL}/payment/internal/distribute-revenue`,
            {
              bookingId: booking._id,
              partnerId: partnerId,
              amount: booking.pricing.total_price_before_discount,
              discountAmount: discountAmount > 0 ? discountAmount : 0,
              description: `Doanh thu tour hoàn thành #${booking._id.toString().slice(-6).toUpperCase()}`
            },
            { headers: { 'x-api-key': API_KEY } }
          );
          console.log(`✅ Đã hoàn tất & Chia tiền (Theo giá gốc): Booking ${booking._id}`);
        } else {
          console.error(`⚠️ Không tìm thấy Partner cho Booking ${booking._id}, chưa chia tiền.`);
        }

      } catch (err) {
        // 👇 THÊM ĐOẠN LOG NÀY 👇
        if (err.response) {
          console.error("❌ AXIOS ERROR URL:", err.config.url); // In ra URL thực tế bị lỗi
          console.error("❌ AXIOS METHOD:", err.config.method);
          console.error("❌ STATUS:", err.response.status);
        }
        console.error(`❌ Lỗi xử lý booking ${booking._id}:`, err.message);
      }
    }

  } catch (error) {
    console.error('❌ [CRON] Lỗi Cron Job:', error);
  }
};

const startCronJob = () => {
  // Lịch chạy: Mỗi tiếng 1 lần
  cron.schedule('0 * * * *', () => {
    checkAndCompleteBookings();
  });

  // 👇 CHẠY NGAY LẬP TỨC KHI KHỞI ĐỘNG SERVER 👇
  console.log('🚀 Cron Job đã khởi động. Đang chạy quét lần đầu tiên...');
  checkAndCompleteBookings();
};

module.exports = startCronJob;