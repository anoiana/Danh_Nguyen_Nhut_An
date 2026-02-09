import axios from "axios";

const axiosClient = axios.create({
  // LƯU Ý QUAN TRỌNG:
  // - Nếu chạy qua Gateway: dùng port 3000
  // - Nếu chạy thẳng User Service (để test nhanh): dùng port 3001
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000",
});

// Interceptor: Tự động gắn Token vào mọi request nếu có
axiosClient.interceptors.request.use(async (config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  // Chỉ set JSON khi data là object thường (không phải FormData)
  const isFormData =
    typeof FormData !== "undefined" && config.data instanceof FormData;

  if (!isFormData && config.data && !config.headers["Content-Type"]) {
    config.headers["Content-Type"] = "application/json";
  }
  return config;
});

// Interceptor: Xử lý lỗi chung
axiosClient.interceptors.response.use(
  (response) => (response && response.data ? response.data : response),
  (error) => {
    throw error;
  }
);

export default axiosClient;
