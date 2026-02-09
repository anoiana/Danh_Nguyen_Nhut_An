import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import InventoryManager from "../../components/admin/InventoryManager";

export default function ManageTourInventory() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tour, setTour] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load thông tin tour để hiển thị tiêu đề
    catalogApi.getById(id)
      .then(res => {
        const t = res.data?.product || res.data || res;
        setTour(t);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div style={{ padding: 20, color: '#6b7280' }}>Đang tải thông tin tour...</div>;

  return (
    <div style={{ maxWidth: 1200, margin: "0 auto", padding: "20px" }}>

      {/* HEADER */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'start',
        marginBottom: 24,
        background: '#fff',
        padding: 24,
        borderRadius: 16,
        boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
        border: '1px solid #e5e7eb'
      }}>
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 900, color: '#111827', margin: 0 }}>
            📦 Lịch Khởi Hành & Tồn Kho
          </h1>
          <div style={{ marginTop: 8, color: '#6b7280', fontSize: 14 }}>
            Tour: <b style={{ color: '#0b5fff' }}>{tour?.title}</b>
          </div>
          <div style={{ marginTop: 4, color: '#6b7280', fontSize: 13, fontFamily: 'monospace' }}>
            ID: {id}
          </div>

          {/* ⚠️ CẢNH BÁO CHẾ ĐỘ READ-ONLY CHO ADMIN */}
          <div style={{
            marginTop: 16,
            background: '#fff7ed',
            border: '1px solid #fdba74',
            color: '#c2410c',
            padding: '10px 14px',
            borderRadius: 8,
            fontSize: 13,
            display: 'inline-flex',
            alignItems: 'center',
            gap: 8,
            fontWeight: 600
          }}>
            <span>🔒</span>
            <span>CHẾ ĐỘ CHỈ XEM (READ-ONLY): Admin không được phép chỉnh sửa Lịch trình & Giá của Partner.</span>
          </div>
        </div>

        <button
          onClick={() => nav(`/admin/manage/tours/${id}`)}
          style={{
            padding: '10px 18px',
            borderRadius: 10,
            border: '1px solid #e5e7eb',
            background: '#fff',
            color: '#374151',
            fontWeight: 700,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
          }}
        >
          ⬅ Quay lại Kiểm Duyệt
        </button>
      </div>

      {/* CONTENT */}
      <div style={{ background: '#fff', borderRadius: 16, border: '1px solid #e5e7eb', overflow: 'hidden', padding: 20 }}>
        {/* Truyền prop readOnly={true} xuống Component con. 
            InventoryManager sẽ tự động ẩn các nút Thêm/Sửa/Xóa.
          */}
        <InventoryManager
          tourId={id}
          basePrice={tour?.base_price}
          readOnly={true}
        />
      </div>
    </div>
  );
}