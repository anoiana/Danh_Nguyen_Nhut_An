import React, { useState } from "react";
import Slider from "rc-slider";
import "rc-slider/assets/index.css";
import Tooltip from "rc-tooltip";
import "rc-tooltip/assets/bootstrap.css";

const oldFilters = [
  { id: "self-catering", label: "Tự nấu", count: 3 },
  { id: "entire-place", label: "Nhà & căn hộ nguyên căn", count: 10 },
];

const popularFilters = [
  { id: "hotel", label: "Khách sạn", count: 19 },
  { id: "breakfast", label: "Bao gồm bữa sáng", count: 28 },
  { id: "parking", label: "Chỗ đỗ xe", count: 45 },
  { id: "excellent-8", label: "Rất tốt: 8 điểm trở lên", count: 33 },
  { id: "free-cancel", label: "Miễn phí huỷ", count: 44 },
  { id: "private-bath", label: "Phòng tắm riêng", count: 48 },
  { id: "four-star", label: "4 sao", count: 5 },
  { id: "resort", label: "Resort", count: 3 },
];

const propertyTypes = [
  { id: "hotel-type", label: "Khách sạn", count: 19 },
  { id: "homestay", label: "Chỗ nghỉ nhà dân", count: 14 },
  { id: "entire-place-type", label: "Nhà & căn hộ nguyên căn", count: 10 },
  { id: "apartment", label: "Căn hộ", count: 4 },
  { id: "nature-lodge", label: "Nhà nghỉ giữa thiên nhiên", count: 4 },
  { id: "resort-type", label: "Resort", count: 3 },
  { id: "hostel", label: "Nhà trọ", count: 2 },
  { id: "guesthouse", label: "Nhà khách", count: 2 },
  { id: "bnb", label: "Nhà nghỉ B&B", count: 1 },
  { id: "camping", label: "Khu cắm trại", count: 1 },
  { id: "holiday-park", label: "Nhà nghỉ mát", count: 1 },
  { id: "farm-stay", label: "Nhà nghỉ nông thôn", count: 1 },
];

const roomAmenities = [
  { id: "private-bath2", label: "Phòng tắm riêng", count: 48 },
  { id: "balcony", label: "Ban công", count: 31 },
  { id: "aircon", label: "Điều hoà không khí", count: 45 },
  { id: "kitchenette", label: "Khu vực bếp", count: 3 },
  { id: "private-pool", label: "Hồ bơi riêng", count: 1 },
];

const reviewScores = [
  { id: "score-9", label: "Tuyệt hảo: 9 điểm trở lên", count: 11 },
  { id: "score-8", label: "Rất tốt: 8 điểm trở lên", count: 33 },
  { id: "score-7", label: "Tốt: 7 điểm trở lên", count: 40 },
  { id: "score-6", label: "Dễ chịu: 6 điểm trở lên", count: 41 },
];

const starRatings = [
  { id: "1-star", label: "1 sao", count: 1 },
  { id: "2-star", label: "2 sao", count: 7 },
  { id: "3-star", label: "3 sao", count: 13 },
  { id: "4-star", label: "4 sao", count: 5 },
];

