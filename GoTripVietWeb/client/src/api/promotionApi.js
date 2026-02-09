// src/api/promotionApi.js
import axiosClient from "./axiosClient";

const promotionApi = {
  getAll() {
    return axiosClient.get("/promotions");
  },

  create(data) {
    return axiosClient.post("/promotions", data);
  },

  update(id, data) {
    return axiosClient.put(`/promotions/${id}`, data);
  },

  remove(id) {
    return axiosClient.delete(`/promotions/${id}`);
  },

  toggleStatus(id) {
    return axiosClient.patch(`/promotions/${id}/status`);
  },
};

export default promotionApi;
