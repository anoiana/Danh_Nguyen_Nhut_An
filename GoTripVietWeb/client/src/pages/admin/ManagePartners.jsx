import React, { useEffect, useState, useMemo } from "react";
import userApi from "../../api/userApi";
import { Badge, Button, Card, Table, Spinner, Form, InputGroup, Nav } from "react-bootstrap";

export default function ManagePartners() {
  const [partners, setPartners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [activeTab, setActiveTab] = useState("pending");

  const loadPartners = async () => {
    setLoading(true);
    try {
      const res = await userApi.getAllPartners({ limit: 1000 });
      const list = res.users || res.data || [];
      setPartners(list.filter(u => u.roles?.includes('partner')));
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadPartners(); }, []);

  const handleApprove = async (id) => {
    if (!window.confirm("Duyệt đối tác này?")) return;
    setProcessing(id);
    try {
      await userApi.approvePartner(id);
      await loadPartners();
      if (activeTab === 'pending') setActiveTab('approved');
    } catch (e) { alert("Lỗi: " + e.message); }
    finally { setProcessing(null); }
  };

  // Logic lọc dữ liệu
  const filtered = useMemo(() => {
    let result = partners;
    if (activeTab === 'pending') result = result.filter(p => !p.partner_details?.is_approved);
    else if (activeTab === 'approved') result = result.filter(p => p.partner_details?.is_approved);

    if (searchTerm) {
      const s = searchTerm.toLowerCase();
      result = result.filter(p =>
        (p.partner_details?.company_name || "").toLowerCase().includes(s) ||
        (p.email || "").toLowerCase().includes(s)
      );
    }
    return result.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }, [partners, searchTerm, activeTab]);

  const counts = {
    pending: partners.filter(p => !p.partner_details?.is_approved).length,
    approved: partners.filter(p => p.partner_details?.is_approved).length,
    all: partners.length
  };

  return (
    <div className="container-fluid px-0">
      {/* --- HEADER --- */}
      <div className="d-flex justify-content-between align-items-end mb-4">
        <div>
          <h3 className="fw-bolder text-dark mb-1">Đối tác Du lịch</h3>
          <p className="text-muted m-0 small">Quản lý và phê duyệt các nhà cung cấp dịch vụ</p>
        </div>
        <Button variant="white" className="border shadow-sm fw-bold text-primary" onClick={loadPartners}>
          <i className="bi bi-arrow-clockwise me-1"></i> Làm mới
        </Button>
      </div>

      <Card className="border-0 shadow-sm rounded-4 overflow-hidden bg-white">
        {/* --- TABS NAVIGATION --- */}
        <div className="px-4 pt-4 border-bottom bg-white">
          <Nav variant="tabs" className="border-bottom-0 gap-3" activeKey={activeTab} onSelect={k => setActiveTab(k)}>
            <Nav.Item>
              <Nav.Link eventKey="pending" className={`px-0 py-2 border-0 bg-transparent fw-bold ${activeTab === 'pending' ? 'text-primary border-bottom border-primary border-3' : 'text-secondary'}`}>
                Chờ duyệt <Badge bg="danger" pill className="ms-1">{counts.pending}</Badge>
              </Nav.Link>
            </Nav.Item>
            <Nav.Item>
              <Nav.Link eventKey="approved" className={`px-0 py-2 border-0 bg-transparent fw-bold ${activeTab === 'approved' ? 'text-primary border-bottom border-primary border-3' : 'text-secondary'}`}>
                Đã duyệt <Badge bg="success" pill className="ms-1">{counts.approved}</Badge>
              </Nav.Link>
            </Nav.Item>
            <Nav.Item>
              <Nav.Link eventKey="all" className={`px-0 py-2 border-0 bg-transparent fw-bold ${activeTab === 'all' ? 'text-primary border-bottom border-primary border-3' : 'text-secondary'}`}>
                Tất cả <Badge bg="secondary" pill className="ms-1">{counts.all}</Badge>
              </Nav.Link>
            </Nav.Item>
          </Nav>
        </div>

        {/* --- TOOLBAR --- */}
        <div className="p-3 bg-light d-flex border-bottom">
          <InputGroup style={{ maxWidth: 350 }}>
            <InputGroup.Text className="bg-white border-end-0 ps-3 rounded-start-pill text-muted">
              <i className="bi bi-search"></i>
            </InputGroup.Text>
            <Form.Control
              className="border-start-0 rounded-end-pill shadow-none"
              placeholder="Tìm theo tên công ty, email..."
              value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
            />
          </InputGroup>
        </div>

        {/* --- TABLE --- */}
        <Card.Body className="p-0 table-responsive">
          <Table hover className="mb-0 align-middle">
            <thead className="bg-light">
              <tr>
                <th className="py-3 ps-4 text-secondary small text-uppercase fw-bold">Doanh nghiệp / Đại diện</th>
                <th className="py-3 text-secondary small text-uppercase fw-bold">Liên hệ</th>
                <th className="py-3 text-secondary small text-uppercase fw-bold">Trạng thái</th>
                <th className="py-3 text-secondary small text-uppercase fw-bold text-end pe-4">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={4} className="text-center py-5"><Spinner animation="border" variant="primary" /></td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={4} className="text-center py-5 text-muted">Không có dữ liệu</td></tr>
              ) : filtered.map(p => {
                const d = p.partner_details || {};
                const isApproved = d.is_approved;
                return (
                  <tr key={p._id || p.id}>
                    <td className="ps-4 py-3">
                      <div className="d-flex align-items-center gap-3">
                        <div className="rounded-3 d-flex align-items-center justify-content-center text-primary fw-bold"
                          style={{ width: 48, height: 48, background: '#eff6ff', fontSize: '1.2rem' }}>
                          {(d.company_name?.[0] || "P").toUpperCase()}
                        </div>
                        <div>
                          <div className="fw-bold text-dark fs-6">{d.company_name || "Chưa cập nhật tên"}</div>
                          <div className="text-muted small">Đại diện: {p.fullName}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="d-flex flex-column small">
                        <span className="text-dark mb-1"><i className="bi bi-envelope me-2 text-muted"></i>{p.email}</span>
                        <span className="text-dark"><i className="bi bi-telephone me-2 text-muted"></i>{d.contact_phone || p.phone}</span>
                      </div>
                    </td>
                    <td>
                      {isApproved ?
                        <Badge bg="success" className="bg-opacity-10 text-success border border-success border-opacity-25 px-3 py-2 rounded-pill">Đã duyệt</Badge> :
                        <Badge bg="warning" className="bg-opacity-10 text-warning border border-warning border-opacity-25 px-3 py-2 rounded-pill">Chờ duyệt</Badge>
                      }
                      <div className="text-muted mt-1" style={{ fontSize: 10 }}>{new Date(p.createdAt).toLocaleDateString()}</div>
                    </td>
                    <td className="text-end pe-4">
                      {!isApproved ? (
                        <Button size="sm" variant="primary" className="px-3 rounded-pill fw-bold shadow-sm"
                          onClick={() => handleApprove(p._id || p.id)} disabled={processing === (p._id || p.id)}>
                          {processing === (p._id || p.id) ? "..." : "✓ Duyệt ngay"}
                        </Button>
                      ) : (
                        <Button size="sm" variant="light" className="px-3 rounded-pill text-muted border" disabled>Đã kích hoạt</Button>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </Table>
        </Card.Body>
      </Card>
    </div>
  );
}