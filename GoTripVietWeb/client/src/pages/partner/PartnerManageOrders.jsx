import React, { useEffect, useState, useMemo } from "react";
import { Container, Row, Col, Card, Table, Badge, Button, Spinner, Form } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import bookingApi from "../../api/bookingApi";

// --- HELPERS ---
const formatCurrency = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

// --- ICONS ---
const OrderIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
);
const UserIcon = () => (
  <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
);
const PhoneIcon = () => (
  <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" /></svg>
);

export default function PartnerManageOrders() {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filterStatus, setFilterStatus] = useState("ALL");

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const res = await bookingApi.getPartnerBookings();
      setOrders(res.bookings || res.data || []);
    } catch (error) {
      console.error("Error loading bookings:", error);
    } finally {
      setLoading(false);
    }
  };

  // --- STATS CALC ---
  const stats = useMemo(() => {
    return {
      total: orders.length,
      pending: orders.filter(o => o.status === 'pending').length,
      confirmed: orders.filter(o => o.status === 'confirmed').length,
      revenue: orders
        .filter(o => o.status === 'completed' || o.status === 'confirmed')
        .reduce((acc, curr) => acc + (curr.pricing?.final_price || 0), 0)
    };
  }, [orders]);

  // --- FILTER ---
  const filtered = useMemo(() => {
    return orders.filter(o => filterStatus === 'ALL' || o.status?.toUpperCase() === filterStatus);
  }, [orders, filterStatus]);

  // --- UI RENDERERS ---
  const renderStatusBadge = (status) => {
    const s = status?.toLowerCase();
    const config = {
      pending: { bg: '#fff7ed', color: '#ea580c', label: 'Chờ xác nhận', icon: '⏳' },
      confirmed: { bg: '#eff6ff', color: '#2563eb', label: 'Đã xác nhận', icon: '✅' },
      completed: { bg: '#f0fdf4', color: '#16a34a', label: 'Hoàn thành', icon: '🏁' },
      cancelled: { bg: '#fef2f2', color: '#dc2626', label: 'Đã hủy', icon: '❌' },
      paid: { bg: '#ecfdf5', color: '#059669', label: 'Đã thanh toán', icon: '💰' } // Often paid means Confirmed/Pending
    };

    const curr = config[s] || { bg: '#f3f4f6', color: '#4b5563', label: status, icon: '•' };

    return (
      <span style={{
        backgroundColor: curr.bg, color: curr.color,
        padding: '6px 14px', borderRadius: '20px',
        fontSize: '12px', fontWeight: '700',
        display: 'inline-flex', alignItems: 'center', gap: '6px',
        border: `1px solid ${curr.color}20`
      }}>
        <span>{curr.icon}</span> {curr.label}
      </span>
    );
  };

  if (loading && orders.length === 0) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh', backgroundColor: '#f8fafc' }}>
        <Spinner animation="border" variant="primary" />
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: '#f8fafc', minHeight: '100vh', paddingBottom: '60px', fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" }}>

      {/* --- PREMIUM HEADER --- */}
      <div style={{
        padding: '60px 0 100px',
        background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)',
        color: '#fff',
        marginBottom: '-80px',
        boxShadow: '0 4px 20px rgba(37, 99, 235, 0.2)'
      }}>
        <Container>
          <div className="d-flex justify-content-between align-items-end">
            <div>
              <h1 style={{ fontSize: '32px', fontWeight: '700', marginBottom: '8px' }}>Quản Lý Booking</h1>
              <p style={{ fontSize: '16px', opacity: 0.9, fontWeight: '500', color: '#dbeafe' }}>
                Theo dõi và xử lý tất cả đơn hàng từ khách hàng của bạn.
              </p>
            </div>
            <Button
              variant="light"
              className="fw-bold shadow-sm"
              style={{ color: '#2563eb' }}
              onClick={fetchData}
            >
              <i className="bi bi-arrow-clockwise me-1"></i> Làm mới
            </Button>
          </div>
        </Container>
      </div>

      <Container>
        {/* --- STATS OVERVIEW --- */}
        <Row className="g-4 mb-4">
          <Col md={4}>
            <div style={{ backgroundColor: '#fff', borderRadius: '20px', padding: '24px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.03)', display: 'flex', alignItems: 'center', gap: '20px' }}>
              <div style={{ width: 56, height: 56, background: '#eff6ff', borderRadius: '16px', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <OrderIcon />
              </div>
              <div>
                <div style={{ color: '#64748b', fontSize: '13px', fontWeight: 'bold', textTransform: 'uppercase' }}>Tổng Đơn Hàng</div>
                <div style={{ fontSize: '28px', fontWeight: '800', color: '#1e293b' }}>{stats.total}</div>
              </div>
            </div>
          </Col>
          <Col md={4}>
            <div style={{ backgroundColor: '#fff', borderRadius: '20px', padding: '24px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.03)', display: 'flex', alignItems: 'center', gap: '20px' }}>
              <div style={{ width: 56, height: 56, background: '#fff7ed', borderRadius: '16px', color: '#ea580c', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontSize: '24px' }}>⏳</span>
              </div>
              <div>
                <div style={{ color: '#64748b', fontSize: '13px', fontWeight: 'bold', textTransform: 'uppercase' }}>Chờ Xác Nhận</div>
                <div style={{ fontSize: '28px', fontWeight: '800', color: '#ea580c' }}>{stats.pending}</div>
              </div>
            </div>
          </Col>
          <Col md={4}>
            <div style={{ backgroundColor: '#fff', borderRadius: '20px', padding: '24px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.03)', display: 'flex', alignItems: 'center', gap: '20px' }}>
              <div style={{ width: 56, height: 56, background: '#f0fdf4', borderRadius: '16px', color: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontSize: '24px' }}>💰</span>
              </div>
              <div>
                <div style={{ color: '#64748b', fontSize: '13px', fontWeight: 'bold', textTransform: 'uppercase' }}>Doanh Thu Tạm Tính</div>
                <div style={{ fontSize: '24px', fontWeight: '800', color: '#16a34a' }}>{formatCurrency(stats.revenue)}</div>
              </div>
            </div>
          </Col>
        </Row>

        {/* --- MAIN CONTENT CARD --- */}
        <Card className="border-0 shadow-sm rounded-4 overflow-hidden">

          {/* TABS HEADER */}
          <div className="bg-white border-bottom px-4 pt-4 pb-0">
            <div className="d-flex gap-4">
              {[
                { key: 'ALL', label: 'Tất cả đơn' },
                { key: 'PENDING', label: 'Chờ xử lý' },
                { key: 'CONFIRMED', label: 'Đã xác nhận' },
                { key: 'COMPLETED', label: 'Hoàn thành' },
                { key: 'CANCELLED', label: 'Đã hủy' }
              ].map(tab => (
                <div
                  key={tab.key}
                  onClick={() => setFilterStatus(tab.key)}
                  style={{
                    paddingBottom: '16px',
                    cursor: 'pointer',
                    fontWeight: '600',
                    fontSize: '14px',
                    color: filterStatus === tab.key ? '#2563eb' : '#64748b',
                    borderBottom: filterStatus === tab.key ? '3px solid #2563eb' : '3px solid transparent',
                    transition: 'all 0.2s'
                  }}
                >
                  {tab.label}
                </div>
              ))}
            </div>
          </div>

          {/* TABLE CONTENT */}
          <div className="table-responsive">
            <Table hover className="mb-0 align-middle">
              <thead className="bg-light">
                <tr>
                  <th className="ps-4 py-3 text-secondary small text-uppercase">Mã / Thời gian</th>
                  <th className="py-3 text-secondary small text-uppercase">Sản phẩm / Dịch vụ</th>
                  <th className="py-3 text-secondary small text-uppercase">Khách hàng</th>
                  <th className="py-3 text-secondary small text-uppercase text-end">Tổng tiền (VND)</th>
                  <th className="py-3 text-secondary small text-uppercase text-center">Trạng thái</th>
                  <th className="pe-4 py-3 text-secondary small text-uppercase text-end">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="text-center py-5">
                      <div className="d-flex flex-column align-items-center">
                        <div style={{ fontSize: '40px', opacity: 0.3, marginBottom: '10px' }}>📭</div>
                        <span className="text-muted fw-bold">Không tìm thấy đơn hàng nào</span>
                      </div>
                    </td>
                  </tr>
                ) : (
                  filtered.map(booking => {
                    const firstItem = booking.items?.[0];
                    const title = firstItem?.snapshot?.title || "Sản phẩm không khả dụng";
                    const itemCount = booking.items?.length || 0;
                    const customerName = booking.customer_details?.fullName || "Khách vãng lai";
                    const customerPhone = booking.customer_details?.phone || "";

                    return (
                      <tr key={booking._id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                        <td className="ps-4 py-3">
                          <div className="font-monospace fw-bold text-dark mb-1">
                            #{booking._id.slice(-6).toUpperCase()}
                          </div>
                          <div className="text-muted small">
                            {new Date(booking.createdAt).toLocaleDateString('vi-VN')}
                          </div>
                        </td>
                        <td style={{ maxWidth: '300px' }}>
                          <div className="fw-bold text-dark text-truncate" title={title} style={{ fontSize: '15px' }}>
                            {title}
                          </div>
                          {itemCount > 1 && (
                            <Badge bg="light" text="primary" className="mt-1 border border-primary-subtle">
                              + {itemCount - 1} dịch vụ khác
                            </Badge>
                          )}
                        </td>
                        <td>
                          <div className="fw-bold text-dark d-flex align-items-center gap-2">
                            <UserIcon /> {customerName}
                          </div>
                          <div className="text-muted small mt-1 d-flex align-items-center gap-2">
                            <PhoneIcon /> {customerPhone}
                          </div>
                        </td>
                        <td className="text-end">
                          <div className="fw-bold" style={{ fontSize: '16px', color: '#1e293b' }}>
                            {formatCurrency(booking.pricing?.final_price || 0)}
                          </div>
                        </td>
                        <td className="text-center">
                          {renderStatusBadge(booking.status)}
                        </td>
                        <td className="pe-4 text-end">
                          <Button
                            variant="outline-primary"
                            size="sm"
                            className="rounded-pill px-3 fw-bold btn-hover-scale"
                            style={{ fontSize: '13px' }}
                            onClick={() => navigate(`/partner/orders/${booking._id}`)}
                          >
                            Xem chi tiết
                          </Button>
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </Table>
          </div>

          {/* TABLE FOOTER / PAGINATION (Placeholder) */}
          <div className="bg-light px-4 py-3 border-top text-end small text-muted">
            Hiển thị {filtered.length} kết quả
          </div>

        </Card>
      </Container>
    </div>
  );
}