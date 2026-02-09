import React, { useEffect, useMemo, useState } from "react";
import locationApi from "../../api/locationApi";
import "../../styles/admin/ManageLocation.css";

// --- HELPERS ---

function normalizeList(res) {
  const a = res?.data ?? res;
  const b = a?.data ?? a;
  if (Array.isArray(b)) return b;
  if (Array.isArray(b?.items)) return b.items;
  if (Array.isArray(b?.locations)) return b.locations;
  if (Array.isArray(b?.results)) return b.results;
  return [];
}

function toRow(x) {
  const coords = x?.coordinates?.coordinates || [0, 0];
  const lng = coords?.[0] ?? 0;
  const lat = coords?.[1] ?? 0;

  const imagesRaw = Array.isArray(x?.images) ? x.images : [];
  const images = imagesRaw
    .map((img) => (typeof img === "string" ? { url: img, public_id: "" } : img))
    .filter((img) => img?.url);

  const tags = Array.isArray(x?.tags) ? x.tags : [];

  return {
    ...x,
    id: x?.id || x?._id,
    images,
    tags,
    tags_csv: tags.join(", "),
    lng,
    lat,
    status: x?.status || "active",
    created_by: x?.created_by,
  };
}

function toPayload(form) {
  const tags =
    typeof form?.tags_csv === "string"
      ? form.tags_csv
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean)
      : [];

  const lng = Number(form?.lng ?? 0);
  const lat = Number(form?.lat ?? 0);

  if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
    throw new Error("Tọa độ không hợp lệ.");
  }
  if (lng < -180 || lng > 180) {
    throw new Error("Kinh độ phải nằm trong khoảng -180 đến 180.");
  }
  if (lat < -90 || lat > 90) {
    throw new Error("Vĩ độ phải nằm trong khoảng -90 đến 90.");
  }

  return {
    name: form?.name?.trim(),
    country: form?.country?.trim() || "",
    description: form?.description || "",
    images: Array.isArray(form.images) ? form.images : [],
    tags,
    coordinates: { type: "Point", coordinates: [lng, lat] },
    status: form.status,
  };
}

