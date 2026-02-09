import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import "../../styles/admin/ManageTours.css";

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

// Map status sang hiển thị đẹp
const STATUS_MAP = {
  pending: { label: "⏳ Chờ duyệt", color: "#d97706", bg: "#fef3c7" },
  active: { label: "✅ Đang bán", color: "#059669", bg: "#d1fae5" },
  rejected: { label: "⛔ Từ chối", color: "#dc2626", bg: "#fee2e2" },
  hidden: { label: "👁️ Đang ẩn", color: "#4b5563", bg: "#f3f4f6" },
  draft: { label: "📝 Bản nháp", color: "#6b7280", bg: "#e5e7eb" },
};

export default function ManageTours() {
  const nav = useNavigate();

  // State
  const [allTours, setAllTours] = useState([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  // Filters
  const [q, setQ] = useState("");
  // [NEW] Default filter là 'pending' để Admin tập trung duyệt bài
  const [filterStatus, setFilterStatus] = useState("pending");

  // Pagination
  const [page, setPage] = useState(1);
  const [limit] = useState(10);

  // Load Data
  const loadTours = async () => {
    setLoading(true);
    setErr("");
    try {
      // [NEW] Gọi API dành riêng cho Admin (getManageTours) để lấy hết status
      // Lấy limit lớn để filter client-side cho mượt (hoặc có thể phân trang server nếu muốn)
      const res = await catalogApi.getManageTours({ limit: 1000 });
      setAllTours(normalizeListResponse(res));
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

  useEffect(() => {
    setPage(1);
  }, [q, filterStatus]);

  // Logic Filter
  const filteredTours = useMemo(() => {
    let result = allTours;

    // 1. Filter by Status
    if (filterStatus !== "all") {
      result = result.filter((x) => x.status === filterStatus);
    }

    // 2. Filter by Search Query
    const keyword = q.trim().toLowerCase();
    if (keyword) {
      result = result.filter((x) => {
        const hay = [
          x.product_code,
          x.title,
          x.slug,
          x.tour_details?.start_point,
          x.partner_id,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        return hay.includes(keyword);
      });
    }

    // [NEW] Sort: Pending luôn lên đầu nếu đang xem All
    if (filterStatus === 'all') {
      result.sort((a, b) => {
        if (a.status === 'pending' && b.status !== 'pending') return -1;
        if (a.status !== 'pending' && b.status === 'pending') return 1;
        return new Date(b.createdAt) - new Date(a.createdAt);
      });
    }

    return result;
  }, [allTours, q, filterStatus]);

  // Pagination Logic
  const totalPages = Math.ceil(filteredTours.length / limit) || 1;
  const visibleTours = useMemo(() => {
    const startIndex = (page - 1) * limit;
    return filteredTours.slice(startIndex, startIndex + limit);
  }, [filteredTours, page, limit]);

  // Actions
  const openDetail = (id) => nav(`/admin/manage/tours/${id}`);
  const openInventory = (id) => nav(`/admin/manage/tours/${id}/inventory`);

  return (
    <div className="tour-page">
      {/* HEADER */}
      <div className="tour-header">
        <div>
          <h1 className="tour-title">Quản lý & Duyệt Tour</h1>
          <div className="tour-subtitle">
            Hệ thống có <b>{allTours.filter(t => t.status === 'pending').length}</b> tour đang chờ duyệt.
          </div>
        </div>
      </div>

      {/* TOOLBAR */}
      <div className="tour-toolbar">
        <div className="tour-search-box">
          <span className="tour-search-icon">🔍</span>
          <input
            className="tour-search-input"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Tìm tên, mã tour..."
          />
        </div>

        <select
          className="tour-select"
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          style={{ minWidth: 200 }}
        >
          <option value="pending">⏳ Chờ duyệt (Ưu tiên)</option>
          <option value="active">✅ Đang bán (Active)</option>
          <option value="rejected">⛔ Đã từ chối</option>
          <option value="hidden">👁️ Đang ẩn</option>
          <option value="all">-- Tất cả --</option>
        </select>

        <button className="tour-btn-refresh" onClick={loadTours} title="Tải lại">
          ↻
        </button>
      </div>

      {/* TABLE */}
      {err && (
        <div style={{ color: "#b91c1c", padding: 12, background: "#fee2e2", borderRadius: 12, marginBottom: 16 }}>
          {err}
        </div>
      )}

      <div className="tour-table-container">
        <table className="tour-table">
          <thead>
            <tr>
              <th style={{ width: "35%" }}>Thông tin Tour</th>
              <th>Người đăng</th>
              <th>Vận hành</th>
              <th>Giá niêm yết</th>
              <th>Trạng thái</th>
              <th style={{ textAlign: "right" }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="6" style={{ textAlign: "center", padding: 40, color: "#6b7280" }}>
                  Đang tải dữ liệu...
                </td>
              </tr>
            ) : visibleTours.length === 0 ? (
              <tr>
                <td colSpan="6" className="tour-empty">
                  Không tìm thấy tour nào.
                </td>
              </tr>
            ) : (
              visibleTours.map((tour) => {
                const id = tour._id || tour.id;
                const img = pickFirstImage(tour.images);
                const statusInfo = STATUS_MAP[tour.status] || STATUS_MAP.draft;

                const price = Number(tour.base_price || 0).toLocaleString("vi-VN");
                const duration = tour.tour_details?.duration_days || 1;
                const startPoint = tour.tour_details?.start_point || "—";
                const partnerInfo = tour.partner_id
                  ? `ID: ...${tour.partner_id.slice(-4)}`
                  : "N/A";

                return (
                  <tr key={id} className={tour.status === 'pending' ? 'tour-tr-pending' : ''}>
                    <td>
                      <div className="tour-info">
                        <img src={img} alt="thumb" className="tour-thumb" />
                        <div className="tour-name-group">
                          <span className="tour-name" title={tour.title}>
                            {tour.title}
                          </span>
                          <span className="tour-code">
                            {tour.product_code || id.slice(-6).toUpperCase()}
                          </span>
                        </div>
                      </div>
                    </td>

                    <td>
                      <code className="tour-code" style={{ fontSize: 11 }}>
                        {partnerInfo}
                      </code>
                    </td>

                    <td>
                      <div style={{ fontSize: 13, color: "#374151" }}>
                        <div>📍 {startPoint}</div>
                        <div style={{ color: "#6b7280", marginTop: 2 }}>⏳ {duration} ngày</div>
                      </div>
                    </td>
                    <td>
                      <span className="tour-price">{price} ₫</span>
                    </td>
                    <td>
                      <span
                        className="tour-badge"
                        style={{
                          color: statusInfo.color,
                          backgroundColor: statusInfo.bg,
                          border: `1px solid ${statusInfo.color}30`
                        }}
                      >
                        {statusInfo.label}
                      </span>
                    </td>
                    <td>
                      <div className="tour-actions">
                        <button
                          className="tour-btn-action tour-btn-inv"
                          onClick={() => openInventory(id)}
                          title="Xem lịch khởi hành"
                        >
                          📦 Lịch
                        </button>
                        <button
                          className="tour-btn-action tour-btn-review"
                          onClick={() => openDetail(id)}
                          style={tour.status === 'pending' ? { backgroundColor: '#2563eb', color: 'white' } : {}}
                        >
                          {tour.status === 'pending' ? '🛡️ Duyệt ngay' : '✏️ Chi tiết'}
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* PAGINATION */}
      {!loading && (allTours.length > 0) && (
        <div className="tour-pagination">
          <span className="tour-page-info">
            Trang <b>{page}</b> / {totalPages}
          </span>
          <button
            className="tour-page-btn"
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
          >
            &lt;
          </button>
          {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
            let pNum = i + 1;
            if (totalPages > 5) {
              if (page > 3) pNum = page - 2 + i;
              if (pNum > totalPages) pNum = totalPages - 4 + i;
            }
            if (pNum > totalPages || pNum < 1) return null;
            return (
              <button
                key={pNum}
                className={`tour-page-btn ${page === pNum ? "active" : ""}`}
                onClick={() => setPage(pNum)}
              >
                {pNum}
              </button>
            );
          })}
          <button
            className="tour-page-btn"
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
          >
            &gt;
          </button>
        </div>
      )}
    </div>
  );
}