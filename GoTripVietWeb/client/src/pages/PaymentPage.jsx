// src/pages/PaymentPage.jsx
import React, { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import Spinner from "react-bootstrap/Spinner";
import Accordion from "react-bootstrap/Accordion";
import Badge from "react-bootstrap/Badge";
import Form from "react-bootstrap/Form";
import "../styles/booking-process.css";
import { formatCurrency } from "../utils/formatData";
import bookingApi from "../api/bookingApi";
import paymentApi from "../api/paymentApi"; // [QUAN TRỌNG] Import API mới

// Component Stepper (Bước 2 sáng lên)
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

export default function PaymentPage() {
    const location = useLocation();
    const navigate = useNavigate();

    // Lấy bookingId từ state truyền qua
    const initialBookingId = location.state?.bookingId;

    const [booking, setBooking] = useState(null);
    const [loading, setLoading] = useState(true);
    const [processing, setProcessing] = useState(false);

    // State lưu phương thức thanh toán (Mặc định chọn VNPAY)
    const [paymentMethod, setPaymentMethod] = useState("vnpay");

    // 1. Tải thông tin Booking từ Backend khi vào trang
    useEffect(() => {
        if (!initialBookingId) {
            alert("Không tìm thấy mã đơn hàng!");
            navigate("/"); // Quay về trang chủ nếu không có ID
            return;
        }

        const fetchBooking = async () => {
            try {
                // Gọi API lấy chi tiết đơn hàng
                const res = await bookingApi.getBookingDetails(initialBookingId);
                setBooking(res.data || res);
            } catch (error) {
                console.error("Lỗi tải đơn hàng:", error);
                alert("Lỗi tải thông tin đơn hàng: " + error.message);
            } finally {
                setLoading(false);
            }
        };

        fetchBooking();
    }, [initialBookingId, navigate]);

    // 2. Xử lý khi bấm nút Thanh Toán (LOGIC VNPAY MỚI)
    // Trong file PaymentPage.jsx (hoặc nơi bạn xử lý nút Thanh toán)

    const handlePayment = async () => {
        try {
            setLoading(true);

            // Kiểm tra xem user chọn cổng nào
            if (paymentMethod === 'vnpay') {
                // 1. Gọi API tạo link
                const response = await paymentApi.createVNPayUrl({
                    amount: booking.pricing?.final_price, // Hoặc số tiền cần thanh toán
                    bookingId: booking._id,
                    bankCode: '', // Để rỗng nếu muốn chọn bank tại VNPAY
                    language: 'vn'
                });

                // [QUAN TRỌNG] Backend trả về { paymentUrl: '...' }
                // Frontend cần tự chuyển hướng trình duyệt sang link đó
                if (response.paymentUrl) {
                    window.location.href = response.paymentUrl;
                } else if (response.data && response.data.paymentUrl) {
                    // Dự phòng trường hợp axios trả về cấu trúc khác
                    window.location.href = response.data.paymentUrl;
                } else {
                    alert("Lỗi: Không lấy được link thanh toán");
                }

            } else if (paymentMethod === 'stripe') {
                // [XÓA HOẶC COMMENT] Vì Backend đã bỏ Stripe
                alert("Phương thức này tạm thời bảo trì.");
            }
        } catch (error) {
            console.error("Lỗi thanh toán:", error);
            alert("Có lỗi xảy ra khi khởi tạo thanh toán.");
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <div className="text-center py-5" style={{ minHeight: '60vh' }}><Spinner animation="border" variant="primary" /><p className="mt-2">Đang tải thông tin đơn hàng...</p></div>;
    if (!booking) return <div className="text-center py-5">Đơn hàng không tồn tại.</div>;



    // Lấy thông tin snapshot (dữ liệu tour lưu cứng lúc đặt) để hiển thị
    const mainItem = booking.items?.[0] || {};
    // Ưu tiên lấy từ snapshot, nếu không có thì lấy trực tiếp từ item
    const tourTitle = mainItem.snapshot?.title || mainItem.productTitle || "Tên tour chưa cập nhật";
    const tourImage = mainItem.snapshot?.image || mainItem.image || "https://placehold.co/100x70";
    const tourDetails = mainItem.snapshot?.detailsText || mainItem.detailsText || "";

    return (
        <Container className="my-5">
            <BookingStepper step={2} />

            <Row className="g-4">
                {/* === CỘT TRÁI: THÔNG TIN CHI TIẾT === */}
                <Col lg={8}>
                    {/* 1. THÔNG TIN LIÊN LẠC */}
                    <Card className="shadow-sm border-0 mb-4 rounded-3">
                        <Card.Header className="bg-white py-3 fw-bold text-primary text-uppercase border-bottom">
                            Thông tin liên lạc
                        </Card.Header>
                        <Card.Body>
                            <Row className="g-3">
                                <Col md={4}>
                                    <small className="text-muted d-block">Họ tên</small>
                                    <strong>{booking.customer_details?.fullName}</strong>
                                </Col>
                                <Col md={4}>
                                    <small className="text-muted d-block">Email</small>
                                    <strong>{booking.customer_details?.email}</strong>
                                </Col>
                                <Col md={4}>
                                    <small className="text-muted d-block">Điện thoại</small>
                                    <strong>{booking.customer_details?.phone}</strong>
                                </Col>
                                <Col md={12}>
                                    <small className="text-muted d-block">Địa chỉ</small>
                                    <strong>{booking.customer_details?.address || "---"}</strong>
                                </Col>
                                <Col md={12}>
                                    <small className="text-muted d-block">Ghi chú</small>
                                    <div className="fst-italic text-secondary">{booking.customer_details?.note || "Không có"}</div>
                                </Col>
                            </Row>
                        </Card.Body>
                    </Card>

                    {/* 2. CHI TIẾT BOOKING */}
                    <Card className="shadow-sm border-0 mb-4 rounded-3">
                        <Card.Header className="bg-white py-3 fw-bold text-primary text-uppercase border-bottom">
                            Chi tiết thanh toán
                        </Card.Header>
                        <Card.Body>
                            <div className="d-flex justify-content-between mb-2 pb-2 border-bottom border-dashed">
                                <span className="fw-bold">Mã đặt chỗ:</span>
                                <span className="text-danger fw-bold fs-5">{booking._id.slice(-6).toUpperCase()}</span>
                            </div>
                            <div className="d-flex justify-content-between mb-2">
                                <span>Ngày tạo:</span>
                                <span>{new Date(booking.createdAt).toLocaleString('vi-VN')}</span>
                            </div>
                            <div className="d-flex justify-content-between mb-2">
                                <span>Trị giá booking:</span>
                                <span className="fw-bold">{formatCurrency(booking.pricing.total_price_before_discount)}</span>
                            </div>
                            {booking.pricing.discount_amount > 0 && (
                                <div className="d-flex justify-content-between mb-2 text-success">
                                    <span>Giảm giá:</span>
                                    <span>-{formatCurrency(booking.pricing.discount_amount)}</span>
                                </div>
                            )}
                            <div className="d-flex justify-content-between mb-2 pb-2 border-bottom border-dashed">
                                <span className="fw-bold">Số tiền phải thanh toán:</span>
                                <span className="fw-bold text-danger fs-4">{formatCurrency(booking.pricing.final_price)}</span>
                            </div>
                        </Card.Body>
                    </Card>

                    {/* 3. DANH SÁCH HÀNH KHÁCH */}
                    <Accordion className="shadow-sm rounded-3 overflow-hidden mb-4" defaultActiveKey="0">
                        <Accordion.Item eventKey="0" className="border-0">
                            <Accordion.Header><span className="fw-bold text-primary text-uppercase">Danh sách hành khách ({booking.passengers?.length || 0})</span></Accordion.Header>
                            <Accordion.Body className="bg-light p-0">
                                {booking.passengers && booking.passengers.length > 0 ? (
                                    <div className="table-responsive">
                                        <table className="table table-hover mb-0">
                                            <thead className="table-light">
                                                <tr className="text-muted small">
                                                    <th className="ps-4">Họ tên</th>
                                                    <th>Đối tượng</th>
                                                    <th>Giới tính</th>
                                                    <th>Ngày sinh</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {booking.passengers.map((p, i) => (
                                                    <tr key={i}>
                                                        <td className="fw-bold ps-4">{p.fullName}</td>
                                                        <td>
                                                            {p.type === 'adult' && <Badge bg="primary">Người lớn</Badge>}
                                                            {p.type === 'child' && <Badge bg="info">Trẻ em</Badge>}
                                                            {p.type === 'toddler' && <Badge bg="warning" text="dark">Trẻ nhỏ</Badge>}
                                                            {p.type === 'infant' && <Badge bg="secondary">Em bé</Badge>}
                                                        </td>
                                                        <td>{p.gender}</td>
                                                        <td>{p.dateOfBirth ? new Date(p.dateOfBirth).toLocaleDateString('vi-VN') : '--'}</td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                ) : (
                                    <p className="text-muted m-3">Không có thông tin chi tiết.</p>
                                )}
                            </Accordion.Body>
                        </Accordion.Item>
                    </Accordion>
                </Col>

                {/* === CỘT PHẢI: PHIẾU XÁC NHẬN & THANH TOÁN === */}
                <Col lg={4}>
                    <Card className="shadow border-0 rounded-3 overflow-hidden sticky-top" style={{ top: '20px' }}>
                        <Card.Header className="bg-white py-3 fw-bold text-primary text-uppercase border-bottom">
                            Thông tin dịch vụ
                        </Card.Header>
                        <Card.Body>
                            {/* Ảnh & Tên Tour */}
                            <div className="d-flex gap-3 mb-3">
                                <img
                                    src={tourImage}
                                    alt="Tour"
                                    className="rounded"
                                    style={{ width: '90px', height: '65px', objectFit: 'cover' }}
                                />
                                <div>
                                    <div className="fw-bold small text-truncate-3-lines mb-1">{tourTitle}</div>
                                </div>
                            </div>



                            <hr className="my-3" />

                            {/* [MỚI] CHỌN PHƯƠNG THỨC THANH TOÁN */}
                            <h6 className="fw-bold mb-3">Chọn phương thức thanh toán:</h6>
                            <Form>
                                {/* 1. VNPAY QR / Ví */}
                                <div className={`payment-option mb-2 border rounded p-2 d-flex align-items-center cursor-pointer ${paymentMethod === 'vnpay' ? 'border-primary bg-primary bg-opacity-10' : ''}`}
                                    onClick={() => setPaymentMethod('vnpay')}>
                                    <Form.Check
                                        type="radio"
                                        name="paymentMethod"
                                        id="vnpay"
                                        label="VNPAY-QR / Ví VNPAY"
                                        className="fw-bold small flex-grow-1"
                                        checked={paymentMethod === 'vnpay'}
                                        onChange={() => setPaymentMethod('vnpay')}
                                    />
                                    <img src="https://vnpay.vn/s1/statics.vnpay.vn/2023/6/0oxhzjmxbksr1686814746087.png" alt="VNPay" style={{ height: '24px' }} />
                                </div>

                            </Form>

                            <Button
                                variant="danger"
                                size="lg"
                                className="w-100 fw-bold text-uppercase py-3 shadow hover-scale"
                                onClick={handlePayment}
                                disabled={processing}
                            >
                                {processing ? (
                                    <>
                                        <Spinner as="span" animation="border" size="sm" role="status" aria-hidden="true" className="me-2" />
                                        Đang kết nối VNPAY...
                                    </>
                                ) : 'Thanh toán ngay'}
                            </Button>

                            <div className="text-center mt-3">
                                <small className="text-muted"><i className="bi bi-shield-lock-fill text-success"></i> Thông tin được bảo mật tuyệt đối</small>
                            </div>
                        </Card.Body>
                    </Card>
                </Col>
            </Row>
        </Container>
    );
}