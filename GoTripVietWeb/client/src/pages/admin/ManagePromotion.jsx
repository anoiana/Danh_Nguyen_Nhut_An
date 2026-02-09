import { useEffect, useState } from "react";
import promotionApi from "../../api/promotionApi";

/* ========== UI helpers (copy style từ ManageEvents) ========== */

function Modal({ open, title, children, onClose }) {
  if (!open) return null;
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.35)",
        display: "grid",
        placeItems: "start center",
        padding: "14px 0",
        zIndex: 80,
      }}
      onMouseDown={onClose}
    >
      <div
        style={{
          width: "min(700px, 92vw)",
          maxHeight: "86vh",
          overflowY: "auto",
          background: "#fff",
          borderRadius: 14,
          padding: 14,
          boxShadow: "0 10px 30px rgba(0,0,0,0.18)",
        }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ fontWeight: 900, fontSize: 16, flex: 1 }}>{title}</div>
          <button
            onClick={onClose}
            style={{ border: 0, background: "transparent", fontSize: 18 }}
          >
            ✕
          </button>
        </div>
        <div style={{ height: 1, background: "#e5e7eb", margin: "10px 0" }} />
        {children}
      </div>
    </div>
  );
}

function Input({ label, ...props }) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 5 }}>
      <span style={{ fontWeight: 800, fontSize: 12 }}>{label}</span>
      <input
        {...props}
        style={{
          borderRadius: 10,
          border: "1px solid #e5e7eb",
          padding: "8px 10px",
          fontSize: 13,
        }}
      />
    </label>
  );
}

function Select({ label, children, ...props }) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 6 }}>
      <span style={{ fontWeight: 800, fontSize: 12 }}>{label}</span>
      <select
        {...props}
        style={{
          borderRadius: 10,
          fontSize: 13,
          border: "1px solid #e5e7eb",
          padding: "8px 10px",
          background: "#fff",
        }}
      >
        {children}
      </select>
    </label>
  );
}

/* =================== MAIN =================== */

