import React, { useEffect, useState } from "react";
import { Container, Row, Col, Spinner } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import paymentApi from "../../api/paymentApi";
import bookingApi from "../../api/bookingApi";
import catalogApi from "../../api/catalogApi";

// --- ICONS ---
const WalletIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>
);
const OrderIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
);
const TourIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
);
const CheckCircleIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
);
const PlusIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" /></svg>
);

// --- HELPER ---
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
};

// --- PREMIUM STAT CARD ---
const StatCard = ({ title, value, icon, color, subContent }) => (
  <div style={{
    backgroundColor: '#fff',
    borderRadius: '20px',
    padding: '24px',
    border: '1px solid rgba(255,255,255,0.8)',
    boxShadow: `0 10px 25px -5px ${color}20, 0 8px 10px -6px ${color}10`,
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-between',
    minHeight: '160px',
    transition: 'all 0.3s ease',
    cursor: 'default',
    position: 'relative',
    overflow: 'hidden'
  }}
    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-5px)'; }}
    onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; }}
  >
    <div style={{
      position: 'absolute', top: -30, right: -30, width: 100, height: 100,
      background: color, opacity: 0.15, filter: 'blur(40px)', borderRadius: '50%'
    }}></div>

    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
      <div style={{
        width: '48px', height: '48px',
        borderRadius: '14px',
        background: `linear-gradient(135deg, ${color}20, ${color}10)`,
        color: color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        border: `1px solid ${color}30`
      }}>
        {icon}
      </div>
      {subContent && (
        <span style={{
          fontSize: '12px', fontWeight: '600', color: color,
          backgroundColor: `${color}15`, padding: '4px 10px', borderRadius: '20px'
        }}>
          {subContent}
        </span>
      )}
    </div>

    <div style={{ marginTop: '20px', position: 'relative', zIndex: 10 }}>
      <h3 style={{ fontSize: '28px', fontWeight: '800', color: '#0f172a', margin: 0, letterSpacing: '-0.5px' }}>
        {value}
      </h3>
      <p style={{ color: '#64748b', fontSize: '13px', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.5px', marginTop: '6px' }}>
        {title}
      </p>
    </div>
  </div>
);

// --- MENU CARD ---
const MenuCard = ({ title, desc, icon, bg, color, onClick, isPrimary }) => (
  <div onClick={onClick} style={{
    backgroundColor: isPrimary ? '#2563eb' : '#fff',
    color: isPrimary ? '#fff' : '#1e293b',
    borderRadius: '24px',
    padding: '28px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    border: isPrimary ? 'none' : '1px solid #e2e8f0',
    boxShadow: isPrimary ? '0 10px 25px -5px rgba(37, 99, 235, 0.4)' : '0 4px 6px -1px rgba(0,0,0,0.05)',
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    position: 'relative',
    overflow: 'hidden'
  }}
    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-5px)'; }}
    onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; }}
  >
    {isPrimary && (
      <div style={{
        position: 'absolute', top: -50, right: -50, width: 200, height: 200,
        background: 'linear-gradient(135deg, rgba(255,255,255,0.2), rgba(255,255,255,0))',
        borderRadius: '50%', pointerEvents: 'none'
      }}></div>
    )}

    <div style={{
      width: '56px', height: '56px', borderRadius: '16px', marginBottom: '20px',
      backgroundColor: isPrimary ? 'rgba(255,255,255,0.2)' : bg,
      color: isPrimary ? '#fff' : color,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: '24px'
    }}>
      {React.isValidElement(icon) ? icon : <i className={`bi ${icon}`}></i>}
    </div>

    <h4 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '8px' }}>{title}</h4>
    <p style={{ fontSize: '14px', margin: 0, opacity: isPrimary ? 0.9 : 0.6, lineHeight: 1.5 }}>
      {desc}
    </p>

    {isPrimary && (
      <div style={{ marginTop: '24px', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '8px' }}>
        Tạo ngay <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M14 5l7 7m0 0l-7 7m7-7H3" /></svg>
      </div>
    )}
  </div>
);

