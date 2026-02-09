import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import locationApi from "../../api/locationApi";
import categoryApi from "../../api/categoryApi";
import "../../styles/admin/CreateTour.css";

export default function ManageTourDetail() {
  const { id } = useParams();
  const nav = useNavigate();

  const [activeTab, setActiveTab] = useState("general");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const [locations, setLocations] = useState([]);
  const [categories, setCategories] = useState([]);

  // Form chứa dữ liệu tour để hiển thị
  const [form, setForm] = useState(null);

  // State riêng cho việc duyệt
  const [status, setStatus] = useState("pending");
  const [reason, setReason] = useState(""); // Lý do từ chối

  // --- 1. LOAD DATA ---
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        const [tourRes, locRes, catRes] = await Promise.all([
          // [SỬA LỖI 1] Dùng API Admin để lấy được tour Pending/Hidden
          catalogApi.getByIdAdmin(id),
          locationApi.getAll(), // Đảm bảo tên hàm đúng trong api/locationApi
          categoryApi.getAll() // Đảm bảo tên hàm đúng trong api/categoryApi
        ]);

        const t = tourRes.data?.product || tourRes.data || tourRes;

        // [SỬA LỖI 2] Map dữ liệu theo 'status' thay vì 'is_active'
        setStatus(t.status || "pending");
        setReason(t.rejection_reason || "");

        setForm({
          _id: t._id || t.id,
          title: t.title || "",
          product_code: t.product_code || "",
          base_price: t.base_price || 0,
          sustainability_score: t.sustainability_score || 0,

          description_short: t.description_short || "",
          description_long: t.description_long || "",
          images: t.images || [],
          tags: (t.tags || []).join(", "),

          location_ids: t.location_ids?.map(l => l._id || l.id || l) || [],
          category_ids: t.category_ids?.map(c => c._id || c.id || c) || [],

          duration_days: t.tour_details?.duration_days || 1,
          start_point: t.tour_details?.start_point || "",
          transport_type: t.tour_details?.transport_type || "Xe du lịch",
          hotel_rating: t.tour_details?.hotel_rating || 0,
          hotel_name: t.tour_details?.hotel_name || "",

          itinerary: t.tour_details?.itinerary || [],
          policies: t.tour_details?.policy_notes || [],

          highlight_attractions: t.tour_details?.trip_highlights?.attractions || "",
          highlight_cuisine: t.tour_details?.trip_highlights?.cuisine || "",
          highlight_suitable: t.tour_details?.trip_highlights?.suitable_for || "",
          highlight_ideal_time: t.tour_details?.trip_highlights?.ideal_time || "",
        });

        const locData = locRes.data || locRes;
        const catData = catRes.data || catRes;

        // Xử lý an toàn dữ liệu trả về
        setLocations(Array.isArray(locData) ? locData : (locData.data || locData.locations || []));
        setCategories(Array.isArray(catData) ? catData : (catData.data || catData.categories || []));

      } catch (err) {
        console.error(err);
        const msg = err.response?.data?.message || err.message;
        alert(`Không tải được thông tin tour: ${msg}`);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, [id]);

  // --- 2. ADMIN ACTIONS ---

  const handleSaveStatus = async () => {
    setSaving(true);
    try {
      // [SỬA LỖI 3] Gọi API chuyên dụng để update status
      await catalogApi.updateTourStatus(id, status, reason);
      alert("✅ Đã cập nhật trạng thái kiểm duyệt thành công!");

      // Load lại để thấy thay đổi mới nhất (hoặc điều hướng về danh sách)
      // nav("/admin/manage/tours"); 
    } catch (e) {
      console.error(e);
      alert("Lỗi cập nhật: " + (e.response?.data?.message || e.message));
    } finally {
      setSaving(false);
    }
  };

  if (loading || !form) return <div style={{ padding: 40, textAlign: 'center' }}>⏳ Đang tải dữ liệu tour...</div>;

  // --- 3. RENDER CONTENT (READ ONLY) ---
  const renderContent = () => {
    switch (activeTab) {
      case "general":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Thông tin cơ bản (Chỉ xem)</div>

            <div className="ct-field"><div className="ct-label">Tên Tour</div><input className="ct-input" value={form.title} disabled /></div>
            <div className="ct-grid-2">
              <div className="ct-field"><div className="ct-label">Mã Tour</div><input className="ct-input" value={form.product_code} disabled /></div>
              <div className="ct-field"><div className="ct-label">Giá (VND)</div><input className="ct-input" value={new Intl.NumberFormat('vi-VN').format(form.base_price)} disabled /></div>
            </div>

            {/* 🔥 KHU VỰC ADMIN DUYỆT (ĐƯỢC SỬA) 🔥 */}
            <div style={{ background: '#fff7ed', padding: 20, borderRadius: 12, border: '1px solid #fdba74', margin: '24px 0', boxShadow: '0 4px 6px -1px rgba(251, 146, 60, 0.1)' }}>
              <div style={{ fontWeight: '800', color: '#c2410c', marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                🛡️ KHU VỰC KIỂM DUYỆT CỦA ADMIN
              </div>

              <div className="ct-grid-2">
                <div className="ct-field" style={{ marginBottom: 0 }}>
                  <div className="ct-label" style={{ color: '#9a3412' }}>Quyết định trạng thái:</div>
                  <select
                    className="ct-select"
                    style={{
                      borderColor: status === 'active' ? '#22c55e' : (status === 'rejected' ? '#ef4444' : '#f59e0b'),
                      borderWidth: 2,
                      fontWeight: 'bold',
                      color: status === 'active' ? '#15803d' : (status === 'rejected' ? '#b91c1c' : '#b45309')
                    }}
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                  >
                    <option value="pending">⏳ Pending (Chờ duyệt)</option>
                    <option value="active">✅ Active (Đã duyệt - Đang bán)</option>
                    <option value="rejected">⛔ Rejected (Từ chối)</option>
                    <option value="hidden">👁️ Hidden (Tạm ẩn)</option>
                  </select>
                </div>

                {status === 'rejected' && (
                  <div className="ct-field" style={{ marginBottom: 0 }}>
                    <div className="ct-label" style={{ color: '#b91c1c' }}>Lý do từ chối:</div>
                    <input
                      className="ct-input"
                      placeholder="Nhập lý do để Partner sửa..."
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      style={{ borderColor: '#fca5a5' }}
                    />
                  </div>
                )}
              </div>

              <div style={{ marginTop: 12, fontSize: 13, color: '#c2410c', fontStyle: 'italic' }}>
                * "Active": Tour sẽ xuất hiện trên trang chủ. "Rejected": Partner sẽ nhận được thông báo để sửa lại.
              </div>
            </div>
            {/* ------------------------------------- */}

            <div className="ct-field"><div className="ct-label">Tags</div><input className="ct-input" value={form.tags} disabled /></div>
            <div className="ct-grid-2">
              <div className="ct-field">
                <div className="ct-label">Địa điểm</div>
                <div className="ct-read-only-box">
                  {locations.filter(l => form.location_ids.includes(l._id || l.id)).map(l => l.name).join(", ")}
                </div>
              </div>
              <div className="ct-field">
                <div className="ct-label">Danh mục</div>
                <div className="ct-read-only-box">
                  {categories.filter(c => form.category_ids.includes(c._id || c.id)).map(c => c.name).join(", ")}
                </div>
              </div>
            </div>
            <div className="ct-field"><div className="ct-label">Mô tả ngắn</div><textarea className="ct-textarea" value={form.description_short} disabled /></div>
          </div>
        );

      case "operation":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Vận hành (Chỉ xem)</div>
            <div className="ct-grid-3">
              <div className="ct-field"><div className="ct-label">Điểm khởi hành</div><input className="ct-input" value={form.start_point} disabled /></div>
              <div className="ct-field"><div className="ct-label">Thời lượng</div><input className="ct-input" value={form.duration_days + " ngày"} disabled /></div>
              <div className="ct-field"><div className="ct-label">Phương tiện</div><input className="ct-input" value={form.transport_type} disabled /></div>
            </div>
            <div className="ct-grid-2">
              <div className="ct-field"><div className="ct-label">Khách sạn</div><input className="ct-input" value={form.hotel_rating + " Sao"} disabled /></div>
              <div className="ct-field"><div className="ct-label">Tên khách sạn</div><input className="ct-input" value={form.hotel_name} disabled /></div>
            </div>
          </div>
        );

      case "itinerary":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Lịch trình chi tiết (Chỉ xem)</div>
            {form.itinerary.map((day, idx) => (
              <div key={idx} className="ct-list-box" style={{ background: '#f9fafb' }}>
                <div className="ct-list-header"><span>Ngày {day.day}: {day.title}</span></div>
                <div style={{ padding: 10, fontSize: 13, whiteSpace: 'pre-wrap' }}>{day.details}</div>
                <div style={{ padding: '0 10px 10px', fontSize: 12, color: '#666' }}>
                  <b>Ăn:</b> {day.meals?.join(", ")} | <b>Nghỉ:</b> {day.accommodation}
                </div>
              </div>
            ))}
          </div>
        );

      case "policies":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Chính sách (Chỉ xem)</div>
            {form.policies.map((pol, idx) => (
              <div key={idx} className="ct-list-box" style={{ background: '#f9fafb' }}>
                <div style={{ fontWeight: 'bold', padding: '10px 10px 5px' }}>{pol.title}</div>
                <div style={{ padding: '0 10px 10px', fontSize: 13 }}>{pol.content}</div>
              </div>
            ))}
          </div>
        );

      case "media":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Hình ảnh ({form.images.length})</div>
            <div className="ct-img-grid">
              {form.images.map((img, idx) => (
                <div key={idx} className="ct-img-wrapper">
                  <img src={img.url} alt="Tour" className="ct-img-thumb" />
                </div>
              ))}
            </div>
          </div>
        );

      default: return null;
    }
  };

  return (
    <div className="create-tour-container">
      {/* Header */}
      <div className="ct-header">
        <div>
          <h1 className="ct-h1">Chi tiết & Kiểm duyệt</h1>
          <div className="ct-sub">Đang xem tour ID: <span style={{ fontFamily: 'monospace' }}>{id}</span></div>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="ct-btn" onClick={() => nav("/admin/manage/tours")}>
            Quay lại
          </button>

          <button
            className="ct-btn"
            style={{ borderColor: '#0b5fff', color: '#0b5fff', background: '#eff6ff' }}
            onClick={() => nav(`/admin/manage/tours/${id}/inventory`)}
          >
            📦 Xem Lịch Khởi Hành
          </button>

          <button
            className="ct-btn-primary"
            onClick={handleSaveStatus}
            disabled={saving}
            style={{ background: '#c2410c', borderColor: '#c2410c', paddingLeft: 20, paddingRight: 20 }}
          >
            {saving ? "Đang xử lý..." : "💾 CẬP NHẬT TRẠNG THÁI"}
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="ct-tabs">
        {['general', 'operation', 'itinerary', 'policies', 'media'].map(tab => (
          <div
            key={tab}
            className={`ct-tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'general' ? '1. Tổng quan' :
              tab === 'operation' ? '2. Vận hành' :
                tab === 'itinerary' ? '3. Lịch trình' :
                  tab === 'policies' ? '4. Chính sách' : '5. Hình ảnh'}
          </div>
        ))}
      </div>

      {renderContent()}
    </div>
  );
}