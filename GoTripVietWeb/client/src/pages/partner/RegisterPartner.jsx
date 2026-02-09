import React, { useState } from "react";
import { Container, Row, Col, Form, Button, Card, Alert } from "react-bootstrap";
import { useNavigate, Link } from "react-router-dom";
import authApi from "../../api/authApi"; // Đảm bảo bạn đã có file này

export default function RegisterPartner() {
  const navigate = useNavigate();
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // State lưu dữ liệu Form
  const [formData, setFormData] = useState({
    fullName: "",        // Tên người đại diện
    email: "",
    password: "",
    confirmPassword: "",
    phone: "",           // SĐT cá nhân người đại diện
    
    // Thông tin doanh nghiệp
    companyName: "",     // Tên công ty/thương hiệu
    contactPhone: "",    // Hotline kinh doanh
    businessLicense: ""  // Mã số thuế (Optional lúc đăng ký)
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    // 1. Validate mật khẩu
    if (formData.password !== formData.confirmPassword) {
      return setError("Mật khẩu xác nhận không khớp!");
    }

    try {
      setLoading(true);

      // 2. Chuẩn bị Payload đúng chuẩn Backend (User Model)
      const payload = {
        fullName: formData.fullName,
        email: formData.email,
        password: formData.password,
        phone: formData.phone,
        role: "partner", // 🔥 QUAN TRỌNG: Đánh dấu là Partner

        // Khớp với user.model.js phần partner_details
        partner_details: {
          company_name: formData.companyName,
          contact_phone: formData.contactPhone,
          business_license: formData.businessLicense,
          is_approved: false // Mặc định chưa duyệt
        }
      };

      // 3. Gọi API đăng ký
      await authApi.register(payload);

      // 4. Thành công -> Chuyển hướng
      alert("Đăng ký hồ sơ Partner thành công! Vui lòng chờ Admin duyệt để bắt đầu đăng tour.");
      navigate("/login");

    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Đăng ký thất bại. Vui lòng kiểm tra lại thông tin.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="py-5" style={{ background: "linear-gradient(to bottom right, #eef2f3, #8e9eab)", minHeight: "100vh" }}>
      <Container>
        <Row className="justify-content-center">
          <Col md={8} lg={6}>
            <div className="text-center mb-4">
              <h2 className="fw-bold text-primary">Đăng ký Đối Tác</h2>
              <p className="text-muted">Hợp tác cùng GoTripViet để tiếp cận hàng triệu khách hàng</p>
            </div>

            <Card className="shadow-lg border-0 rounded-4 overflow-hidden">
              <div className="bg-primary p-2"></div> {/* Thanh màu trang trí */}
              <Card.Body className="p-4 p-md-5">
                {error && <Alert variant="danger" className="text-center">{error}</Alert>}

                <Form onSubmit={handleSubmit}>
                  
                  {/* --- PHẦN 1: THÔNG TIN DOANH NGHIỆP --- */}
                  <h6 className="fw-bold text-uppercase text-secondary mb-3 small">1. Thông tin Doanh nghiệp</h6>
                  
                  <Form.Group className="mb-3">
                    <Form.Label>Tên Công ty / Thương hiệu Tour <span className="text-danger">*</span></Form.Label>
                    <Form.Control 
                      type="text" 
                      name="companyName" 
                      required 
                      placeholder="VD: VietTravel, Saigon Tourist..."
                      value={formData.companyName}
                      onChange={handleChange}
                      className="bg-light"
                    />
                  </Form.Group>

                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Hotline Kinh doanh <span className="text-danger">*</span></Form.Label>
                        <Form.Control 
                          type="text" 
                          name="contactPhone" 
                          required 
                          placeholder="0909..."
                          value={formData.contactPhone}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Mã số thuế / GPKD</Form.Label>
                        <Form.Control 
                          type="text" 
                          name="businessLicense" 
                          placeholder="Optional"
                          value={formData.businessLicense}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                  </Row>

                  <hr className="my-4 opacity-25"/>

                  {/* --- PHẦN 2: THÔNG TIN TÀI KHOẢN --- */}
                  <h6 className="fw-bold text-uppercase text-secondary mb-3 small">2. Thông tin Tài khoản Quản trị</h6>

                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Họ tên người đại diện <span className="text-danger">*</span></Form.Label>
                        <Form.Control 
                          type="text" 
                          name="fullName" 
                          required 
                          placeholder="Nguyễn Văn A"
                          value={formData.fullName}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>SĐT Cá nhân</Form.Label>
                        <Form.Control 
                          type="text" 
                          name="phone" 
                          placeholder="098..."
                          value={formData.phone}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                  </Row>

                  <Form.Group className="mb-3">
                    <Form.Label>Email đăng nhập <span className="text-danger">*</span></Form.Label>
                    <Form.Control 
                      type="email" 
                      name="email" 
                      required 
                      placeholder="partner@company.com"
                      value={formData.email}
                      onChange={handleChange}
                    />
                  </Form.Group>

                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Mật khẩu <span className="text-danger">*</span></Form.Label>
                        <Form.Control 
                          type="password" 
                          name="password" 
                          required 
                          placeholder="******"
                          value={formData.password}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-4">
                        <Form.Label>Xác nhận mật khẩu <span className="text-danger">*</span></Form.Label>
                        <Form.Control 
                          type="password" 
                          name="confirmPassword" 
                          required 
                          placeholder="******"
                          value={formData.confirmPassword}
                          onChange={handleChange}
                        />
                      </Form.Group>
                    </Col>
                  </Row>

                  <div className="d-grid">
                    <Button variant="primary" size="lg" type="submit" disabled={loading} className="fw-bold rounded-pill">
                      {loading ? "Đang xử lý..." : "Đăng Ký Đối Tác Ngay"}
                    </Button>
                  </div>

                  <div className="text-center mt-4">
                    <small className="text-muted">
                      Đã có tài khoản? <Link to="/login" className="fw-bold text-decoration-none">Đăng nhập</Link>
                    </small>
                  </div>
                </Form>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>
    </div>
  );
}