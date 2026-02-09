import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import "../../styles/admin/ManageTours.css"  // [QUAN TRỌNG] Import file CSS mới

// --- HELPERS ---
function pickFirstImage(images) {
  if (!images) return "https://via.placeholder.com/80?text=No+Img";
  if (typeof images === "string") return images.split(",")[0]?.trim() || "";
  if (Array.isArray(images)) {
    const first = images[0];
    if (!first) return "https://via.placeholder.com/80?text=No+Img";
    return typeof first === "string" ? first : (first.url || "");
  }
  return "";
}

function normalizeListResponse(res) {
  const a = res?.data ?? res;
  const b = a?.data ?? a;
  if (Array.isArray(b)) return b;
  if (Array.isArray(b?.items)) return b.items;
  if (Array.isArray(b?.products)) return b.products;
  return [];
}

export default function ManageTours() {
  const nav = useNavigate();

  // State
  const [q, setQ] = useState("");
  const [filterStatus, setFilterStatus] = useState("all"); // all | active | inactive
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  // Load Data
  const loadTours = async () => {
    setLoading(true);
    setErr("");
    try {
      const res = await catalogApi.getAll({ product_type: "tour", limit: 100 }); // Lấy 100 tour mới nhất
      setItems(normalizeListResponse(res));
    } catch (e) {
      console.error(e);
      setErr(e?.response?.data?.message || "Không thể tải danh sách tour.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTours();
  }, []);

  // Filter Logic (Client-side)
  const filtered = useMemo(() => {
    let result = items;

    // 1. Filter by Status
    if (filterStatus !== "all") {
      const isActive = filterStatus === "active";
      result = result.filter(x => !!x.is_active === isActive);
    }

    // 2. Filter by Search Query
    const keyword = q.trim().toLowerCase();
    if (keyword) {
      result = result.filter((x) => {
        const hay = [
          x.product_code,
          x.title,
          x.slug,
          x.tour_details?.start_point
        ].filter(Boolean).join(" ").toLowerCase();
        return hay.includes(keyword);
      });
    }

    return result;
  }, [items, q, filterStatus]);

  // Actions
  const createTour = () => nav("/admin/manage/tours/create");
  const openDetail = (id) => nav(`/admin/manage/tours/${id}`);
  const openInventory = (id) => nav(`/admin/manage/tours/${id}/inventory`); // [MỚI] Nút nhanh vào Inventory

  const deleteTour = async (id, title) => {
    if (!window.confirm(`Xóa vĩnh viễn tour: "${title}"?`)) return;
    try {
      await catalogApi.remove(id);
      loadTours(); // Reload list
    } catch (e) {
      alert("Xóa thất bại: " + e.message);
    }
  };

  return (
    <div className="mt-container">
      {/* HEADER */}
      <div className="mt-header">
        <div className="mt-title-group">
          <h1>Quản lý Tour</h1>
          <p>Danh sách tất cả các tour du lịch hiện có trên hệ thống.</p>
        </div>
        <button className="mt-btn-create" onClick={createTour}>
          <span>+</span> Tạo Tour Mới
        </button>
      </div>

      {/* TOOLBAR */}
      <div className="mt-toolbar">
        <div className="mt-search-box">
          <span className="mt-search-icon">🔍</span>
          <input
            className="mt-input"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Tìm theo tên, mã tour, điểm đi..."
          />
        </div>

        <select 
          className="mt-select" 
          value={filterStatus} 
          onChange={(e) => setFilterStatus(e.target.value)}
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Đang hoạt động</option>
          <option value="inactive">Đang ẩn</option>
        </select>

        <button className="mt-btn-icon" onClick={loadTours} title="Tải lại">
          ↻
        </button>
      </div>

      {/* TABLE */}
      {err && <div style={{color: 'red', padding: 10, background: '#fee2e2', borderRadius: 8}}>{err}</div>}
      
      <div className="mt-table-wrapper">
        <table className="mt-table">
          <thead>
            <tr>
              <th style={{width: '40%'}}>Thông tin Tour</th>
              <th>Vận hành</th>
              <th>Giá cơ bản</th>
              <th>Trạng thái</th>
              <th style={{textAlign: 'right'}}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan="5" style={{textAlign:'center', padding: 20}}>Đang tải dữ liệu...</td></tr>
            )}
            
            {!loading && filtered.length === 0 && (
              <tr><td colSpan="5" className="mt-empty">Không tìm thấy tour nào phù hợp.</td></tr>
            )}

            {filtered.map((tour) => {
              const id = tour._id || tour.id;
              const img = pickFirstImage(tour.images);
              const isActive = !!tour.is_active;
              const price = Number(tour.base_price || 0).toLocaleString('vi-VN');
              const duration = tour.tour_details?.duration_days || 1;
              const startPoint = tour.tour_details?.start_point || "—";
              const transport = tour.tour_details?.transport_type || "—";

              return (
                <tr key={id}>
                  <td>
                    <div className="mt-tour-info">
                      <img src={img} alt="thumb" className="mt-thumb" />
                      <div>
                        <span className="mt-tour-name" title={tour.title}>{tour.title}</span>
                        <span className="mt-tour-code">
                          {tour.product_code || id.slice(-6).toUpperCase()}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{fontSize: 13}}>
                      <div>📍 {startPoint}</div>
                      <div style={{color:'#6b7280'}}>⏳ {duration} ngày • 🚌 {transport}</div>
                    </div>
                  </td>
                  <td>
                    <span className="mt-price">{price} ₫</span>
                  </td>
                  <td>
                    <span className={`mt-badge ${isActive ? 'mt-badge-active' : 'mt-badge-inactive'}`}>
                      {isActive ? 'Hoạt động' : 'Tạm ẩn'}
                    </span>
                  </td>
                  <td>
                    <div className="mt-actions">
                      <button 
                        className="mt-btn-action"
                        onClick={() => openInventory(id)} 
                        title="Quản lý lịch & chỗ"
                        style={{color: '#0b5fff', borderColor: '#bfdbfe', background: '#eff6ff'}}
                      >
                        📦 Lịch & Chỗ
                      </button>
                      <button 
                        className="mt-btn-action" 
                        onClick={() => openDetail(id)}
                      >
                        Sửa
                      </button>
                      <button 
                        className="mt-btn-action mt-btn-danger" 
                        onClick={() => deleteTour(id, tour.title)}
                      >
                        Xóa
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      
      {/* Footer text */}
      <div style={{textAlign: 'right', fontSize: 12, color: '#9ca3af', paddingRight: 10}}>
        Hiển thị {filtered.length} / {items.length} tour
      </div>
    </div>
  );
}