import React, { useEffect, useState } from "react";
import { Container, Row, Col, Card, Form, Button, Badge, Spinner, Alert } from "react-bootstrap";
import authApi from "../../api/authApi";

// --- ICONS ---
const UserIcon = () => (
  <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
);
const BuildingIcon = () => (
  <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
);
const PhoneIcon = () => (
  <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" /></svg>
);
const MailIcon = () => (
  <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
);

export default function PartnerProfile() {
  const [me, setMe] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState({ type: '', text: '' });

  // Form State
  const [partnerInfo, setPartnerInfo] = useState({
    company_name: "",
    business_license: "",
    contact_phone: "",
    website: "",
    address: ""
  });

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      setLoading(true);
      const data = await authApi.getProfile();
      setMe(data);
      if (data.partner_details) {
        setPartnerInfo({
          company_name: data.partner_details.company_name || "",
          business_license: data.partner_details.business_license || "",
          contact_phone: data.partner_details.contact_phone || "",
          website: data.partner_details.website || "",
          address: data.partner_details.address || ""
        });
      }
    } catch (err) {
      console.error(err);
      setMsg({ type: 'danger', text: 'Không thể tải thông tin hồ sơ.' });
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      setMsg({ type: '', text: '' });
      await authApi.updateProfile({ partner_details: partnerInfo });
      setMsg({ type: 'success', text: 'Cập nhật thông tin doanh nghiệp thành công! 🎉' });
      // Reload to reflect changes
      const updated = await authApi.getProfile();
      setMe(updated);
    } catch (error) {
      console.error(error);
      setMsg({ type: 'danger', text: error.response?.data?.message || 'Có lỗi xảy ra, vui lòng thử lại.' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh', backgroundColor: '#f8fafc' }}>
        <Spinner animation="border" variant="primary" />
      </div>
    );
  }

  const isApproved = me?.partner_details?.is_approved;

  return (
    <div style={{ backgroundColor: '#f8fafc', minHeight: '100vh', paddingBottom: '60px', fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" }}>

      {/* --- HEADER --- */}
      <div style={{
        padding: '60px 0 100px',
        background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)',
        color: '#fff',
        marginBottom: '-80px',
        boxShadow: '0 4px 20px rgba(37, 99, 235, 0.2)'
      }}>
        <Container>
          <h1 style={{ fontSize: '32px', fontWeight: '700', marginBottom: '8px' }}>Hồ Sơ Doanh Nghiệp</h1>
          <p style={{ fontSize: '16px', opacity: 0.9, fontWeight: '500', color: '#dbeafe' }}>
            Quản lý thông tin hiển thị với khách hàng và trạng thái tài khoản.
          </p>
        </Container>
      </div>

      <Container>
        <Row className="g-4">
          {/* LEFT COLUMN: OVERVIEW */}
          <Col lg={4}>
            <Card className="border-0 shadow-sm rounded-4 h-100 overflow-hidden">
              <div style={{ height: '100px', background: 'linear-gradient(to right, #e2e8f0, #f1f5f9)' }}></div>
              <Card.Body className="text-center px-4 pb-5" style={{ marginTop: '-60px' }}>
                <div style={{
                  width: '120px', height: '120px', margin: '0 auto 20px',
                  borderRadius: '50%', background: '#fff', padding: '6px',
                  boxShadow: '0 4px 10px rgba(0,0,0,0.1)'
                }}>
                  <div style={{
                    width: '100%', height: '100%', borderRadius: '50%',
                    backgroundColor: '#eff6ff', color: '#3b82f6',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '48px', fontWeight: '800'
                  }}>
                    {partnerInfo.company_name?.charAt(0).toUpperCase() || me?.fullName?.charAt(0).toUpperCase() || "P"}
                  </div>
                </div>

                <h3 className="fw-bold text-dark mb-1">{partnerInfo.company_name || me?.fullName}</h3>
                <p className="text-muted small mb-3">{me?.email}</p>

                <div className="mb-4">
                  {isApproved ? (
                    <Badge bg="success" className="px-3 py-2 rounded-pill">
                      <i className="bi bi-patch-check-fill me-1"></i> Đã xác thực
                    </Badge>
                  ) : (
                    <Badge bg="warning" text="dark" className="px-3 py-2 rounded-pill">
                      <i className="bi bi-hourglass-split me-1"></i> Đang chờ duyệt
                    </Badge>
                  )}
                </div>

                <div className="text-start mt-4 pt-4 border-top">
                  <div className="d-flex align-items-center gap-3 mb-3 text-muted">
                    <UserIcon /> <span className="text-dark fw-500">{me?.fullName}</span>
                  </div>
                  <div className="d-flex align-items-center gap-3 mb-3 text-muted">
                    <PhoneIcon /> <span className="text-dark fw-500">{me?.phone || "Chưa cập nhật"}</span>
                  </div>
                  <div className="d-flex align-items-center gap-3 mb-3 text-muted">
                    <MailIcon /> <span className="text-dark fw-500">{me?.email}</span>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>

          {/* RIGHT COLUMN: EDIT FORM */}
          <Col lg={8}>
            <Card className="border-0 shadow-sm rounded-4">
              <Card.Header className="bg-white py-3 border-bottom fs-5 fw-bold text-primary">
                <i className="bi bi-pencil-square me-2"></i> Cập nhật thông tin
              </Card.Header>
              <Card.Body className="p-4">
                {msg.text && (
                  <Alert variant={msg.type} onClose={() => setMsg({ type: '', text: '' })} dismissible>
                    {msg.text}
                  </Alert>
                )}

                <Form onSubmit={handleUpdate}>
                  <h6 className="fw-bold mb-3 text-uppercase text-secondary small">🏢 Thông tin doanh nghiệp</h6>
                  <Row className="g-3 mb-4">
                    <Col md={12}>
                      <Form.Group>
                        <Form.Label className="fw-bold small text-muted">Tên Công Ty / Thương Hiệu <span className="text-danger">*</span></Form.Label>
                        <Form.Control
                          size="lg"
                          placeholder="Nhập tên doanh nghiệp hiển thị..."
                          value={partnerInfo.company_name}
                          onChange={(e) => setPartnerInfo({ ...partnerInfo, company_name: e.target.value })}
                          required
                          style={{ fontSize: '15px' }}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group>
                        <Form.Label className="fw-bold small text-muted">Mã Số Thuế / GPKD <span className="text-danger">*</span></Form.Label>
                        <Form.Control
                          placeholder="Số giấy phép kinh doanh..."
                          value={partnerInfo.business_license}
                          onChange={(e) => setPartnerInfo({ ...partnerInfo, business_license: e.target.value })}
                          required
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group>
                        <Form.Label className="fw-bold small text-muted">Website (Nếu có)</Form.Label>
                        <Form.Control
                          placeholder="https://..."
                          value={partnerInfo.website}
                          onChange={(e) => setPartnerInfo({ ...partnerInfo, website: e.target.value })}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={12}>
                      <Form.Group>
                        <Form.Label className="fw-bold small text-muted">Địa chỉ trụ sở</Form.Label>
                        <Form.Control
                          placeholder="Địa chỉ văn phòng giao dịch..."
                          value={partnerInfo.address}
                          onChange={(e) => setPartnerInfo({ ...partnerInfo, address: e.target.value })}
                        />
                      </Form.Group>
                    </Col>
                  </Row>

                  <h6 className="fw-bold mb-3 text-uppercase text-secondary small pt-3 border-top">📞 Liên hệ khách hàng</h6>
                  <Row className="g-3 mb-4">
                    <Col md={6}>
                      <Form.Group>
                        <Form.Label className="fw-bold small text-muted">Hotline Đặt Tour</Form.Label>
                        <Form.Control
                          placeholder="Số điện thoại CSKH..."
                          value={partnerInfo.contact_phone}
                          onChange={(e) => setPartnerInfo({ ...partnerInfo, contact_phone: e.target.value })}
                        />
                        <Form.Text className="text-muted small">
                          Số mày sẽ hiển thị công khai trên các tour để khách liên hệ.
                        </Form.Text>
                      </Form.Group>
                    </Col>
                  </Row>

                  <div className="d-flex justify-content-end gap-3 pt-3 border-top">
                    <Button variant="light" onClick={() => loadProfile()} className="fw-bold text-muted border">Hủy thay đổi</Button>
                    <Button
                      type="submit"
                      variant="primary"
                      disabled={saving}
                      className="px-4 py-2 fw-bold shadow-sm"
                      style={{ minWidth: '140px' }}
                    >
                      {saving ? <><Spinner as="span" animation="border" size="sm" className="me-2" /> Đang lưu...</> : "Lưu thay đổi"}
                    </Button>
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