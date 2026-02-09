import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
// 👇 IMPORT QUAN TRỌNG: Tái sử dụng component quản lý kho của Admin
import InventoryManager from "../../components/admin/InventoryManager";

export default function PartnerInventory() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tour, setTour] = useState(null);

  // 1. Chỉ cần lấy thông tin Tour để hiện tên và lấy giá gốc
  useEffect(() => {
    const fetchTourInfo = async () => {
      try {
        const res = await catalogApi.getById(id);
        // Xử lý response linh hoạt (tùy cấu trúc backend trả về)
        const data = res.data?.product || res.data || res;
        setTour(data);
      } catch (error) {
        console.error("Lỗi tải thông tin tour:", error);
      }
    };

    fetchTourInfo();
  }, [id]);

  return (
    <div style={{ maxWidth: 1000, margin: "0 auto", padding: "20px 20px 40px" }}>

      {/* --- PHẦN HEADER (Giống hệt Admin) --- */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 24,
        paddingBottom: 20,
        borderBottom: '1px solid #eee'
      }}>
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 800, color: '#111827', marginBottom: 4 }}>
            Quản lý Lịch & Tồn kho
          </h1>
          <div style={{ color: '#6b7280', fontSize: 15 }}>
            Đang thiết lập cho Tour: <b style={{ color: '#0b5fff' }}>{tour?.title || "Đang tải..."}</b>
          </div>
        </div>

        <button
          onClick={() => nav("/partner/tours")} // Quay về danh sách Tour của Partner
          style={{
            padding: '10px 18px',
            borderRadius: 8,
            border: '1px solid #e5e7eb',
            background: '#fff',
            color: '#374151',
            fontWeight: 600,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
          }}
        >
          <span>←</span> Quay lại
        </button>
      </div>

      {/* --- CORE COMPONENT (Tái sử dụng của Admin) --- */}
      {/* Component này sẽ tự lo việc gọi API create/delete inventory */}
      <InventoryManager
        tourId={id}
        basePrice={tour?.base_price}
      />

    </div>
  );
}