import React, { useState } from "react";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";

// 1. Thêm giá trị mặc định categories = []
export default function Listing({ 
  title, 
  description, 
  categories = [], 
  initialVisibleCount = 10,
  onItemClick 
}) {
  const [visibleCount, setVisibleCount] = useState(initialVisibleCount);

  // 2. [QUAN TRỌNG] Kiểm tra an toàn: Nếu categories lỗi thì dùng mảng rỗng
  const safeCategories = Array.isArray(categories) ? categories : [];
  
  // 3. Cắt mảng từ biến an toàn
  const currentItems = safeCategories.slice(0, visibleCount);

  return (
    <div className="py-4">
      <Container>
        {title && <h3 className="fw-bold mb-2">{title}</h3>}
        {description && <p className="text-muted mb-4">{description}</p>}
        
        <Row>
          {currentItems.map((cat, idx) => (
            <Col key={cat.id || idx} xs={6} md={4} lg={3} className="mb-4">
              <div 
                className="d-flex align-items-center gap-3 p-3 border rounded-3 cursor-pointer hover-shadow transition-all bg-white"
                onClick={() => onItemClick && onItemClick(cat)}
                style={{ cursor: 'pointer' }}
              >
                <div 
                  className="rounded-3 overflow-hidden flex-shrink-0"
                  style={{ width: "60px", height: "60px" }}
                >
                  <img 
                    // Sửa luôn lỗi ảnh tại đây
                    src={cat.imageUrl || "https://placehold.co/60x60"} 
                    alt={cat.title}
                    className="w-100 h-100 object-fit-cover"
                  />
                </div>
                <div>
                  <div className="fw-bold text-dark">{cat.title}</div>
                  {cat.subTitle && <div className="small text-muted">{cat.subTitle}</div>}
                </div>
              </div>
            </Col>
          ))}
        </Row>

        {visibleCount < safeCategories.length && (
          <div className="text-center mt-3">
            <button 
              className="btn btn-outline-primary rounded-pill px-4 fw-semibold"
              onClick={() => setVisibleCount(prev => prev + 10)}
            >
              Xem thêm {safeCategories.length - visibleCount} loại hình khác
            </button>
          </div>
        )}
      </Container>
    </div>
  );
}