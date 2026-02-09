import React, { useEffect, useState } from "react";
import { Container, Row, Col, Card, Badge, Button, Spinner, Table } from "react-bootstrap";
import { useParams, useNavigate } from "react-router-dom";
import bookingApi from "../../api/bookingApi";

// Hàm format tiền tệ
const formatCurrency = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

export default function PartnerOrderDetail() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [booking, setBooking] = useState(null);
    const [loading, setLoading] = useState(true);

    // Load dữ liệu
    useEffect(() => {
        const fetchDetail = async () => {
            try {
                setLoading(true);
                const res = await bookingApi.getPartnerBookingDetail(id);
                setBooking(res);
            } catch (error) {
                alert("Lỗi tải chi tiết đơn hàng: " + error.message);
                navigate("/partner/orders");
            } finally {
                setLoading(false);
            }
        };
        fetchDetail();
    }, [id, navigate]);

    // [LOGIC MỚI] Xử lý cập nhật trạng thái (Confirm / Cancel)
    const handleUpdateStatus = async (newStatus) => {
        // Xác định tên hành động để hiển thị thông báo
        const actionName = newStatus === 'confirmed' ? 'XÁC NHẬN' : 'HỦY';

        if (!window.confirm(`Bạn có chắc chắn muốn ${actionName} đơn hàng này không?`)) return;

        try {
            setLoading(true); // Hiện loading khi đang xử lý
            await bookingApi.updateStatus(id, newStatus);
            alert(`Đã ${actionName.toLowerCase()} đơn hàng thành công!`);

            // Reload lại dữ liệu mới nhất từ server
            const res = await bookingApi.getPartnerBookingDetail(id);
            setBooking(res);
        } catch (error) {
            console.error(error);
            alert("Lỗi cập nhật: " + (error.response?.data?.message || error.message));
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <Container className="py-5 text-center"><Spinner animation="border" /></Container>;
    if (!booking) return null;

    // Helpers hiển thị Badge trạng thái
    const getStatusBadge = (status) => {
        const s = status?.toLowerCase();
        if (s === 'pending') return <Badge bg="warning" text="dark">Chờ xác nhận</Badge>;
        if (s === 'confirmed') return <Badge bg="primary">Đã xác nhận</Badge>;
        if (s === 'completed') return <Badge bg="success">Hoàn thành</Badge>;
        if (s === 'cancelled') return <Badge bg="danger">Đã hủy</Badge>;
        return <Badge bg="secondary">{status}</Badge>;
    };

    const customer = booking.customer_details || {};
    const items = booking.items || [];
    const payments = booking.payments || [];

    return (
        <Container className="py-4">
            {/* HEADER */}
            <div className="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h4 className="fw-bold mb-1">Chi tiết đơn hàng #{booking._id.slice(-6).toUpperCase()}</h4>
                    <div className="text-muted small">
                        Ngày đặt: {new Date(booking.createdAt).toLocaleString('vi-VN')}
                    </div>
                </div>
                <div className="d-flex gap-2">
                    <Button variant="outline-secondary" onClick={() => navigate("/partner/orders")}>
                        ← Quay lại
                    </Button>

                    {/* Nút thao tác nhanh trên Header (Chỉ hiện khi Pending) */}
                    {booking.status === 'pending' && (
                        <Button variant="primary" onClick={() => handleUpdateStatus('confirmed')}>
                            Xác nhận đơn
                        </Button>
                    )}
                </div>
            </div>

            <Row className="g-4">
                {/* CỘT TRÁI: THÔNG TIN SẢN PHẨM & THANH TOÁN */}
                <Col lg={8}>
                    {/* 1. Sản phẩm đã đặt */}
                    <Card className="border-0 shadow-sm rounded-4 mb-4">
                        <Card.Header className="bg-white fw-bold py-3">📦 Thông tin sản phẩm</Card.Header>
                        <Card.Body className="p-0">
                            <Table responsive className="mb-0 align-middle">
                                <thead className="bg-light">
                                    <tr>
                                        <th className="ps-3">Sản phẩm</th>
                                        <th>Đơn giá</th>
                                        <th>SL</th>
                                        <th className="text-end pe-3">Thành tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {items.map((item, idx) => (
                                        <tr key={idx}>
                                            <td className="ps-3">
                                                <div className="d-flex align-items-center">
                                                    {item.snapshot?.image && (
                                                        <img
                                                            src={item.snapshot.image}
                                                            alt="thumb"
                                                            style={{ width: 50, height: 50, objectFit: 'cover', borderRadius: 6, marginRight: 12 }}
                                                        />
                                                    )}
                                                    <div>
                                                        <div className="fw-bold text-dark">{item.snapshot?.title || "Sản phẩm"}</div>
                                                        <small className="text-muted">{item.product_type}</small>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>{formatCurrency(item.unit_price)}</td>
                                            <td>x{item.quantity}</td>
                                            <td className="text-end fw-bold pe-3">
                                                {formatCurrency(item.unit_price * item.quantity)}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </Table>
                        </Card.Body>
                        <Card.Footer className="bg-white text-end py-3">
                            <div className="mb-1">Tổng tiền hàng: <strong>{formatCurrency(booking.pricing?.total_price_before_discount || 0)}</strong></div>
                            {booking.pricing?.discount_amount > 0 && (
                                <div className="text-success mb-1">Giảm giá: -{formatCurrency(booking.pricing.discount_amount)}</div>
                            )}
                            <div className="fs-5 fw-bold text-primary">
                                Tổng cộng: {formatCurrency(booking.pricing?.final_price || 0)}
                            </div>
                        </Card.Footer>
                    </Card>

                    {/* 2. Lịch sử thanh toán */}
                    <Card className="border-0 shadow-sm rounded-4">
                        <Card.Header className="bg-white fw-bold py-3">💳 Lịch sử thanh toán</Card.Header>
                        <Card.Body>
                            {payments.length === 0 ? (
                                <p className="text-muted text-center my-3">Chưa có giao dịch thanh toán nào.</p>
                            ) : (
                                payments.map((pay, idx) => (
                                    <div key={idx} className="d-flex justify-content-between align-items-center border-bottom py-2">
                                        <div>
                                            <div className="fw-bold">{pay.gateway?.toUpperCase()}</div>
                                            <small className="text-muted">Mã GD: {pay.gateway_transaction_id}</small>
                                        </div>
                                        <div className="text-end">
                                            <div className="fw-bold text-success">+{formatCurrency(pay.amount)}</div>
                                            <small>{new Date(pay.timestamp).toLocaleString('vi-VN')}</small>
                                        </div>
                                    </div>
                                ))
                            )}
                            <div className="mt-3 pt-2 border-top d-flex justify-content-between">
                                <span>Trạng thái thanh toán:</span>
                                <span className={`fw-bold ${booking.payment_status === 'paid' ? 'text-success' : 'text-danger'}`}>
                                    {booking.payment_status === 'paid' ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN'}
                                </span>
                            </div>
                        </Card.Body>
                    </Card>
                </Col>

                {/* CỘT PHẢI: THÔNG TIN KHÁCH HÀNG & TRẠNG THÁI */}
                <Col lg={4}>
                    {/* Trạng thái đơn & Nút Hành động */}
                    <Card className="border-0 shadow-sm rounded-4 mb-4">
                        <Card.Body>
                            <h6 className="fw-bold text-muted mb-3">TRẠNG THÁI ĐƠN HÀNG</h6>
                            <div className="fs-5 mb-3">{getStatusBadge(booking.status)}</div>

                            {/* [LOGIC NÚT BẤM] */}

                            {/* 1. Nếu đơn đang chờ: Cho phép Xác nhận hoặc Từ chối */}
                            {booking.status === 'pending' && (
                                <div className="d-grid gap-2">
                                    <Button variant="primary" onClick={() => handleUpdateStatus('confirmed')}>
                                        Xác nhận Booking
                                    </Button>
                                    <Button variant="outline-danger" onClick={() => handleUpdateStatus('cancelled')}>
                                        Từ chối đơn
                                    </Button>
                                </div>
                            )}

                            {/* 2. Nếu đơn đã xác nhận: Vẫn cho phép Hủy (Sự cố vận hành) */}
                            {booking.status === 'confirmed' && (
                                <div className="d-grid gap-2">
                                    <Button variant="danger" size="sm" onClick={() => handleUpdateStatus('cancelled')}>
                                        Hủy đơn (Sự cố vận hành)
                                    </Button>
                                </div>
                            )}

                        </Card.Body>
                    </Card>

                    {/* Thông tin khách hàng */}
                    <Card className="border-0 shadow-sm rounded-4">
                        <Card.Body>
                            <h6 className="fw-bold text-muted mb-3">KHÁCH HÀNG</h6>
                            <div className="d-flex align-items-center mb-3">
                                <div className="bg-light rounded-circle d-flex align-items-center justify-content-center me-3" style={{ width: 40, height: 40 }}>
                                    <i className="bi bi-person-fill text-secondary fs-5"></i>
                                </div>
                                <div>
                                    <div className="fw-bold">{customer.fullName || "Khách vãng lai"}</div>
                                    <div className="small text-muted">ID: {booking.user_id}</div>
                                </div>
                            </div>

                            <div className="mb-2">
                                <i className="bi bi-envelope me-2 text-primary"></i>
                                <span>{customer.email || "Không có email"}</span>
                            </div>
                            <div className="mb-2">
                                <i className="bi bi-telephone me-2 text-primary"></i>
                                <span>{customer.phone || "Không có SĐT"}</span>
                            </div>
                            <div className="mb-3">
                                <i className="bi bi-geo-alt me-2 text-primary"></i>
                                <span>{customer.address || "Không có địa chỉ"}</span>
                            </div>

                            {customer.note && (
                                <div className="alert alert-warning small mb-0">
                                    <strong>Ghi chú:</strong> {customer.note}
                                </div>
                            )}
                        </Card.Body>
                    </Card>
                </Col>
            </Row>
        </Container>
    );
}