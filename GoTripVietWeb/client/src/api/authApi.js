// src/api/authApi.js
import axiosClient from './axiosClient';

const authApi = {
  login: (data) => {
    // data = { email, password }
    // Đường dẫn này khớp với route bên User Service
    return axiosClient.post('/auth/login', data);
  },
  
  register: (data) => {
    // data = { email, password, fullName, ... }
    return axiosClient.post('/auth/register', data);
  },

  getProfile: () => {
    return axiosClient.get('/users/me');
  },

  // [MỚI] Hàm cập nhật thông tin
  updateProfile: (data) => {
    // data gồm { fullName, phone, ... }
    return axiosClient.put('/users/me', data);
  },

  forgotPassword: (email) => {
    // Backend cần endpoint này (thường là POST /auth/forgot-password)
    return axiosClient.post('/auth/forgot-password', { email });
  }


};

export default authApi;