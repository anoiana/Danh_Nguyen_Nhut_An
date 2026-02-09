import React, { useEffect, useRef, useState } from "react";

const DEFAULT_OPTIONS = [
  { value: "top_choice", label: "Lựa chọn hàng đầu của chúng tôi" },
  { value: "home_apartment", label: "Ưu tiên nhà & căn hộ" },
  { value: "price_low", label: "Giá (ưu tiên thấp nhất)" },
  { value: "price_high", label: "Giá (ưu tiên cao nhất)" },
  {
    value: "best_value",
    label: "Được đánh giá tốt nhất và có giá thấp nhất",
  },
  { value: "stars_high", label: "Xếp hạng chỗ nghỉ (cao đến thấp)" },
  { value: "stars_low", label: "Xếp hạng chỗ nghỉ (thấp đến cao)" },
  { value: "stars_price", label: "Xếp hạng chỗ nghỉ và giá" },
  { value: "distance_center", label: "Khoảng cách từ trung tâm thành phố" },
  { value: "top_rated", label: "Được đánh giá hàng đầu" },
];

const BestChoiceSearch = ({
  options = DEFAULT_OPTIONS,
  value,
  defaultValue,
  onChange,
  className,
}) => {
  const [open, setOpen] = useState(false);
  const [internalValue, setInternalValue] = useState(
    defaultValue ?? options[0]?.value ?? ""
  );
  const containerRef = useRef(null);

  const currentValue = value ?? internalValue;
  const currentOption =
    options.find((o) => o.value === currentValue) ?? options[0];

  const toggleOpen = () => setOpen((o) => !o);

  const handleSelect = (opt) => {
    if (value == null) {
      setInternalValue(opt.value);
    }
    onChange && onChange(opt.value, opt);
    setOpen(false);
  };

  // đóng dropdown khi click ra ngoài
  useEffect(() => {
    if (!open) return;
    const onClick = (e) => {
      if (!containerRef.current) return;
      if (!containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, [open]);

  return (
    <div
      ref={containerRef}
      className={`position-relative d-inline-block ${className ?? ""}`}
      style={{ maxWidth: "100%" }}
    >
      {/* Nút chính */}
      <button
        type="button"
        className="btn btn-outline-secondary rounded-pill d-flex align-items-center px-3 py-2 w-100 text-start"
        onClick={toggleOpen}
      >
        <i className="bi bi-arrow-down-up me-2" />
        <span className="small text-muted me-1">Sắp xếp theo:</span>
        <span className="small fw-semibold text-truncate">
          {currentOption?.label}
        </span>
        <i
          className={
            "bi ms-auto " + (open ? "bi-chevron-up" : "bi-chevron-down")
          }
        />
      </button>

      {/* Dropdown */}
      {open && (
        <div
          className="position-absolute mt-1 bg-white shadow rounded-3 py-1"
          style={{
            zIndex: 1050,
            minWidth: "100%",
            maxHeight: 320,
            overflowY: "auto",
          }}
        >
          {options.map((opt) => {
            const active = opt.value === currentValue;
            return (
              <button
                key={opt.value}
                type="button"
                className={
                  "w-100 text-start border-0 bg-transparent px-3 py-2 small " +
                  (active ? "fw-semibold text-primary" : "")
                }
                onClick={() => handleSelect(opt)}
              >
                {opt.label}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default BestChoiceSearch;
