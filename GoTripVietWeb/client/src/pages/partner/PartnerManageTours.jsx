import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi"; 
import "../../styles/partner/PartnerManageTours.css"; // Đảm bảo bạn đã có file CSS này từ câu trả lời trước

// Helper xử lý ảnh
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

export default function PartnerManageTours() {
  const nav = useNavigate();

  // State
  const [allTours, setAllTours] = useState([]);
  const [loading, setLoading] = useState(false);
  const [q, setQ] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Load Data
  const loadMyTours = async () => {
    setLoading(true);
    try {
      // Gọi API lấy tour của partner
      const res = await catalogApi.getPartnerTours({ limit: 1000 }); 
      setAllTours(normalizeListResponse(res));
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMyTours();
  }, []);

  // Filter Logic
  const filtered = useMemo(() => {
    let result = allTours;

    if (filterStatus !== "all") {
      const isActive = filterStatus === "active";
      result = result.filter(x => !!x.is_active === isActive);
    }

    const keyword = q.trim().toLowerCase();
    if (keyword) {
      result = result.filter((x) => {
        const hay = [x.product_code, x.title].filter(Boolean).join(" ").toLowerCase();
        return hay.includes(keyword);
      });
    }
    return result;
  }, [allTours, q, filterStatus]);

  // Actions
  const createTour = () => nav("/partner/tours/create");
  const openDetail = (id) => nav(`/partner/tours/${id}`); // Sửa tour
  const openInventory = (id) => nav(`/partner/tours/${id}/inventory`); // Quản lý lịch

  const deleteTour = async (id, title) => {
    if (!window.confirm(`Bạn muốn xóa tour: "${title}"?`)) return;
    try {
      await catalogApi.remove(id);
      loadMyTours();
    } catch (e) {
      alert("Xóa thất bại: " + e.message);
    }
  };

  return (
    <div className="pt-container">
      
      {/* 1. HEADER */}
      <div className="pt-header">
        <div>
          <h1 className="pt-title">Tour Của Tôi</h1>
          <div className="pt-subtitle">Quản lý danh sách tour và lịch khởi hành.</div>
        </div>
        <button className="pt-btn-create" onClick={createTour}>
          <span>+</span> Đăng Tour Mới
        </button>
      </div>

      {/* 2. TOOLBAR (FILTER & SEARCH) */}
      <div className="pt-toolbar">
        <div className="pt-search">
          <span style={{opacity: 0.5}}>🔍</span>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Tìm tên tour, mã tour..."
          />
        </div>

        <div style={{ display: 'flex', gap: 8 }}>
          <button 
            className={`pt-filter-btn ${filterStatus === 'all' ? 'active' : ''}`}
            onClick={() => setFilterStatus('all')}
          >
            Tất cả
          </button>
          <button 
            className={`pt-filter-btn ${filterStatus === 'active' ? 'active' : ''}`}
            onClick={() => setFilterStatus('active')}
          >
            Đang hoạt động
          </button>
          <button 
            className={`pt-filter-btn ${filterStatus === 'inactive' ? 'active' : ''}`}
            onClick={() => setFilterStatus('inactive')}
          >
            Tạm ẩn
          </button>
        </div>
      </div>

      {/* 3. TABLE */}
      <div className="pt-table-card">
        <table className="pt-table">
          <thead>
            <tr>
              <th style={{ width: '40%', paddingLeft: 24 }}>Thông tin Tour</th>
              <th>Thời lượng</th>
              <th>Giá niêm yết</th>
              <th>Trạng thái</th>
              <th style={{ textAlign: 'right', paddingRight: 24 }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan="5" style={{ textAlign: 'center', padding: 60, color: '#9ca3af' }}>Đang tải dữ liệu...</td></tr>
            )}

            {!loading && filtered.length === 0 && (
              <tr><td colSpan="5" className="pt-empty">Bạn chưa có tour nào. Hãy tạo mới!</td></tr>
            )}

            {filtered.map((tour) => {
              const id = tour._id || tour.id;
              const img = pickFirstImage(tour.images);
              const isActive = !!tour.is_active;
              const price = Number(tour.base_price || 0).toLocaleString('vi-VN');

              return (
                <tr key={id}>
                  <td style={{ paddingLeft: 24 }}>
                    <div className="pt-product">
                      <img src={img} alt="thumb" className="pt-thumb" />
                      <div>
                        <div className="pt-name" title={tour.title}>{tour.title}</div>
                        <div className="pt-meta">
                          <span className="pt-code">{tour.product_code || "NO-CODE"}</span>
                          <span>• {tour.tour_details?.start_point || "Chưa cập nhật điểm đi"}</span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    {tour.tour_details?.duration_days} ngày
                  </td>
                  <td>
                    <span className="pt-price">{price} ₫</span>
                  </td>
                  <td>
                    <span className={isActive ? "pt-badge pt-badge-active" : "pt-badge pt-badge-inactive"}>
                      {isActive ? "Đang bán" : "Tạm ẩn"}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right', paddingRight: 24 }}>
                    <div className="pt-actions">
                      <button 
                        className="pt-btn-action pt-btn-inv" 
                        onClick={() => openInventory(id)} 
                        title="Cài đặt lịch khởi hành"
                      >
                        📅 Lịch & Chỗ
                      </button>
                      <button 
                        className="pt-btn-action pt-btn-edit" 
                        onClick={() => openDetail(id)}
                        title="Chỉnh sửa thông tin"
                      >
                        ✎ Sửa
                      </button>
                      <button 
                        className="pt-btn-action pt-btn-delete" 
                        onClick={() => deleteTour(id, tour.title)}
                        title="Xóa tour"
                      >
                        🗑️
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}