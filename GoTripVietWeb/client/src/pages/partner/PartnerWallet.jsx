import React, { useEffect, useState } from "react";
import { Container, Row, Col, Card, Table, Badge, Button, Spinner, Modal, Form } from "react-bootstrap";
import authApi from "../../api/authApi";
import paymentApi from "../../api/paymentApi";
import { formatCurrency } from "../../utils/formatData";

// --- CUSTOM ICONS ---
const BankIcon = () => (
  <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" /></svg>
);
const WalletIcon = () => (
  <svg width="32" height="32" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>
);
const HistoryIcon = () => (
  <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
);

export default function PartnerWallet() {
  const [user, setUser] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [walletBalance, setWalletBalance] = useState(0);
  const [loading, setLoading] = useState(true);

  // Modal State
  const [showWithdrawModal, setShowWithdrawModal] = useState(false);
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [bankInfo, setBankInfo] = useState({ bankName: "", accountNumber: "", accountName: "" });
  const [withdrawLoading, setWithdrawLoading] = useState(false);

  // --- LOAD DATA ---
  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const userData = await authApi.getProfile();
      setUser(userData);

      const res = await paymentApi.getWalletTransactions();
      if (res.transactions) {
        setTransactions(res.transactions);
        setWalletBalance(res.balance || 0);
      } else if (Array.isArray(res)) {
        setTransactions(res);
        setWalletBalance(userData.wallet_balance || 0);
      } else if (res.data) {
        setTransactions(res.data.transactions || []);
        setWalletBalance(res.data.balance || 0);
      }
    } catch (error) {
      console.error("Error loading wallet:", error);
    } finally {
      setLoading(false);
    }
  };

  // --- WITHDRAWAL LOGIC ---
  const handleWithdrawSubmit = async () => {
    const amount = Number(withdrawAmount);
    if (!amount || amount <= 0) return alert("Vui lòng nhập số tiền hợp lệ.");
    if (amount > walletBalance) return alert("Số dư không đủ.");
    if (!bankInfo.bankName || !bankInfo.accountNumber || !bankInfo.accountName) {
      return alert("Vui lòng điền đầy đủ thông tin ngân hàng.");
    }

    try {
      setWithdrawLoading(true);
      await paymentApi.requestPayout(amount, bankInfo);
      alert("✅ Gửi yêu cầu rút tiền thành công!");
      setShowWithdrawModal(false);
      setWithdrawAmount("");
      fetchData(); // Reload
    } catch (error) {
      alert("⚠️ Thất bại: " + (error.response?.data?.message || error.message));
    } finally {
      setWithdrawLoading(false);
    }
  };

  const pendingIncome = transactions
    .filter(t => t.status === 'PENDING' && t.type === 'INCOME')
    .reduce((acc, curr) => acc + curr.amount, 0);

  const totalWithdrawn = transactions
    .filter(t => (t.status === 'COMPLETED' || t.status === 'PENDING') && t.type === 'WITHDRAWAL')
    .reduce((acc, curr) => acc + curr.amount, 0);

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
        padding: '60px 0 100px',
        background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)',
        color: '#fff',
        marginBottom: '-80px',
        boxShadow: '0 4px 20px rgba(37, 99, 235, 0.2)'
      }}>
        <Container>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h1 style={{ fontSize: '32px', fontWeight: '700', marginBottom: '8px' }}>Ví Tài Chính</h1>
              <p style={{ fontSize: '16px', opacity: 0.9, fontWeight: '500', color: '#dbeafe' }}>
                Quản lý dòng tiền, doanh thu và lịch sử giao dịch minh bạch.
              </p>
            </div>
          </div>
        </Container>
      </div>

      <Container>
        {/* --- MAIN CARDS ROW --- */}
        <Row className="g-4 mb-5">
          {/* 1. MAIN WALLET CARD (Gradient Style) */}
          <Col lg={5}>
            <div style={{
              background: 'linear-gradient(135deg, #0f172a 0%, #334155 100%)',
              borderRadius: '24px',
              padding: '32px',
              color: '#fff',
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              boxShadow: '0 20px 25px -5px rgba(15, 23, 42, 0.3)',
              position: 'relative',
              overflow: 'hidden'
            }}>
              {/* Decorative Circles */}
              <div style={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, background: '#ffffff', opacity: 0.05, borderRadius: '50%' }}></div>
              <div style={{ position: 'absolute', bottom: -50, left: -50, width: 150, height: 150, background: '#3b82f6', opacity: 0.1, borderRadius: '50%' }}></div>

              <div className="d-flex justify-content-between align-items-start mb-4">
                <div>
                  <p style={{ opacity: 0.7, textTransform: 'uppercase', letterSpacing: '2px', fontSize: '12px', fontWeight: '600' }}>Số dư khả dụng</p>
                  <h2 style={{ fontSize: '42px', fontWeight: '800', margin: '4px 0' }}>{formatCurrency(walletBalance)}</h2>
                </div>
                <div style={{ padding: '12px', background: 'rgba(255,255,255,0.1)', borderRadius: '16px', backdropFilter: 'blur(5px)' }}>
                  <WalletIcon />
                </div>
              </div>

              <div>
                <Button
                  onClick={() => setShowWithdrawModal(true)}
                  style={{
                    background: '#3b82f6', border: 'none', padding: '12px 24px',
                    borderRadius: '12px', fontSize: '15px', fontWeight: '600',
                    width: '100%', boxShadow: '0 4px 6px -1px rgba(59, 130, 246, 0.5)',
                    transition: 'transform 0.2s'
                  }}
                  onMouseEnter={(e) => e.target.style.transform = 'translateY(-2px)'}
                  onMouseLeave={(e) => e.target.style.transform = 'translateY(0)'}
                >
                  Rút Về Ngân Hàng
                </Button>
                <p style={{ fontSize: '13px', opacity: 0.6, marginTop: '12px', textAlign: 'center' }}>
                  Yêu cầu rút tiền được xử lý trong vòng 24h làm việc.
                </p>
              </div>
            </div>
          </Col>

          {/* 2. STATS OVERVIEW */}
          <Col lg={7}>
            <Row className="g-4 h-100">
              <Col md={6}>
                <div style={{ backgroundColor: '#fff', padding: '24px', borderRadius: '24px', height: '100%', border: '1px solid #f1f5f9', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '48px', height: '48px', background: '#fef3c7', borderRadius: '14px', color: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px' }}>
                    <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  </div>
                  <p style={{ color: '#64748b', fontSize: '13px', fontWeight: '600', textTransform: 'uppercase' }}>Doanh thu chờ duyệt</p>
                  <h3 style={{ fontSize: '28px', fontWeight: '700', color: '#d97706' }}>{formatCurrency(pendingIncome)}</h3>
                  <p style={{ fontSize: '13px', color: '#94a3b8', marginTop: '4px' }}>Sẽ cộng vào ví sau khi Tour hoàn thành.</p>
                </div>
              </Col>
              <Col md={6}>
                <div style={{ backgroundColor: '#fff', padding: '24px', borderRadius: '24px', height: '100%', border: '1px solid #f1f5f9', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '48px', height: '48px', background: '#ecfdf5', borderRadius: '14px', color: '#059669', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px' }}>
                    <BankIcon />
                  </div>
                  <p style={{ color: '#64748b', fontSize: '13px', fontWeight: '600', textTransform: 'uppercase' }}>Đã rút về bank</p>
                  <h3 style={{ fontSize: '28px', fontWeight: '700', color: '#059669' }}>{formatCurrency(totalWithdrawn)}</h3>
                  <p style={{ fontSize: '13px', color: '#94a3b8', marginTop: '4px' }}>Tổng số tiền đã rút thành công.</p>
                </div>
              </Col>
            </Row>
          </Col>
        </Row>

        {/* --- TRANSACTION HISTORY --- */}
        <div style={{ backgroundColor: '#fff', borderRadius: '24px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.02)' }}>
          <div style={{ padding: '24px 32px', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h4 style={{ fontSize: '18px', fontWeight: '700', margin: 0, display: 'flex', alignItems: 'center', gap: '10px' }}>
              <HistoryIcon /> Lịch sử giao dịch
            </h4>
            <Button variant="light" size="sm" className="fw-bold text-muted border" onClick={fetchData}>
              Làm mới
            </Button>
          </div>

          <Table hover responsive style={{ margin: 0 }}>
            <thead style={{ backgroundColor: '#f8fafc' }}>
              <tr>
                <th className="ps-4 py-3 text-secondary small text-uppercase">Mã GD</th>
                <th className="py-3 text-secondary small text-uppercase">Loại</th>
                <th className="py-3 text-secondary small text-uppercase">Nội dung</th>
                <th className="py-3 text-secondary small text-uppercase text-end">Số tiền</th>
                <th className="py-3 text-secondary small text-uppercase text-center">Trạng thái</th>
                <th className="pe-4 py-3 text-secondary small text-uppercase text-end">Thời gian</th>
              </tr>
            </thead>
            <tbody>
              {transactions.length === 0 ? (
                <tr><td colSpan="6" className="text-center py-5 text-muted">Chưa có giao dịch nào phát sinh.</td></tr>
              ) : (
                transactions.map((tx, idx) => (
                  <tr key={idx} style={{ verticalAlign: 'middle', borderBottom: '1px solid #f1f5f9' }}>

                    {/* 1. Mã GD */}
                    <td className="ps-4 py-3">
                      <span style={{ fontFamily: 'monospace', fontWeight: '600', color: '#64748b', background: '#f8fafc', padding: '4px 8px', borderRadius: '6px' }}>
                        #{tx._id ? tx._id.slice(-6).toUpperCase() : '---'}
                      </span>
                    </td>

                    {/* 2. Loại Giao Dịch (Có Icon) */}
                    <td className="py-3">
                      <div className="d-flex align-items-center gap-2">
                        {tx.type === 'INCOME' && (
                          <div style={{ width: 32, height: 32, background: '#dcfce7', borderRadius: '50%', color: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
                          </div>
                        )}
                        {tx.type === 'WITHDRAWAL' && (
                          <div style={{ width: 32, height: 32, background: '#f1f5f9', borderRadius: '50%', color: '#475569', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
                          </div>
                        )}
                        {tx.type === 'COMMISSION' && (
                          <div style={{ width: 32, height: 32, background: '#fef2f2', borderRadius: '50%', color: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <span style={{ fontWeight: 'bold', fontSize: '14px' }}>%</span>
                          </div>
                        )}

                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                          <span style={{ fontWeight: '600', fontSize: '14px', color: '#334155' }}>
                            {tx.type === 'INCOME' ? 'Doanh thu' : tx.type === 'WITHDRAWAL' ? 'Rút tiền' : 'Phí sàn'}
                          </span>
                        </div>
                      </div>
                    </td>

                    {/* 3. Mô tả */}
                    <td className="py-3">
                      <span style={{ color: '#475569', fontSize: '14px' }}>{tx.description}</span>
                    </td>

                    {/* 4. Số tiền (Highlight) */}
                    <td className="py-3 text-end">
                      <div className="d-flex flex-column align-items-end">
                        <span style={{
                          fontWeight: '700', fontSize: '15px',
                          color: tx.type === 'INCOME' ? '#16a34a' : tx.type === 'WITHDRAWAL' ? '#475569' : '#dc2626'
                        }}>
                          {tx.type === 'INCOME' ? '+' : '-'}{formatCurrency(tx.amount)}
                        </span>

                        {/* Hiển thị Thực nhận ước tính cho dòng Doanh Thu */}
                        {tx.type === 'INCOME' && (
                          <span style={{ fontSize: '11px', color: '#64748b', fontWeight: '500' }}>
                            Thực nhận: <span style={{ color: '#166534' }}>{formatCurrency(tx.amount * 0.85)}</span>
                          </span>
                        )}
                        <span style={{ fontSize: '10px', color: '#9ca3af', fontStyle: 'italic' }}>
                          {tx.type === 'INCOME' ? '(Chưa trừ phí)' : ''}
                        </span>
                      </div>
                    </td>

                    {/* 5. Trạng thái */}
                    <td className="py-3 text-center">
                      {tx.status === 'COMPLETED' && <Badge bg="success" className="rounded-pill px-3 py-2 fw-normal">Hoàn thành</Badge>}
                      {tx.status === 'PENDING' && <Badge bg="warning" text="dark" className="rounded-pill px-3 py-2 fw-normal">Đang xử lý</Badge>}
                      {(tx.status === 'FAILED' || tx.status === 'REJECTED') && <Badge bg="danger" className="rounded-pill px-3 py-2 fw-normal">Thất bại</Badge>}
                    </td>

                    {/* 6. Thời gian */}
                    <td className="py-3 pe-4 text-end">
                      <div className="d-flex flex-column align-items-end">
                        <span style={{ fontSize: '13px', fontWeight: '600', color: '#334155' }}>
                          {tx.createdAt ? new Date(tx.createdAt).toLocaleDateString('vi-VN') : '--'}
                        </span>
                        <span style={{ fontSize: '12px', color: '#94a3b8' }}>
                          {tx.createdAt ? new Date(tx.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : ''}
                        </span>
                      </div>
                    </td>

                  </tr>
                ))
              )}
            </tbody>
          </Table>
        </div>
      </Container>


      {/* --- WITHDRAW MODAL (Premium Form) --- */}
      <Modal show={showWithdrawModal} onHide={() => setShowWithdrawModal(false)} centered size="lg">
        <Modal.Header closeButton className="border-0 pb-0">
          <Modal.Title className="fw-bold fs-4">Yêu cầu Rút tiền</Modal.Title>
        </Modal.Header>
        <Modal.Body className="p-4">
          <div style={{ backgroundColor: '#eff6ff', borderRadius: '16px', padding: '20px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ width: 40, height: 40, background: '#fff', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
              <WalletIcon />
            </div>
            <div>
              <div className="text-muted small fw-bold text-uppercase">Số dư khả dụng</div>
              <div className="fs-3 fw-bold text-primary">{formatCurrency(walletBalance)}</div>
            </div>
          </div>

          <Form>
            <Form.Group className="mb-4">
              <Form.Label className="fw-bold">Số tiền muốn rút (VND)</Form.Label>
              <Form.Control
                type="number"
                placeholder="Nhập số tiền..."
                value={withdrawAmount}
                onChange={(e) => setWithdrawAmount(e.target.value)}
                style={{ fontSize: '18px', padding: '12px' }}
              />
            </Form.Group>

            <h6 className="fw-bold mb-3 pt-2 border-top mt-4">Thông tin tài khoản nhận tiền</h6>
            <Row className="g-3">
              <Col md={12}>
                <Form.Group>
                  <Form.Label className="small text-muted fw-bold">NGÂN HÀNG</Form.Label>
                  <Form.Control
                    placeholder="VD: Vietcombank, Techcombank..."
                    value={bankInfo.bankName}
                    onChange={(e) => setBankInfo({ ...bankInfo, bankName: e.target.value })}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="small text-muted fw-bold">SỐ TÀI KHOẢN</Form.Label>
                  <Form.Control
                    placeholder="VD: 1900xxxxxx"
                    value={bankInfo.accountNumber}
                    onChange={(e) => setBankInfo({ ...bankInfo, accountNumber: e.target.value })}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group>
                  <Form.Label className="small text-muted fw-bold">CHỦ TÀI KHOẢN</Form.Label>
                  <Form.Control
                    placeholder="VD: NGUYEN VAN A"
                    value={bankInfo.accountName}
                    onChange={(e) => setBankInfo({ ...bankInfo, accountName: e.target.value.toUpperCase() })}
                  />
                </Form.Group>
              </Col>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer className="border-0 pt-0 pb-4 pe-4">
          <Button variant="light" onClick={() => setShowWithdrawModal(false)} className="px-4 py-2 fw-bold text-muted">Hủy bỏ</Button>
          <Button variant="primary" onClick={handleWithdrawSubmit} disabled={withdrawLoading} className="px-4 py-2 fw-bold shadow-sm">
            {withdrawLoading ? "Đang xử lý..." : "Xác nhận Rút tiền"}
          </Button>
        </Modal.Footer>
      </Modal>

    </div>
  );
}