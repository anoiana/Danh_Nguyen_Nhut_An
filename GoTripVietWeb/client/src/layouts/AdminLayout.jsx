import React, { useEffect } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import NavbarAdmin from "../components/admin/NavbarAdmin";
import { ensureAdminSeed } from "../data/adminStore";

import AdminProfile from "../pages/admin/AdminProfile";
import DashboardAdvanced from "../pages/admin/DashboardAdvanced";
import ManageCategory from "../pages/admin/ManageCategory";
import ManageLocation from "../pages/admin/ManageLocation";
import ManageTours from "../pages/admin/ManageTours";
import ManageTourDetail from "../pages/admin/ManageTourDetail";
import CreateTour from "../pages/admin/CreateTour";
import ManageUsers from "../pages/admin/ManageUsers";
import ManageAdmins from "../pages/admin/ManageAdmins";
// 👇 [MỚI] Import component ManagePartners
import ManagePartners from "../pages/admin/ManagePartners";

import ManageExpenses from "../pages/admin/ManageExpenses";
import ManagePromotion from "../pages/admin/ManagePromotion";
import ManageEvents from "../pages/admin/ManageEvents";
import ManageOrders from "../pages/admin/ManageOrders";
import ManageTourInventory from "../pages/admin/ManageTourInventory";

export default function AdminLayout() {
  useEffect(() => {
    ensureAdminSeed();
  }, []);

  return (
    <div style={{ display: "flex", minHeight: "100vh", background: "#f6f7fb" }}>
      <NavbarAdmin />

      <div style={{ flex: 1, padding: 20, minWidth: 0, overflowX: "hidden" }}>
        <Routes>
          {/* Chuyển hướng mặc định */}
          <Route path="/" element={<Navigate to="dashboard/advanced" replace />} />

          <Route path="dashboard/advanced" element={<DashboardAdvanced />} />

          <Route path="profile" element={<AdminProfile />} />

          <Route path="manage/categories" element={<ManageCategory />} />
          <Route path="manage/locations" element={<ManageLocation />} />

          {/* --- QUẢN LÝ TOUR --- */}
          <Route path="manage/tours" element={<ManageTours />} />
          <Route path="manage/tours/create" element={<CreateTour />} />
          <Route path="manage/tours/:id" element={<ManageTourDetail />} />
          <Route path="manage/tours/:id/inventory" element={<ManageTourInventory />} />

          <Route path="manage/promotions" element={<ManagePromotion />} />
          <Route path="manage/events" element={<ManageEvents />} />

          {/* --- QUẢN LÝ TÀI KHOẢN --- */}
          <Route path="manage/users" element={<ManageUsers />} />
          <Route path="manage/admins" element={<ManageAdmins />} />

          {/* 👇 [MỚI] Thêm Route cho trang Partners */}
          <Route path="manage/partners" element={<ManagePartners />} />


          {/* Route bắt các link sai -> Quay về dashboard chính */}
          <Route path="*" element={<Navigate to="/admin/dashboard/advanced" replace />} />
        </Routes>
      </div>
    </div>
  );
}