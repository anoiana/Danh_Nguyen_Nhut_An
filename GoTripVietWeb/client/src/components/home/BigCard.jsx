import React from "react";
import Button from "react-bootstrap/Button";

// Helper định dạng ngày tháng ngắn gọn (15/05)
const formatDate = (dateString) => {
  if (!dateString) return "";
  const d = new Date(dateString);
  if (isNaN(d.getTime())) return dateString;
  return d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" });
};

export default function BigCard({
  imageUrl,
  title,
  tourCode,
  startPoint,
  duration,
  departureDates = [],
  transport,
  transportIcon,
  onClick,
}) {
  return (
    <div
      className="card h-100 border shadow-sm cursor-pointer hover-shadow"
      onClick={onClick}
    >
      {/* 1. ẢNH THUMBNAIL */}
      <div
        className="position-relative overflow-hidden"
        style={{ height: "200px" }}
      >
        <img
          src={imageUrl || "https://placehold.co/600x400?text=Tour+Image"}
          className="card-img-top h-100 w-100"
          alt={title}
          style={{ objectFit: "cover", transition: "transform 0.5s ease" }}
          onError={(e) => {
            e.target.onerror = null;
            e.target.src = "https://placehold.co/600x400?text=No+Image";
          }}
        />

        {/* [ĐÃ XÓA] Badge giảm giá ở đây */}
      </div>

      <div className="card-body p-3 d-flex flex-column">
        {/* 2. TIÊU ĐỀ TOUR */}
        <h6
          className="card-title fw-bold text-dark mb-3 text-truncate-2-lines"
          title={title}
        >
          {title}
        </h6>

        {/* 3. THÔNG TIN CHI TIẾT */}
        <div className="row g-2 mb-3 small text-secondary">
          <div className="col-6 d-flex align-items-center gap-2">
            <i className="bi bi-ticket-perforated text-muted fs-6"></i>
            <span className="text-truncate">
              Mã: <span className="fw-bold text-dark">{tourCode || "N/A"}</span>
            </span>
          </div>

          <div className="col-6 d-flex align-items-center gap-2">
            <i className="bi bi-geo-alt text-muted fs-6"></i>
            <span className="text-truncate">
              Từ: <span className="fw-bold text-primary">{startPoint}</span>
            </span>
          </div>

          <div className="col-6 d-flex align-items-center gap-2">
            <i className="bi bi-clock text-muted fs-6"></i>
            <span>{duration}</span>
          </div>

          <div className="col-6 d-flex align-items-center gap-2">
            <i
              className={`bi ${
                transportIcon || "bi-bus-front"
              } text-primary fs-6`}
            ></i>
            <span className="text-truncate" title={transport}>
              {transport}
            </span>
          </div>
        </div>

        {/* 4. NGÀY KHỞI HÀNH */}
        <div className="d-flex align-items-center gap-2 mb-3">
          <i className="bi bi-calendar3 text-muted"></i>
          <span className="small text-muted me-1" style={{ minWidth: "60px" }}>
            Khởi hành:
          </span>
          <div className="d-flex gap-1 overflow-hidden">
            {departureDates && departureDates.length > 0 ? (
              departureDates.slice(0, 3).map((date, index) => (
                <span
                  key={index}
                  className="border border-secondary text-secondary rounded px-2 py-0 small bg-light"
                  style={{ fontSize: "11px", whiteSpace: "nowrap" }}
                >
                  {formatDate(date)}
                </span>
              ))
            ) : (
              <span className="text-muted small fst-italic">Liên hệ</span>
            )}
            {departureDates.length > 3 && (
              <span className="small text-muted">...</span>
            )}
          </div>
        </div>

        {/* 5. FOOTER (Đã sửa: Chỉ còn nút bấm) */}
        <div className="mt-auto pt-3 border-top">
          {/* [ĐÃ XÓA] Phần hiển thị giá tiền ở đây */}

          {/* Nút bấm giờ để full chiều rộng (w-100) cho đẹp */}
          <Button
            variant="outline-primary"
            size="sm"
            className="fw-bold w-100 rounded-pill hover-bg-primary"
          >
            Xem chi tiết
          </Button>
        </div>
      </div>
    </div>
  );
}
