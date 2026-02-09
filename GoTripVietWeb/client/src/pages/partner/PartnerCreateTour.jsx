import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import locationApi from "../../api/locationApi";
import categoryApi from "../../api/categoryApi";
import LocationRequestModal from "../../components/partner/LocationRequestModal";
import CategoryRequestModal from "../../components/partner/CategoryRequestModal";
import "../../styles/admin/CreateTour.css"; // Sử dụng file CSS mới

export default function PartnerCreateTour() {
  const nav = useNavigate();
  const [activeTab, setActiveTab] = useState("general");
  const [loading, setLoading] = useState(false);

  // Data lists
  const [locations, setLocations] = useState([]);
  const [categories, setCategories] = useState([]);

  // State for Modals
  const [showLocModal, setShowLocModal] = useState(false);
  const [showCatModal, setShowCatModal] = useState(false);

  // --- INITIAL STATE ---
  const [form, setForm] = useState({
    product_type: "tour",
    title: "",
    product_code: "",
    base_price: 0,
    sustainability_score: 3, // Mặc định trung bình
    is_active: true,
    location_ids: [],
    category_ids: [],
    tags: "",
    description_short: "",
    description_long: "",
    images: [],

    // tour_details
    duration_days: 3,
    start_point: "Hồ Chí Minh",
    transport_type: "Xe du lịch",
    hotel_rating: 3,
    hotel_name: "",

    // trip_highlights
    highlight_attractions: "",
    highlight_cuisine: "",
    highlight_suitable: "",
    highlight_ideal_time: "",

    // policy_notes (Array)
    policies: [
      { title: "Giá bao gồm", content: "Xe đưa đón, HDV, Nước uống..." },
      { title: "Giá không bao gồm", content: "Thuế VAT, Chi phí cá nhân..." },
    ],

    // itinerary (Array)
    itinerary: [
      { day: 1, title: "Khởi hành", details: "", meals: [], accommodation: "" },
    ],
  });

  // --- LOAD DATA ---
  useEffect(() => {
    const fetchResources = async () => {
      try {
        // [THAY ĐỔI TẠI ĐÂY]
        // Sử dụng .getManage() thay vì .getAll() với query_mode
        // Backend route /manage đã tự động nhận diện Partner qua token để trả về Pending items của họ
        const [locs, cats] = await Promise.all([
          locationApi.getManage(),
          categoryApi.getManage(),
        ]);

        const locData = locs.data || locs;
        const catData = cats.data || cats;
        setLocations(Array.isArray(locData) ? locData : locData.data || []);
        setCategories(Array.isArray(catData) ? catData : catData.data || []);
      } catch (err) {
        console.error("Lỗi tải resources:", err);
      }
    };
    fetchResources();
  }, []);

  // --- HANDLERS ---

  // Callback khi thêm địa điểm thành công
  const handleLocationAdded = (newLocation) => {
    setLocations((prev) => [...prev, newLocation]);
    const newId = newLocation._id || newLocation.id;
    setForm((prev) => ({
      ...prev,
      location_ids: [...prev.location_ids, newId],
    }));
    alert(`Đã thêm địa điểm "${newLocation.name}". Đang chờ Admin duyệt.`);
  };

  // Callback khi thêm danh mục thành công
  const handleCategoryAdded = (newCategory) => {
    setCategories((prev) => [...prev, newCategory]);
    const newId = newCategory._id || newCategory.id;
    setForm((prev) => ({
      ...prev,
      category_ids: [...prev.category_ids, newId],
    }));
    alert(`Đã thêm danh mục "${newCategory.name}". Đang chờ Admin duyệt.`);
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleMultiSelect = (e, field) => {
    const opts = Array.from(e.target.selectedOptions, (option) => option.value);
    setForm((prev) => ({ ...prev, [field]: opts }));
  };

  const handleUpload = async (e) => {
    const files = Array.from(e.target.files);
    if (!files.length) return;

    setLoading(true);
    try {
      const uploads = await Promise.all(
        files.map((file) => {
          const fd = new FormData();
          fd.append("file", file);
          return catalogApi.uploadTourImage(fd);
        })
      );

      const newImages = uploads.map((res) => ({
        url: res.url || res.data.url,
        public_id: res.public_id || res.data.public_id,
      }));

      setForm((prev) => ({ ...prev, images: [...prev.images, ...newImages] }));
    } catch (err) {
      alert("Lỗi upload ảnh: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const addItineraryDay = () => {
    setForm((prev) => ({
      ...prev,
      itinerary: [
        ...prev.itinerary,
        {
          day: prev.itinerary.length + 1,
          title: "",
          details: "",
          meals: [],
          accommodation: "",
        },
      ],
    }));
  };

  const updateItinerary = (index, field, value) => {
    const newItin = [...form.itinerary];
    newItin[index][field] = value;
    setForm((prev) => ({ ...prev, itinerary: newItin }));
  };

  const addPolicy = () => {
    setForm((prev) => ({
      ...prev,
      policies: [...prev.policies, { title: "", content: "" }],
    }));
  };

  const updatePolicy = (index, field, value) => {
    const newPol = [...form.policies];
    newPol[index][field] = value;
    setForm((prev) => ({ ...prev, policies: newPol }));
  };

  const handleSubmit = async () => {
    // --- 1. VALIDATE CLIENT SIDE ---
    if (!form.title.trim()) return alert("⚠️ Vui lòng nhập tên Tour!");
    if (form.base_price <= 0) return alert("⚠️ Giá tour phải lớn hơn 0!");
    if (form.location_ids.length === 0) return alert("⚠️ Vui lòng chọn ít nhất 1 Địa điểm!");
    if (form.category_ids.length === 0) return alert("⚠️ Vui lòng chọn ít nhất 1 Danh mục!");
    if (form.images.length === 0) return alert("⚠️ Vui lòng tải lên ít nhất 1 hình ảnh!");

    setLoading(true);
    try {
      const payload = {
        product_code: form.product_code || undefined,
        product_type: "tour",
        title: form.title,
        base_price: Number(form.base_price),
        sustainability_score: Number(form.sustainability_score),
        is_active: form.is_active,
        description_short: form.description_short,
        description_long: form.description_long,
        images: form.images,
        tags: form.tags.split(",").map((t) => t.trim()).filter(Boolean),
        location_ids: form.location_ids,
        category_ids: form.category_ids,

        tour_details: {
          start_point: form.start_point,
          duration_days: Number(form.duration_days),
          transport_type: form.transport_type,
          hotel_rating: Number(form.hotel_rating),
          hotel_name: form.hotel_name,

          itinerary: form.itinerary,
          policy_notes: form.policies,

          trip_highlights: {
            attractions: form.highlight_attractions,
            cuisine: form.highlight_cuisine,
            suitable_for: form.highlight_suitable,
            ideal_time: form.highlight_ideal_time,
          },
        },
      };

      await catalogApi.create(payload);
      alert("✅ Đăng tour thành công! Vui lòng chờ Admin duyệt.");
      nav("/partner/tours");
    } catch (err) {
      console.error("Full Error:", err);
      const serverMessage =
        err.response?.data?.message ||
        err.response?.data?.error ||
        (typeof err.response?.data === 'string' ? err.response?.data : JSON.stringify(err.response?.data)) ||
        err.message ||
        "Lỗi không xác định";

      alert("❌ Lỗi tạo tour: " + serverMessage);
    } finally {
      setLoading(false);
    }
  };

  // --- RENDER SECTIONS ---
  const renderContent = () => {
    switch (activeTab) {
      case "general":
        return (
          <div className="ct-card">
            <div className="ct-section-title">1. Thông tin cơ bản</div>

            <div className="ct-field">
              <label className="ct-label">Tên Tour <span style={{ color: "red" }}>*</span></label>
              <input
                className="ct-input"
                name="title"
                value={form.title}
                onChange={handleChange}
                placeholder="VD: Tour Đà Lạt 3N2Đ - Săn Mây Đại Ngàn"
                autoFocus
              />
            </div>

            <div className="ct-grid-2">
              <div className="ct-field">
                <label className="ct-label">Mã Tour (Tự động in hoa)</label>
                <input
                  className="ct-input"
                  name="product_code"
                  value={form.product_code}
                  onChange={handleChange}
                  placeholder="VD: DL-001 (Nếu bỏ trống hệ thống tự sinh)"
                />
              </div>
              <div className="ct-field">
                <label className="ct-label">Giá cơ bản (VND) <span style={{ color: "red" }}>*</span></label>
                <input
                  type="number"
                  className="ct-input"
                  name="base_price"
                  value={form.base_price}
                  onChange={handleChange}
                  placeholder="0"
                />
              </div>
            </div>

            <div className="ct-grid-3">
              <div className="ct-field">
                <label className="ct-label">Điểm bền vững</label>
                <input
                  type="number"
                  min={0}
                  max={5}
                  className="ct-input"
                  name="sustainability_score"
                  value={form.sustainability_score}
                  onChange={handleChange}
                  disabled
                  title="Chỉ Admin mới có quyền đánh giá lại"
                  style={{ backgroundColor: "#f3f4f6", cursor: 'not-allowed' }}
                />
              </div>
              <div className="ct-field">
                <label className="ct-label">Trạng thái ban đầu</label>
                <select
                  className="ct-select"
                  name="is_active"
                  value={form.is_active}
                  onChange={(e) => setForm({ ...form, is_active: e.target.value === "true" })}
                >
                  <option value="true">Hoạt động ngay</option>
                  <option value="false">Tạm ẩn (Nháp)</option>
                </select>
              </div>
              <div className="ct-field">
                <label className="ct-label">Tags (Từ khóa tìm kiếm)</label>
                <input
                  className="ct-input"
                  name="tags"
                  value={form.tags}
                  onChange={handleChange}
                  placeholder="biển, hè, giá rẻ..."
                />
              </div>
            </div>

            <div className="ct-grid-2">
              {/* LOCATIONS */}
              <div className="ct-field">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                  <label className="ct-label mb-0">Địa điểm (Giữ Ctrl chọn nhiều)</label>
                  <button
                    type="button"
                    onClick={() => setShowLocModal(true)}
                    style={{ background: 'none', border: 'none', color: '#0b5fff', fontSize: 13, fontWeight: '600', cursor: 'pointer' }}
                  >
                    + Đề xuất địa điểm
                  </button>
                </div>
                <select
                  multiple
                  className="ct-select"
                  style={{ height: 120 }}
                  onChange={(e) => handleMultiSelect(e, "location_ids")}
                  value={form.location_ids}
                >
                  {locations.map((l) => (
                    <option key={l._id || l.id} value={l._id || l.id}>
                      {l.name} {l.status === 'pending' ? "(⏳ Chờ duyệt)" : ""}
                    </option>
                  ))}
                </select>
              </div>

              {/* CATEGORIES */}
              <div className="ct-field">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                  <label className="ct-label mb-0">Danh mục (Giữ Ctrl chọn nhiều)</label>
                  <button
                    type="button"
                    onClick={() => setShowCatModal(true)}
                    style={{ background: 'none', border: 'none', color: '#0b5fff', fontSize: 13, fontWeight: '600', cursor: 'pointer' }}
                  >
                    + Đề xuất danh mục
                  </button>
                </div>
                <select
                  multiple
                  className="ct-select"
                  style={{ height: 120 }}
                  onChange={(e) => handleMultiSelect(e, "category_ids")}
                  value={form.category_ids}
                >
                  {categories.map((c) => (
                    <option key={c._id || c.id} value={c._id || c.id}>
                      {c.name} {c.status === 'pending' ? "(⏳ Chờ duyệt)" : ""}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="ct-field">
              <label className="ct-label">Mô tả ngắn (Hiển thị trên card tour)</label>
              <textarea
                className="ct-textarea"
                style={{ minHeight: 80 }}
                name="description_short"
                value={form.description_short}
                onChange={handleChange}
                placeholder="Tóm tắt những điểm hấp dẫn nhất của tour..."
              />
            </div>
            <div className="ct-field">
              <label className="ct-label">Mô tả chi tiết</label>
              <textarea
                className="ct-textarea"
                style={{ minHeight: 150 }}
                name="description_long"
                value={form.description_long}
                onChange={handleChange}
                placeholder="Giới thiệu chi tiết về hành trình, trải nghiệm..."
              />
            </div>
          </div>
        );

      case "operation":
        return (
          <div className="ct-card">
            <div className="ct-section-title">2. Vận hành & Lưu trú</div>
            <div className="ct-grid-3">
              <div className="ct-field">
                <label className="ct-label">Điểm khởi hành</label>
                <input
                  className="ct-input"
                  name="start_point"
                  value={form.start_point}
                  onChange={handleChange}
                  placeholder="VD: Sân bay Tân Sơn Nhất"
                />
              </div>
              <div className="ct-field">
                <label className="ct-label">Thời lượng (ngày)</label>
                <input
                  type="number"
                  className="ct-input"
                  name="duration_days"
                  value={form.duration_days}
                  onChange={handleChange}
                />
              </div>
              <div className="ct-field">
                <label className="ct-label">Phương tiện di chuyển</label>
                <select
                  className="ct-select"
                  name="transport_type"
                  value={form.transport_type}
                  onChange={handleChange}
                >
                  <option value="Xe du lịch">Xe du lịch</option>
                  <option value="Máy bay">Máy bay</option>
                  <option value="Tàu hỏa">Tàu hỏa</option>
                  <option value="Du thuyền">Du thuyền</option>
                  <option value="Xe máy">Xe máy</option>
                  <option value="Tự túc">Tự túc</option>
                </select>
              </div>
            </div>

            <div className="ct-grid-2">
              <div className="ct-field">
                <label className="ct-label">Tiêu chuẩn Khách sạn</label>
                <select
                  className="ct-select"
                  name="hotel_rating"
                  value={form.hotel_rating}
                  onChange={handleChange}
                >
                  <option value="0">Không có (Về trong ngày / Ngủ lều)</option>
                  <option value="1">1 Sao</option>
                  <option value="2">2 Sao</option>
                  <option value="3">3 Sao</option>
                  <option value="4">4 Sao</option>
                  <option value="5">5 Sao</option>
                </select>
              </div>
              <div className="ct-field">
                <label className="ct-label">Tên Khách sạn (Dự kiến)</label>
                <input
                  className="ct-input"
                  name="hotel_name"
                  value={form.hotel_name}
                  onChange={handleChange}
                  placeholder="VD: Mường Thanh Luxury"
                />
              </div>
            </div>

            <div style={{ marginTop: 24 }}>
              <div className="ct-section-title">Điểm nổi bật (Highlights)</div>
              <div className="ct-grid-2">
                <div className="ct-field">
                  <label className="ct-label">Điểm tham quan chính</label>
                  <input
                    className="ct-input"
                    name="highlight_attractions"
                    value={form.highlight_attractions}
                    onChange={handleChange}
                    placeholder="Vịnh Hạ Long, Hang Sửng Sốt..."
                  />
                </div>
                <div className="ct-field">
                  <label className="ct-label">Ẩm thực đặc sắc</label>
                  <input
                    className="ct-input"
                    name="highlight_cuisine"
                    value={form.highlight_cuisine}
                    onChange={handleChange}
                    placeholder="Chả mực, Hải sản..."
                  />
                </div>
                <div className="ct-field">
                  <label className="ct-label">Đối tượng thích hợp</label>
                  <input
                    className="ct-input"
                    name="highlight_suitable"
                    value={form.highlight_suitable}
                    onChange={handleChange}
                    placeholder="Gia đình, Cặp đôi, Nhóm bạn..."
                  />
                </div>
                <div className="ct-field">
                  <label className="ct-label">Thời gian lý tưởng</label>
                  <input
                    className="ct-input"
                    name="highlight_ideal_time"
                    value={form.highlight_ideal_time}
                    onChange={handleChange}
                    placeholder="Tháng 4 - Tháng 9"
                  />
                </div>
              </div>
            </div>
          </div>
        );

      case "itinerary":
        return (
          <div className="ct-card">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20, paddingBottom: 10, borderBottom: '1px solid #eee' }}>
              <div className="ct-section-title" style={{ marginBottom: 0, border: 'none' }}>3. Lịch trình chi tiết</div>
              <button onClick={addItineraryDay} className="ct-btn ct-btn-primary" style={{ padding: '8px 16px' }}>
                + Thêm Ngày {form.itinerary.length + 1}
              </button>
            </div>

            {form.itinerary.map((day, idx) => (
              <div key={idx} className="ct-list-box">
                <div className="ct-list-header">
                  <span style={{ fontSize: 16 }}>🗓️ Ngày {day.day}</span>
                  <button
                    onClick={() => setForm((s) => ({ ...s, itinerary: s.itinerary.filter((_, i) => i !== idx) }))}
                    className="ct-btn-danger"
                    style={{ cursor: "pointer", border: "none", fontSize: 13, padding: '4px 10px', borderRadius: 6 }}
                  >
                    Xóa ngày này
                  </button>
                </div>
                <div className="ct-field">
                  <label className="ct-label">Tiêu đề ngày</label>
                  <input
                    className="ct-input"
                    value={day.title}
                    onChange={(e) => updateItinerary(idx, "title", e.target.value)}
                    placeholder="VD: Đón sân bay - Check in khách sạn"
                  />
                </div>
                <div className="ct-field">
                  <label className="ct-label">Chi tiết hoạt động</label>
                  <textarea
                    className="ct-textarea"
                    style={{ minHeight: 80 }}
                    value={day.details}
                    onChange={(e) => updateItinerary(idx, "details", e.target.value)}
                    placeholder="- 08:00: Ăn sáng tại khách sạn..."
                  />
                </div>
                <div className="ct-grid-2">
                  <div className="ct-field">
                    <label className="ct-label">Các bữa ăn (Gõ tay)</label>
                    <input
                      className="ct-input"
                      value={day.meals?.join(", ")}
                      onChange={(e) => updateItinerary(idx, "meals", e.target.value.split(","))}
                      placeholder="Sáng, Trưa, Tối"
                    />
                  </div>
                  <div className="ct-field">
                    <label className="ct-label">Nơi nghỉ đêm</label>
                    <input
                      className="ct-input"
                      value={day.accommodation}
                      onChange={(e) => updateItinerary(idx, "accommodation", e.target.value)}
                      placeholder="Tên khách sạn hoặc 'Trên xe/tàu'"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        );

      case "policies":
        return (
          <div className="ct-card">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <div className="ct-section-title" style={{ marginBottom: 0 }}>4. Chính sách & Điều khoản</div>
              <button onClick={addPolicy} className="ct-btn ct-btn-sm" style={{ border: '1px solid #ccc' }}>+ Thêm điều khoản</button>
            </div>
            {form.policies.map((pol, idx) => (
              <div key={idx} className="ct-list-box">
                <div className="ct-field">
                  <label className="ct-label">Tiêu đề mục</label>
                  <input
                    className="ct-input"
                    value={pol.title}
                    onChange={(e) => updatePolicy(idx, "title", e.target.value)}
                    placeholder="VD: Chính sách hoàn hủy"
                  />
                </div>
                <div className="ct-field">
                  <label className="ct-label">Nội dung chi tiết</label>
                  <textarea
                    className="ct-textarea"
                    style={{ minHeight: 60 }}
                    value={pol.content}
                    onChange={(e) => updatePolicy(idx, "content", e.target.value)}
                  />
                </div>
                <div style={{ textAlign: 'right' }}>
                  <button
                    onClick={() => setForm((s) => ({ ...s, policies: s.policies.filter((_, i) => i !== idx) }))}
                    style={{ color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, textDecoration: 'underline' }}
                  >
                    Xóa mục này
                  </button>
                </div>
              </div>
            ))}
          </div>
        );

      case "media":
        return (
          <div className="ct-card">
            <div className="ct-section-title">5. Hình ảnh quảng bá</div>

            <div className="ct-upload-box">
              <div style={{ fontSize: 40, marginBottom: 10 }}>📷</div>
              <p style={{ fontWeight: 600, color: "#374151", marginBottom: 4 }}>
                Kéo thả hình ảnh vào đây
              </p>
              <p style={{ fontSize: 13, color: "#6b7280", marginBottom: 16 }}>
                Hỗ trợ JPG, PNG. Tối đa 5MB mỗi ảnh.
              </p>

              <input
                type="file"
                multiple
                accept="image/*"
                onChange={handleUpload}
                style={{ display: "none" }}
                id="upload-btn"
              />
              <label
                htmlFor="upload-btn"
                className="ct-btn-primary"
                style={{ display: "inline-block", padding: '10px 24px' }}
              >
                Chọn ảnh từ máy tính
              </label>
            </div>

            {loading && (
              <div style={{ marginTop: 20, textAlign: 'center', color: "#0b5fff", fontWeight: 600 }}>
                ⏳ Đang tải ảnh lên máy chủ...
              </div>
            )}

            <div className="ct-img-grid">
              {form.images.map((img, idx) => (
                <div key={idx} className="ct-img-wrapper">
                  <img src={img.url} alt="Tour" className="ct-img-thumb" />
                  <button
                    onClick={() => setForm((s) => ({ ...s, images: s.images.filter((_, i) => i !== idx) }))}
                    className="ct-img-remove"
                    title="Xóa ảnh"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="create-tour-container">
      {/* RENDER MODALS */}
      <LocationRequestModal show={showLocModal} onHide={() => setShowLocModal(false)} onSuccess={handleLocationAdded} />
      <CategoryRequestModal show={showCatModal} onHide={() => setShowCatModal(false)} onSuccess={handleCategoryAdded} />

      <div className="ct-header">
        <div>
          <h1 className="ct-h1">Tạo Tour Mới</h1>
          <div className="ct-sub">
            Hoàn tất 5 bước dưới đây để đăng tải sản phẩm của bạn.
          </div>
        </div>
        <button className="ct-btn" onClick={() => nav("/partner/tours")}>
          Thoát
        </button>
      </div>

      <div className="ct-tabs">
        {['general', 'operation', 'itinerary', 'policies', 'media'].map((tabKey, index) => (
          <div
            key={tabKey}
            className={`ct-tab ${activeTab === tabKey ? "active" : ""}`}
            onClick={() => setActiveTab(tabKey)}
          >
            {index + 1}. {
              tabKey === 'general' ? 'Tổng quan' :
                tabKey === 'operation' ? 'Vận hành' :
                  tabKey === 'itinerary' ? 'Lịch trình' :
                    tabKey === 'policies' ? 'Chính sách' : 'Hình ảnh'
            }
          </div>
        ))}
      </div>

      {renderContent()}

      <div className="ct-btn-group">
        <button className="ct-btn" onClick={() => nav("/partner/tours")}>
          Hủy bỏ
        </button>
        <button
          className="ct-btn-primary"
          onClick={handleSubmit}
          disabled={loading}
        >
          {loading ? "Đang xử lý..." : "Hoàn tất & Đăng Tour"}
        </button>
      </div>
    </div>
  );
}