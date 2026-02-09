import React, { useEffect, useState, useMemo } from "react";
import paymentApi from "../../api/paymentApi";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

// --- HELPERS ---
const formatCurrency = (amount) => {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
  }).format(amount);
};

// --- ICONS ---
const IconWrapper = ({ children }) => (
  <div style={{ width: "24px", height: "24px", minWidth: "24px", display: "flex", alignItems: "center", justifyContent: "center" }}>
    {children}
  </div>
);

const RefreshIcon = () => (
  <IconWrapper>
    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
    </svg>
  </IconWrapper>
);
const MoneyIcon = () => (
  <IconWrapper>
    <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  </IconWrapper>
);
const TrendingUpIcon = () => (
  <IconWrapper>
    <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
    </svg>
  </IconWrapper>
);
const HandshakeIcon = () => (
  <IconWrapper>
    <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
    </svg>
  </IconWrapper>
);

export default function DashboardAdvanced() {
  const [stats, setStats] = useState({
    totalVolume: 0,
    adminProfit: 0,
    partnerPayout: 0,
    adminGrossProfit: 0,
    totalVoucherCost: 0,
  });
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  // [NEW] Grouped Data State
  const [bookingGroups, setBookingGroups] = useState([]);

  // [NEW] Tab State: 'chart' | 'list'
  const [activeTab, setActiveTab] = useState("chart");

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await paymentApi.getSystemStats();
        if (res) {
          // ✅ FIX: Dùng trực tiếp stats từ Backend gửi về
          // Backend đã tính đúng: Volume (100%), Profit (15%), Payout (85%)
          if (res.stats) {
            setStats(prev => ({ ...prev, ...res.stats }));
          }

          // Sort transactions chỉ để hiển thị danh sách
          const sortedTxs = (res.transactions || []).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
          setTransactions(sortedTxs);

          // [NEW] Logic gom nhóm theo Booking ID
          const groups = {};
          sortedTxs.forEach(tx => {
            if (!tx.booking_id) return;
            if (!groups[tx.booking_id]) {
              groups[tx.booking_id] = {
                booking_id: tx.booking_id,
                createdAt: tx.createdAt,
                income: 0,
                commission: 0,
                voucher: 0,
                status: tx.status
              };
            }
            const amt = Math.abs(tx.amount || 0);
            if (tx.type === 'INCOME') groups[tx.booking_id].income = amt;
            if (tx.type === 'COMMISSION') groups[tx.booking_id].commission += amt;
            if (tx.type === 'VOUCHER_COST') groups[tx.booking_id].voucher += amt;
          });
          setBookingGroups(Object.values(groups).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));

        }
      } catch (error) {
        console.error("Error fetching stats:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  // --- CHART LOGIC ---
  const chartData = useMemo(() => {
    if (!transactions || transactions.length === 0) return [];
    const revenueByDate = {};
    // Use reverse() copy to calculate chart from old to new
    [...transactions].reverse().forEach((tx) => {
      if (tx.type === "INCOME" && tx.status === "COMPLETED") {
        const dateKey = new Date(tx.createdAt).toLocaleDateString("vi-VN", { day: '2-digit', month: '2-digit' });
        if (!revenueByDate[dateKey]) revenueByDate[dateKey] = 0;
        revenueByDate[dateKey] += tx.amount;
      }
    });
    return Object.keys(revenueByDate).map((date) => ({ date, revenue: revenueByDate[date] }));
  }, [transactions]);

  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '80vh' }}>
      <div className="spinner-border text-primary" role="status"></div>
    </div>
  );

  // --- PREMIUM UI COMPONENTS ---
  const StatCard = ({ title, value, icon, color, subContent, style, valueStyle }) => (
    <div style={{
      backgroundColor: '#fff',
      borderRadius: '24px',
      padding: '28px',
      border: '1px solid rgba(255,255,255,0.8)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      minWidth: '260px',
      flex: 1,
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      cursor: 'default',
      position: 'relative',
      overflow: 'hidden',
      ...style
    }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-5px) scale(1.01)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0) scale(1)';
      }}
    >
      {/* Decorative Glow Blob - Hiệu ứng quầng sáng nền */}
      <div style={{
        position: 'absolute',
        top: -40,
        right: -40,
        width: 140,
        height: 140,
        background: color,
        opacity: 0.12,
        filter: 'blur(50px)',
        borderRadius: '50%',
        zIndex: 0,
        pointerEvents: 'none'
      }}></div>

      <div style={{ position: 'relative', zIndex: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
        <div>
          <p style={{ color: '#64748b', fontSize: '12px', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '8px', opacity: 0.9 }}>
            {title}
          </p>
          <h3 style={{ fontSize: '30px', fontWeight: '800', color: '#1e293b', margin: 0, letterSpacing: '-1px', lineHeight: 1.1, ...valueStyle }}>
            {value}
          </h3>
        </div>
        <div style={{
          width: '52px', height: '52px',
          borderRadius: '16px',
          background: `linear-gradient(135deg, ${color}20, ${color}10)`,
          color: color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 4px 12px ${color}25`,
          border: `1px solid ${color}20`,
          backdropFilter: 'blur(4px)'
        }}>
          {React.cloneElement(icon, { width: 26, height: 26 })}
        </div>
      </div>

      {subContent && (
        <div style={{
          position: 'relative',
          zIndex: 10,
          borderTop: `1px solid ${color}15`,
          paddingTop: '16px',
          marginTop: 'auto'
        }}>
          {subContent}
        </div>
      )}
    </div>
  );

  return (
    <div style={{
      backgroundColor: '#f8fafc', // Slate-50 mostly
      minHeight: '100%',
      fontFamily: "'Inter', sans-serif",
      paddingBottom: '40px'
    }}>

      {/* --- PREMIUM HEADER --- */}
      <div style={{
        padding: '40px 48px',
        background: 'linear-gradient(to bottom, #ffffff, #f8fafc)',
        borderBottom: '1px solid #e2e8f0',
        marginBottom: '48px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'end'
      }}>
        <div>
          <h1 style={{ fontSize: '36px', fontWeight: '800', color: '#0f172a', margin: 0, letterSpacing: '-1.5px', lineHeight: '1.1' }}>
            Tổng Quan
          </h1>
          <p style={{ color: '#64748b', marginTop: '8px', fontSize: '15px', fontWeight: '500' }}>
            Chào mừng trở lại! Dưới đây là báo cáo hiệu suất hôm nay.
          </p>
        </div>
        <button
          onClick={() => window.location.reload()}
          style={{
            display: 'flex', alignItems: 'center', gap: '10px',
            padding: '12px 24px', backgroundColor: '#fff', border: '1px solid #e2e8f0',
            borderRadius: '14px', fontSize: '14px', fontWeight: '600', color: '#475569',
            cursor: 'pointer', transition: 'all 0.2s', boxShadow: '0 2px 5px rgba(0,0,0,0.03)'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.borderColor = '#cbd5e1';
            e.currentTarget.style.transform = 'translateY(-1px)';
            e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.05)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.borderColor = '#e2e8f0';
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 5px rgba(0,0,0,0.03)';
          }}
        >
          <RefreshIcon /> Cập nhật dữ liệu
        </button>
      </div>

      <div style={{ padding: '0 48px', maxWidth: '1800px', margin: '0 auto' }}>

        {/* --- STATS CARDS ROW --- */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '24px', marginBottom: '32px' }}>

          <StatCard
            title="Tổng Doanh Số (GMV)"
            value={formatCurrency(stats.totalVolume)}
            icon={<MoneyIcon />}
            color="#2563eb" // Blue-600
            style={{
              background: 'linear-gradient(135deg, #ffffff 0%, #eff6ff 100%)',
              border: '1px solid #bfdbfe',
              boxShadow: '0 4px 6px -1px rgba(59, 130, 246, 0.1)'
            }}
            valueStyle={{ color: '#1e40af' }}
            subContent={
              <span style={{ fontSize: '12px', color: '#60a5fa', fontWeight: '600' }}>
                Tổng giá trị giao dịch
              </span>
            }
          />

          <StatCard
            title="Đã Trả Partner"
            value={formatCurrency(stats.partnerPayout)}
            icon={<HandshakeIcon />}
            color="#d97706" // Amber-600
            style={{
              background: 'linear-gradient(135deg, #ffffff 0%, #fffbeb 100%)',
              border: '1px solid #fde68a',
              boxShadow: '0 4px 6px -1px rgba(245, 158, 11, 0.1)'
            }}
            valueStyle={{ color: '#92400e' }}
            subContent={
              <span style={{ fontSize: '12px', color: '#f59e0b', fontWeight: '600' }}>
                85% doanh thu sau chiết khấu
              </span>
            }
          />

          <StatCard
            title="Chi Phí Mã Giảm Giá"
            value={`-${formatCurrency(Math.abs(stats.totalVoucherCost || 0))}`}
            icon={
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                </svg>
              </div>
            }
            color="#dc2626" // Red-600
            style={{
              background: 'linear-gradient(135deg, #ffffff 0%, #fef2f2 100%)',
              border: '1px solid #fecaca',
              boxShadow: '0 4px 6px -1px rgba(239, 68, 68, 0.1)'
            }}
            valueStyle={{ color: '#b91c1c' }}
            subContent={
              <span style={{ fontSize: '12px', color: '#f87171', fontWeight: '600' }}>
                Admin tài trợ
              </span>
            }
          />

          <StatCard
            title="Lợi Nhuận Ròng (Admin)"
            value={formatCurrency(stats.adminProfit)}
            icon={<TrendingUpIcon />}
            color="#059669" // Emerald-600
            style={{
              flex: '1.8', // TO NHẤT
              background: 'linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%)', // Gradient Xanh đậm hơn
              border: '2px solid #10b981', // Viền xanh nổi bật
              boxShadow: '0 10px 15px -3px rgba(16, 185, 129, 0.2)', // Bóng đổ xanh
              transform: 'scale(1.02)'
            }}
            valueStyle={{ fontSize: '36px', color: '#064e3b', fontWeight: '900' }} // Text Xanh đậm
            subContent={
              <div style={{ fontSize: '13px', color: '#166534', fontWeight: '700', display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                <span>Phí sàn: <b style={{ color: '#059669' }}>+{formatCurrency(stats.adminGrossProfit || 0)}</b></span>
                <span>Voucher: <b style={{ color: '#dc2626' }}>-{formatCurrency(Math.abs(stats.totalVoucherCost || 0))}</b></span>
              </div>
            }
          />
        </div>

        {/* --- MAIN CONTENT (TABS) --- */}
        <div style={{ backgroundColor: '#fff', borderRadius: '24px', boxShadow: '0 4px 20px rgba(0,0,0,0.04)', border: '1px solid #f1f5f9', overflow: 'hidden' }}>

          {/* Internal Tab Header */}
          <div style={{ padding: '0 32px', borderBottom: '1px solid #e2e8f0', display: 'flex', gap: '32px' }}>
            {['chart', 'list'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  padding: '24px 4px',
                  background: 'none',
                  border: 'none',
                  borderBottom: activeTab === tab ? '3px solid #3b82f6' : '3px solid transparent',
                  fontSize: '15px',
                  fontWeight: activeTab === tab ? '700' : '500',
                  color: activeTab === tab ? '#3b82f6' : '#64748b',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  transform: activeTab === tab ? 'translateY(1px)' : 'none'
                }}
              >
                {tab === 'chart' ? 'Biểu Đồ Tăng Trưởng' : 'Lịch Sử Đơn Hàng'}
              </button>
            ))}
          </div>

          <div style={{ padding: '32px' }}>

            {/* --- TAB 1: CHART --- */}
            {activeTab === 'chart' && (
              <div style={{ animation: 'fadeIn 0.4s ease-out' }}>
                <div style={{ marginBottom: '32px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
                  <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                    Doanh thu 30 ngày gần nhất
                  </h3>
                  <div style={{ fontSize: '13px', color: '#94a3b8', fontWeight: '500' }}>* Dữ liệu tự động cập nhật</div>
                </div>

                <div style={{ width: "100%", height: 450 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData}>
                      <defs>
                        <linearGradient id="colorRevenueNew" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.15} />
                          <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis
                        dataKey="date"
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: '#94a3b8', fontSize: 12, fontWeight: 500 }}
                        dy={15}
                      />
                      <YAxis
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: '#94a3b8', fontSize: 12, fontWeight: 500 }}
                        tickFormatter={(value) => `${value / 1000}k`}
                        dx={-10}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'rgba(255, 255, 255, 0.95)',
                          borderRadius: '12px',
                          border: '1px solid #e2e8f0',
                          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.1)',
                          padding: '12px 16px'
                        }}
                        itemStyle={{ color: '#0f172a', fontWeight: '700', fontSize: '14px' }}
                        labelStyle={{ color: '#64748b', marginBottom: '4px', fontSize: '12px' }}
                        formatter={(value) => [formatCurrency(value), "Doanh thu"]}
                      />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        stroke="#3b82f6"
                        strokeWidth={3}
                        fillOpacity={1}
                        fill="url(#colorRevenueNew)"
                        activeDot={{ r: 6, strokeWidth: 0, fill: '#3b82f6' }}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}

            {/* --- TAB 2: LIST --- */}
            {activeTab === 'list' && (
              <div style={{ animation: 'fadeIn 0.3s ease-out' }}>
                <div style={{
                  maxHeight: '600px',
                  overflowY: 'auto',
                  border: '1px solid #f1f5f9',
                  borderRadius: '16px'
                }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                    <thead style={{ position: 'sticky', top: 0, zIndex: 10, backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase' }}>Đơn Hàng</th>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', textAlign: 'right' }}>Tổng Giá Trị</th>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', textAlign: 'right' }}>Hoa Hồng (Thu)</th>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', textAlign: 'right' }}>Voucher (Chi)</th>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#166534', textTransform: 'uppercase', textAlign: 'right', backgroundColor: '#f0fdf4' }}>Lợi Nhuận Ròng</th>
                        <th style={{ padding: '16px 24px', fontSize: '12px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', textAlign: 'center' }}>Trạng Thái</th>
                      </tr>
                    </thead>
                    <tbody>
                      {bookingGroups.length > 0 ? (
                        bookingGroups.map((group, index) => {
                          const netProfit = group.commission - group.voucher;
                          const isEven = index % 2 === 0;
                          return (
                            <tr key={group.booking_id} style={{ borderBottom: '1px solid #f1f5f9', backgroundColor: isEven ? '#fff' : '#fafafa' }}>
                              <td style={{ padding: '20px 24px' }}>
                                <div style={{ display: 'flex', flexDirection: 'column' }}>
                                  <span style={{ fontFamily: 'monospace', fontSize: '13px', fontWeight: '700', color: '#334155' }}>
                                    #{group.booking_id.slice(-6).toUpperCase()}
                                  </span>
                                  <span style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
                                    {new Date(group.createdAt).toLocaleString("vi-VN")}
                                  </span>
                                </div>
                              </td>

                              <td style={{ padding: '20px 24px', textAlign: 'right' }}>
                                <span style={{ fontSize: '14px', fontWeight: '600', color: '#334155' }}>
                                  {formatCurrency(group.income)}
                                </span>
                              </td>

                              <td style={{ padding: '20px 24px', textAlign: 'right' }}>
                                <span style={{ fontSize: '14px', fontWeight: '600', color: '#3b82f6' }}>
                                  +{formatCurrency(group.commission)}
                                </span>
                              </td>

                              <td style={{ padding: '20px 24px', textAlign: 'right' }}>
                                {group.voucher > 0 ? (
                                  <span style={{ fontSize: '14px', fontWeight: '600', color: '#ef4444' }}>
                                    -{formatCurrency(group.voucher)}
                                  </span>
                                ) : (
                                  <span style={{ fontSize: '14px', color: '#cbd5e1' }}>—</span>
                                )}
                              </td>

                              <td style={{ padding: '20px 24px', textAlign: 'right', backgroundColor: '#f0fdf4' }}>
                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                                  <span style={{ fontSize: '15px', fontWeight: '800', color: '#166534' }}>
                                    +{formatCurrency(netProfit)}
                                  </span>
                                  {group.voucher > 0 && <span style={{ fontSize: '11px', color: '#22c55e', fontWeight: 500 }}>(Sau KM)</span>}
                                </div>
                              </td>

                              <td style={{ padding: '20px 24px', textAlign: 'center' }}>
                                <span style={{ fontSize: '11px', fontWeight: '700', color: '#166534', backgroundColor: '#dcfce7', padding: '6px 12px', borderRadius: '30px' }}>
                                  HOÀN TẤT
                                </span>
                              </td>
                            </tr>
                          );
                        })
                      ) : (
                        <tr>
                          <td colSpan="6" style={{ padding: '80px', textAlign: 'center', color: '#94a3b8' }}>
                            Trống trơn! Chưa có đơn hàng nào hoàn tất.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

          </div>
        </div>

      </div>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>




  );
}