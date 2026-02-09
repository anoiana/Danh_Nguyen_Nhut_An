import React, { useEffect, useState } from "react";
import {
  Container, Row, Col, Card, Form, Button, Alert, Spinner, Tabs, Tab, Badge, Fade
} from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import authApi from "../api/authApi";
import bookingApi from "../api/bookingApi";
import { formatCurrency } from "../utils/formatData";

// [MỚI] Import file CSS đã tách
import "../styles/Profile.css"; 

export default function Profile() {
  const navigate = useNavigate();

  // --- STATES ---
  const [user, setUser] = useState(null);
  const [bookings, setBookings] = useState([]);
  const [formData, setFormData] = useState({ fullName: "", phone: "", email: "" });
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [message, setMessage] = useState({ type: "", content: "" });

  // --- 1. LẤY DỮ LIỆU ---
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [userData, bookingsData] = await Promise.all([
          authApi.getProfile(),
          bookingApi.getMyBookings()
        ]);

        setUser(userData);
        setFormData({
          fullName: userData.fullName || "",
          phone: userData.phone || "",
          email: userData.email || ""
        });
        setBookings(Array.isArray(bookingsData) ? bookingsData : []);
      } catch (error) {
        console.error("Lỗi tải profile:", error);
        setMessage({ type: "danger", content: "Không thể tải thông tin. Vui lòng thử lại sau." });
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  // --- 2. XỬ LÝ CẬP NHẬT PROFILE ---
  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setUpdating(true);
    setMessage({ type: "", content: "" });
    try {
      const updatedUser = await authApi.updateProfile({
        fullName: formData.fullName,
        phone: formData.phone
      });
      setUser(updatedUser);
      localStorage.setItem("user", JSON.stringify(updatedUser));
      setMessage({ type: "success", content: "Cập nhật hồ sơ thành công!" });
    } catch (error) {
      setMessage({ type: "danger", content: error.response?.data?.message || "Lỗi cập nhật." });
    } finally {
      setUpdating(false);
    }
  };

  // --- HELPER: RENDER TRẠNG THÁI ---
  const renderBookingStatus = (status, paymentStatus) => {
    const statusMap = {
      pending: { label: "Chờ xử lý", bg: "warning", icon: "bi-hourglass-split" },
      confirmed: { label: "Đã xác nhận", bg: "primary", icon: "bi-check-circle-fill" },
      completed: { label: "Hoàn thành", bg: "success", icon: "bi-flag-fill" },
      cancelled: { label: "Đã hủy", bg: "danger", icon: "bi-x-circle-fill" },
      failed: { label: "Thất bại", bg: "dark", icon: "bi-exclamation-triangle-fill" },
    };

    const s = statusMap[status] || { label: status, bg: "secondary", icon: "bi-question-circle" };

    let payBadge = <span className="badge bg-secondary-subtle text-secondary border border-secondary-subtle rounded-pill ms-2"><i className="bi bi-dash-circle"></i> Chưa thanh toán</span>;
    
    if (paymentStatus === "paid") {
      payBadge = <span className="badge bg-success-subtle text-success border border-success-subtle rounded-pill ms-2"><i className="bi bi-cash-coin"></i> Đã thanh toán</span>;
    } else if (paymentStatus === "refunded") {
      payBadge = <span className="badge bg-info-subtle text-info border border-info-subtle rounded-pill ms-2"><i className="bi bi-arrow-return-left"></i> Đã hoàn tiền</span>;
    }

    return (
      <div className="d-flex align-items-center flex-wrap gap-2 mt-2">
        <span className={`badge bg-${s.bg}-subtle text-${s.bg} border border-${s.bg}-subtle rounded-pill px-3`}>
          <i className={`bi ${s.icon} me-1`}></i> {s.label}
        </span>
        {payBadge}
      </div>
    );
  };

  if (loading) {
    return (
      <Container className="d-flex flex-column align-items-center justify-content-center vh-50 py-5">
        <Spinner animation="grow" variant="primary" style={{ width: '3rem', height: '3rem' }} />
        <p className="mt-3 text-muted fw-semibold">Đang tải dữ liệu của bạn...</p>
      </Container>
    );
  }

  return (
    <Container className="my-5">
      <div className="mb-4">
        <h2 className="fw-bold text-dark">Hồ sơ cá nhân</h2>
        <p className="text-muted">Quản lý thông tin và xem lại lịch sử chuyến đi của bạn</p>
      </div>

      {message.content && (
        <Alert variant={message.type} onClose={() => setMessage({ type: "", content: "" })} dismissible className="shadow-sm border-0 rounded-3">
          <i className={`bi ${message.type === 'success' ? 'bi-check-circle' : 'bi-exclamation-circle'} me-2`}></i>
          {message.content}
        </Alert>
      )}

      <Row className="g-4">
        {/* --- CỘT TRÁI: PROFILE CARD --- */}
        <Col lg={4} xl={3}>
          <Card className="border-0 shadow-sm rounded-4 overflow-hidden h-100">
            <div className="profile-bg-header"></div>
            <Card.Body className="text-center pt-0 px-4 pb-4">
              <div className="avatar-wrapper d-inline-block">
                <div 
                  className="bg-white p-1 rounded-circle shadow-lg d-flex align-items-center justify-content-center"
                >
                  <div 
                    className="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center fw-bold display-4"
                    style={{ width: 110, height: 110 }}
                  >
                    {formData.fullName ? formData.fullName.charAt(0).toUpperCase() : "U"}
                  </div>
                </div>
              </div>
              
              <h5 className="fw-bold mt-3 mb-1">{formData.fullName || "Khách hàng"}</h5>
              <p className="text-muted small mb-3"><i className="bi bi-envelope-fill me-1 text-primary"></i> {formData.email}</p>
              
              {/* <div className="d-flex justify-content-center gap-2 mb-4">
                 <Badge bg="light" text="dark" className="border">Thành viên</Badge>
                 <Badge bg="warning" text="dark" className="border border-warning"><i className="bi bi-star-fill"></i> Tiềm năng</Badge>
              </div> */}

              <div className="d-grid gap-2">
                <Button variant="outline-primary" className="rounded-pill fw-semibold" size="sm">
                  <i className="bi bi-key me-1"></i> Đổi mật khẩu
                </Button>
                <Button variant="outline-danger" className="rounded-pill fw-semibold" size="sm" onClick={() => {
                  if(window.confirm("Bạn có chắc chắn muốn đăng xuất?")) {
                    localStorage.removeItem('token');
                    localStorage.removeItem('user');
                    window.location.href = '/login';
                  }
                }}>
                  <i className="bi bi-box-arrow-right me-1"></i> Đăng xuất
                </Button>
              </div>
            </Card.Body>
          </Card>
        </Col>

        {/* --- CỘT PHẢI: TABS --- */}
        <Col lg={8} xl={9}>
          <Card className="border-0 shadow-sm rounded-4 h-100">
            <Card.Body className="p-4">
              <Tabs defaultActiveKey="orders" id="profile-tabs" className="mb-4 custom-pills border-bottom-0" variant="pills">
                
                {/* TAB 1: LỊCH SỬ ĐƠN HÀNG */}
                <Tab eventKey="orders" title={<span><i className="bi bi-ticket-perforated me-1"></i> Lịch sử đặt tour</span>}>
                  <Fade in>
                    <div>
                      {bookings.length === 0 ? (
                        <div className="text-center py-5 bg-light rounded-4 border border-dashed mt-2">
                          <div className="mb-3 text-secondary opacity-50">
                             <i className="bi bi-airplane display-1"></i>
                          </div>
                          <h5 className="fw-bold text-secondary">Bạn chưa có chuyến đi nào</h5>
                          <p className="text-muted mb-4">Hãy khám phá các tour du lịch hấp dẫn và đặt ngay hôm nay!</p>
                          <Button variant="primary" className="rounded-pill px-4 shadow-sm" onClick={() => navigate("/")}>
                            <i className="bi bi-search me-2"></i> Tìm tour ngay
                          </Button>
                        </div>
                      ) : (
                        // Vùng cuộn danh sách đơn hàng
                        <div className="custom-scrollbar pe-2" style={{ maxHeight: '650px', overflowY: 'auto' }}>
                          <div className="d-flex flex-column gap-3 pt-2">
                            {bookings.map((booking) => {
                              const firstItem = booking.items?.[0] || {};
                              const snapshot = firstItem.snapshot || {};
                              
                              return (
                                <Card key={booking._id} className="order-card border-0 shadow-sm rounded-4 overflow-hidden">
                                  <Card.Body className="p-3">
                                    <Row className="align-items-center g-3">
                                      {/* Ảnh Tour */}
                                      <Col xs={12} sm={3} lg={2}>
                                        <div className="position-relative">
                                          <img 
                                            src={snapshot.image || "https://placehold.co/150x100"} 
                                            alt="Tour" 
                                            className="img-fluid rounded-3 object-fit-cover w-100"
                                            style={{ height: '90px' }}
                                          />
                                          <div className="position-absolute top-0 start-0 m-1">
                                              <Badge bg="dark" className="bg-opacity-75" style={{fontSize: '0.65rem'}}>
                                                  ID: {booking._id.slice(-6).toUpperCase()}
                                              </Badge>
                                          </div>
                                        </div>
                                      </Col>
                                      
                                      {/* Thông tin */}
                                      <Col xs={12} sm={9} lg={6}>
                                        <div className="d-flex flex-column h-100 justify-content-center">
                                          <div className="text-muted small mb-1">
                                              <i className="bi bi-calendar-event me-1"></i> 
                                              Ngày đặt: {new Date(booking.createdAt).toLocaleDateString('vi-VN')}
                                          </div>
                                          <h6 className="fw-bold text-dark mb-1 text-truncate-2-lines" style={{lineHeight: '1.4'}}>
                                            {snapshot.title || firstItem.productTitle || "Tên dịch vụ đang cập nhật"}
                                          </h6>
                                          {/* Phần trạng thái */}
                                          {renderBookingStatus(booking.status, booking.payment_status)}
                                        </div>
                                      </Col>

                                      {/* Giá & Button */}
                                      <Col xs={12} lg={4}>
                                        <div className="d-flex flex-lg-column justify-content-between align-items-lg-end h-100 gap-2 border-start-lg ps-lg-4">
                                          <div className="text-lg-end">
                                              <div className="small text-muted">Tổng thanh toán</div>
                                              <div className="fs-5 fw-bold text-primary">
                                                  {formatCurrency(booking.pricing?.final_price || 0)}
                                              </div>
                                          </div>
                                          
                                          <Button 
                                            variant="outline-primary" 
                                            size="sm" 
                                            className="rounded-pill px-3 fw-semibold mt-lg-2"
                                            onClick={() => navigate(`/order-detail/${booking._id}`)}
                                          >
                                            Xem chi tiết <i className="bi bi-arrow-right ms-1"></i>
                                          </Button>
                                        </div>
                                      </Col>
                                    </Row>
                                  </Card.Body>
                                </Card>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  </Fade>
                </Tab>

                {/* TAB 2: CẬP NHẬT THÔNG TIN */}
                <Tab eventKey="info" title={<span><i className="bi bi-person-gear me-1"></i> Cập nhật thông tin</span>}>
                  <Fade in>
                    <div className="py-2">
                      <Form onSubmit={handleSubmit} className="px-lg-3">
                        <Row className="g-4">
                          <Col md={6}>
                            <Form.Group>
                              <Form.Label className="fw-semibold text-secondary small">ĐỊA CHỈ EMAIL</Form.Label>
                              <div className="input-group">
                                  <span className="input-group-text bg-light border-end-0"><i className="bi bi-envelope"></i></span>
                                  <Form.Control type="email" value={formData.email} disabled className="bg-light border-start-0" />
                              </div>
                              <Form.Text className="text-muted small ms-1">Email không thể thay đổi.</Form.Text>
                            </Form.Group>
                          </Col>
                          <Col md={6}>
                            <Form.Group>
                              <Form.Label className="fw-semibold text-secondary small">SỐ ĐIỆN THOẠI</Form.Label>
                              <div className="input-group">
                                  <span className="input-group-text bg-white"><i className="bi bi-telephone"></i></span>
                                  <Form.Control 
                                    type="tel" name="phone" value={formData.phone} 
                                    onChange={handleChange} placeholder="Nhập số điện thoại"
                                    className="border-start-0"
                                  />
                              </div>
                            </Form.Group>
                          </Col>
                          <Col md={12}>
                            <Form.Group>
                              <Form.Label className="fw-semibold text-secondary small">HỌ VÀ TÊN</Form.Label>
                              <div className="input-group">
                                  <span className="input-group-text bg-white"><i className="bi bi-person"></i></span>
                                  <Form.Control 
                                    type="text" name="fullName" value={formData.fullName} 
                                    onChange={handleChange} required placeholder="Nhập họ tên của bạn"
                                    className="border-start-0"
                                  />
                              </div>
                            </Form.Group>
                          </Col>
                        </Row>

                        <div className="d-flex justify-content-end mt-5 border-top pt-4">
                          <Button variant="light" className="me-3 rounded-pill" onClick={() => navigate('/')}>Hủy bỏ</Button>
                          <Button variant="primary" type="submit" disabled={updating} className="px-5 rounded-pill shadow fw-bold">
                            {updating ? (
                              <>
                                <Spinner as="span" animation="border" size="sm" className="me-2" /> 
                                Đang lưu...
                              </>
                            ) : (
                              <span><i className="bi bi-save me-1"></i> Lưu thay đổi</span>
                            )}
                          </Button>
                        </div>
                      </Form>
                    </div>
                  </Fade>
                </Tab>

              </Tabs>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}