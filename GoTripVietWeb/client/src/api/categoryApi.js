import axiosClient from "./axiosClient";

const categoryApi = {
  // Public
  getAll(params) {
    return axiosClient.get("/categories", { params });
  },

  // [MỚI] Management
  getManage(params) {
    return axiosClient.get("/categories/manage", { params });
  },

  getById(idOrSlug) {
    return axiosClient.get(`/categories/${idOrSlug}`);
  },

  requestNew(payload) {
    return axiosClient.post("/categories/request", payload);
  },

  create(payload) {
    return axiosClient.post("/categories", payload);
  },

  update(id, payload) {
    return axiosClient.put(`/categories/${id}`, payload);
  },

  remove(id) {
    return axiosClient.delete(`/categories/${id}`);
  },

  uploadCategoryImage(formData) {
    return axiosClient.post("/uploads/category-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  }
};

export default categoryApi;