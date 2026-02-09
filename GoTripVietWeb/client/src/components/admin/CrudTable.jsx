import React, { useMemo, useState } from "react";
import { Badge } from "react-bootstrap";

// Helper: Lấy chữ cái đầu làm Avatar
const getInitials = (name) => {
  if (!name) return "U";
  return name.trim().charAt(0).toUpperCase();
};

// Helper: Rút gọn ID
const shortId = (id) => {
  if (!id) return "";
  return "#" + id.slice(-6).toUpperCase();
};

function Modal({ open, title, children, onClose }) {
  if (!open) return null;
  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 1050,
      background: "rgba(0,0,0,0.4)", backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center"
    }} onClick={onClose}>
      <div style={{
        background: "#fff", width: "600px", maxWidth: "90vw",
        borderRadius: "16px", padding: "24px",
        boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)"
      }} onClick={e => e.stopPropagation()}>
        <div className="d-flex justify-content-between align-items-center mb-3">
          <h4 className="fw-bold m-0 text-dark">{title}</h4>
          <button onClick={onClose} className="btn-close"></button>
        </div>
        {children}
      </div>
    </div>
  );
}

export default function CrudTable({
  title, data, schema, onAdd, onUpdate, onDelete, onToggleStatus,
  statusKey = "status", renderRowActions,
}) {
  const [q, setQ] = useState("");
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return data;
    return data.filter((x) => JSON.stringify(x).toLowerCase().includes(s));
  }, [data, q]);

  const handleSubmit = (e) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    const obj = {};
    schema.forEach((f) => {
      if (f.type === "boolean") obj[f.key] = fd.get(f.key) === "on";
      else if (f.type === "number") obj[f.key] = Number(fd.get(f.key) || 0);
      else obj[f.key] = String(fd.get(f.key) || "");
    });
    if (editing?.id) onUpdate(editing.id, obj);
    else onAdd({ ...obj, [statusKey]: obj[statusKey] || "ACTIVE" });
    setOpen(false);
  };

  return (
    <div className="card border-0 shadow-sm rounded-4 overflow-hidden bg-white">
      {/* --- HEADER --- */}
      <div className="card-header bg-white border-bottom-0 p-4 d-flex flex-wrap align-items-center gap-3">
        <div className="flex-grow-1">
          <h4 className="fw-bolder text-dark mb-1">{title}</h4>
          <div className="text-muted small">Quản lý danh sách {filtered.length} bản ghi</div>
        </div>

        {/* Search Box */}
        <div className="position-relative" style={{ minWidth: 250 }}>
          <i className="bi bi-search position-absolute top-50 start-0 translate-middle-y ms-3 text-secondary"></i>
          <input
            className="form-control rounded-pill border-0 bg-light ps-5 py-2"
            placeholder="Tìm kiếm nhanh..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
            style={{ fontSize: '0.95rem' }}
          />
        </div>

        <button
          onClick={() => { setEditing(null); setOpen(true); }}
          className="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
        >
          <i className="bi bi-plus-lg me-1"></i> Thêm mới
        </button>
      </div>

      {/* --- TABLE --- */}
      <div className="table-responsive">
        <table className="table table-hover align-middle mb-0" style={{ borderCollapse: 'separate', borderSpacing: '0' }}>
          <thead className="bg-light">
            <tr>
              <th className="py-3 ps-4 text-secondary fw-bold text-uppercase" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>Thông tin</th>
              {schema.filter(f => f.key !== 'id' && f.key !== 'fullName').map((f) => (
                <th key={f.key} className="py-3 text-secondary fw-bold text-uppercase" style={{ fontSize: '0.75rem', letterSpacing: '0.5px' }}>{f.label}</th>
              ))}
              <th className="py-3 text-secondary fw-bold text-uppercase" style={{ fontSize: '0.75rem' }}>Trạng thái</th>
              <th className="py-3 pe-4 text-end text-secondary fw-bold text-uppercase" style={{ fontSize: '0.75rem' }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr><td colSpan={10} className="text-center py-5 text-muted">Không tìm thấy dữ liệu</td></tr>
            ) : filtered.map((row, idx) => (
              <tr key={row.id || idx}>
                {/* Custom User Info Cell (Avatar + Name + ID) */}
                <td className="ps-4 py-3">
                  <div className="d-flex align-items-center gap-3">
                    <div className="rounded-circle d-flex align-items-center justify-content-center text-white fw-bold shadow-sm"
                      style={{
                        width: 40, height: 40,
                        background: `hsl(${(idx * 50) % 360}, 70%, 60%)`, // Random màu đẹp
                        fontSize: '1rem'
                      }}
                    >
                      {getInitials(row.fullName || row.email)}
                    </div>
                    <div>
                      <div className="fw-bold text-dark">{row.fullName || "No Name"}</div>
                      <div className="text-muted" style={{ fontSize: '0.75rem' }}>ID: {shortId(row.id)}</div>
                    </div>
                  </div>
                </td>

                {/* Các cột khác */}
                {schema.filter(f => f.key !== 'id' && f.key !== 'fullName').map((f) => (
                  <td key={f.key} className="text-dark">
                    {f.key === 'createdAt' ? (
                      <span className="text-muted small">{new Date(row[f.key]).toLocaleDateString('vi-VN')}</span>
                    ) : f.type === "boolean" ? (
                      row[f.key] ? <i className="bi bi-check-circle-fill text-success"></i> : <span className="text-muted">-</span>
                    ) : (
                      <span style={{ fontSize: '0.9rem' }}>{String(row[f.key] ?? "")}</span>
                    )}
                  </td>
                ))}

                {/* Status Badge */}
                <td>
                  <span
                    onClick={() => onToggleStatus?.(row.id, row[statusKey])}
                    className={`badge rounded-pill px-3 py-2 cursor-pointer border ${row[statusKey] === "ACTIVE"
                      ? "bg-success bg-opacity-10 text-success border-success border-opacity-25"
                      : "bg-danger bg-opacity-10 text-danger border-danger border-opacity-25"
                      }`}
                  >
                    {row[statusKey] === "ACTIVE" ? "Hoạt động" : "Đã khóa"}
                  </span>
                </td>

                {/* Actions */}
                <td className="text-end pe-4">
                  <div className="d-flex justify-content-end gap-2">
                    {renderRowActions?.(row)}
                    <button onClick={() => { setEditing(row); setOpen(true); }} className="btn btn-sm btn-light text-primary border rounded-3" title="Sửa">
                      <i className="bi bi-pencil-fill"></i>
                    </button>
                    <button onClick={() => onDelete(row.id)} className="btn btn-sm btn-light text-danger border rounded-3" title="Xóa">
                      <i className="bi bi-trash-fill"></i>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal Form */}
      <Modal open={open} title={editing?.id ? "Cập nhật dữ liệu" : "Thêm dữ liệu mới"} onClose={() => setOpen(false)}>
        <form onSubmit={handleSubmit} className="row g-3">
          {schema.filter(f => !f.hideOnForm).map((f) => (
            <div key={f.key} className="col-12">
              <label className="form-label fw-bold text-secondary small text-uppercase">{f.label}</label>
              {f.type === "textarea" ? (
                <textarea name={f.key} defaultValue={editing?.[f.key] ?? ""} rows={3} className="form-control bg-light" />
              ) : f.type === "select" ? (
                <select name={f.key} defaultValue={editing?.[f.key] ?? f.options?.[0]?.value} className="form-select bg-light">
                  {f.options?.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
              ) : (
                <input name={f.key} type={f.type === "number" ? "number" : "text"} defaultValue={editing?.[f.key] ?? ""} className="form-control bg-light" />
              )}
            </div>
          ))}
          <div className="col-12 text-end mt-4">
            <button type="button" onClick={() => setOpen(false)} className="btn btn-light fw-bold me-2">Hủy bỏ</button>
            <button type="submit" className="btn btn-primary fw-bold px-4">Lưu thay đổi</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}