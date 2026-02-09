// src/api/bookingApi.js
import axios from 'axios';

// 1. Tạo instance Axios riêng cho Booking Service
// (Booking Service chạy ở port 3004)
const bookingClient = axios.create({
  baseURL: 'http://localhost:3004',
  headers: {
    'Content-Type': 'application/json',
  },
});

// 2. Interceptor Request: Tự động gắn Token vào header
bookingClient.interceptors.request.use(async (config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

// 3. Interceptor Response: Trả về data gọn gàng
bookingClient.interceptors.response.use((response) => {
  // Trả về response.data để component không cần gọi .data lần nữa
  return response.data;
}, (error) => {
  return Promise.reject(error);
});

const bookingApi = {
  // --- USER APIs ---

  // 1. Tạo đơn hàng mới
  createBooking: (data) => {
    return bookingClient.post('/bookings', data);
  },

  // 2. Lấy danh sách đơn hàng của chính User đang đăng nhập
  getMyBookings: () => {
    return bookingClient.get('/bookings/my-bookings');
  },

  // --- PARTNER APIs ---

  // 3. [MỚI] Lấy danh sách Booking dành cho Partner
  // Gọi vào endpoint mà chúng ta vừa thêm ở Backend: /bookings/partner/me
  getPartnerBookings: (params) => {
    return bookingClient.get('/bookings/partner/me', { params });
  },

  // --- SHARED APIs ---

  // 4. Lấy chi tiết đơn hàng
  getBookingDetails: (id) => {
    return bookingClient.get(`/bookings/${id}`);
  },

  // 5. Cập nhật trạng thái đơn hàng (Thường dùng cho Admin hoặc luồng thanh toán)
  updateStatus: (id, status) => {
    return bookingClient.patch(`/bookings/${id}/status`, { status });
  },

  // 6. Hủy đơn hàng
  cancelBooking: (id) => {
    return bookingClient.post(`/bookings/${id}/cancel`);
  },

  getPartnerBookingDetail: (id) => {
    return bookingClient.get(`/bookings/partner/detail/${id}`);
  },

  updateStatus: (id, status) => {
    return bookingClient.patch(`/bookings/${id}/status`, { status });
  },
};

export default bookingApi;