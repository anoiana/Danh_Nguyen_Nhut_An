import axiosClient from "./axiosClient";

const catalogApi = {
  // --- SẢN PHẨM (Public) ---
  getAll: (params) => axiosClient.get("/products", { params }),
  getById: (id) => axiosClient.get(`/products/${id}`),
  
  // [NEW] API Quản lý cho Admin (Xem hết status)
  getManageTours: (params) => axiosClient.get("/products/admin/manage", { params }),

  // [NEW] API Duyệt/Từ chối Tour
  updateTourStatus: (id, status, reason) => 
    axiosClient.patch(`/products/${id}/status`, { status, reason }),

  getByIdAdmin: (idOrSlug) => axiosClient.get(`/products/admin/${idOrSlug}`),
  
  create: (payload) => axiosClient.post("/products", payload),
  update: (id, payload) => axiosClient.put(`/products/${id}`, payload),
  remove: (id) => axiosClient.delete(`/products/${id}`),
  
  uploadTourImage(formData) {
    return axiosClient.post("/uploads/tour-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  getPartnerTours(params) {
    return axiosClient.get("/products/partner/me", { params });
  },

  addSchedule(productId, data) {
    return axiosClient.post(`/products/${productId}/schedules`, data);
  },

  removeSchedule(productId, scheduleId) {
    return axiosClient.delete(`/products/${productId}/schedules/${scheduleId}`);
  },

  // --- ĐỊA ĐIỂM ---
  getAllLocations: (params) => axiosClient.get("/locations", { params }),
  getManageLocations: (params) => axiosClient.get("/locations/manage", { params }), // Đã thêm ở bước trước
  requestLocation: (payload) => axiosClient.post("/locations/request", payload),
  createLocation: (payload) => axiosClient.post("/locations", payload),
  updateLocation: (id, payload) => axiosClient.put(`/locations/${id}`, payload),
  deleteLocation: (id) => axiosClient.delete(`/locations/${id}`),
  uploadLocationImage(formData) {
    return axiosClient.post("/uploads/location-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  // --- DANH MỤC ---
  getAllCategories: (params) => axiosClient.get("/categories", { params }),
  getManageCategories: (params) => axiosClient.get("/categories/manage", { params }), // Đã thêm ở bước trước
  requestCategory: (payload) => axiosClient.post("/categories/request", payload),
  createCategory: (payload) => axiosClient.post("/categories", payload),
  updateCategory: (id, payload) => axiosClient.put(`/categories/${id}`, payload),
  deleteCategory: (id) => axiosClient.delete(`/categories/${id}`),
  uploadCategoryImage(formData) {
    return axiosClient.post("/uploads/category-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
};

export default catalogApi;