export default function PartnerDashboard() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState({
    balance: 0,
    pendingBookings: 0,
    activeTours: 0,
    totalBookings: 0
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        // 1. Fetch Wallet
        const walletRes = await paymentApi.getWalletTransactions();
        const balance = walletRes.balance || 0;

        // 2. Fetch Bookings
        const bookings = await bookingApi.getPartnerBookings();
        const bookingList = Array.isArray(bookings) ? bookings : (bookings.data || []);
        const totalBookings = bookingList.length;
        // Count bookings that need attention (e.g., 'paid' or 'pending')
        const pendingBookings = bookingList.filter(b => b.status === 'paid' || b.status === 'pending').length;

        // 3. Fetch Tours
        const toursRes = await catalogApi.getPartnerTours({ limit: 100 });
        const tours = toursRes.data || toursRes || [];
        const activeTours = tours.filter(t => t.status === 'active' || t.status === 'approved').length;

        setData({
          balance,
          pendingBookings,
          activeTours,
          totalBookings
        });
      } catch (error) {
        console.error("Error fetching partner dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const stats = [
    {
      title: "Số dư ví hiện tại",
      value: formatCurrency(data.balance),
      icon: <WalletIcon />,
      color: "#10b981",
      subContent: "Sẵn sàng rút"
    },
    {
      title: "Booking chờ xử lý",
      value: data.pendingBookings,
      icon: <OrderIcon />,
      color: "#3b82f6",
      subContent: "Cần xác nhận"
    },
    {
      title: "Tour đang hoạt động",
      value: data.activeTours,
      icon: <TourIcon />,
      color: "#f59e0b"
    },
    {
      title: "Tổng lượt Booking",
      value: data.totalBookings,
      icon: <CheckCircleIcon />,
      color: "#8b5cf6",
      subContent: "Toàn thời gian"
    },
  ];

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh', backgroundColor: '#f8fafc' }}>
        <Spinner animation="border" variant="primary" />
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: '#f8fafc', minHeight: '100vh', paddingBottom: '60px', fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" }}>

      {/* --- HEADER --- */}
      <div style={{
        padding: '60px 0 80px', // Extra padding bottom for overlap effect
        background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)', // Blue Theme
        color: '#fff',
        marginBottom: '-60px' // Negative margin to pull content up
      }}>
        <Container>
          <div className="d-flex justify-content-between align-items-end">
            <div>
              <h1 style={{ fontSize: '32px', fontWeight: '700', marginBottom: '8px' }}>Xin chào, Đối tác! 👋</h1>
              <p style={{ fontSize: '16px', opacity: 0.9, fontWeight: '500', color: '#dbeafe' }}>
                Dưới đây là tình hình kinh doanh thực tế của bạn.
              </p>
            </div>
          </div>
        </Container>
      </div>

      <Container>
        {/* --- STATS ROW --- */}
        <Row className="g-4 mb-5">
          {stats.map((item, idx) => (
            <Col md={6} lg={3} key={idx}>
              <StatCard {...item} />
            </Col>
          ))}
        </Row>

        {/* --- QUICK MENU GRID --- */}
        <h3 style={{ fontSize: '20px', fontWeight: '700', color: '#334155', marginBottom: '24px' }}>Truy cập nhanh</h3>
        <Row className="g-4">
          <Col md={4}>
            <MenuCard
              isPrimary={true}
              title="Đăng Tour Mới"
              desc="Tạo sản phẩm du lịch mới để tiếp cận hàng triệu khách hàng tiềm năng."
              icon={<PlusIcon />}
              onClick={() => navigate('/partner/tours/create')}
            />
          </Col>
          <Col md={4}>
            <MenuCard
              title="Quản lý Tour"
              desc="Xem danh sách, chỉnh sửa giá, cập nhật lịch trình và đóng/mở tour."
              icon="bi-list-ul"
              bg="#eff6ff" color="#3b82f6"
              onClick={() => navigate('/partner/tours')}
            />
          </Col>
          <Col md={4}>
            <MenuCard
              title="Quản lý Booking"
              desc="Xem và xử lý các đơn đặt chỗ mới từ khách hàng. Xác nhận hoặc từ chối."
              icon="bi-receipt"
              bg="#fffbeb" color="#f59e0b"
              onClick={() => navigate('/partner/orders')}
            />
          </Col>
          <Col md={4}>
            <MenuCard
              title="Ví & Tài Chính"
              desc="Theo dõi dòng tiền, lịch sử thanh toán và yêu cầu rút tiền về tài khoản."
              icon="bi-wallet2"
              bg="#ecfdf5" color="#10b981"
              onClick={() => navigate('/partner/wallet')}
            />
          </Col>
          <Col md={4}>
            <MenuCard
              title="Hồ Sơ Của Tôi"
              desc="Cập nhật thông tin doanh nghiệp, logo và thông tin liên hệ."
              icon="bi-person-circle"
              bg="#f3e8ff" color="#7e22ce"
              onClick={() => navigate('/partner/profile')}
            />
          </Col>
        </Row>
      </Container>
    </div>
  );
}