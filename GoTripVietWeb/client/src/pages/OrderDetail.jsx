// src/pages/OrderDetail.jsx
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  Container,
  Row,
  Col,
  Card,
  Badge,
  Table,
  Button,
  Spinner,
  Alert,
} from "react-bootstrap";
import bookingApi from "../api/bookingApi";
import { formatCurrency } from "../utils/formatData";

// [MỚI] Import CSS
import "../styles/OrderDetail.css";

export default function OrderDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [booking, setBooking] = useState(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);
  const [error, setError] = useState(null);

  // --- LẤY DỮ LIỆU ---
  const fetchBooking = async () => {
    try {
      const res = await bookingApi.getBookingDetails(id);
      setBooking(res.data || res);
    } catch (err) {
      console.error("Lỗi lấy chi tiết đơn:", err);
      setError("Không tìm thấy đơn hàng hoặc bạn không có quyền truy cập.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBooking();
  }, [id]);

  // --- XỬ LÝ HỦY ĐƠN ---
  const handleCancel = async () => {
    const confirmText = "Bạn có chắc chắn muốn hủy đơn hàng này không?";
    if (!window.confirm(confirmText)) return;

    setCancelling(true);
    try {
      // Backend sẽ tự refund + gửi email (nếu đã paid)
      await bookingApi.cancelBooking(id); // POST /bookings/:id/cancel:contentReference[oaicite:1]{index=1}

      // Không alert gì trên web — chỉ reload lại data
      await fetchBooking();
    } catch (err) {
      // Không muốn thông báo UI thì chỉ log để dev debug
      console.error("Lỗi hủy đơn:", err.response?.data || err.message);
    } finally {
      setCancelling(false);
    }
  };

  // --- HELPER: RENDER PROGRESS STEPS ---
  const renderProgress = (status, paymentStatus) => {
    let step = 1;
    if (paymentStatus === "paid") step = 2;
    if (status === "completed") step = 3;
    if (status === "cancelled") step = -1; // Case đặc biệt

    if (step === -1) {
      return (
        <Alert variant="danger" className="text-center fw-bold shadow-sm">
          <i className="bi bi-x-circle-fill me-2"></i> ĐƠN HÀNG ĐÃ BỊ HỦY
        </Alert>
      );
    }

    return (
      <div className="step-indicator">
        <div className={`step-item ${step >= 1 ? "active" : ""}`}>
          <div className="step-circle">
            <i className="bi bi-check-lg"></i>
          </div>
          <span className="small">Đặt đơn</span>
        </div>
        <div className={`step-item ${step >= 2 ? "active" : ""}`}>
          <div className="step-circle">
            {step >= 2 ? <i className="bi bi-check-lg"></i> : "2"}
          </div>
          <span className="small">Thanh toán</span>
        </div>
        <div className={`step-item ${step >= 3 ? "active" : ""}`}>
          <div className="step-circle">
            {step >= 3 ? <i className="bi bi-check-lg"></i> : "3"}
          </div>
          <span className="small">Hoàn thành</span>
        </div>
      </div>
    );
  };

  // --- HELPER HIỂN THỊ BADGE ---
  const renderStatusBadge = (status) => {
    const map = {
      pending: { bg: "warning", text: "Chờ xử lý", icon: "bi-hourglass-split" },
      confirmed: {
        bg: "primary",
        text: "Đã xác nhận",
        icon: "bi-check2-circle",
      },
      completed: { bg: "success", text: "Hoàn thành", icon: "bi-flag-fill" },
      cancelled: { bg: "danger", text: "Đã hủy", icon: "bi-x-circle" },
      failed: { bg: "dark", text: "Lỗi", icon: "bi-exclamation-triangle" },
    };
    const s = map[status] || map.pending;
    return (
      <Badge bg={s.bg} className="py-2 px-3">
        <i className={`bi ${s.icon} me-1`}></i> {s.text}
      </Badge>
    );
  };

  if (loading)
    return (
      <Container className="d-flex justify-content-center align-items-center vh-50">
        <Spinner animation="border" variant="primary" />
      </Container>
    );
  if (error)
    return (
      <Container className="py-5 text-center">
        <div className="display-1 text-muted mb-3">
          <i className="bi bi-search"></i>
        </div>
        <h3>{error}</h3>
        <Button
          variant="outline-primary"
          className="mt-3"
          onClick={() => navigate("/profile")}
        >
          Quay lại danh sách
        </Button>
      </Container>
    );
  if (!booking) return null;

  const item = booking.items?.[0] || {};
  const snapshot = item.snapshot || {};
  const customer = booking.customer_details || {};

  return (
    <Container className="py-5">
      {/* TOP NAVIGATION */}
      <div className="d-flex justify-content-between align-items-center mb-4">
        <Button
          variant="link"
          className="text-decoration-none text-muted ps-0 fw-semibold"
          onClick={() => navigate("/profile")}
        >
          <i className="bi bi-arrow-left me-2"></i> Quay lại danh sách
        </Button>
        <div className="text-muted small">
          Mã đơn:{" "}
          <span className="text-dark fw-bold">
            {booking._id.slice(-6).toUpperCase()}
          </span>
        </div>
      </div>

      <Row className="g-4">
        {/* CỘT TRÁI: CHI TIẾT */}
        <Col lg={8}>
          {/* 1. CARD SẢN PHẨM (STYLE VÉ) */}
          <Card className="shadow-sm border-0 mb-4 rounded-4">
            <div className="ticket-header p-4">
              <div className="d-flex justify-content-between align-items-start">
                <div>
                  <Badge bg="light" text="primary" className="mb-2">
                    TOUR DU LỊCH
                  </Badge>
                  <h4 className="fw-bold mb-1">
                    {snapshot.title || item.productTitle}
                  </h4>
                  <div className="opacity-75 small">
                    <i className="bi bi-calendar-event me-1"></i> Ngày đặt:{" "}
                    {new Date(booking.createdAt).toLocaleString("vi-VN")}
                  </div>
                </div>
                <div className="text-end d-none d-md-block">
                  <div className="display-6 fw-bold">
                    {booking.passengers?.length || item.quantity}
                  </div>
                  <div className="small opacity-75">Hành khách</div>
                </div>
              </div>
            </div>
            <Card.Body className="p-4 pt-5">
              <div className="d-flex gap-4 flex-wrap">
                <img
                  src={snapshot.image || "https://placehold.co/150x100"}
                  alt="Tour"
                  className="rounded-3 shadow-sm object-fit-cover"
                  style={{ width: 140, height: 100 }}
                />
                <div className="flex-grow-1">
                  <h6 className="fw-bold text-secondary text-uppercase small mb-2">
                    Chi tiết dịch vụ
                  </h6>
                  <p className="text-muted mb-0" style={{ lineHeight: "1.6" }}>
                    {snapshot.details_text ||
                      item.detailsText ||
                      "Thông tin chi tiết đang được cập nhật..."}
                  </p>
                </div>
              </div>
            </Card.Body>
          </Card>

          {/* 2. DANH SÁCH HÀNH KHÁCH */}
          <Card className="shadow-sm border-0 mb-4 rounded-4">
            <Card.Header className="bg-white border-bottom-0 pt-4 px-4 pb-0">
              <h6 className="fw-bold text-primary text-uppercase mb-0">
                <i className="bi bi-people-fill me-2"></i> Danh sách hành khách
              </h6>
            </Card.Header>
            <Card.Body className="p-4">
              <div className="table-responsive rounded-3 border">
                <Table hover className="mb-0 align-middle">
                  <thead className="bg-light">
                    <tr>
                      <th className="ps-4 border-0">Họ tên</th>
                      <th className="border-0">Đối tượng</th>
                      <th className="border-0">Giới tính</th>
                      <th className="border-0">Ngày sinh</th>
                    </tr>
                  </thead>
                  <tbody>
                    {booking.passengers?.map((p, idx) => (
                      <tr key={idx}>
                        <td className="ps-4 fw-bold text-dark">{p.fullName}</td>
                        <td>
                          <Badge bg="light" text="dark" className="border">
                            {p.type === "adult"
                              ? "Người lớn"
                              : p.type === "child"
                                ? "Trẻ em"
                                : p.type === "toddler"
                                  ? "Trẻ nhỏ"
                                  : "Em bé"}
                          </Badge>
                        </td>
                        <td>{p.gender}</td>
                        <td className="text-muted">
                          {p.dateOfBirth
                            ? new Date(p.dateOfBirth).toLocaleDateString(
                                "vi-VN",
                              )
                            : "--"}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </div>
            </Card.Body>
          </Card>

          {/* 3. THÔNG TIN LIÊN HỆ */}
          <Card className="shadow-sm border-0 rounded-4">
            <Card.Header className="bg-white border-bottom-0 pt-4 px-4 pb-0">
              <h6 className="fw-bold text-primary text-uppercase mb-0">
                <i className="bi bi-person-lines-fill me-2"></i> Thông tin liên
                hệ
              </h6>
            </Card.Header>
            <Card.Body className="p-4">
              <Row className="g-4">
                <Col md={6}>
                  <div className="d-flex align-items-start">
                    <div className="info-icon">
                      <i className="bi bi-person"></i>
                    </div>
                    <div>
                      <small
                        className="text-muted d-block text-uppercase"
                        style={{ fontSize: "0.7rem", letterSpacing: "1px" }}
                      >
                        Người liên hệ
                      </small>
                      <span className="fw-bold text-dark">
                        {customer.fullName}
                      </span>
                    </div>
                  </div>
                </Col>
                <Col md={6}>
                  <div className="d-flex align-items-start">
                    <div className="info-icon">
                      <i className="bi bi-telephone"></i>
                    </div>
                    <div>
                      <small
                        className="text-muted d-block text-uppercase"
                        style={{ fontSize: "0.7rem", letterSpacing: "1px" }}
                      >
                        Điện thoại
                      </small>
                      <span className="fw-bold text-dark">
                        {customer.phone}
                      </span>
                    </div>
                  </div>
                </Col>
                <Col md={6}>
                  <div className="d-flex align-items-start">
                    <div className="info-icon">
                      <i className="bi bi-envelope"></i>
                    </div>
                    <div>
                      <small
                        className="text-muted d-block text-uppercase"
                        style={{ fontSize: "0.7rem", letterSpacing: "1px" }}
                      >
                        Email
                      </small>
                      <span className="fw-bold text-dark">
                        {customer.email}
                      </span>
                    </div>
                  </div>
                </Col>
                <Col md={12}>
                  <div className="d-flex align-items-start">
                    <div className="info-icon">
                      <i className="bi bi-geo-alt"></i>
                    </div>
                    <div>
                      <small
                        className="text-muted d-block text-uppercase"
                        style={{ fontSize: "0.7rem", letterSpacing: "1px" }}
                      >
                        Địa chỉ
                      </small>
                      <span className="fw-bold text-dark">
                        {customer.address || "Chưa cập nhật"}
                      </span>
                    </div>
                  </div>
                </Col>
                {customer.note && (
                  <Col md={12}>
                    <div className="bg-warning bg-opacity-10 p-3 rounded-3 d-flex gap-3">
                      <i className="bi bi-sticky text-warning fs-4"></i>
                      <div>
                        <strong className="d-block text-warning-emphasis">
                          Ghi chú:
                        </strong>
                        <span className="text-dark opacity-75">
                          {customer.note}
                        </span>
                      </div>
                    </div>
                  </Col>
                )}
              </Row>
            </Card.Body>
          </Card>
        </Col>

        {/* CỘT PHẢI: TRẠNG THÁI & THANH TOÁN */}
        <Col lg={4}>
          <Card
            className="shadow-lg border-0 mb-4 rounded-4 sticky-top"
            style={{ top: "20px", zIndex: 10 }}
          >
            <Card.Body className="p-4">
              <h6 className="fw-bold text-uppercase text-secondary mb-4">
                Trạng thái đơn hàng
              </h6>

              {/* THANH TIẾN TRÌNH */}
              {renderProgress(booking.status, booking.payment_status)}

              <div className="d-flex justify-content-between align-items-center mb-4 bg-light p-3 rounded-3">
                <span className="fw-semibold">Trạng thái hiện tại:</span>
                {renderStatusBadge(booking.status)}
              </div>

              <hr className="border-dashed my-4" />

              <h6 className="fw-bold text-uppercase text-secondary mb-3">
                Chi phí
              </h6>
              <div className="d-flex justify-content-between mb-2 text-muted">
                <span>Tạm tính</span>
                <span>
                  {formatCurrency(booking.pricing?.total_price_before_discount)}
                </span>
              </div>
              {booking.pricing?.discount_amount > 0 && (
                <div className="d-flex justify-content-between mb-2 text-success">
                  <span>
                    <i className="bi bi-tag-fill me-1"></i> Giảm giá
                  </span>
                  <span>
                    -{formatCurrency(booking.pricing.discount_amount)}
                  </span>
                </div>
              )}
              <div className="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                <span className="fw-bold text-dark">Tổng cộng</span>
                <span className="fw-bold fs-3 text-primary">
                  {formatCurrency(booking.pricing?.final_price)}
                </span>
              </div>

              {/* NÚT HÀNH ĐỘNG */}
              <div className="d-grid gap-2 mt-4">
                {booking.payment_status === "unpaid" &&
                  booking.status !== "cancelled" && (
                    <Button
                      variant="danger"
                      size="lg"
                      className="fw-bold shadow-sm"
                      onClick={() =>
                        navigate("/payment", {
                          state: { bookingId: booking._id },
                        })
                      }
                    >
                      THANH TOÁN NGAY
                    </Button>
                  )}

                {(booking.status === "pending" ||
                  booking.status === "confirmed") && (
                  <Button
                    variant="outline-secondary"
                    className="border-0 text-muted"
                    onClick={handleCancel}
                    disabled={cancelling}
                  >
                    {cancelling ? (
                      <Spinner size="sm" animation="border" />
                    ) : (
                      <>
                        <i className="bi bi-x-circle me-1"></i>{" "}
                        {booking.payment_status === "paid"
                          ? "Hủy & hoàn tiền"
                          : "Hủy đơn hàng"}
                      </>
                    )}
                  </Button>
                )}
              </div>
            </Card.Body>
          </Card>

          {/* LỊCH SỬ GIAO DỊCH */}
          {booking.payments?.length > 0 && (
            <Card className="shadow-sm border-0 rounded-4">
              <Card.Header className="bg-white fw-bold py-3 border-bottom-0">
                <i className="bi bi-clock-history me-2 text-primary"></i> Lịch
                sử giao dịch
              </Card.Header>
              <Card.Body className="p-0">
                {booking.payments.map((pay, i) => (
                  <div
                    key={i}
                    className="p-3 border-top d-flex justify-content-between align-items-center hover-bg-light transition-all"
                  >
                    <div>
                      <div className="fw-bold text-dark text-uppercase">
                        {pay.gateway}
                      </div>
                      <div className="small text-muted">
                        {new Date(pay.timestamp).toLocaleString()}
                      </div>
                    </div>
                    <div className="text-end">
                      <div className="fw-bold text-success">
                        +{formatCurrency(pay.amount)}
                      </div>
                      <Badge
                        bg={pay.status === "succeeded" ? "success" : "warning"}
                        pill
                      >
                        {pay.status}
                      </Badge>
                    </div>
                  </div>
                ))}
              </Card.Body>
            </Card>
          )}
        </Col>
      </Row>
    </Container>
  );
}
