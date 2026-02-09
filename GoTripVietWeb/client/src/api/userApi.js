// src/api/userApi.js
import axiosClient from "./axiosClient";

const userApi = {
  // GET /users?page=&limit=
  getAll: (params = { page: 1, limit: 100 }) => {
    return axiosClient.get("/users", { params });
  },

  // GET /users/:id
  getById: (id) => axiosClient.get(`/users/${id}`),

  // PUT /users/:id  (update fullName, phone)
  updateById: (id, data) => axiosClient.put(`/users/${id}`, data),

  // DELETE /users/:id
  deleteById: (id) => axiosClient.delete(`/users/${id}`),

  // PUT /users/:id/role  (roles: array)
  updateRole: (id, roles) => axiosClient.put(`/users/${id}/role`, { roles }),

  // PUT /users/:id/status  (status: "ACTIVE" | "LOCKED" | "BANNED")
  updateStatus: (id, status) =>
    axiosClient.put(`/users/${id}/status`, { status }),

  approvePartner: (id) => {
    return axiosClient.patch(`/users/${id}/approve`);
  },

  // [MỚI] Lấy danh sách Partner (có thể filter theo status)
  getAllPartners: (params = {}) => {
    // Giả sử backend hỗ trợ filter role=partner
    return axiosClient.get("/users", { params: { ...params, role: "partner" } });
  }
};

export default userApi;
