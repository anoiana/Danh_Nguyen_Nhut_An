// src/api/paymentApi.js
import axios from 'axios';

// 1. Tạo instance Axios cho Payment Service
// (Giữ nguyên port 3005 như file bạn gửi)
const paymentClient = axios.create({
  baseURL: 'http://localhost:3005',
  headers: {
    'Content-Type': 'application/json',
  },
});

// 2. Interceptor Request: Tự động gắn Token
// Quan trọng để Backend biết ai đang gọi API (Partner nào, User nào)
paymentClient.interceptors.request.use(async (config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => Promise.reject(error));

// 3. Interceptor Response: Trả về data gọn gàng
paymentClient.interceptors.response.use((response) => {
  return response.data;
}, (error) => Promise.reject(error));

const paymentApi = {

  // --- A. WALLET API (Dành cho Partner) ---

  // 1. [QUAN TRỌNG] Lấy thông tin ví & lịch sử giao dịch
  // Endpoint này sẽ trả về: { balance: 5000000, transactions: [...] }
  getWalletTransactions: () => {
    return paymentClient.get('/payment/wallet/me');
  },

  // 2. [QUAN TRỌNG] Yêu cầu rút tiền
  // Gửi số tiền và thông tin ngân hàng lên Server
  requestPayout: (amount, bankInfo) => {
    return paymentClient.post('/payment/payout-request', { amount, bankInfo });
  },

  // --- B. PAYMENT GATEWAY API (Dành cho User thanh toán Booking) ---

  /**
   * Tạo URL thanh toán VNPAY
   * @param {object} data - { amount, bookingId, bankCode, language }
   */
  createVNPayUrl: (data) => {
    return paymentClient.post("/payment/create-vnpay-url", data);
  },

  /**
   * Xác thực kết quả trả về từ VNPAY
   * (Gọi khi VNPAY redirect về frontend)
   */
  verifyVNPay: (params) => {
    return paymentClient.get("/payment/vnpay-return", { params });
  },

  // (Tùy chọn) Mock Payment để test nhanh mà không cần VNPAY thật
  processMockPayment: (bookingId) => {
    return paymentClient.post('/payment/mock-success', { bookingId });
  },

  getSystemStats: () => {
    return paymentClient.get('/payment/admin/stats');
  },
};



export default paymentApi;