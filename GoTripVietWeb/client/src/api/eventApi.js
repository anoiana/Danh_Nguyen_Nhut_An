import axiosClient from "./axiosClient";

const eventApi = {
  getAll() {
    return axiosClient.get("/events");
  },
  getById(id) {
    return axiosClient.get(`/events/${id}`);
  },
  create(payload) {
    return axiosClient.post("/events", payload);
  },
  update(id, payload) {
    return axiosClient.put(`/events/${id}`, payload);
  },
  remove(id) {
    return axiosClient.delete(`/events/${id}`);
  },
  toggleStatus(id) {
    return axiosClient.patch(`/events/${id}/status`);
  },
  uploadEventImage(formData) {
    // formData: append("file", file)
    return axiosClient.post("/events/upload-image", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
};

export default eventApi;
