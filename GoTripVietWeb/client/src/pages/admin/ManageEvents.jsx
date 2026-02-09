import { useEffect, useMemo, useState } from "react";
import eventApi from "../../api/eventApi";
import axiosClient from "../../api/axiosClient";

/* ========== UI helpers (same style as ManagePromotion) ========== */
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
          width: "min(900px, 92vw)",
          maxHeight: "86vh",
          overflowY: "auto",
          overflowX: "hidden",
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
          outline: "none",
          ...props.style,
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
          outline: "none",
          ...props.style,
        }}
      >
        {children}
      </select>
    </label>
  );
}

function Th({ children }) {
  return (
    <th
      style={{
        textAlign: "left",
        padding: "10px",
        fontSize: 12,
        color: "#6b7280",
        borderBottom: "1px solid #e5e7eb",
        whiteSpace: "nowrap",
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
        verticalAlign: "top",
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
  background: "#fff",
  fontWeight: 900,
  cursor: "pointer",
  lineHeight: 1,
};

function normalizeProducts(res) {
  if (Array.isArray(res)) return res;
  if (!res || typeof res !== "object") return [];
  return (
    res.products ||
    res.items ||
    res.data ||
    res.rows ||
    res.results ||
    res.list ||
    []
  );
}

function formatMoney(v) {
  const n = Number(v || 0);
  return n.toLocaleString("vi-VN") + "₫";
}

function mmdd(sm, sd, em, ed) {
  const pad = (x) => String(x ?? "").padStart(2, "0");
  return `${pad(sd)}/${pad(sm)} → ${pad(ed)}/${pad(em)}`;
}

export default function ManageEvents() {
  const [rows, setRows] = useState([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState("");

  // tours list from catalog-service
  const [tours, setTours] = useState([]);
  const [tourQ, setTourQ] = useState("");
  const [selectedTourIds, setSelectedTourIds] = useState(new Set());

  // image upload
  const [uploadingImg, setUploadingImg] = useState(false);
  const [localPreview, setLocalPreview] = useState("");

  // form
  const [form, setForm] = useState({
    name: "",
    description: "",
    image: { url: "", public_id: "" },

    discount_type: "percentage", // percentage | fixed_amount
    discount_value: 1,

    is_yearly: true,
    start_month: 1,
    start_day: 1,
    end_month: 1,
    end_day: 1,

    apply_to_all_tours: true,
    priority: 0,
    is_active: true,
  });

  const load = async () => {
    const res = await eventApi.getAll();
    setRows(Array.isArray(res) ? res : []);
  };

  const loadTours = async () => {
    // catalog-service: GET /products?product_type=tour
    const res = await axiosClient.get("/products", {
      params: { product_type: "tour", page: 1, limit: 500 },
    });
    const list = normalizeProducts(res);
    setTours(Array.isArray(list) ? list : []);
  };

  useEffect(() => {
    load();
    loadTours();
  }, []);

  const filteredTours = useMemo(() => {
    const q = tourQ.trim().toLowerCase();
    if (!q) return tours;
    return tours.filter((t) => {
      const name = String(t.title || t.name || "").toLowerCase();
      const id = String(t._id || t.id || "").toLowerCase();
      return name.includes(q) || id.includes(q);
    });
  }, [tours, tourQ]);

  const resetForm = () => {
    setForm({
      name: "",
      description: "",
      image: { url: "", public_id: "" },

      discount_type: "percentage",
      discount_value: 1,

      is_yearly: true,
      start_month: 1,
      start_day: 1,
      end_month: 1,
      end_day: 1,

      apply_to_all_tours: true,
      priority: 0,
      is_active: true,
    });
    setSelectedTourIds(new Set());
    setTourQ("");
    setError("");
    if (localPreview) URL.revokeObjectURL(localPreview);
    setLocalPreview("");
  };

  const openAdd = () => {
    setEditing(null);
    resetForm();
    setOpen(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      name: row.name || "",
      description: row.description || "",
      image: row.image || { url: "", public_id: "" },

      discount_type: row.discount_type || "percentage",
      discount_value: Number(row.discount_value || 1),

      is_yearly: row.is_yearly ?? true,
      start_month: Number(row.start_month || 1),
      start_day: Number(row.start_day || 1),
      end_month: Number(row.end_month || 1),
      end_day: Number(row.end_day || 1),

      apply_to_all_tours: row.apply_to_all_tours ?? true,
      priority: Number(row.priority || 0),
      is_active: row.is_active ?? true,
    });

    const ids = Array.isArray(row.tour_ids) ? row.tour_ids : [];
    setSelectedTourIds(new Set(ids));
    setTourQ("");
    setError("");

    if (localPreview) URL.revokeObjectURL(localPreview);
    setLocalPreview("");
    setOpen(true);
  };

  const validateForm = () => {
    if (!form.name.trim()) return "Tên event không được rỗng.";

    const v = Number(form.discount_value);
    if (!Number.isFinite(v)) return "Giá trị giảm không hợp lệ.";

    if (form.discount_type === "percentage") {
      if (!(v > 0 && v < 100))
        return "Giảm theo % phải lớn hơn 0 và nhỏ hơn 100.";
    } else {
      if (!(v > 0)) return "Giảm số tiền phải lớn hơn 0.";
      if (v % 1000 !== 0) return "Giảm số tiền phải chia hết cho 1.000.";
    }

    const sm = Number(form.start_month);
    const sd = Number(form.start_day);
    const em = Number(form.end_month);
    const ed = Number(form.end_day);
    if (![sm, sd, em, ed].every(Number.isFinite))
      return "Ngày bắt đầu/kết thúc không hợp lệ.";
    if (sm < 1 || sm > 12 || em < 1 || em > 12)
      return "Tháng phải trong khoảng 1-12.";
    if (sd < 1 || sd > 31 || ed < 1 || ed > 31)
      return "Ngày phải trong khoảng 1-31.";

    if (!form.apply_to_all_tours && selectedTourIds.size === 0) {
      return "Bạn phải chọn ít nhất 1 tour hoặc bật 'Áp dụng cho tất cả tour'.";
    }

    return "";
  };

  const save = async () => {
    const msg = validateForm();
    if (msg) {
      setError(msg);
      alert(msg);
      return;
    }
    setError("");

    const payload = {
      ...form,
      discount_value: Number(form.discount_value),
      start_month: Number(form.start_month),
      start_day: Number(form.start_day),
      end_month: Number(form.end_month),
      end_day: Number(form.end_day),
      priority: Number(form.priority || 0),
      tour_ids: form.apply_to_all_tours ? [] : Array.from(selectedTourIds),
    };

    if (editing?._id) {
      await eventApi.update(editing._id, payload);
    } else {
      await eventApi.create(payload);
    }

    setOpen(false);
    load();
  };

  const remove = async (id) => {
    if (!confirm("Xóa event này?")) return;
    await eventApi.remove(id);
    load();
  };

  const toggleStatus = async (id) => {
    await eventApi.toggleStatus(id);
    load();
  };

  const pickAndUploadImage = async (file) => {
    if (!file) return;
    if (!file.type?.startsWith("image/")) return alert("Chỉ nhận file ảnh.");
    if (file.size > 5 * 1024 * 1024) return alert("Tối đa 5MB.");

    if (localPreview) URL.revokeObjectURL(localPreview);
    setLocalPreview(URL.createObjectURL(file));

    setUploadingImg(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await eventApi.uploadEventImage(fd);
      const url = res?.url;
      const public_id = res?.public_id || "";
      if (!url) throw new Error("Server không trả về liên kết ảnh");

      setForm((s) => ({ ...s, image: { url, public_id } }));
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Upload ảnh thất bại");
    } finally {
      setUploadingImg(false);
    }
  };

  const onDropImage = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    const f = e.dataTransfer?.files?.[0];
    await pickAndUploadImage(f);
  };

  const selectAllVisibleTours = () => {
    const next = new Set(selectedTourIds);
    filteredTours.forEach((t) => next.add(String(t._id || t.id)));
    setSelectedTourIds(next);
  };

  const clearAllVisibleTours = () => {
    const next = new Set(selectedTourIds);
    filteredTours.forEach((t) => next.delete(String(t._id || t.id)));
    setSelectedTourIds(next);
  };

  const months = Array.from({ length: 12 }, (_, i) => i + 1);
  const days = Array.from({ length: 31 }, (_, i) => i + 1);

  return (
    <div style={{ display: "grid", gap: 14 }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "end", gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 900, fontSize: 22 }}>Quản lý sự kiện</div>
          <div style={{ color: "#6b7280" }}>
            Tạo event hằng năm và áp giảm giá vào tour (qua danh sách tour từ
            catalog-service).
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
            cursor: "pointer",
          }}
        >
          + Tạo event
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
          Danh sách Events
        </div>

        <div style={{ overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "separate" }}>
            <thead>
              <tr>
                <Th>#</Th>
                <Th>Ảnh</Th>
                <Th>Tên</Th>
                <Th>Thời gian</Th>
                <Th>Giảm giá</Th>
                <Th>Áp dụng</Th>
                <Th>Trạng thái</Th>
                <Th>Ngày tạo</Th>
                <Th>Thao tác</Th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, idx) => {
                const active = !!r.is_active;
                return (
                  <tr key={r._id}>
                    <Td>{idx + 1}</Td>
                    <Td>
                      {r.image?.url ? (
                        <img
                          src={r.image.url}
                          alt="event"
                          style={{
                            width: 56,
                            height: 40,
                            objectFit: "cover",
                            borderRadius: 10,
                            border: "1px solid #e5e7eb",
                          }}
                        />
                      ) : (
                        <span style={{ color: "#9ca3af" }}>—</span>
                      )}
                    </Td>
                    <Td style={{ fontWeight: 900 }}>{r.name}</Td>
                    <Td>
                      {mmdd(r.start_month, r.start_day, r.end_month, r.end_day)}
                    </Td>
                    <Td>
                      {r.discount_type === "percentage" ? (
                        <>
                          Giảm <b>{Number(r.discount_value || 0)}</b>%
                        </>
                      ) : (
                        <>
                          Giảm <b>{formatMoney(r.discount_value)}</b>
                        </>
                      )}
                    </Td>
                    <Td>
                      {r.apply_to_all_tours ? (
                        <span>Toàn bộ tour</span>
                      ) : (
                        <span>
                          Đã chọn{" "}
                          <b>
                            {Array.isArray(r.tour_ids) ? r.tour_ids.length : 0}
                          </b>{" "}
                          tour
                        </span>
                      )}
                    </Td>
                    <Td>
                      <span
                        style={{
                          padding: "4px 8px",
                          borderRadius: 999,
                          fontWeight: 900,
                          background: active
                            ? "rgba(16,185,129,0.15)"
                            : "rgba(239,68,68,0.15)",
                        }}
                      >
                        {active ? "Đang hoạt động" : "Ngưng hoạt động"}
                      </span>
                    </Td>
                    <Td>
                      {r.createdAt
                        ? new Date(r.createdAt).toLocaleDateString("vi-VN")
                        : "—"}
                    </Td>
                    <Td>
                      <div
                        style={{ display: "flex", gap: 8, flexWrap: "wrap" }}
                      >
                        {/* Toggle icon */}
                        <button
                          onClick={() => toggleStatus(r._id)}
                          title={active ? "Dừng lại" : "Hoạt động"}
                          style={{
                            ...iconBtn,
                            background: active
                              ? "rgba(239,68,68,0.12)"
                              : "rgba(34,197,94,0.12)",
                            borderColor: active
                              ? "rgba(239,68,68,0.35)"
                              : "rgba(34,197,94,0.35)",
                            color: active ? "#ef4444" : "#16a34a",
                          }}
                        >
                          {active ? "⛔" : "✅"}
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
                );
              })}

              {rows.length === 0 && (
                <tr>
                  <Td colSpan={9}>Chưa có event</Td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal create/edit */}
      <Modal
        open={open}
        title={editing ? "Sửa event" : "Tạo event"}
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
              label="Tên event"
              value={form.name}
              onChange={(e) => setForm((s) => ({ ...s, name: e.target.value }))}
              placeholder="Ví dụ: Ưu đãi hè 2026"
              style={{ gridColumn: "1 / -1" }}
            />

            <Input
              label="Mô tả"
              value={form.description}
              onChange={(e) =>
                setForm((s) => ({ ...s, description: e.target.value }))
              }
              placeholder="Mô tả ngắn..."
              style={{ gridColumn: "1 / -1" }}
            />

            <Select
              label="Loại giảm"
              value={form.discount_type}
              onChange={(e) => {
                const nextType = e.target.value;
                setForm((s) => ({
                  ...s,
                  discount_type: nextType,
                  discount_value: nextType === "percentage" ? 1 : 1000,
                }));
              }}
            >
              <option value="percentage">Giảm theo %</option>
              <option value="fixed_amount">Giảm số tiền</option>
            </Select>

            <Input
              label={
                form.discount_type === "percentage"
                  ? "Giá trị (%)"
                  : "Giá trị (VND)"
              }
              type="number"
              min={form.discount_type === "percentage" ? 1 : 1000}
              max={form.discount_type === "percentage" ? 99 : undefined}
              step={form.discount_type === "percentage" ? 1 : 1000}
              value={form.discount_value}
              onChange={(e) => {
                const raw = Number(e.target.value);
                if (form.discount_type === "fixed_amount") {
                  const normalized = Math.floor(raw / 1000) * 1000;
                  setForm((s) => ({ ...s, discount_value: normalized }));
                  return;
                }
                setForm((s) => ({ ...s, discount_value: raw }));
              }}
            />

            <Input
              label="Độ ưu tiên"
              type="number"
              value={form.priority}
              onChange={(e) =>
                setForm((s) => ({ ...s, priority: e.target.value }))
              }
            />

            <Select
              label="Trạng thái"
              value={form.is_active ? "true" : "false"}
              onChange={(e) =>
                setForm((s) => ({ ...s, is_active: e.target.value === "true" }))
              }
            >
              <option value="true">Đang hoạt động</option>
              <option value="false">Ngưng hoạt động</option>
            </Select>

            {/* yearly range */}
            <Select
              label="Tháng bắt đầu"
              value={form.start_month}
              onChange={(e) =>
                setForm((s) => ({ ...s, start_month: Number(e.target.value) }))
              }
            >
              {months.map((m) => (
                <option key={m} value={m}>
                  Tháng {m}
                </option>
              ))}
            </Select>

            <Select
              label="Ngày bắt đầu"
              value={form.start_day}
              onChange={(e) =>
                setForm((s) => ({ ...s, start_day: Number(e.target.value) }))
              }
            >
              {days.map((d) => (
                <option key={d} value={d}>
                  Ngày {d}
                </option>
              ))}
            </Select>

            <Select
              label="Tháng kết thúc"
              value={form.end_month}
              onChange={(e) =>
                setForm((s) => ({ ...s, end_month: Number(e.target.value) }))
              }
            >
              {months.map((m) => (
                <option key={m} value={m}>
                  Tháng {m}
                </option>
              ))}
            </Select>

            <Select
              label="Ngày kết thúc"
              value={form.end_day}
              onChange={(e) =>
                setForm((s) => ({ ...s, end_day: Number(e.target.value) }))
              }
            >
              {days.map((d) => (
                <option key={d} value={d}>
                  Ngày {d}
                </option>
              ))}
            </Select>

            {/* image uploader */}
            <div
              style={{
                gridColumn: "1 / -1",
                border: "1px dashed #e5e7eb",
                borderRadius: 14,
                padding: 12,
                background: "#fff",
              }}
              onDragOver={(e) => e.preventDefault()}
              onDrop={onDropImage}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 900 }}>Ảnh event</div>
                  <div style={{ color: "#6b7280", fontSize: 12, marginTop: 4 }}>
                    Kéo-thả ảnh vào đây hoặc bấm “Chọn ảnh” (tối đa 5MB).
                  </div>
                </div>

                <label
                  style={{
                    ...btn,
                    padding: "8px 10px",
                    background: uploadingImg ? "#f3f4f6" : "#fff",
                    cursor: uploadingImg ? "not-allowed" : "pointer",
                  }}
                >
                  {uploadingImg ? "Đang tải..." : "Chọn ảnh"}
                  <input
                    type="file"
                    accept="image/*"
                    disabled={uploadingImg}
                    style={{ display: "none" }}
                    onChange={(e) => pickAndUploadImage(e.target.files?.[0])}
                  />
                </label>
              </div>

              <div
                style={{
                  marginTop: 10,
                  display: "flex",
                  gap: 12,
                  flexWrap: "wrap",
                }}
              >
                {form.image?.url || localPreview ? (
                  <div
                    style={{ display: "flex", gap: 10, alignItems: "center" }}
                  >
                    <img
                      src={localPreview || form.image.url}
                      alt="preview"
                      style={{
                        width: 140,
                        height: 90,
                        objectFit: "cover",
                        borderRadius: 12,
                        border: "1px solid #e5e7eb",
                      }}
                    />
                    <button
                      type="button"
                      onClick={() =>
                        setForm((s) => ({
                          ...s,
                          image: { url: "", public_id: "" },
                        }))
                      }
                      style={{ ...btn, borderColor: "#fecaca" }}
                    >
                      Gỡ ảnh
                    </button>
                  </div>
                ) : (
                  <div style={{ color: "#9ca3af" }}>Chưa có ảnh</div>
                )}
              </div>
            </div>

            {/* apply to tours */}
            <div style={{ gridColumn: "1 / -1" }}>
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={form.apply_to_all_tours}
                  onChange={(e) => {
                    const checked = e.target.checked;
                    setForm((s) => ({ ...s, apply_to_all_tours: checked }));
                    if (checked) setSelectedTourIds(new Set());
                  }}
                  style={{ width: 18, height: 18 }}
                />
                <span style={{ fontWeight: 900 }}>Áp dụng cho tất cả tour</span>
              </label>

              {!form.apply_to_all_tours && (
                <div
                  style={{
                    marginTop: 10,
                    border: "1px solid #e5e7eb",
                    borderRadius: 14,
                    padding: 12,
                  }}
                >
                  <div
                    style={{ display: "flex", alignItems: "center", gap: 10 }}
                  >
                    <div style={{ fontWeight: 900, flex: 1 }}>
                      Chọn tour (đã chọn: {selectedTourIds.size})
                    </div>
                    <button
                      type="button"
                      onClick={selectAllVisibleTours}
                      style={btn}
                    >
                      Chọn tất cả (đang hiển thị)
                    </button>
                    <button
                      type="button"
                      onClick={clearAllVisibleTours}
                      style={{ ...btn, borderColor: "#fecaca" }}
                    >
                      Bỏ chọn (đang hiển thị)
                    </button>
                  </div>

                  <div style={{ marginTop: 10 }}>
                    <Input
                      label="Tìm tour theo tên hoặc ID"
                      value={tourQ}
                      onChange={(e) => setTourQ(e.target.value)}
                      placeholder="Ví dụ: Đà Lạt / Phú Quốc / 6957..."
                    />
                  </div>

                  <div
                    style={{
                      marginTop: 10,
                      maxHeight: 260,
                      overflow: "auto",
                      border: "1px solid #e5e7eb",
                      borderRadius: 12,
                    }}
                  >
                    {filteredTours.map((t) => {
                      const id = String(t._id || t.id);
                      const checked = selectedTourIds.has(id);
                      const title = t.title || t.name || id;
                      const price =
                        t.price ??
                        t.basePrice ??
                        t.minPrice ??
                        t.price_from ??
                        null;

                      return (
                        <label
                          key={id}
                          style={{
                            display: "flex",
                            alignItems: "start",
                            gap: 10,
                            padding: "10px 12px",
                            borderBottom: "1px solid #f1f5f9",
                            cursor: "pointer",
                          }}
                        >
                          <input
                            type="checkbox"
                            checked={checked}
                            onChange={() => {
                              const next = new Set(selectedTourIds);
                              if (next.has(id)) next.delete(id);
                              else next.add(id);
                              setSelectedTourIds(next);
                            }}
                            style={{ width: 18, height: 18, marginTop: 2 }}
                          />
                          <div style={{ flex: 1 }}>
                            <div style={{ fontWeight: 900, fontSize: 13 }}>
                              {title}
                            </div>
                            <div style={{ color: "#6b7280", fontSize: 11 }}>
                              ID: {id}
                              {price != null
                                ? ` • Giá: ${formatMoney(price)}`
                                : ""}
                            </div>
                          </div>
                        </label>
                      );
                    })}

                    {filteredTours.length === 0 && (
                      <div style={{ padding: 12, color: "#6b7280" }}>
                        Không có tour phù hợp
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* footer buttons */}
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
              disabled={uploadingImg}
              title={uploadingImg ? "Đang upload ảnh, vui lòng chờ" : ""}
            >
              Lưu
            </button>
          </div>

          {error && (
            <div
              style={{
                background: "rgba(239,68,68,0.12)",
                border: "1px solid rgba(239,68,68,0.25)",
                padding: "10px 12px",
                borderRadius: 12,
                fontWeight: 800,
                marginTop: 10,
              }}
            >
              {error}
            </div>
          )}
        </div>
      </Modal>
    </div>
  );
}
