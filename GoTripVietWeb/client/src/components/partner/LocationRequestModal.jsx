import React, { useState, useEffect } from "react";
import { Modal, Button, Form, Alert } from "react-bootstrap";
import locationApi from "../../api/locationApi";

export default function LocationRequestModal({ show, onHide, onSuccess }) {
  // State thông tin form
  const [name, setName] = useState("");
  const [country, setCountry] = useState("");
  const [description, setDescription] = useState("");

  // State xử lý ảnh
  const [imageFile, setImageFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState("");

  // UI state
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Reset form khi đóng modal
  useEffect(() => {
    if (!show) {
      setName("");
      setCountry("");
      setDescription("");
      setImageFile(null);
      setPreviewUrl("");
      setError("");
    }
  }, [show]);

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
      setError("Vui lòng nhập tên địa điểm.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      let imageUrl = "";

      // 1. Upload ảnh nếu có
      if (imageFile) {
        const formData = new FormData();
        formData.append("file", imageFile); // Backend đang nhận field là 'file'
        
        // Gọi API upload
        const uploadRes = await locationApi.uploadLocationImage(formData);
        // Xử lý kết quả trả về (thường là { url: "...", public_id: "..." })
        imageUrl = uploadRes.url || uploadRes.data?.url || uploadRes;

        if (!imageUrl) throw new Error("Upload ảnh thất bại");
      }

      // 2. Gửi request tạo location
      const payload = {
        name: name.trim(),
        country: country.trim(),
        description: description.trim(),
        image: imageUrl // Gửi URL ảnh
      };

      const res = await locationApi.requestNew(payload);
      const newLoc = res.data || res;

      onSuccess(newLoc);
      onHide();
    } catch (err) {
      console.error("Lỗi request location:", err);
      setError(err.response?.data?.message || err.message || "Có lỗi xảy ra.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal show={show} onHide={onHide} centered backdrop="static" size="lg">
      <Modal.Header closeButton>
        <Modal.Title>Đề xuất Địa điểm mới</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && <Alert variant="danger">{error}</Alert>}
        
        <p className="text-muted small mb-3">
          Vui lòng nhập đầy đủ thông tin để Admin duyệt nhanh hơn.
        </p>

        <Form>
          <div className="row">
            <div className="col-md-6">
              <Form.Group className="mb-3">
                <Form.Label className="fw-bold">Tên địa điểm <span className="text-danger">*</span></Form.Label>
                <Form.Control
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="VD: Vịnh Hạ Long"
                  autoFocus
                />
              </Form.Group>
            </div>
            <div className="col-md-6">
              <Form.Group className="mb-3">
                <Form.Label className="fw-bold">Quốc gia</Form.Label>
                <Form.Control
                  value={country}
                  onChange={(e) => setCountry(e.target.value)}
                  placeholder="VD: Việt Nam"
                />
              </Form.Group>
            </div>
          </div>

          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Mô tả ngắn</Form.Label>
            <Form.Control
              as="textarea"
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Giới thiệu sơ lược về địa điểm này..."
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label className="fw-bold">Hình ảnh đại diện</Form.Label>
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
                  style={{ maxHeight: '200px', maxWidth: '100%', borderRadius: '4px' }} 
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
        <Button variant="secondary" onClick={onHide} disabled={loading}>
          Hủy bỏ
        </Button>
        <Button variant="primary" onClick={handleSubmit} disabled={loading}>
          {loading ? "Đang xử lý..." : "Gửi đề xuất"}
        </Button>
      </Modal.Footer>
    </Modal>
  );
}