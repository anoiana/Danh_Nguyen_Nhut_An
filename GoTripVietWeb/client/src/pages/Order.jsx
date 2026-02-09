// src/pages/Order.jsx
import React, { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";
import Badge from "react-bootstrap/Badge";
import "../styles/booking-process.css";
import { formatCurrency } from "../utils/formatData";
import inventoryApi from "../api/inventoryApi";
import bookingApi from "../api/bookingApi";
import promotionApi from "../api/promotionApi";

// Component con: Thanh tiến trình
const BookingStepper = ({ step }) => (
  <div className="booking-stepper">
    <div className="step-connector"></div>
    <div className={`step-item ${step >= 1 ? "active" : ""}`}>
      <div className="step-icon"><i className="bi bi-person-lines-fill"></i></div>
      <span>NHẬP THÔNG TIN</span>
    </div>
    <div className={`step-item ${step >= 2 ? "active" : ""}`}>
      <div className="step-icon"><i className="bi bi-credit-card"></i></div>
      <span>THANH TOÁN</span>
    </div>
    <div className={`step-item ${step >= 3 ? "active" : ""}`}>
      <div className="step-icon"><i className="bi bi-check-lg"></i></div>
      <span>HOÀN TẤT</span>
    </div>
  </div>
);

export default function Order() {
  const navigate = useNavigate();
  const location = useLocation();
  const productData = location.state?.product;

  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // --- STATES CHO FORM & VALIDATION ---
  const [contactInfo, setContactInfo] = useState({
    fullName: "", phone: "", email: "", address: "", note: ""
  });
  const [errors, setErrors] = useState({}); // [MỚI] State lưu lỗi

  // --- STATES CHO PROMOTION ---
  const [showPromoModal, setShowPromoModal] = useState(false);
  const [availablePromos, setAvailablePromos] = useState([]);
  const [promoCode, setPromoCode] = useState("");
  const [appliedPromo, setAppliedPromo] = useState(null);
  const [promoError, setPromoError] = useState("");

  // --- STATES HÀNH KHÁCH ---
  const initialCounts = productData?.bookingInfo ? {
    adult: productData.bookingInfo.adults || 1,
    child: productData.bookingInfo.children || 0,
    toddler: 0,
    infant: 0
  } : { adult: 1, child: 0, toddler: 0, infant: 0 };

  const [counts, setCounts] = useState(initialCounts);
  const [passengers, setPassengers] = useState([]);
  const [useSingleRoom, setUseSingleRoom] = useState(false);
  const SINGLE_ROOM_PRICE = 1400000;

  // --- KIỂM TRA DỮ LIỆU ĐẦU VÀO ---
  useEffect(() => {
    if (!productData) {
      alert("Không tìm thấy thông tin chuyến đi. Vui lòng chọn tour lại!");
      navigate("/");
    }
    const token = localStorage.getItem("token");
    setIsLoggedIn(!!token);
  }, [productData, navigate]);

  // --- LOAD PROMOTION ---
  useEffect(() => {
    const fetchPromos = async () => {
      try {
        const res = await promotionApi.getAll();
        const list = res.data || res;
        const now = new Date();

        const activeList = list.filter(p => {
          const isActive = p.is_active === true || p.status === 'active';
          const validStart = p.start_date ? new Date(p.start_date) <= now : true;
          const validEnd = p.end_date ? new Date(p.end_date) >= now : true;
          const hasQuantity = (p.total_quantity - p.used_quantity) > 0;
          return isActive && validStart && validEnd && hasQuantity;
        });
        setAvailablePromos(activeList);
      } catch (error) {
        console.error("Lỗi load promo:", error);
      }
    };
    fetchPromos();
  }, []);

  // --- CẬP NHẬT LIST HÀNH KHÁCH KHI SỐ LƯỢNG THAY ĐỔI ---
  useEffect(() => {
    let newPassengers = [];
    for (let i = 0; i < counts.adult; i++) newPassengers.push({ type: 'adult', label: 'Người lớn', index: i, gender: 'Nam' });
    for (let i = 0; i < counts.child; i++) newPassengers.push({ type: 'child', label: 'Trẻ em', index: i, gender: 'Nam' });
    for (let i = 0; i < counts.toddler; i++) newPassengers.push({ type: 'toddler', label: 'Trẻ nhỏ', index: i, gender: 'Nam' });
    for (let i = 0; i < counts.infant; i++) newPassengers.push({ type: 'infant', label: 'Em bé', index: i, gender: 'Nam' });

    setPassengers(prev => {
      return newPassengers.map((p, idx) => {
        if (prev[idx] && prev[idx].type === p.type) {
          return { ...p, ...prev[idx], index: idx };
        }
        return p;
      });
    });
  }, [counts]);

  if (!productData) return null;
  const { transportInfo } = productData;

  // --- HÀM VALIDATE FORM (MỚI) ---
  const validateForm = () => {
    let newErrors = {};
    let isValid = true;

    // 1. Validate Liên hệ
    if (!contactInfo.fullName.trim()) {
      newErrors.fullName = "Vui lòng nhập họ tên người liên hệ.";
      isValid = false;
    }

    // Regex số điện thoại VN: Bắt đầu bằng 0, theo sau là 9-10 chữ số
    const phoneRegex = /(84|0[3|5|7|8|9])+([0-9]{8})\b/;
    if (!contactInfo.phone.trim()) {
      newErrors.phone = "Vui lòng nhập số điện thoại.";
      isValid = false;
    } else if (!phoneRegex.test(contactInfo.phone)) {
      newErrors.phone = "Số điện thoại không hợp lệ (VD: 0901234567).";
      isValid = false;
    }

    // Regex Email cơ bản
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!contactInfo.email.trim()) {
      newErrors.email = "Vui lòng nhập email.";
      isValid = false;
    } else if (!emailRegex.test(contactInfo.email)) {
      newErrors.email = "Email không đúng định dạng.";
      isValid = false;
    }

    // 2. Validate Hành khách
    passengers.forEach((p, idx) => {
      if (!p.fullName || !p.fullName.trim()) {
        newErrors[`pass_name_${idx}`] = "Vui lòng nhập họ tên.";
        isValid = false;
      }
      if (!p.dateOfBirth) {
        newErrors[`pass_dob_${idx}`] = "Vui lòng chọn ngày sinh.";
        isValid = false;
      }
    });

    setErrors(newErrors);
    return isValid;
  };

  // --- LOGIC TÍNH GIÁ ---
  const calculateTotal = () => {
    let total = 0;
    const basePrice = productData.basePrice || 0;

    total += counts.adult * basePrice;
    total += counts.child * (basePrice * 0.8);
    total += counts.toddler * (basePrice * 0.5);
    total += counts.infant * (basePrice * 0.1);

    if (useSingleRoom) total += SINGLE_ROOM_PRICE;

    const subTotalBeforeDiscount = total;
    let promoDiscount = 0;

    if (appliedPromo) {
      if (appliedPromo.type === 'percentage') {
        promoDiscount = subTotalBeforeDiscount * (appliedPromo.value / 100);
        if (appliedPromo.rules?.max_discount && promoDiscount > appliedPromo.rules.max_discount) {
          promoDiscount = appliedPromo.rules.max_discount;
        }
      } else if (appliedPromo.type === 'fixed_amount') {
        promoDiscount = appliedPromo.value;
      }
      if (promoDiscount > subTotalBeforeDiscount) promoDiscount = subTotalBeforeDiscount;
    }

    return { subTotal: total, promoDiscount, final: total - promoDiscount };
  };

  const { subTotal, promoDiscount, final } = calculateTotal();

  // --- HANDLERS ---
  const handleCountChange = (type, delta) => {
    setCounts(prev => {
      const newVal = prev[type] + delta;
      if (newVal < 0) return prev;
      if (type === 'adult' && newVal < 1) return prev;
      return { ...prev, [type]: newVal };
    });
  };

  const handlePassengerChange = (index, field, value) => {
    setPassengers(prev => {
      const updated = [...prev];
      if (!updated[index]) return prev;
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
    // Xóa lỗi khi người dùng bắt đầu nhập
    if (errors[`pass_${field === 'fullName' ? 'name' : 'dob'}_${index}`]) {
      setErrors(prev => ({ ...prev, [`pass_${field === 'fullName' ? 'name' : 'dob'}_${index}`]: null }));
    }
  };

  const handleContactChange = (field, value) => {
    setContactInfo(prev => ({ ...prev, [field]: value }));
    if (errors[field]) setErrors(prev => ({ ...prev, [field]: null }));
  };

  const handleApplyPromo = async (codeOverride = null) => {
    const codeToCheck = codeOverride || promoCode;
    if (!codeToCheck) return;
    setPromoError("");
    try {
      const res = await inventoryApi.checkPromotion(codeToCheck);
      const promo = res.data || res;

      if (promo.rules && promo.rules.min_spend > subTotal) {
        setPromoError(`Đơn hàng từ ${formatCurrency(promo.rules.min_spend)} mới được dùng.`);
        setAppliedPromo(null);
        return;
      }
      setAppliedPromo(promo);
      if (codeOverride) setPromoCode(codeOverride);
    } catch (error) {
      setAppliedPromo(null);
      setPromoError("Mã giảm giá không hợp lệ hoặc hết hạn.");
    }
  };

  const handleSelectPromo = (promo) => {
    if (promo.rules && promo.rules.min_spend > subTotal) return;
    setPromoCode(promo.code);
    handleApplyPromo(promo.code);
    setShowPromoModal(false);
  };

  const handleSubmit = async () => {
    // [QUAN TRỌNG] Gọi hàm validate trước khi submit
    if (!validateForm()) {
      alert("Vui lòng kiểm tra lại thông tin nhập liệu (các ô màu đỏ).");
      // Scroll lên đầu để user thấy lỗi
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    try {
      const departDate = transportInfo?.details?.depart?.date
        || productData.bookingInfo?.date
        || "Chưa xác định";

      const payload = {
        items: [{
          productId: productData.id,
          inventoryId: productData.bookingInfo?.inventoryId,
          productType: 'tour',
          quantity: counts.adult + counts.child + counts.toddler + counts.infant,
          unitPrice: productData.basePrice,
          productTitle: productData.title,
          image: productData.image,
          detailsText: `Ngày đi: ${departDate}`
        }],
        promotionCode: appliedPromo ? appliedPromo.code : null,
        passengers: passengers,
        contactInfo: contactInfo
      };

      const res = await bookingApi.createBooking(payload);
      const bookingId = res.data?.bookingId || res.bookingId;

      if (bookingId) {
        navigate("/payment", { state: { bookingId: bookingId } });
      } else {
        throw new Error("Không nhận được Booking ID.");
      }
    } catch (error) {
      console.error("Lỗi đặt tour:", error);
      const msg = error.response?.data?.message || error.message;
      alert("Lỗi đặt tour: " + msg);
    }
  };

  const renderTransportInfo = () => { /* ... Giữ nguyên logic cũ ... */
    if (!transportInfo || transportInfo.type === 'other') {
      return <div className="p-3 border-bottom bg-light small text-muted fst-italic">Phương tiện: {transportInfo?.details?.vehicle || "Theo lịch trình"}</div>;
    }
    const details = transportInfo.details || {};
    const depart = details.depart || {};
    const isFlight = transportInfo.type === 'flight';
    return (
      <div className="p-3 border-bottom bg-light bg-opacity-50">
        <div className="fw-bold small mb-2 text-primary">{isFlight ? "✈️ CHUYẾN BAY" : "🚌 DI CHUYỂN"}</div>
        <div className="mb-2 fw-bold text-dark">{isFlight ? details.airline : details.vehicle}</div>
        <div className="mb-3">
          <div className="d-flex justify-content-between small text-muted mb-1"><span>Khởi hành - {depart.date}</span></div>
          <div className="d-flex justify-content-between fw-bold small"><span>{depart.time}</span><span>{isFlight ? depart.code : (depart.location || "Điểm hẹn")}</span></div>
        </div>
      </div>
    );
  };

  return (
    <Container className="my-5">
      <BookingStepper step={1} />
      <Row className="g-4">
        <Col lg={8}>
          {/* 1. LIÊN LẠC (CÓ VALIDATION) */}
          <h5 className="fw-bold mb-3 text-uppercase">Thông tin liên lạc</h5>
          <div className="bg-light p-3 rounded mb-4 border">
            {!isLoggedIn && (
              <div className="bg-white p-2 mb-3 rounded border border-info text-primary d-flex align-items-center gap-2 small">
                <i className="bi bi-person-circle"></i> <span><strong>Đăng nhập</strong> để tích điểm!</span>
              </div>
            )}
            <Row className="g-3">
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Họ tên <span className="text-danger">*</span></Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Nhập họ tên"
                    value={contactInfo.fullName}
                    onChange={e => handleContactChange('fullName', e.target.value)}
                    isInvalid={!!errors.fullName} // Báo đỏ nếu lỗi
                  />
                  <Form.Control.Feedback type="invalid">{errors.fullName}</Form.Control.Feedback>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Điện thoại <span className="text-danger">*</span></Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="09..."
                    value={contactInfo.phone}
                    onChange={e => handleContactChange('phone', e.target.value)}
                    isInvalid={!!errors.phone}
                  />
                  <Form.Control.Feedback type="invalid">{errors.phone}</Form.Control.Feedback>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Email <span className="text-danger">*</span></Form.Label>
                  <Form.Control
                    type="email"
                    placeholder="email@example.com"
                    value={contactInfo.email}
                    onChange={e => handleContactChange('email', e.target.value)}
                    isInvalid={!!errors.email}
                  />
                  <Form.Control.Feedback type="invalid">{errors.email}</Form.Control.Feedback>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Địa chỉ</Form.Label>
                  <Form.Control type="text" placeholder="Địa chỉ (Tùy chọn)" value={contactInfo.address} onChange={e => handleContactChange('address', e.target.value)} />
                </Form.Group>
              </Col>
            </Row>
          </div>

          {/* 2. SỐ LƯỢNG (Giữ nguyên) */}
          <h5 className="fw-bold mb-3 text-uppercase">Hành khách</h5>
          <Row className="g-3 mb-4">
            {[
              { key: 'adult', label: 'Người lớn', sub: '>12 tuổi', min: 1 },
              { key: 'child', label: 'Trẻ em', sub: '5-11 tuổi', min: 0 },
              { key: 'toddler', label: 'Trẻ nhỏ', sub: '2-4 tuổi', min: 0 },
              { key: 'infant', label: 'Em bé', sub: '<2 tuổi', min: 0 },
            ].map((item) => (
              <Col md={6} key={item.key}>
                <div className="qty-box bg-white h-100 p-3 border rounded d-flex justify-content-between align-items-center shadow-sm">
                  <div><div className="fw-bold">{item.label}</div><div className="small text-muted">{item.sub}</div></div>
                  <div className="d-flex align-items-center gap-3">
                    <Button variant="outline-secondary" size="sm" onClick={() => handleCountChange(item.key, -1)} disabled={counts[item.key] <= item.min}>-</Button>
                    <span className="fw-bold fs-5">{counts[item.key]}</span>
                    <Button variant="outline-primary" size="sm" onClick={() => handleCountChange(item.key, 1)}>+</Button>
                  </div>
                </div>
              </Col>
            ))}
          </Row>

          {/* 3. CHI TIẾT KHÁCH (CÓ VALIDATION) */}
          <h5 className="fw-bold mb-3 text-uppercase">Thông tin hành khách</h5>
          <div className="bg-white border rounded p-3 mb-4">
            {passengers.map((p, idx) => (
              <div key={idx} className={`mb-3 ${idx < passengers.length - 1 ? "border-bottom pb-3" : ""}`}>
                <div className="d-flex align-items-center gap-2 mb-2">
                  <i className="bi bi-person-fill text-muted"></i>
                  <span className="fw-bold">{p.label} {p.index + 1}</span>
                </div>
                <Row className="g-2">
                  <Col md={4}>
                    <Form.Control
                      size="sm"
                      placeholder="Họ tên *"
                      value={p.fullName || ''}
                      onChange={(e) => handlePassengerChange(idx, 'fullName', e.target.value)}
                      isInvalid={!!errors[`pass_name_${idx}`]}
                    />
                    <Form.Control.Feedback type="invalid">{errors[`pass_name_${idx}`]}</Form.Control.Feedback>
                  </Col>
                  <Col md={3}>
                    <Form.Select size="sm" value={p.gender || 'Nam'} onChange={(e) => handlePassengerChange(idx, 'gender', e.target.value)}>
                      <option value="Nam">Nam</option>
                      <option value="Nữ">Nữ</option>
                      <option value="Khác">Khác</option>
                    </Form.Select>
                  </Col>
                  <Col md={3}>
                    <Form.Control
                      size="sm"
                      type="date"
                      value={p.dateOfBirth || ''}
                      onChange={(e) => handlePassengerChange(idx, 'dateOfBirth', e.target.value)}
                      isInvalid={!!errors[`pass_dob_${idx}`]}
                    />
                    <Form.Control.Feedback type="invalid">Chọn ngày sinh</Form.Control.Feedback>
                  </Col>
                </Row>
              </div>
            ))}
          </div>

          {/* 4. GHI CHÚ */}
          <h5 className="fw-bold mb-3 text-uppercase">Ghi chú</h5>
          <div className="bg-white border rounded p-3 mb-4">
            <Form.Control as="textarea" rows={3} placeholder="Nội dung lời nhắn..." value={contactInfo.note} onChange={e => handleContactChange('note', e.target.value)} />
          </div>
        </Col>

        {/* Cột Phải: Tóm tắt */}
        <Col lg={4}>
          <div className="summary-card bg-white overflow-hidden shadow rounded border">
            <div className="p-3 border-bottom">
              <h6 className="fw-bold mb-2">TÓM TẮT CHUYẾN ĐI</h6>
              <div className="d-flex gap-2">
                <img src={productData.image} className="rounded" style={{ width: 80, height: 60, objectFit: 'cover' }} alt="Tour" />
                <div>
                  <div className="fw-bold small text-truncate-2-lines">{productData.title}</div>
                  <div className="small text-muted">Mã: {productData.code}</div>
                </div>
              </div>
            </div>
            {renderTransportInfo()}
            <div className="p-3">
              <div className="d-flex justify-content-between align-items-center mb-2">
                <span className="fw-bold">TẠM TÍNH</span>
                <span className="fw-bold text-danger fs-5">{formatCurrency(subTotal)}</span>
              </div>

              {/* Chi tiết giá */}
              <div className="small mb-1 d-flex justify-content-between"><span>Người lớn</span><span>{counts.adult} x {formatCurrency(productData.basePrice)}</span></div>
              {counts.child > 0 && <div className="small mb-1 d-flex justify-content-between"><span>Trẻ em</span><span>{counts.child} x {formatCurrency(productData.basePrice * 0.8)}</span></div>}
              {counts.toddler > 0 && <div className="small mb-1 d-flex justify-content-between"><span>Trẻ nhỏ</span><span>{counts.toddler} x {formatCurrency(productData.basePrice * 0.5)}</span></div>}
              {counts.infant > 0 && <div className="small mb-1 d-flex justify-content-between"><span>Em bé</span><span>{counts.infant} x {formatCurrency(productData.basePrice * 0.1)}</span></div>}

              <hr className="my-2" />
              {/* KHU VỰC MÃ GIẢM GIÁ */}
              <div className="mt-3 bg-light p-3 rounded border border-dashed">
                <div className="d-flex justify-content-between align-items-center mb-2">
                  <div className="fw-bold small text-primary"><i className="bi bi-tag-fill"></i> MÃ GIẢM GIÁ</div>
                  <Button variant="link" className="p-0 text-decoration-none small" onClick={() => setShowPromoModal(true)}>Chọn mã <i className="bi bi-chevron-right"></i></Button>
                </div>
                <div className="input-group mb-2">
                  <Form.Control type="text" placeholder="Nhập mã" value={promoCode} onChange={(e) => setPromoCode(e.target.value.toUpperCase())} disabled={!!appliedPromo} size="sm" />
                  {appliedPromo ? <Button variant="outline-danger" size="sm" onClick={() => { setAppliedPromo(null); setPromoCode(""); }}>Xóa</Button> : <Button variant="primary" size="sm" onClick={() => handleApplyPromo()}>Áp dụng</Button>}
                </div>
                {promoError && <div className="text-danger small fst-italic">{promoError}</div>}
                {appliedPromo && <div className="d-flex justify-content-between text-success small fw-bold"><span><i className="bi bi-check-circle"></i> {appliedPromo.code}</span><span>-{formatCurrency(promoDiscount)}</span></div>}
              </div>

              <hr />
              <div className="d-flex justify-content-between align-items-center mb-3">
                <span className="fw-bold fs-5">TỔNG CỘNG</span>
                <span className="fw-bold text-danger fs-4">{formatCurrency(final)}</span>
              </div>
              <Button variant="danger" size="lg" className="w-100 fw-bold shadow hover-scale" onClick={handleSubmit}>TIẾP TỤC THANH TOÁN</Button>
            </div>
          </div>
        </Col>
      </Row>

      {/* MODAL MÃ GIẢM GIÁ */}
      <Modal show={showPromoModal} onHide={() => setShowPromoModal(false)} centered>
        <Modal.Header closeButton><Modal.Title className="fw-bold fs-5">Chọn mã giảm giá</Modal.Title></Modal.Header>
        <Modal.Body className="p-0 bg-light" style={{ maxHeight: '400px', overflowY: 'auto' }}>
          {availablePromos.length === 0 ? <div className="text-center p-4 text-muted">Chưa có mã giảm giá phù hợp.</div> : (
            <div className="list-group list-group-flush">
              {availablePromos.map(promo => {
                const canUse = promo.rules?.min_spend ? subTotal >= promo.rules.min_spend : true;
                return (
                  <div key={promo._id} className={`list-group-item list-group-item-action p-3 ${!canUse ? 'opacity-50' : ''}`} style={{ cursor: canUse ? 'pointer' : 'not-allowed' }} onClick={() => canUse && handleSelectPromo(promo)}>
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <span className="fw-bold text-primary border border-primary px-2 rounded bg-white">{promo.code}</span>
                      <Badge bg="danger">Giảm {promo.type === 'percentage' ? `${promo.value}%` : formatCurrency(promo.value)}</Badge>
                    </div>
                    <div className="small fw-bold">{promo.description || promo.name}</div>
                    <div className="text-muted small">Đơn tối thiểu: {formatCurrency(promo.rules?.min_spend || 0)}</div>
                    {!canUse && <div className="text-danger x-small fst-italic">* Đơn hàng chưa đủ điều kiện</div>}
                  </div>
                );
              })}
            </div>
          )}
        </Modal.Body>
        <Modal.Footer><Button variant="secondary" onClick={() => setShowPromoModal(false)}>Đóng</Button></Modal.Footer>
      </Modal>
    </Container>
  );
}