const SearchingBar = ({ className, mapQuery = "" }) => {
  const safeQuery = (mapQuery || "").trim() || "Việt Nam";
  const googleMapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
    safeQuery
  )}`;
  const googleEmbedUrl = `https://www.google.com/maps?q=${encodeURIComponent(
    safeQuery
  )}&output=embed`;

  const [budgetMin, setBudgetMin] = useState(150_000);
  const [budgetMax, setBudgetMax] = useState(2_000_000);
  const [bedrooms, setBedrooms] = useState(0);
  const [bathrooms, setBathrooms] = useState(0);

  const formatVND = (v) =>
    "VND " +
    v.toLocaleString("vi-VN", {
      maximumFractionDigits: 0,
    });

  const renderCheckboxGroup = (title, items) => (
    <div className="mb-3">
      <div className="fw-semibold mb-2">{title}</div>
      <div className="d-flex flex-column gap-1">
        {items.map((item) => (
          <label
            key={item.id}
            className="d-flex justify-content-between align-items-center small"
          >
            <span>
              <input type="checkbox" className="form-check-input me-2" />
              {item.label}
            </span>
            {item.count !== undefined && (
              <span className="text-muted">{item.count}</span>
            )}
          </label>
        ))}
      </div>
    </div>
  );

  const renderCounter = (label, value, setValue) => (
    <div className="d-flex justify-content-between align-items-center mb-2">
      <span className="small">{label}</span>
      <div className="d-inline-flex align-items-center border rounded-3">
        <button
          type="button"
          className="btn btn-sm btn-outline-secondary border-0"
          onClick={() => setValue(Math.max(0, value - 1))}
        >
          –
        </button>
        <span
          className="px-3 small"
          style={{ minWidth: 24, textAlign: "center" }}
        >
          {value}
        </span>
        <button
          type="button"
          className="btn btn-sm btn-outline-secondary border-0"
          onClick={() => setValue(value + 1)}
        >
          +
        </button>
      </div>
    </div>
  );

  return (
    <aside className={className} style={{ maxWidth: 320, width: "100%" }}>
      <div className="border rounded-3 overflow-hidden bg-white">
        {/* Map section */}
        <div
          className="position-relative"
          style={{ height: 180, backgroundColor: "#e5eefb" }}
        >
          <iframe
            title={`Google map - ${safeQuery}`}
            src={googleEmbedUrl}
            width="100%"
            height="180"
            style={{ border: 0 }}
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
          />

          <div className="position-absolute top-0 start-0 p-2">
            <a
              href={googleMapsUrl}
              target="_blank"
              rel="noreferrer"
              className="btn btn-primary btn-sm rounded-pill shadow-sm"
            >
              <i className="bi bi-geo-alt-fill me-1" />
              Hiển thị trên bản đồ
            </a>
          </div>
        </div>

        <div className="p-3">
          <div className="fw-bold mb-2">Chọn lọc theo:</div>

          {/* Dùng các bộ lọc cũ */}
          <div className="mb-3">
            <div className="fw-semibold mb-2">Dùng các bộ lọc cũ</div>
            <div className="d-flex flex-column gap-1">
              {oldFilters.map((item) => (
                <label
                  key={item.id}
                  className="d-flex justify-content-between align-items-center small"
                >
                  <span>
                    <input type="checkbox" className="form-check-input me-2" />
                    {item.label}
                  </span>
                  <span className="text-muted">{item.count}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Ngân sách */}
          <div className="mb-3">
            <div className="fw-semibold mb-1">Ngân sách của bạn (mỗi đêm)</div>
            <div className="small text-muted mb-2">
              {formatVND(budgetMin)} - {formatVND(budgetMax)}+
            </div>

            {/* Histogram placeholder */}
            <div
              className="mb-2 rounded-3"
              style={{
                height: 40,
                background:
                  "repeating-linear-gradient(to right, #d0d8e8 0, #d0d8e8 2px, #f4f6fb 2px, #f4f6fb 6px)",
              }}
            />

            {/* Range slider (min-max chung 1 thanh) */}
            <div className="px-1">
              <Slider
                range
                min={150000}
                max={2000000}
                step={50000}
                allowCross={false}
                value={[budgetMin, budgetMax]}
                onChange={(vals) => {
                  if (!Array.isArray(vals)) return;
                  const [minV, maxV] = vals;
                  setBudgetMin(minV);
                  setBudgetMax(maxV);
                }}
                handleRender={(node, handleProps) => (
                  <Tooltip
                    overlay={formatVND(handleProps.value)}
                    placement="top"
                    visible={handleProps.dragging} // chỉ hiện khi đang kéo cho đỡ rối
                  >
                    {node}
                  </Tooltip>
                )}
              />
            </div>
          </div>

          {/* Các bộ lọc phổ biến */}
          {renderCheckboxGroup("Các bộ lọc phổ biến", popularFilters)}

          {/* Loại chỗ ở */}
          {renderCheckboxGroup("Loại chỗ ở", propertyTypes)}

          {/* Phòng ngủ & phòng tắm */}
          <div className="mb-3">
            <div className="fw-semibold mb-2">Phòng ngủ và phòng tắm</div>
            {renderCounter("Phòng ngủ", bedrooms, setBedrooms)}
            {renderCounter("Phòng tắm", bathrooms, setBathrooms)}
          </div>

          {/* Tiện nghi phòng */}
          <div className="mb-3">
            <div className="fw-semibold mb-2">Tiện nghi phòng</div>
            <div className="d-flex flex-column gap-1">
              {roomAmenities.map((item) => (
                <label
                  key={item.id}
                  className="d-flex justify-content-between align-items-center small"
                >
                  <span>
                    <input type="checkbox" className="form-check-input me-2" />
                    {item.label}
                  </span>
                  <span className="text-muted">{item.count}</span>
                </label>
              ))}
            </div>
            <button className="btn btn-link p-0 small mt-1">
              Hiển thị tất cả 25 loại
            </button>
          </div>

          {/* Điểm đánh giá của khách */}
          {renderCheckboxGroup("Điểm đánh giá của khách", reviewScores)}

          {/* Xếp hạng chỗ nghỉ */}
          <div className="mb-1">
            <div className="fw-semibold mb-2">Xếp hạng chỗ nghỉ</div>
            <p className="small text-muted mb-2">
              Tìm khách sạn và nhà nghỉ dưỡng chất lượng cao
            </p>
            <div className="d-flex flex-column gap-1">
              {starRatings.map((item) => (
                <label
                  key={item.id}
                  className="d-flex justify-content-between align-items-center small"
                >
                  <span>
                    <input type="checkbox" className="form-check-input me-2" />
                    {item.label}
                  </span>
                  <span className="text-muted">{item.count}</span>
                </label>
              ))}
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
};

export default SearchingBar;