// --- MODAL COMPONENT ---
function Modal({ open, title, onClose, children }) {
  if (!open) return null;
  return (
    <div
      className="loc-overlay"
      onMouseDown={onClose}
    >
      <div
        className="loc-modal"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="loc-modal-header">
          <div className="loc-modal-title">{title}</div>
          <button className="loc-btn loc-btn-default" style={{ padding: '4px 8px' }} onClick={onClose} type="button">
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

// --- MAIN COMPONENT ---

export default function ManageLocation() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  // Pagination State
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [limit] = useState(10);

  const [editOpen, setEditOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const [form, setForm] = useState({
    name: "",
    country: "",
    description: "",
    tags_csv: "",
    images: [],
    lng: 0,
    lat: 0,
    status: "active",
  });

  const [uploadingImg, setUploadingImg] = useState(false);
  const [localPreview, setLocalPreview] = useState("");

  useEffect(() => {
    return () => {
      if (localPreview) URL.revokeObjectURL(localPreview);
    };
  }, [localPreview]);

  const load = async () => {
    setLoading(true);
    try {
      // 1. Call API with page/limit params
      const res = await locationApi.getManage();

      // 2. Normalize raw data
      let list = normalizeList(res).map(toRow);

      // 3. Check for Server-side vs Client-side pagination
      const isServerPaginated = res.totalPages !== undefined;

      if (isServerPaginated) {
        setTotalPages(res.totalPages);
        // Server already sliced the data
      } else {
        // --- CLIENT-SIDE SLICING LOGIC ---
        // If server returned ALL items, we calculate pages and slice here
        const totalItems = list.length;
        setTotalPages(Math.ceil(totalItems / limit) || 1);

        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;

        list = list.slice(startIndex, endIndex);
      }

      // Sort: Pending items on top
      list.sort((a, b) => {
        if (a.status === "pending" && b.status !== "pending") return -1;
        if (a.status !== "pending" && b.status === "pending") return 1;
        return 0;
      });

      setRows(list);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [page]);

  const openCreate = () => {
    setEditing(null);
    setForm({
      name: "",
      country: "",
      description: "",
      tags_csv: "",
      images: [],
      lng: 0,
      lat: 0,
      status: "active",
    });
    setLocalPreview("");
    setEditOpen(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      name: row?.name || "",
      country: row?.country || "",
      description: row?.description || "",
      tags_csv: row?.tags_csv || "",
      images: Array.isArray(row?.images) ? row.images : [],
      lng: row?.lng ?? 0,
      lat: row?.lat ?? 0,
      status: row?.status || "active",
    });
    setLocalPreview("");
    setEditOpen(true);
  };

  const save = async () => {
    if (!form.name.trim()) return alert("Vui lòng nhập tên địa điểm.");

    try {
      const payload = toPayload(form);
      if (!editing) await locationApi.create(payload);
      else await locationApi.update(editing.id, payload);

      setEditOpen(false);
      await load();
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Lưu địa điểm thất bại");
    }
  };

  const approve = async (row) => {
    if (!confirm(`Duyệt địa điểm "${row.name}"?`)) return;
    try {
      await locationApi.update(row.id, { status: 'active' });
      await load();
    } catch (e) {
      alert("Lỗi duyệt: " + e.message);
    }
  };

  const remove = async (id) => {
    if (!confirm("Xóa địa điểm này?")) return;
    try {
      await locationApi.remove(id);
      await load();
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Xóa địa điểm thất bại");
    }
  };

  const pickAndUploadOne = async (file) => {
    if (!file) return;
    if (!file.type?.startsWith("image/")) return alert("Chỉ nhận file ảnh.");

    if (localPreview) URL.revokeObjectURL(localPreview);
    setLocalPreview(URL.createObjectURL(file));

    setUploadingImg(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await locationApi.uploadLocationImage(fd);
      const url = res?.url;
      const public_id = res?.public_id || "";
      if (!url) throw new Error("Server không trả về liên kết ảnh");
      setForm((s) => ({
        ...s,
        images: [...(s.images || []), { url, public_id }],
      }));
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Upload ảnh thất bại");
    } finally {
      setUploadingImg(false);
    }
  };

  const pickAndUploadMany = async (files) => {
    const list = Array.from(files || []).filter(Boolean);
    for (const f of list) {
      await pickAndUploadOne(f);
    }
  };

  const onDropImage = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    await pickAndUploadMany(e.dataTransfer.files);
  };

  return (
    <div className="loc-page">
      <div className="loc-header">
        <div>
          <h1 className="loc-title">Quản lý địa điểm</h1>
          <div className="loc-subtitle">
            Duyệt các địa điểm Pending từ Partner và quản lý dữ liệu gốc.
          </div>
        </div>

        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={load} className="loc-btn loc-btn-default" disabled={loading}>
            {loading ? "Đang tải..." : "↻ Tải lại"}
          </button>
          <button onClick={openCreate} className="loc-btn loc-btn-primary">
            + Thêm mới
          </button>
        </div>
      </div>

      <div className="loc-table-card">
        <table className="loc-table">
          <thead>
            <tr>
              <th className="loc-th">Địa điểm / Trạng thái</th>
              <th className="loc-th">Slug</th>
              <th className="loc-th">Quốc gia</th>
              <th className="loc-th">Ảnh</th>
              <th className="loc-th">Tọa độ</th>
              <th className="loc-th" style={{ textAlign: 'right' }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>Đang tải dữ liệu...</td></tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>
                  Chưa có địa điểm nào.
                </td>
              </tr>
            ) : (
              rows.map((x) => {
                const isPending = x.status === 'pending';
                return (
                  <tr key={x.id || x._id} className={`loc-tr ${isPending ? 'loc-tr-pending' : ''}`}>
                    <td className="loc-td">
                      <div style={{ fontWeight: 700, color: '#1e293b' }}>{x.name}</div>
                      {isPending && <span className="loc-badge loc-badge-pending">⏳ Chờ duyệt</span>}
                      {x.created_by && isPending && <div style={{ fontSize: 11, color: '#666', marginTop: 4 }}>Từ Partner</div>}
                    </td>
                    <td className="loc-td">
                      {x.slug ? (
                        <code className="loc-slug">{x.slug}</code>
                      ) : (
                        <span style={{ color: '#94a3b8' }}>—</span>
                      )}
                    </td>
                    <td className="loc-td">
                      {x.country || <span style={{ color: '#94a3b8' }}>—</span>}
                    </td>
                    <td className="loc-td">
                      {Array.isArray(x.images) && x.images.length ? (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <img
                            src={x.images[0].url}
                            alt="thumb"
                            style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover', border: '1px solid #e2e8f0' }}
                          />
                          <span style={{ fontSize: 12, color: '#64748b', fontWeight: 600 }}>+{x.images.length}</span>
                        </div>
                      ) : (
                        <span style={{ color: '#94a3b8' }}>—</span>
                      )}
                    </td>
                    <td className="loc-td">
                      <div style={{ fontFamily: 'monospace', fontSize: 12, color: '#64748b' }}>
                        <div>{Number(x.lng).toFixed(4)},</div>
                        <div>{Number(x.lat).toFixed(4)}</div>
                      </div>
                    </td>
                    <td className="loc-td" style={{ textAlign: "right", whiteSpace: "nowrap" }}>
                      {isPending && (
                        <button className="loc-btn loc-btn-success" onClick={() => approve(x)} style={{ marginRight: 6 }}>
                          ✓ Duyệt
                        </button>
                      )}

                      <button className="loc-btn loc-btn-default" onClick={() => openEdit(x)} style={{ marginRight: 6 }}>
                        Sửa
                      </button>
                      <button className="loc-btn loc-btn-danger" onClick={() => remove(x.id)}>
                        Xóa
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>

        {/* PAGINATION CONTROLS */}
        {!loading && (rows.length > 0 || totalPages > 1) && (
          <div className="loc-pagination">
            <span className="loc-page-info">
              Trang {page} / {totalPages}
            </span>
            <button
              className="loc-page-btn"
              disabled={page <= 1}
              onClick={() => setPage(p => p - 1)}
            >
              &lt;
            </button>

            {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
              let pNum = i + 1;
              if (totalPages > 5) {
                if (page > 3) pNum = page - 2 + i;
                if (pNum > totalPages) pNum = totalPages - 4 + i;
              }
              if (pNum > totalPages || pNum < 1) return null;

              return (
                <button
                  key={pNum}
                  className={`loc-page-btn ${page === pNum ? 'active' : ''}`}
                  onClick={() => setPage(pNum)}
                >
                  {pNum}
                </button>
              )
            })}

            <button
              className="loc-page-btn"
              disabled={page >= totalPages}
              onClick={() => setPage(p => p + 1)}
            >
              &gt;
            </button>
          </div>
        )}
      </div>

      <Modal
        open={editOpen}
        title={editing ? "Chỉnh sửa địa điểm" : "Thêm địa điểm mới"}
        onClose={() => setEditOpen(false)}
      >
        <div className="loc-modal-body">
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            <div className="loc-form-group">
              <label className="loc-label">Tên địa điểm</label>
              <input
                className="loc-input"
                value={form.name}
                onChange={(e) => setForm((s) => ({ ...s, name: e.target.value }))}
                placeholder="Ví dụ: Đà Lạt..."
              />
            </div>
            <div className="loc-form-group">
              <label className="loc-label">Trạng thái</label>
              <select
                className="loc-select"
                value={form.status}
                onChange={(e) => setForm(s => ({ ...s, status: e.target.value }))}
              >
                <option value="active">Active (Hoạt động)</option>
                <option value="pending">Pending (Chờ duyệt)</option>
                <option value="rejected">Rejected (Từ chối)</option>
              </select>
            </div>
          </div>

          <div className="loc-form-group">
            <label className="loc-label">Quốc gia</label>
            <input
              className="loc-input"
              value={form.country}
              onChange={(e) =>
                setForm((s) => ({ ...s, country: e.target.value }))
              }
              placeholder="Ví dụ: Việt Nam"
            />
          </div>

          <div className="loc-form-group">
            <label className="loc-label">Mô tả ngắn</label>
            <textarea
              className="loc-textarea"
              value={form.description}
              onChange={(e) =>
                setForm((s) => ({ ...s, description: e.target.value }))
              }
              placeholder="Nhập mô tả về địa điểm này..."
            />
          </div>

          <div className="loc-form-group">
            <label className="loc-label">Thẻ (Tags)</label>
            <input
              className="loc-input"
              value={form.tags_csv}
              onChange={(e) =>
                setForm((s) => ({ ...s, tags_csv: e.target.value }))
              }
              placeholder="Ví dụ: biển, nghỉ dưỡng, check-in"
            />
            <small style={{ color: '#64748b', fontSize: 12 }}>Nhập nhiều thẻ, ngăn cách bằng dấu phẩy.</small>
          </div>

          <div className="loc-form-group">
            <label className="loc-label">Hình ảnh</label>
            <div
              className="loc-upload-area"
              onDragOver={(e) => e.preventDefault()}
              onDrop={onDropImage}
            >
              <div style={{ fontSize: 14, color: '#64748b', marginBottom: 12 }}>
                Kéo & thả ảnh vào đây, hoặc bấm nút dưới
              </div>

              <label className="loc-btn loc-btn-primary">
                {uploadingImg ? "Đang tải ảnh lên..." : "⬆ Chọn ảnh từ máy"}
                <input
                  type="file"
                  accept="image/*"
                  hidden
                  multiple
                  onChange={(e) => pickAndUploadMany(e.target.files)}
                  disabled={uploadingImg}
                />
              </label>

              {(localPreview || (Array.isArray(form.images) && form.images.length > 0)) && (
                <div className="loc-img-grid">
                  {localPreview && (
                    <div className="loc-img-item">
                      <img src={localPreview} alt="preview" className="loc-img-preview" />
                    </div>
                  )}

                  {(form.images || []).map((img) => (
                    <div key={img.public_id || img.url} className="loc-img-item">
                      <img src={img.url} alt="loc" className="loc-img-preview" />
                      <button
                        type="button"
                        className="loc-img-remove"
                        onClick={() =>
                          setForm((s) => ({
                            ...s,
                            images: (s.images || []).filter(
                              (x) => (x.public_id || x.url) !== (img.public_id || img.url)
                            ),
                          }))
                        }
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            <div className="loc-form-group">
              <label className="loc-label">Kinh độ (Lng)</label>
              <input
                className="loc-input"
                type="number"
                value={form.lng}
                onChange={(e) => setForm((s) => ({ ...s, lng: e.target.value }))}
                placeholder="Ví dụ: 108.4583"
              />
            </div>
            <div className="loc-form-group">
              <label className="loc-label">Vĩ độ (Lat)</label>
              <input
                className="loc-input"
                type="number"
                value={form.lat}
                onChange={(e) => setForm((s) => ({ ...s, lat: e.target.value }))}
                placeholder="Ví dụ: 11.9404"
              />
            </div>
          </div>
        </div>

        <div className="loc-modal-footer">
          <button className="loc-btn loc-btn-default" onClick={() => setEditOpen(false)}>
            Hủy bỏ
          </button>
          <button className="loc-btn loc-btn-primary" onClick={save} disabled={uploadingImg}>
            Lưu địa điểm
          </button>
        </div>
      </Modal>
    </div>
  );
}