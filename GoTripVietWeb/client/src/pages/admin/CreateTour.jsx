import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import locationApi from "../../api/locationApi";
import categoryApi from "../../api/categoryApi";
import "../../styles/admin/CreateTour.css" // [QUAN TRỌNG] Import file CSS

export default function CreateTour() {
  const nav = useNavigate();
  const [activeTab, setActiveTab] = useState("general");
  const [loading, setLoading] = useState(false);
  const [locations, setLocations] = useState([]);
  const [categories, setCategories] = useState([]);

  // --- INITIAL STATE ---
  const [form, setForm] = useState({
    product_type: "tour",
    title: "",
    product_code: "",
    base_price: 0,
    sustainability_score: 3,
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
      { title: "Giá không bao gồm", content: "Thuế VAT, Chi phí cá nhân..." }
    ],

    // itinerary (Array)
    itinerary: [
      { day: 1, title: "Khởi hành", details: "", meals: [], accommodation: "" }
    ]
  });

  // --- LOAD DATA ---
  useEffect(() => {
    const fetchResources = async () => {
      try {
        const [locs, cats] = await Promise.all([locationApi.getAll(), categoryApi.getAll()]);
        const locData = locs.data || locs;
        const catData = cats.data || cats;
        setLocations(Array.isArray(locData) ? locData : (locData.data || []));
        setCategories(Array.isArray(catData) ? catData : (catData.data || []));
      } catch (err) {
        console.error("Lỗi tải resources:", err);
      }
    };
    fetchResources();
  }, []);

  // --- HANDLERS ---
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm(prev => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value
    }));
  };

  const handleMultiSelect = (e, field) => {
    const opts = Array.from(e.target.selectedOptions, option => option.value);
    setForm(prev => ({ ...prev, [field]: opts }));
  };

  const handleUpload = async (e) => {
    const files = Array.from(e.target.files);
    if (!files.length) return;

    setLoading(true);
    try {
      const uploads = await Promise.all(files.map(file => {
        const fd = new FormData();
        fd.append("file", file);
        return catalogApi.uploadTourImage(fd);
      }));

      const newImages = uploads.map(res => ({
        url: res.url || res.data.url,
        public_id: res.public_id || res.data.public_id
      }));

      setForm(prev => ({ ...prev, images: [...prev.images, ...newImages] }));
    } catch (err) {
      alert("Lỗi upload ảnh: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const addItineraryDay = () => {
    setForm(prev => ({
      ...prev,
      itinerary: [
        ...prev.itinerary,
        { day: prev.itinerary.length + 1, title: "", details: "", meals: [], accommodation: "" }
      ]
    }));
  };

  const updateItinerary = (index, field, value) => {
    const newItin = [...form.itinerary];
    newItin[index][field] = value;
    setForm(prev => ({ ...prev, itinerary: newItin }));
  };

  const addPolicy = () => {
    setForm(prev => ({
      ...prev,
      policies: [...prev.policies, { title: "", content: "" }]
    }));
  };

  const updatePolicy = (index, field, value) => {
    const newPol = [...form.policies];
    newPol[index][field] = value;
    setForm(prev => ({ ...prev, policies: newPol }));
  };

  const handleSubmit = async () => {
    if (!form.title.trim()) return alert("Vui lòng nhập tên Tour");
    if (form.base_price < 0) return alert("Giá không hợp lệ");

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
        tags: form.tags.split(",").map(t => t.trim()).filter(Boolean),
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
            ideal_time: form.highlight_ideal_time
          }
        }
      };

      await catalogApi.create(payload);
      alert("Tạo tour thành công!");
      nav("/admin/manage/tours");
    } catch (err) {
      console.error(err);
      alert("Lỗi tạo tour: " + (err.response?.data?.message || err.message));
    } finally {
      setLoading(false);
    }
  };

  const renderContent = () => {
    switch (activeTab) {
      case "general":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Thông tin cơ bản</div>
            <div className="ct-field">
              <div className="ct-label">Tên Tour <span style={{color:'red'}}>*</span></div>
              <input className="ct-input" name="title" value={form.title} onChange={handleChange} placeholder="VD: Tour Đà Lạt 3N2Đ - Săn Mây" />
            </div>
            
            <div className="ct-grid-2">
              <div className="ct-field">
                <div className="ct-label">Mã Tour (Tự động in hoa)</div>
                <input className="ct-input" name="product_code" value={form.product_code} onChange={handleChange} placeholder="VD: DL-001" />
              </div>
              <div className="ct-field">
                <div className="ct-label">Giá cơ bản (VND) <span style={{color:'red'}}>*</span></div>
                <input type="number" className="ct-input" name="base_price" value={form.base_price} onChange={handleChange} />
              </div>
            </div>

            <div className="ct-grid-3">
              <div className="ct-field">
                <div className="ct-label">Điểm bền vững (0-5)</div>
                <input type="number" min={0} max={5} className="ct-input" name="sustainability_score" value={form.sustainability_score} onChange={handleChange} />
              </div>
              <div className="ct-field">
                <div className="ct-label">Trạng thái</div>
                <select className="ct-select" name="is_active" value={form.is_active} onChange={(e) => setForm({...form, is_active: e.target.value === 'true'})}>
                  <option value="true">Hoạt động</option>
                  <option value="false">Tạm ẩn</option>
                </select>
              </div>
              <div className="ct-field">
                <div className="ct-label">Tags (cách nhau dấu phẩy)</div>
                <input className="ct-input" name="tags" value={form.tags} onChange={handleChange} placeholder="biển, hè, giá rẻ..." />
              </div>
            </div>

            <div className="ct-grid-2">
              <div className="ct-field">
                <div className="ct-label">Địa điểm (Giữ Ctrl để chọn nhiều)</div>
                <select multiple className="ct-select" style={{height: 120}} onChange={(e) => handleMultiSelect(e, 'location_ids')}>
                  {locations.map(l => <option key={l._id || l.id} value={l._id || l.id}>{l.name}</option>)}
                </select>
              </div>
              <div className="ct-field">
                <div className="ct-label">Danh mục (Giữ Ctrl để chọn nhiều)</div>
                <select multiple className="ct-select" style={{height: 120}} onChange={(e) => handleMultiSelect(e, 'category_ids')}>
                  {categories.map(c => <option key={c._id || c.id} value={c._id || c.id}>{c.name}</option>)}
                </select>
              </div>
            </div>

            <div className="ct-field">
              <div className="ct-label">Mô tả ngắn</div>
              <textarea className="ct-textarea" style={{minHeight: 80}} name="description_short" value={form.description_short} onChange={handleChange} />
            </div>
            <div className="ct-field">
              <div className="ct-label">Mô tả chi tiết</div>
              <textarea className="ct-textarea" name="description_long" value={form.description_long} onChange={handleChange} />
            </div>
          </div>
        );

      case "operation":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Vận hành & Lưu trú</div>
            <div className="ct-grid-3">
              <div className="ct-field">
                <div className="ct-label">Điểm khởi hành</div>
                <input className="ct-input" name="start_point" value={form.start_point} onChange={handleChange} />
              </div>
              <div className="ct-field">
                <div className="ct-label">Thời lượng (ngày)</div>
                <input type="number" className="ct-input" name="duration_days" value={form.duration_days} onChange={handleChange} />
              </div>
              <div className="ct-field">
                <div className="ct-label">Phương tiện</div>
                <select className="ct-select" name="transport_type" value={form.transport_type} onChange={handleChange}>
                  <option value="Xe du lịch">Xe du lịch</option>
                  <option value="Máy bay">Máy bay</option>
                  <option value="Tàu hỏa">Tàu hỏa</option>
                  <option value="Du thuyền">Du thuyền</option>
                  <option value="Tự túc">Tự túc</option>
                </select>
              </div>
            </div>

            <div className="ct-grid-2">
              <div className="ct-field">
                <div className="ct-label">Khách sạn (Sao)</div>
                <select className="ct-select" name="hotel_rating" value={form.hotel_rating} onChange={handleChange}>
                  <option value="0">Không có</option>
                  <option value="1">1 Sao</option>
                  <option value="2">2 Sao</option>
                  <option value="3">3 Sao</option>
                  <option value="4">4 Sao</option>
                  <option value="5">5 Sao</option>
                </select>
              </div>
              <div className="ct-field">
                <div className="ct-label">Tên Khách sạn (Dự kiến)</div>
                <input className="ct-input" name="hotel_name" value={form.hotel_name} onChange={handleChange} />
              </div>
            </div>

            <div style={{marginTop: 20}}>
              <div className="ct-section-title">Điểm nổi bật (Highlights)</div>
              <div className="ct-grid-2">
                <div className="ct-field">
                  <div className="ct-label">Điểm tham quan</div>
                  <input className="ct-input" name="highlight_attractions" value={form.highlight_attractions} onChange={handleChange} placeholder="Vịnh Hạ Long, Hang Sửng Sốt..." />
                </div>
                <div className="ct-field">
                  <div className="ct-label">Ẩm thực</div>
                  <input className="ct-input" name="highlight_cuisine" value={form.highlight_cuisine} onChange={handleChange} placeholder="Chả mực, Hải sản..." />
                </div>
                <div className="ct-field">
                  <div className="ct-label">Đối tượng thích hợp</div>
                  <input className="ct-input" name="highlight_suitable" value={form.highlight_suitable} onChange={handleChange} placeholder="Gia đình, Cặp đôi..." />
                </div>
                <div className="ct-field">
                  <div className="ct-label">Thời gian lý tưởng</div>
                  <input className="ct-input" name="highlight_ideal_time" value={form.highlight_ideal_time} onChange={handleChange} placeholder="Tháng 4 - Tháng 9" />
                </div>
              </div>
            </div>
          </div>
        );

      case "itinerary":
        return (
          <div className="ct-card">
            <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 16}}>
              <div className="ct-section-title">Lịch trình chi tiết</div>
              <button onClick={addItineraryDay} className="ct-btn ct-btn-sm">+ Thêm ngày</button>
            </div>
            
            {form.itinerary.map((day, idx) => (
              <div key={idx} className="ct-list-box">
                <div className="ct-list-header">
                  <span>Ngày {day.day}</span>
                  <button 
                    onClick={() => setForm(s => ({...s, itinerary: s.itinerary.filter((_, i) => i !== idx)}))}
                    className="ct-btn-danger"
                    style={{cursor:'pointer', border:'none', fontSize: 13}}
                  >Xóa</button>
                </div>
                <div className="ct-field">
                  <div className="ct-label">Tiêu đề ngày</div>
                  <input 
                    className="ct-input" 
                    value={day.title} 
                    onChange={(e) => updateItinerary(idx, 'title', e.target.value)} 
                    placeholder="VD: Đón sân bay - Check in khách sạn"
                  />
                </div>
                <div className="ct-field">
                  <div className="ct-label">Chi tiết hoạt động</div>
                  <textarea 
                    className="ct-textarea"
                    style={{minHeight: 80}} 
                    value={day.details} 
                    onChange={(e) => updateItinerary(idx, 'details', e.target.value)}
                  />
                </div>
                <div className="ct-grid-2">
                  <div className="ct-field">
                    <div className="ct-label">Ăn uống (Gõ tay: Sáng, Trưa, Tối)</div>
                    <input 
                      className="ct-input" 
                      value={day.meals?.join(", ")} 
                      onChange={(e) => updateItinerary(idx, 'meals', e.target.value.split(","))} 
                      placeholder="Sáng, Trưa"
                    />
                  </div>
                  <div className="ct-field">
                    <div className="ct-label">Nơi nghỉ</div>
                    <input 
                      className="ct-input" 
                      value={day.accommodation} 
                      onChange={(e) => updateItinerary(idx, 'accommodation', e.target.value)} 
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
            <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 16}}>
              <div className="ct-section-title">Chính sách & Lưu ý</div>
              <button onClick={addPolicy} className="ct-btn ct-btn-sm">+ Thêm mục</button>
            </div>
            {form.policies.map((pol, idx) => (
              <div key={idx} className="ct-list-box">
                <div className="ct-field">
                  <div className="ct-label">Tiêu đề</div>
                  <input 
                    className="ct-input" 
                    value={pol.title} 
                    onChange={(e) => updatePolicy(idx, 'title', e.target.value)} 
                  />
                </div>
                <div className="ct-field">
                  <div className="ct-label">Nội dung</div>
                  <textarea 
                    className="ct-textarea"
                    style={{minHeight: 60}} 
                    value={pol.content} 
                    onChange={(e) => updatePolicy(idx, 'content', e.target.value)} 
                  />
                </div>
                <button 
                  onClick={() => setForm(s => ({...s, policies: s.policies.filter((_, i) => i !== idx)}))}
                  className="ct-btn-danger"
                  style={{cursor:'pointer', border:'none', fontSize: 12}}
                >
                  Xóa mục này
                </button>
              </div>
            ))}
          </div>
        );

      case "media":
        return (
          <div className="ct-card">
            <div className="ct-section-title">Hình ảnh</div>
            <div className="ct-upload-box">
              <p style={{fontWeight: 700, color: '#374151'}}>Kéo thả hoặc bấm để chọn ảnh</p>
              <input type="file" multiple accept="image/*" onChange={handleUpload} style={{display:'none'}} id="upload-btn" />
              <label htmlFor="upload-btn" className="ct-btn-primary" style={{display: 'inline-block', marginTop: 10}}>Chọn ảnh</label>
            </div>
            
            {loading && <div style={{marginTop: 10, color: '#0b5fff'}}>Đang tải ảnh lên...</div>}

            <div className="ct-img-grid">
              {form.images.map((img, idx) => (
                <div key={idx} className="ct-img-wrapper">
                  <img src={img.url} alt="Tour" className="ct-img-thumb" />
                  <button 
                    onClick={() => setForm(s => ({...s, images: s.images.filter((_, i) => i !== idx)}))}
                    className="ct-img-remove"
                  >x</button>
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
      <div className="ct-header">
        <div>
          <h1 className="ct-h1">Tạo Tour Mới</h1>
          <div className="ct-sub">Nhập đầy đủ thông tin để thu hút khách hàng</div>
        </div>
        <button className="ct-btn" onClick={() => nav("/admin/manage/tours")}>Thoát</button>
      </div>

      <div className="ct-tabs">
        <div className={`ct-tab ${activeTab === 'general' ? 'active' : ''}`} onClick={() => setActiveTab("general")}>1. Tổng quan</div>
        <div className={`ct-tab ${activeTab === 'operation' ? 'active' : ''}`} onClick={() => setActiveTab("operation")}>2. Vận hành</div>
        <div className={`ct-tab ${activeTab === 'itinerary' ? 'active' : ''}`} onClick={() => setActiveTab("itinerary")}>3. Lịch trình</div>
        <div className={`ct-tab ${activeTab === 'policies' ? 'active' : ''}`} onClick={() => setActiveTab("policies")}>4. Chính sách</div>
        <div className={`ct-tab ${activeTab === 'media' ? 'active' : ''}`} onClick={() => setActiveTab("media")}>5. Hình ảnh</div>
      </div>

      {renderContent()}

      <div className="ct-btn-group">
        <button className="ct-btn" onClick={() => nav("/admin/manage/tours")}>Hủy bỏ</button>
        <button className="ct-btn-primary" onClick={handleSubmit} disabled={loading}>
          {loading ? "Đang xử lý..." : "Hoàn tất & Tạo Tour"}
        </button>
      </div>
    </div>
  );
}