export default function ManagePromotion() {
  const [rows, setRows] = useState([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    code: "",
    type: "percentage",
    value: 0,
    description: "",
    total_quantity: 1,
    is_active: true,
  });
  const [error, setError] = useState("");

  const load = async () => {
    const res = await promotionApi.getAll();
    setRows(res);
  };

  useEffect(() => {
    load();
  }, []);

  const validateForm = () => {
    if (!form.code.trim()) return "Mã không được rỗng";

    if (form.type === "percentage") {
      if (!(form.value > 0 && form.value < 100)) {
        return "Giá trị giảm theo % phải lớn hơn 0 và nhỏ hơn 100";
      }
    }

    if (form.type === "fixed_amount") {
      if (!(form.value > 0)) return "Giá trị giảm số tiền phải lớn hơn 0";
      if (form.value % 1000 !== 0)
        return "Giá trị giảm số tiền phải chia hết cho 1.000";
    }

    if (!(form.total_quantity >= 1)) return "Số lượng voucher phải >= 1";

    return "";
  };

  const toggleStatus = async (id) => {
    await promotionApi.toggleStatus(id);
    load();
  };

  const openAdd = () => {
    setEditing(null);
    setForm({
      code: "",
      type: "percentage",
      value: 0,
      description: "",
      total_quantity: 1,
      is_active: true,
    });
    setOpen(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      code: row.code,
      type: row.type,
      value: row.value,
      description: row.description || "",
      total_quantity: row.total_quantity ?? 1,
      is_active: row.is_active,
    });
    setOpen(true);
  };

  const save = async () => {
    const msg = validateForm();
    if (msg) {
      setError(msg);
      alert(msg);
      return;
    }
    setError("");

    if (editing?._id) {
      await promotionApi.update(editing._id, form);
    } else {
      await promotionApi.create(form);
    }

    setOpen(false);
    load();
  };

  const remove = async (id) => {
    if (!confirm("Xóa promotion này?")) return;
    await promotionApi.remove(id);
    load();
  };

  return (
    <div style={{ display: "grid", gap: 14 }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "end", gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 900, fontSize: 22 }}>
            Quản lý khuyến mãi
          </div>
        </div>

        <button
          onClick={openAdd}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: 0,
            background: "#0b5fff",
            color: "#fff",
            fontWeight: 900,
          }}
        >
          + Tạo promotion
        </button>
      </div>

      {/* Table */}
      <div
        style={{
          background: "#fff",
          border: "1px solid #e5e7eb",
          borderRadius: 16,
          padding: 14,
        }}
      >
        <div style={{ fontWeight: 900, fontSize: 16, marginBottom: 10 }}>
          Danh sách Promotions
        </div>

        <div style={{ overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "separate" }}>
            <thead>
              <tr>
                <Th>#</Th>
                <Th>Mã</Th>
                <Th>Loại</Th>
                <Th>Giá trị</Th>
                <Th>Trạng thái</Th>
                <Th>Ngày tạo</Th>
                <Th>Số lượt</Th>
                <Th>Thao tác</Th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, idx) => (
                <tr key={r._id}>
                  <Td>{idx + 1}</Td>
                  <Td style={{ fontWeight: 900 }}>{r.code}</Td>
                  <Td>{r.type}</Td>
                  <Td>
                    {r.value}
                    {r.type === "percentage" ? " %" : " VND"}
                  </Td>
                  <Td>
                    <span
                      style={{
                        padding: "4px 8px",
                        borderRadius: 999,
                        fontWeight: 900,
                        background: r.is_active
                          ? "rgba(16,185,129,0.15)"
                          : "rgba(239,68,68,0.15)",
                      }}
                    >
                      {r.is_active ? "Đang hoạt động" : "Ngưng hoạt động"}
                    </span>
                  </Td>
                  <Td>{new Date(r.createdAt).toLocaleDateString("vi-VN")}</Td>
                  <Td>
                    {r.used_quantity ?? 0} / {r.total_quantity ?? 0}
                  </Td>
                  <Td>
                    <div style={{ display: "flex", gap: 8 }}>
                      <button
                        onClick={() => toggleStatus(r._id)}
                        title={r.is_active ? "Dừng lại" : "Hoạt động"}
                        style={{
                          ...iconBtn,
                          background: r.is_active
                            ? "rgba(239,68,68,0.12)"
                            : "rgba(34,197,94,0.12)",
                          borderColor: r.is_active
                            ? "rgba(239,68,68,0.35)"
                            : "rgba(34,197,94,0.35)",
                          color: r.is_active ? "#ef4444" : "#16a34a",
                        }}
                      >
                        {r.is_active ? "⛔" : "✅"}
                      </button>
                      <button onClick={() => openEdit(r)} style={btn}>
                        Sửa
                      </button>
                      <button
                        onClick={() => remove(r._id)}
                        style={{ ...btn, borderColor: "#fecaca" }}
                      >
                        Xóa
                      </button>
                    </div>
                  </Td>
                </tr>
              ))}

              {rows.length === 0 && (
                <tr>
                  <Td colSpan={8}>Chưa có promotion</Td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      <Modal
        open={open}
        title={editing ? "Sửa promotion" : "Tạo promotion"}
        onClose={() => setOpen(false)}
      >
        <div style={{ display: "grid", gap: 12 }}>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
              gap: 12,
            }}
          >
            <Input
              label="Mã"
              value={form.code}
              disabled={Boolean(editing)}
              onChange={(e) => setForm((s) => ({ ...s, code: e.target.value }))}
            />

            <Select
              label="Loại"
              value={form.type}
              onChange={(e) => {
                const nextType = e.target.value;
                setForm((s) => ({
                  ...s,
                  type: nextType,
                  value: nextType === "percentage" ? 1 : 1000, // reset hợp lệ
                }));
              }}
            >
              <option value="percentage">Giảm theo (%)</option>
              <option value="fixed_amount">Giảm số tiền</option>
            </Select>

            <Input
              label="Số lượng voucher"
              type="number"
              min={1}
              value={form.total_quantity}
              onChange={(e) =>
                setForm((s) => ({
                  ...s,
                  total_quantity: Number(e.target.value),
                }))
              }
            />

            <Input
              label={
                form.type === "percentage" ? "Giá trị (%)" : "Giá trị (VND)"
              }
              type="number"
              min={form.type === "percentage" ? 1 : 1000}
              max={form.type === "percentage" ? 99 : undefined}
              step={form.type === "percentage" ? 1 : 1000}
              value={form.value}
              onChange={(e) => {
                const raw = Number(e.target.value);

                // Nếu giảm số tiền, auto làm tròn xuống bội số 1000 để UX tốt hơn
                if (form.type === "fixed_amount") {
                  const normalized = Math.floor(raw / 1000) * 1000;
                  setForm((s) => ({ ...s, value: normalized }));
                  return;
                }

                setForm((s) => ({ ...s, value: raw }));
              }}
            />

            <Input
              label="Mô tả"
              value={form.description}
              onChange={(e) =>
                setForm((s) => ({ ...s, description: e.target.value }))
              }
              style={{ gridColumn: "1 / -1" }}
            />

            <Select
              label="Trạng thái"
              value={form.is_active ? "true" : "false"}
              onChange={(e) =>
                setForm((s) => ({
                  ...s,
                  is_active: e.target.value === "true",
                }))
              }
            >
              <option value="true">Đang hoạt động</option>
              <option value="false">Không hoạt động</option>
            </Select>
          </div>

          <div style={{ display: "flex", justifyContent: "flex-end", gap: 10 }}>
            <button onClick={() => setOpen(false)} style={btn}>
              Hủy
            </button>
            <button
              onClick={save}
              style={{
                ...btn,
                background: "#0b5fff",
                color: "#fff",
                border: 0,
              }}
            >
              Lưu
            </button>
          </div>
        </div>
        <br></br>
        {error && (
          <div
            style={{
              background: "rgba(239,68,68,0.12)",
              border: "1px solid rgba(239,68,68,0.25)",
              padding: "10px 12px",
              borderRadius: 12,
              fontWeight: 800,
            }}
          >
            {error}
          </div>
        )}
      </Modal>
    </div>
  );
}

/* ========== table helpers ========== */

function Th({ children }) {
  return (
    <th
      style={{
        textAlign: "left",
        padding: "10px",
        fontSize: 12,
        color: "#6b7280",
        borderBottom: "1px solid #e5e7eb",
      }}
    >
      {children}
    </th>
  );
}

function Td({ children, colSpan, style }) {
  return (
    <td
      colSpan={colSpan}
      style={{
        padding: "10px",
        borderBottom: "1px solid #f1f5f9",
        fontSize: 13,
        ...style,
      }}
    >
      {children}
    </td>
  );
}

const btn = {
  borderRadius: 12,
  border: "1px solid #e5e7eb",
  padding: "8px 12px",
  background: "#fff",
  fontWeight: 900,
  cursor: "pointer",
};

const iconBtn = {
  borderRadius: 12,
  border: "1px solid #e5e7eb",
  padding: "8px 10px",
  fontWeight: 900,
  cursor: "pointer",
};
