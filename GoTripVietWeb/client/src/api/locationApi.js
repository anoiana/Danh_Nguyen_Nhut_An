import axiosClient from "./axiosClient";

const locationApi = {
  // Public (Guest) - Chỉ lấy Active
  getAll(params) {
    return axiosClient.get("/locations", { params });
  },

  // [MỚI] Management (Admin/Partner) - Lấy Active + Pending
  getManage(params) {
    return axiosClient.get("/locations/manage", { params });
  },

  getById(id) {
    return axiosClient.get(`/locations/${id}`);
  },

  requestNew(payload) {
    return axiosClient.post("/locations/request", payload);
  },

  create(payload) {
    return axiosClient.post("/locations", payload);
  },

  update(id, payload) {
    return axiosClient.put(`/locations/${id}`, payload);
  },

  remove(id) {
    return axiosClient.delete(`/locations/${id}`);
  },

  uploadLocationImage(formData) {
    return axiosClient.post("/uploads/location-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
};

export default locationApi;
