import React, { useEffect, useMemo, useState } from "react";
import categoryApi from "../../api/categoryApi";
import "../../styles/admin/ManageCategory.css";

// --- HELPERS ---
function normalizeList(res) {
  const a = res?.data ?? res;
  const b = a?.data ?? a;
  if (Array.isArray(b)) return b;
  if (Array.isArray(b?.items)) return b.items;
  if (Array.isArray(b?.categories)) return b.categories;
  if (Array.isArray(b?.results)) return b.results;
  return [];
}

function normalizeImage(img) {
  if (!img) return { url: "", public_id: "" };
  if (typeof img === "string") return { url: img, public_id: "" };
  return {
    url: img?.url || "",
    public_id: img?.public_id || "",
  };
}

function toRow(x) {
  const parentObj =
    typeof x?.parent === "object" && x?.parent !== null ? x.parent : null;

  const image = normalizeImage(x?.image);
  return {
    ...x,
    id: x?.id || x?._id,
    parentId: parentObj?._id || x?.parent || null,
    parentName: parentObj?.name || "",
    slug: x?.slug || "",
    image,
    imageUrl: image.url,
    status: x?.status || "active", // [NEW] Lấy status
    created_by: x?.created_by, // [NEW] Lấy người tạo
  };
}

function toPayload(row) {
  return {
    name: row?.name?.trim(),
    parent: row?.parentId || null,
    description: row?.description || "",
    image: row?.image || { url: "", public_id: "" },
    status: row?.status, // Giữ nguyên status khi update
  };
}

