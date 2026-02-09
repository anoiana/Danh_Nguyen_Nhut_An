import React, { useRef, useState } from "react";
import SmallCard from "./SmallCard.jsx";

const Slider = ({
  title,
  description,
  items,
  defaultVisible = true,
  onClose,
  itemMinWidth = 260,
  className,
}) => {
  const [visible, setVisible] = useState(defaultVisible);
  const trackRef = useRef(null);

  if (!visible || items.length === 0) return null;

  const handleClose = () => {
    setVisible(false);
    onClose && onClose();
  };

  const scrollNext = () => {
    const el = trackRef.current;
    if (!el) return;
    const step = Math.max(itemMinWidth, Math.floor(el.clientWidth * 0.7));
    el.scrollBy({ left: step, behavior: "smooth" });
  };

  return (
    <section className={`card border-0 shadow-sm rounded-4 ${className ?? ""}`}>
      <div className="card-body">
        {/* Header: title + close */}
        <div className="d-flex align-items-start justify-content-between mb-3">
          <div>
            {title && <h5 className="fw-bold mb-1">{title}</h5>}
            {description && (
              <p className="small text-muted mb-0">{description}</p>
            )}
          </div>

          <button
            type="button"
            className="btn btn-link text-muted p-0 ms-3"
            onClick={handleClose}
            aria-label="Đóng"
          >
            <i className="bi bi-x-lg fs-5" />
          </button>
        </div>

        {/* Slider body */}
        <div className="position-relative">
          <div
            ref={trackRef}
            className="d-flex overflow-auto pb-2"
            style={{ gap: 16 }}
          >
            {items.map((item, idx) => (
              <div
                key={item.name + idx}
                style={{
                  flex: `0 0 ${itemMinWidth}px`,
                  maxWidth: 320,
                }}
              >
                <SmallCard {...item} />
              </div>
            ))}
          </div>

          {/* Nút mũi tên tròn bên phải */}
          {items.length > 3 && (
            <button
              type="button"
              className="btn btn-light rounded-circle shadow position-absolute top-50 end-0 translate-middle-y me-1 d-none d-md-flex"
              onClick={scrollNext}
              aria-label="Xem thêm"
            >
              <i className="bi bi-chevron-right" />
            </button>
          )}
        </div>
      </div>
    </section>
  );
};

export default Slider;
