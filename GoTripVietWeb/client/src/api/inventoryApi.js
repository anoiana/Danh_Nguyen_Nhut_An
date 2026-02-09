import axios from "axios";

// Cấu hình axios riêng cho Inventory Service (Port 3003)
const inventoryClient = axios.create({
  baseURL: "http://localhost:3003",
  headers: {
    "Content-Type": "application/json",
  },
});

// Interceptor: Tự động gắn Token vào Header để qua được Auth Middleware
inventoryClient.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

const inventoryApi = {
  // 1. Tên hàm mới (Dùng cho Admin)
  getByProductId: (productId) => {
    return inventoryClient.get(`/inventory/product/${productId}`);
  },

  // 2. [FIX LỖI] Giữ lại tên hàm cũ (Dùng cho Client/ProductDetail)
  getInventoryByProductId: (productId) => {
    return inventoryClient.get(`/inventory/product/${productId}`);
  },

  // POST: Tạo lịch mới
  create: (data) => {
    // data payload phải khớp với cấu trúc Backend yêu cầu
    return inventoryClient.post("/inventory", data);
  },

  // PATCH: Cập nhật (ví dụ sửa giá, số chỗ)
  update: (id, data) => {
    return inventoryClient.patch(`/inventory/${id}`, data);
  },

  // DELETE: Xóa lịch
  remove: (id) => {
    return inventoryClient.delete(`/inventory/${id}`);
  },
  // Kiểm tra mã giảm giá
  checkPromotion: (code) => {
    return inventoryClient.get(`/promotions/code/${code}`);
  },
  // EVENTS (PUBLIC)
  getActiveEvents: () => {
    return inventoryClient.get(`/events/active`);
  },
  // Lấy chi tiết sự kiện public theo id hoặc slug
  getPublicEventByIdOrSlug: (idOrSlug) => {
    return inventoryClient.get(`/events/public/${idOrSlug}`);
  },
  // Lấy danh sách tour áp dụng sự kiện public theo id hoặc slug
  getPublicEventTours: (idOrSlug) => {
    return inventoryClient.get(`/events/public/${idOrSlug}/tours`);
  },
  // Lấy tất cả event trong tháng (theo month 1-12)
  getEventsInMonth: (year, month) => {
    return inventoryClient.get(`/events/public/month`, {
      params: { year, month },
    });
  },

  getActivePromotionsPublic: () => {
    return inventoryClient.get("/promotions/public/active");
  },
};

export default inventoryApi;
