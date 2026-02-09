// src/components/ProtectedRoute.jsx
import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

// Hàm lấy thông tin user từ localStorage
const getUser = () => {
  const userStr = localStorage.getItem("user");
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch (e) {
    return null;
  }
};

const ProtectedRoute = ({ roles = [], children }) => {
  const user = getUser();

  // 1. Nếu chưa đăng nhập -> Đá về trang login
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // 2. Nếu có yêu cầu role cụ thể (ví dụ ['admin'])
  if (roles.length > 0) {
    // Kiểm tra xem user có quyền không (user.roles là mảng)
    const userRoles = user.roles || [];
    const hasPermission = roles.some(role => userRoles.includes(role));

    if (!hasPermission) {
      // Đăng nhập rồi nhưng không đủ quyền -> Đá về trang chủ hoặc trang 403
      alert("Bạn không có quyền truy cập trang này!");
      return <Navigate to="/" replace />;
    }
  }

  // 3. Hợp lệ -> Cho phép hiển thị nội dung bên trong
  return children ? children : <Outlet />;
};

export default ProtectedRoute;