import React, { useState, useEffect } from "react";
import { Modal, Button, Form, Alert } from "react-bootstrap";
import categoryApi from "../../api/categoryApi";

export default function CategoryRequestModal({ show, onHide, onSuccess }) {
  // Form State
  const [name, setName] = useState("");
  const [parentId, setParentId] = useState("");
  const [description, setDescription] = useState("");
  
  // Image State
  const [imageFile, setImageFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState("");
  
  // Data & UI State
  const [availableCategories, setAvailableCategories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Load danh mục cha khi mở modal
  useEffect(() => {
    if (show) {
      fetchCategories();
      // Reset form
      setName("");
      setParentId("");
      setDescription("");
      setImageFile(null);
      setPreviewUrl("");
      setError("");
    }
  }, [show]);

  const fetchCategories = async () => {
    try {
      // Dùng hàm getManage để lấy cả pending categories của chính user này
      const res = await categoryApi.getManage();
      const data = res.data || res;
      if (Array.isArray(data)) {
        setAvailableCategories(data);
      }
    } catch (err) {
      console.error("Lỗi tải danh mục:", err);
    }
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError("Kích thước ảnh tối đa 5MB");
        return;
      }
      setImageFile(file);
      setPreviewUrl(URL.createObjectURL(file));
      setError("");
    }
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError("Vui lòng nhập tên danh mục.");
      return;
    }
    setLoading(true);
    setError("");

    try {
      let imageUrl = "";

      // 1. Upload ảnh
      if (imageFile) {
        const formData = new FormData();
        formData.append("file", imageFile);
        
        const uploadRes = await categoryApi.uploadCategoryImage(formData);
        imageUrl = uploadRes.url || uploadRes.data?.url || uploadRes;

        if (!imageUrl) throw new Error("Upload ảnh thất bại");
      }

      // 2. Gửi request
      const payload = {
        name: name.trim(),
        parent: parentId || null,
        description: description.trim(),
        image: imageUrl // Gửi URL ảnh
      };

      const res = await categoryApi.requestNew(payload);
      const newCat = res.data || res;

      onSuccess(newCat);
      onHide();
    } catch (err) {
      console.error("Lỗi request category:", err);
      setError(err.response?.data?.message || err.message || "Có lỗi xảy ra.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal show={show} onHide={onHide} centered backdrop="static">
      <Modal.Header closeButton>
        <Modal.Title>Đề xuất Danh mục mới</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && <Alert variant="danger">{error}</Alert>}
        
        <Form>
          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Tên Danh mục <span className="text-danger">*</span></Form.Label>
            <Form.Control 
              value={name} 
              onChange={(e) => setName(e.target.value)}
              placeholder="VD: Du lịch mạo hiểm" 
              autoFocus
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Danh mục cha (nếu có)</Form.Label>
            <Form.Select 
              value={parentId} 
              onChange={(e) => setParentId(e.target.value)}
            >
              <option value="">-- Là danh mục gốc --</option>
              {availableCategories.map((cat) => (
                <option key={cat._id || cat.id} value={cat._id || cat.id}>
                  {cat.name} {cat.status === 'pending' ? '(Chờ duyệt)' : ''}
                </option>
              ))}
            </Form.Select>
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Mô tả</Form.Label>
            <Form.Control 
              as="textarea"
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Mô tả ngắn gọn..."
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Hình ảnh</Form.Label>
            <Form.Control 
              type="file" 
              accept="image/*" 
              onChange={handleFileChange} 
            />
            {previewUrl && (
              <div className="mt-3 text-center border p-2 rounded bg-light">
                <img 
                  src={previewUrl} 
                  alt="Preview" 
                  style={{ maxHeight: '150px', maxWidth: '100%', borderRadius: '4px' }} 
                />
                 <div className="mt-2">
                  <Button 
                    variant="outline-danger" 
                    size="sm" 
                    onClick={() => { setImageFile(null); setPreviewUrl(""); }}
                  >
                    Xóa ảnh
                  </Button>
                </div>
              </div>
            )}
          </Form.Group>
        </Form>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide} disabled={loading}>Hủy</Button>
        <Button variant="primary" onClick={handleSubmit} disabled={loading}>
          {loading ? "Đang gửi..." : "Gửi đề xuất"}
        </Button>
      </Modal.Footer>
    </Modal>
  );
}