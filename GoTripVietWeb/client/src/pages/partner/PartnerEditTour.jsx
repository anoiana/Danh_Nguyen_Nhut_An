import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import catalogApi from "../../api/catalogApi";
import locationApi from "../../api/locationApi";
import categoryApi from "../../api/categoryApi";
import LocationRequestModal from "../../components/partner/LocationRequestModal";
import CategoryRequestModal from "../../components/partner/CategoryRequestModal";
import "../../styles/admin/CreateTour.css"; // Sử dụng chung file CSS đẹp

export default function PartnerEditTour() {
    const nav = useNavigate();
    const { id } = useParams();
    const isEditMode = !!id; // True nếu đang sửa

    const [activeTab, setActiveTab] = useState("general");
    const [loading, setLoading] = useState(false);

    // Data lists
    const [locations, setLocations] = useState([]);
    const [categories, setCategories] = useState([]);

    // Modals
    const [showLocModal, setShowLocModal] = useState(false);
    const [showCatModal, setShowCatModal] = useState(false);

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

        // tour_details flattened
        duration_days: 3,
        start_point: "Hồ Chí Minh",
        transport_type: "Xe du lịch",
        hotel_rating: 3,
        hotel_name: "",

        // highlights flattened
        highlight_attractions: "",
        highlight_cuisine: "",
        highlight_suitable: "",
        highlight_ideal_time: "",

        // Arrays
        policies: [
            { title: "Giá bao gồm", content: "Xe đưa đón, HDV, Nước uống..." },
            { title: "Giá không bao gồm", content: "Thuế VAT, Chi phí cá nhân..." },
        ],
        itinerary: [
            { day: 1, title: "Khởi hành", details: "", meals: [], accommodation: "" },
        ],

        // [QUAN TRỌNG] Lưu lịch cũ để không bị mất khi update
        schedules: []
    });

    // --- 1. LOAD RESOURCES ---
    useEffect(() => {
        const fetchResources = async () => {
            try {
                const [locs, cats] = await Promise.all([
                    locationApi.getAll({ query_mode: 'partner' }),
                    categoryApi.getAll({ query_mode: 'partner' }),
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

    // --- 2. LOAD TOUR DATA (EDIT MODE) ---
    useEffect(() => {
        if (!isEditMode) return;

        const fetchTourData = async () => {
            try {
                setLoading(true);
                const res = await catalogApi.getById(id);
                const data = res.data?.product || res.data || res;

                setForm(prev => ({
                    ...prev,
                    product_type: data.product_type || "tour",
                    title: data.title || "",
                    product_code: data.product_code || "",
                    base_price: data.base_price || 0,
                    sustainability_score: data.sustainability_score || 3,
                    is_active: data.is_active,

                    location_ids: data.location_ids?.map(x => x._id || x) || [],
                    category_ids: data.category_ids?.map(x => x._id || x) || [],

                    tags: Array.isArray(data.tags) ? data.tags.join(", ") : (data.tags || ""),
                    description_short: data.description_short || "",
                    description_long: data.description_long || "",
                    images: data.images || [],

                    duration_days: data.tour_details?.duration_days || 1,
                    start_point: data.tour_details?.start_point || "",
                    transport_type: data.tour_details?.transport_type || "Xe du lịch",
                    hotel_rating: data.tour_details?.hotel_rating || 3,
                    hotel_name: data.tour_details?.hotel_name || "",

                    highlight_attractions: data.tour_details?.trip_highlights?.attractions || "",
                    highlight_cuisine: data.tour_details?.trip_highlights?.cuisine || "",
                    highlight_suitable: data.tour_details?.trip_highlights?.suitable_for || "",
                    highlight_ideal_time: data.tour_details?.trip_highlights?.ideal_time || "",

                    policies: data.tour_details?.policy_notes || [],
                    itinerary: data.tour_details?.itinerary || [],
                    schedules: data.tour_details?.schedules || []
                }));
            } catch (err) {
                alert("Không thể tải thông tin tour: " + err.message);
                nav("/partner/tours");
            } finally {
                setLoading(false);
            }
        };

        fetchTourData();
    }, [id, isEditMode, nav]);

    // --- HANDLERS ---
    const handleLocationAdded = (newLocation) => {
        setLocations((prev) => [...prev, newLocation]);
        const newId = newLocation._id || newLocation.id;
        setForm((prev) => ({ ...prev, location_ids: [...prev.location_ids, newId] }));
        alert(`Đã thêm địa điểm "${newLocation.name}". Đang chờ Admin duyệt.`);
    };

    const handleCategoryAdded = (newCategory) => {
        setCategories((prev) => [...prev, newCategory]);
        const newId = newCategory._id || newCategory.id;
        setForm((prev) => ({ ...prev, category_ids: [...prev.category_ids, newId] }));
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
                { day: prev.itinerary.length + 1, title: "", details: "", meals: [], accommodation: "" },
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

    // --- SUBMIT ---
    const handleSubmit = async () => {
        if (!form.title.trim()) return alert("⚠️ Vui lòng nhập tên Tour!");
        if (form.base_price <= 0) return alert("⚠️ Giá tour phải lớn hơn 0!");
        if (form.location_ids.length === 0) return alert("⚠️ Vui lòng chọn ít nhất 1 Địa điểm!");
        if (form.category_ids.length === 0) return alert("⚠️ Vui lòng chọn ít nhất 1 Danh mục!");

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
                    schedules: form.schedules, // Giữ lịch cũ

                    trip_highlights: {
                        attractions: form.highlight_attractions,
                        cuisine: form.highlight_cuisine,
                        suitable_for: form.highlight_suitable,
                        ideal_time: form.highlight_ideal_time,
                    },
                },
            };

            if (isEditMode) {
                await catalogApi.update(id, payload);
                alert("✅ Cập nhật tour thành công!");
            } else {
                await catalogApi.create(payload);
                alert("✅ Đăng tour thành công! Vui lòng chờ duyệt.");
            }

            nav("/partner/tours");
        } catch (err) {
            console.error("Full Error:", err);
            const msg = err.response?.data?.message || err.message || "Lỗi không xác định";
            alert("❌ Lỗi lưu tour: " + msg);
        } finally {
            setLoading(false);
        }
    };

    // --- RENDER ---
    const renderContent = () => {
        switch (activeTab) {
            case "general":
                return (
                    <div className="ct-card">
                        <div className="ct-section-title">1. Thông tin cơ bản</div>
                        <div className="ct-field">
                            <label className="ct-label">Tên Tour <span style={{ color: "red" }}>*</span></label>
                            <input className="ct-input" name="title" value={form.title} onChange={handleChange} />
                        </div>

                        <div className="ct-grid-2">
                            <div className="ct-field">
                                <label className="ct-label">Mã Tour {isEditMode && "(Không thể sửa)"}</label>
                                <input
                                    className="ct-input"
                                    name="product_code"
                                    value={form.product_code}
                                    onChange={handleChange}
                                    disabled={isEditMode}
                                    style={isEditMode ? { background: '#f3f4f6', cursor: 'not-allowed' } : {}}
                                    placeholder="VD: DL-001"
                                />
                            </div>
                            <div className="ct-field">
                                <label className="ct-label">Giá cơ bản (VND) <span style={{ color: "red" }}>*</span></label>
                                <input type="number" className="ct-input" name="base_price" value={form.base_price} onChange={handleChange} />
                            </div>
                        </div>

                        <div className="ct-grid-3">
                            <div className="ct-field">
                                <label className="ct-label">Điểm bền vững</label>
                                <input type="number" className="ct-input" value={form.sustainability_score} disabled style={{ backgroundColor: "#f3f4f6" }} />
                            </div>
                            <div className="ct-field">
                                <label className="ct-label">Trạng thái</label>
                                <select className="ct-select" name="is_active" value={String(form.is_active)} onChange={(e) => setForm({ ...form, is_active: e.target.value === "true" })}>
                                    <option value="true">Hoạt động</option>
                                    <option value="false">Tạm ẩn</option>
                                </select>
                            </div>
                            <div className="ct-field">
                                <label className="ct-label">Tags</label>
                                <input className="ct-input" name="tags" value={form.tags} onChange={handleChange} placeholder="biển, hè..." />
                            </div>
                        </div>

                        <div className="ct-grid-2">
                            <div className="ct-field">
                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                                    <label className="ct-label mb-0">Địa điểm (Ctrl+Click)</label>
                                    <span onClick={() => setShowLocModal(true)} style={{ fontSize: 12, color: '#0b5fff', cursor: 'pointer', fontWeight: 'bold' }}>+ Thêm mới</span>
                                </div>
                                <select multiple className="ct-select" style={{ height: 120 }} onChange={(e) => handleMultiSelect(e, "location_ids")} value={form.location_ids}>
                                    {locations.map((l) => (
                                        <option key={l._id || l.id} value={l._id || l.id}>{l.name} {l.status === 'pending' ? "(⏳)" : ""}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="ct-field">
                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                                    <label className="ct-label mb-0">Danh mục (Ctrl+Click)</label>
                                    <span onClick={() => setShowCatModal(true)} style={{ fontSize: 12, color: '#0b5fff', cursor: 'pointer', fontWeight: 'bold' }}>+ Thêm mới</span>
                                </div>
                                <select multiple className="ct-select" style={{ height: 120 }} onChange={(e) => handleMultiSelect(e, "category_ids")} value={form.category_ids}>
                                    {categories.map((c) => (
                                        <option key={c._id || c.id} value={c._id || c.id}>{c.name} {c.status === 'pending' ? "(⏳)" : ""}</option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        <div className="ct-field">
                            <label className="ct-label">Mô tả ngắn</label>
                            <textarea className="ct-textarea" style={{ minHeight: 80 }} name="description_short" value={form.description_short} onChange={handleChange} />
                        </div>
                        <div className="ct-field">
                            <label className="ct-label">Mô tả chi tiết</label>
                            <textarea className="ct-textarea" style={{ minHeight: 150 }} name="description_long" value={form.description_long} onChange={handleChange} />
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
                                <input className="ct-input" name="start_point" value={form.start_point} onChange={handleChange} />
                            </div>
                            <div className="ct-field">
                                <label className="ct-label">Thời lượng (ngày)</label>
                                <input type="number" className="ct-input" name="duration_days" value={form.duration_days} onChange={handleChange} />
                            </div>
                            <div className="ct-field">
                                <label className="ct-label">Phương tiện</label>
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
                                <label className="ct-label">Khách sạn (Sao)</label>
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
                                <label className="ct-label">Tên Khách sạn</label>
                                <input className="ct-input" name="hotel_name" value={form.hotel_name} onChange={handleChange} />
                            </div>
                        </div>
                        <div style={{ marginTop: 24 }}>
                            <div className="ct-section-title">Highlights</div>
                            <div className="ct-grid-2">
                                <div className="ct-field"><label className="ct-label">Điểm tham quan</label><input className="ct-input" name="highlight_attractions" value={form.highlight_attractions} onChange={handleChange} /></div>
                                <div className="ct-field"><label className="ct-label">Ẩm thực</label><input className="ct-input" name="highlight_cuisine" value={form.highlight_cuisine} onChange={handleChange} /></div>
                                <div className="ct-field"><label className="ct-label">Đối tượng</label><input className="ct-input" name="highlight_suitable" value={form.highlight_suitable} onChange={handleChange} /></div>
                                <div className="ct-field"><label className="ct-label">Thời gian lý tưởng</label><input className="ct-input" name="highlight_ideal_time" value={form.highlight_ideal_time} onChange={handleChange} /></div>
                            </div>
                        </div>
                    </div>
                );

            case "itinerary":
                return (
                    <div className="ct-card">
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                            <div className="ct-section-title" style={{ marginBottom: 0, border: 'none' }}>3. Lịch trình chi tiết</div>
                            <button onClick={addItineraryDay} className="ct-btn ct-btn-primary" style={{ padding: '6px 12px' }}>+ Thêm ngày</button>
                        </div>
                        {form.itinerary.map((day, idx) => (
                            <div key={idx} className="ct-list-box">
                                <div className="ct-list-header">
                                    <span style={{ fontSize: 16 }}>🗓️ Ngày {day.day}</span>
                                    <button onClick={() => setForm(s => ({ ...s, itinerary: s.itinerary.filter((_, i) => i !== idx) }))} className="ct-btn-danger" style={{ border: 'none', cursor: 'pointer', padding: '4px 8px', borderRadius: 6, fontSize: 13 }}>Xóa</button>
                                </div>
                                <div className="ct-field"><label className="ct-label">Tiêu đề</label><input className="ct-input" value={day.title} onChange={e => updateItinerary(idx, "title", e.target.value)} /></div>
                                <div className="ct-field"><label className="ct-label">Chi tiết</label><textarea className="ct-textarea" style={{ minHeight: 60 }} value={day.details} onChange={e => updateItinerary(idx, "details", e.target.value)} /></div>
                                <div className="ct-grid-2">
                                    <div className="ct-field"><label className="ct-label">Ăn uống</label><input className="ct-input" value={day.meals?.join(", ")} onChange={e => updateItinerary(idx, "meals", e.target.value.split(","))} placeholder="Sáng, Trưa..." /></div>
                                    <div className="ct-field"><label className="ct-label">Nơi nghỉ</label><input className="ct-input" value={day.accommodation} onChange={e => updateItinerary(idx, "accommodation", e.target.value)} /></div>
                                </div>
                            </div>
                        ))}
                    </div>
                );

            case "policies":
                return (
                    <div className="ct-card">
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                            <div className="ct-section-title" style={{ marginBottom: 0 }}>4. Chính sách</div>
                            <button onClick={addPolicy} className="ct-btn ct-btn-sm" style={{ border: '1px solid #ddd' }}>+ Thêm mục</button>
                        </div>
                        {form.policies.map((pol, idx) => (
                            <div key={idx} className="ct-list-box">
                                <div className="ct-field"><label className="ct-label">Tiêu đề</label><input className="ct-input" value={pol.title} onChange={e => updatePolicy(idx, "title", e.target.value)} /></div>
                                <div className="ct-field"><label className="ct-label">Nội dung</label><textarea className="ct-textarea" style={{ minHeight: 60 }} value={pol.content} onChange={e => updatePolicy(idx, "content", e.target.value)} /></div>
                                <div style={{ textAlign: 'right' }}>
                                    <button onClick={() => setForm(s => ({ ...s, policies: s.policies.filter((_, i) => i !== idx) }))} style={{ color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, textDecoration: 'underline' }}>Xóa mục này</button>
                                </div>
                            </div>
                        ))}
                    </div>
                );

            case "media":
                return (
                    <div className="ct-card">
                        <div className="ct-section-title">5. Hình ảnh</div>
                        <div className="ct-upload-box">
                            <div style={{ fontSize: 40, marginBottom: 10 }}>📷</div>
                            <p style={{ fontWeight: 600, color: '#374151', marginBottom: 4 }}>Kéo thả hoặc bấm để chọn ảnh</p>
                            <input type="file" multiple accept="image/*" onChange={handleUpload} style={{ display: "none" }} id="upload-btn" />
                            <label htmlFor="upload-btn" className="ct-btn-primary" style={{ display: "inline-block", marginTop: 10, padding: '8px 20px' }}>Chọn ảnh từ máy</label>
                        </div>
                        {loading && <div style={{ marginTop: 10, textAlign: 'center', color: '#0b5fff' }}>⏳ Đang tải ảnh...</div>}
                        <div className="ct-img-grid">
                            {form.images.map((img, idx) => (
                                <div key={idx} className="ct-img-wrapper">
                                    <img src={img.url} alt="Tour" className="ct-img-thumb" />
                                    <button onClick={() => setForm(s => ({ ...s, images: s.images.filter((_, i) => i !== idx) }))} className="ct-img-remove">×</button>
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
            {/* MODALS */}
            <LocationRequestModal show={showLocModal} onHide={() => setShowLocModal(false)} onSuccess={handleLocationAdded} />
            <CategoryRequestModal show={showCatModal} onHide={() => setShowCatModal(false)} onSuccess={handleCategoryAdded} />

            <div className="ct-header">
                <div>
                    <h1 className="ct-h1">{isEditMode ? "Chỉnh Sửa Tour" : "Tạo Tour Mới"}</h1>
                    <div className="ct-sub">Cập nhật thông tin chi tiết để thu hút khách hàng.</div>
                </div>
                <button className="ct-btn" onClick={() => nav("/partner/tours")}>Thoát</button>
            </div>

            <div className="ct-tabs">
                {['general', 'operation', 'itinerary', 'policies', 'media'].map((tab, idx) => (
                    <div key={tab} className={`ct-tab ${activeTab === tab ? "active" : ""}`} onClick={() => setActiveTab(tab)}>
                        {idx + 1}. {tab === 'general' ? 'Tổng quan' : tab === 'operation' ? 'Vận hành' : tab === 'itinerary' ? 'Lịch trình' : tab === 'policies' ? 'Chính sách' : 'Hình ảnh'}
                    </div>
                ))}
            </div>

            {renderContent()}

            <div className="ct-btn-group">
                <button className="ct-btn" onClick={() => nav("/partner/tours")}>Hủy bỏ</button>
                <button className="ct-btn-primary" onClick={handleSubmit} disabled={loading}>
                    {loading ? "Đang lưu..." : (isEditMode ? "Lưu Thay Đổi" : "Hoàn tất & Đăng")}
                </button>
            </div>
        </div>
    );
}