// --- MODAL COMPONENT ---
function Modal({ open, title, onClose, children }) {
  if (!open) return null;
  return (
    <div className="cat-modal-overlay" onMouseDown={onClose}>
      <div className="cat-modal" onMouseDown={(e) => e.stopPropagation()}>
        <div className="cat-modal-header">
          <div className="cat-modal-title">{title}</div>
          <button className="cat-close-btn" onClick={onClose} type="button">
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

// --- MAIN COMPONENT ---
export default function ManageCategory() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  // Pagination State
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [limit] = useState(10);

  const [detailOpen, setDetailOpen] = useState(false);
  const [detailRow, setDetailRow] = useState(null);

  const [editOpen, setEditOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    name: "",
    parentId: "",
    description: "",
    image: { url: "", public_id: "" },
    status: "active",
  });

  const [uploadingImg, setUploadingImg] = useState(false);
  const [localPreview, setLocalPreview] = useState("");
  const [allCategories, setAllCategories] = useState([]);

  const load = async () => {
    setLoading(true);
    try {
      const res = await categoryApi.getManage({ page, limit });

      // 1) full list (chưa cắt trang)
      let fullList = normalizeList(res).map(toRow);

      // 2) sort pending lên đầu
      fullList.sort((a, b) => {
        if (a.status === "pending" && b.status !== "pending") return -1;
        if (a.status !== "pending" && b.status === "pending") return 1;
        return 0;
      });

      // LƯU full list để làm parent options
      setAllCategories(fullList);

      // 3) tạo list hiển thị (có phân trang)
      let list = fullList;

      const isServerPaginated = res.totalPages !== undefined;
      if (isServerPaginated) {
        setTotalPages(res.totalPages);
        // nếu server đã paginate thì list đã là trang hiện tại, giữ nguyên
        // (nhưng fullList lúc này vẫn chỉ là trang hiện tại nếu server paginate)
      } else {
        const totalItems = fullList.length;
        setTotalPages(Math.ceil(totalItems / limit) || 1);

        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;
        list = fullList.slice(startIndex, endIndex);
      }

      // 4) Map parent name dựa trên FULL LIST (không phải list đã slice)
      const idToName = new Map(fullList.map((c) => [c.id, c.name]));
      const list2 = list.map((c) => ({
        ...c,
        parentName:
          c.parentName || (c.parentId ? idToName.get(c.parentId) || "" : ""),
      }));

      setRows(list2);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [page]);

  const parentOptions = useMemo(() => {
    return allCategories.map((c) => ({ id: c.id, name: c.name }));
  }, [allCategories]);

  const openCreate = () => {
    setEditing(null);
    setForm({
      name: "",
      parentId: "",
      description: "",
      image: { url: "", public_id: "" },
      status: "active",
    });
    setLocalPreview("");
    setEditOpen(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      name: row?.name || "",
      parentId: row?.parentId || "",
      description: row?.description || "",
      image: row?.image || { url: "", public_id: "" },
      status: row?.status || "active",
    });
    setLocalPreview("");
    setEditOpen(true);
  };

  const openDetail = (row) => {
    setDetailRow(row);
    setDetailOpen(true);
  };

  const save = async () => {
    if (!form.name.trim()) return alert("Vui lòng nhập tên danh mục.");
    if (editing?.id && form.parentId && form.parentId === editing.id) {
      return alert("Danh mục cha không thể là chính nó.");
    }

    try {
      const payload = toPayload({
        ...editing,
        ...form,
        parentId: form.parentId || null,
      });

      if (!editing) {
        await categoryApi.create(payload);
      } else {
        await categoryApi.update(editing.id, payload);
      }

      setEditOpen(false);
      await load();
    } catch (e) {
      console.error(e);
      alert(
        e?.response?.data?.message || e?.message || "Lưu danh mục thất bại",
      );
    }
  };

  // [NEW] Logic duyệt danh mục
  const approve = async (row) => {
    if (!confirm(`Duyệt danh mục "${row.name}"?`)) return;
    try {
      await categoryApi.update(row.id, { status: "active" });
      await load();
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Lỗi khi duyệt");
    }
  };

  const remove = async (id) => {
    if (!confirm("Xóa danh mục này?")) return;
    try {
      await categoryApi.remove(id);
      await load();
    } catch (e) {
      console.error(e);
      alert(
        e?.response?.data?.message || e?.message || "Xóa danh mục thất bại",
      );
    }
  };

  useEffect(() => {
    return () => {
      if (localPreview) URL.revokeObjectURL(localPreview);
    };
  }, [localPreview]);

  const pickAndUpload = async (file) => {
    if (!file) return;
    if (!file.type?.startsWith("image/")) return alert("Chỉ nhận file ảnh.");

    if (localPreview) URL.revokeObjectURL(localPreview);
    const preview = URL.createObjectURL(file);
    setLocalPreview(preview);

    setUploadingImg(true);
    try {
      const fd = new FormData();
      fd.append("file", file);

      const res = await categoryApi.uploadCategoryImage(fd);
      const url = res?.url || res?.data?.url;
      const public_id = res?.public_id || res?.data?.public_id || "";

      if (!url) throw new Error("Server không trả về url");

      setForm((s) => ({ ...s, image: { url, public_id } }));
    } catch (e) {
      console.error(e);
      alert(e?.response?.data?.message || e?.message || "Upload ảnh thất bại");
    } finally {
      setUploadingImg(false);
    }
  };

  const onDropImage = (e) => {
    e.preventDefault();
    e.stopPropagation();
    const file = e.dataTransfer.files?.[0];
    pickAndUpload(file);
  };

  return (
    <div className="cat-page">
      {/* HEADER */}
      <div className="cat-header">
        <div>
          <h1 className="cat-title">Quản lý danh mục</h1>
          <div className="cat-subtitle">
            Duyệt các yêu cầu tạo danh mục từ Partner và quản lý dữ liệu.
          </div>
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          <button
            className="cat-btn cat-btn-default"
            onClick={load}
            disabled={loading}
          >
            {loading ? "..." : "↻ Tải lại"}
          </button>
          <button className="cat-btn cat-btn-primary" onClick={openCreate}>
            + Thêm danh mục
          </button>
        </div>
      </div>

      {/* TABLE */}
      <div className="cat-table-container">
        <table className="cat-table">
          <thead>
            <tr>
              <th>Tên danh mục</th>
              <th>Slug</th>
              <th>Danh mục cha</th>
              <th>Mô tả</th>
              <th style={{ textAlign: "right" }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td
                  colSpan={5}
                  style={{ padding: 40, textAlign: "center", color: "#6b7280" }}
                >
                  Đang tải dữ liệu...
                </td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  style={{ padding: 40, textAlign: "center", color: "#6b7280" }}
                >
                  Chưa có danh mục nào.
                </td>
              </tr>
            ) : (
              rows.map((x) => {
                const isPending = x.status === "pending";
                return (
                  <tr
                    key={x.id || x._id}
                    className={isPending ? "cat-tr-pending" : ""}
                  >
                    <td>
                      <div style={{ fontWeight: 600 }}>{x.name}</div>
                      {isPending && (
                        <span
                          className="cat-badge"
                          style={{
                            backgroundColor: "#f59e0b",
                            color: "#fff",
                            fontSize: 11,
                            padding: "2px 6px",
                            borderRadius: 4,
                          }}
                        >
                          ⏳ Chờ duyệt
                        </span>
                      )}
                    </td>
                    <td>
                      {x.slug ? (
                        <code className="cat-code">{x.slug}</code>
                      ) : (
                        <span className="text-muted">Tự động</span>
                      )}
                    </td>
                    <td>
                      {x.parentName || <span className="text-muted">—</span>}
                    </td>
                    <td>
                      {x.description ? (
                        <span style={{ color: "#4b5563" }}>
                          {x.description}
                        </span>
                      ) : (
                        <span className="text-muted">—</span>
                      )}
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "flex-end",
                          gap: 6,
                        }}
                      >
                        {/* [NEW] Nút Duyệt */}
                        {isPending && (
                          <button
                            className="cat-btn cat-btn-success"
                            style={{
                              backgroundColor: "#10b981",
                              color: "white",
                              borderColor: "#10b981",
                              padding: "6px 12px",
                            }}
                            onClick={() => approve(x)}
                            title="Duyệt ngay"
                          >
                            ✓ Duyệt
                          </button>
                        )}

                        <button
                          className="cat-btn cat-btn-default"
                          onClick={() => openDetail(x)}
                          title="Chi tiết"
                          style={{ padding: "6px 12px" }}
                        >
                          👁️
                        </button>
                        <button
                          className="cat-btn cat-btn-default"
                          onClick={() => openEdit(x)}
                          title="Sửa"
                          style={{ padding: "6px 12px" }}
                        >
                          ✎
                        </button>
                        <button
                          className="cat-btn cat-btn-danger"
                          onClick={() => remove(x.id)}
                          title="Xóa"
                          style={{ padding: "6px 12px" }}
                        >
                          ✕
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* PAGINATION CONTROLS */}
      {!loading && (rows.length > 0 || totalPages > 1) && (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "flex-end",
            gap: 8,
            marginTop: 8,
          }}
        >
          <span style={{ fontSize: 14, color: "#6b7280", marginRight: 12 }}>
            Trang <b>{page}</b> / {totalPages}
          </span>
          <button
            className="cat-btn cat-btn-default"
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
            style={{ width: 36, height: 36, padding: 0 }}
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
                className={`cat-btn ${page === pNum ? "cat-btn-primary" : "cat-btn-default"}`}
                onClick={() => setPage(pNum)}
                style={{ width: 36, height: 36, padding: 0 }}
              >
                {pNum}
              </button>
            );
          })}

          <button
            className="cat-btn cat-btn-default"
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
            style={{ width: 36, height: 36, padding: 0 }}
          >
            &gt;
          </button>
        </div>
      )}

      {/* MODAL CHI TIẾT */}
      <Modal
        open={detailOpen}
        title="Chi tiết danh mục"
        onClose={() => setDetailOpen(false)}
      >
        <div className="cat-modal-body">
          <div className="cat-detail-row">
            <div>
              <div className="cat-label">Tên danh mục</div>
              <div className="cat-detail-value">
                {detailRow?.name}
                {detailRow?.status === "pending" && (
                  <span style={{ color: "orange", marginLeft: 8 }}>
                    (Chờ duyệt)
                  </span>
                )}
              </div>
            </div>
            <div>
              <div className="cat-label">Slug</div>
              <div className="cat-detail-value">
                {detailRow?.slug ? (
                  <code className="cat-code">{detailRow.slug}</code>
                ) : (
                  "—"
                )}
              </div>
            </div>
          </div>
          <div className="cat-detail-row">
            <div>
              <div className="cat-label">Danh mục cha</div>
              <div className="cat-detail-value">
                {detailRow?.parentName || "—"}
              </div>
            </div>
            <div>
              <div className="cat-label">Ảnh</div>
              <div className="cat-detail-value">
                {detailRow?.image?.url ? (
                  <img
                    src={detailRow.image.url}
                    alt="category"
                    className="cat-preview-img"
                    style={{ marginTop: 0 }}
                    onError={(e) => (e.currentTarget.style.display = "none")}
                  />
                ) : (
                  "—"
                )}
              </div>
            </div>
          </div>
          <div>
            <div className="cat-label">Mô tả</div>
            <div className="cat-detail-value">
              {detailRow?.description || "—"}
            </div>
          </div>
        </div>
        <div className="cat-modal-footer">
          <button
            className="cat-btn cat-btn-default"
            onClick={() => setDetailOpen(false)}
          >
            Đóng
          </button>
          {detailRow?.status === "pending" && (
            <button
              className="cat-btn cat-btn-success"
              style={{
                backgroundColor: "#10b981",
                color: "white",
                borderColor: "#10b981",
              }}
              onClick={() => {
                setDetailOpen(false);
                approve(detailRow);
              }}
            >
              Duyệt ngay
            </button>
          )}
          <button
            className="cat-btn cat-btn-primary"
            onClick={() => {
              setDetailOpen(false);
              openEdit(detailRow);
            }}
          >
            Chỉnh sửa
          </button>
        </div>
      </Modal>

      {/* MODAL THÊM/SỬA */}
      <Modal
        open={editOpen}
        title={editing ? "Chỉnh sửa danh mục" : "Thêm danh mục"}
        onClose={() => setEditOpen(false)}
      >
        <div className="cat-modal-body">
          <div className="cat-form-group">
            <label className="cat-label">Tên danh mục</label>
            <input
              className="cat-input"
              value={form.name}
              onChange={(e) => setForm((s) => ({ ...s, name: e.target.value }))}
              placeholder="VD: Tour Biển"
            />
          </div>

          <div className="cat-form-group">
            <label className="cat-label">Trạng thái</label>
            <select
              className="cat-select"
              value={form.status}
              onChange={(e) =>
                setForm((s) => ({ ...s, status: e.target.value }))
              }
            >
              <option value="active">Active (Hoạt động)</option>
              <option value="pending">Pending (Chờ duyệt)</option>
              <option value="rejected">Rejected (Từ chối)</option>
            </select>
          </div>

          <div className="cat-form-group">
            <label className="cat-label">Danh mục cha</label>

            <input
              className="cat-input"
              list="parentCategoryList"
              placeholder="Gõ để tìm danh mục cha..."
              value={
                // hiển thị tên nếu có id
                form.parentId
                  ? allCategories.find((c) => c.id === form.parentId)?.name ||
                    ""
                  : ""
              }
              onChange={(e) => {
                const name = e.target.value;
                const match = allCategories.find(
                  (c) => c.name.toLowerCase() === name.toLowerCase(),
                );
                setForm((s) => ({ ...s, parentId: match?.id || "" }));
              }}
            />

            <datalist id="parentCategoryList">
              {/* option "none" */}
              {/* (datalist không có option value="" kiểu select, nên bạn để placeholder là đủ) */}
              {allCategories
                .filter((p) => !editing || p.id !== editing.id)
                .map((p) => (
                  <option key={p.id} value={p.name} />
                ))}
            </datalist>

            <div className="text-muted" style={{ fontSize: 12, marginTop: 6 }}>
              Gõ tên danh mục để tìm nhanh. Nếu để trống: danh mục cấp 1.
            </div>
          </div>

          <div className="cat-form-group">
            <label className="cat-label">Mô tả</label>
            <textarea
              className="cat-textarea"
              value={form.description}
              onChange={(e) =>
                setForm((s) => ({ ...s, description: e.target.value }))
              }
              placeholder="Mô tả ngắn cho danh mục..."
            />
          </div>

          <div className="cat-form-group">
            <label className="cat-label">Ảnh</label>
            <div
              className="cat-upload-area"
              onDragOver={(e) => e.preventDefault()}
              onDrop={onDropImage}
            >
              <div className="cat-upload-text">
                Kéo & thả ảnh vào đây, hoặc bấm nút bên dưới
              </div>
              <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                <label className="cat-btn cat-btn-primary">
                  {uploadingImg ? "Đang upload..." : "Chọn ảnh từ máy"}
                  <input
                    type="file"
                    accept="image/*"
                    hidden
                    onChange={(e) => pickAndUpload(e.target.files?.[0])}
                    disabled={uploadingImg}
                  />
                </label>
                {form.image?.url && (
                  <button
                    type="button"
                    className="cat-btn cat-btn-danger"
                    onClick={() => {
                      setForm((s) => ({
                        ...s,
                        image: { url: "", public_id: "" },
                      }));
                      setLocalPreview("");
                    }}
                    disabled={uploadingImg}
                  >
                    Xóa ảnh
                  </button>
                )}
              </div>
              {(localPreview || form.image?.url) && (
                <img
                  src={localPreview || form.image.url}
                  alt="preview"
                  className="cat-preview-img"
                  onError={(e) => (e.currentTarget.style.display = "none")}
                />
              )}
            </div>
          </div>
        </div>

        <div className="cat-modal-footer">
          <button
            className="cat-btn cat-btn-default"
            onClick={() => setEditOpen(false)}
          >
            Hủy
          </button>
          <button className="cat-btn cat-btn-primary" onClick={save}>
            {editing ? "Lưu thay đổi" : "Tạo danh mục"}
          </button>
        </div>
      </Modal>
    </div>
  );
}
