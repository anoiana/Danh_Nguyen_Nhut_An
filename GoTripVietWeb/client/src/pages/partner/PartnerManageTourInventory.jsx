// src/pages/admin/ManageTourInventory.jsx
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import InventoryManager from "../../components/admin/InventoryManager";

export default function ManageTourInventory() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tour, setTour] = useState(null);

  useEffect(() => {
    catalogApi.getById(id).then(res => {
      const t = res.data?.product || res.data || res;
      setTour(t);
    }).catch(console.error);
  }, [id]);

  return (
    <div style={{ maxWidth: 1000, margin: "0 auto", padding: 20 }}>
      {/* ... (Phần Header giữ nguyên) ... */}
      
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 900, marginBottom: 4 }}>Quản lý Tồn kho (Inventory)</h1>
          <div style={{ color: '#6b7280' }}>
            Tour: <b style={{ color: '#0b5fff' }}>{tour?.title || "Đang tải..."}</b>
          </div>
        </div>
        <button 
          onClick={() => nav(`/admin/manage/tours/${id}`)}
          style={{ padding: '10px 16px', borderRadius: 8, border: '1px solid #e5e7eb', background: '#fff', fontWeight: 700, cursor: 'pointer' }}
        >
          ← Quay lại Chi tiết
        </button>
      </div>

      {/* Truyền basePrice vào để làm giá mặc định */}
      <InventoryManager tourId={id} basePrice={tour?.base_price} />
    </div>
  );
}