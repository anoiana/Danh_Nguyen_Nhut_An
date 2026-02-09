import React from "react";

function formatCurrency(value, currency = "VND") {
  return (
    currency +
    " " +
    value.toLocaleString("vi-VN", {
      maximumFractionDigits: 0,
    })
  );
}

function getRatingLabel(score) {
  if (score == null) return undefined;
  if (score >= 9) return "Xuất sắc";
  if (score >= 8) return "Tuyệt vời";
  if (score >= 7) return "Tốt";
  if (score >= 6) return "Dễ chịu";
  return "Đánh giá";
}

const ListingCard = ({
  // ảnh & yêu thích
  imageUrl,
  title,
  isFavorite,
  onToggleFavorite,

  // thông tin chung
  stars,
  badgeLabel,
  location,
  distanceToCenterKm,
  onMapClick,

  // rating
  ratingScore,
  reviewCount,
  newLabel,

  // labels bên trái
  eventLabel,

  // phòng
  roomName,
  roomDescription,

  includesBreakfast,
  freeCancellation,
  payAtProperty,
  remainingRoomsText,

  // giá
  priceInfo,

  // click actions
  onViewAvailability,
}) => {
  const {
    basePrice,
    discountedPrice,
    currency = "VND",
    breakdownTooltip,
    nights = 1,
    adults = 2,
  } = priceInfo;

  const displayScore =
    typeof ratingScore === "number"
      ? Math.round(ratingScore * 10) / 10
      : undefined;
  const ratingLabel = getRatingLabel(ratingScore);

  const hasDiscount =
    typeof discountedPrice === "number" && discountedPrice < basePrice;

  const finalPrice = hasDiscount ? discountedPrice : basePrice;

  const tooltipText =
    breakdownTooltip ??
    (hasDiscount
      ? `Giá gốc: ${formatCurrency(
          basePrice,
          currency
        )}\nGiảm giá: -${formatCurrency(
          basePrice - finalPrice,
          currency
        )}\nTổng cộng: ${formatCurrency(finalPrice, currency)}`
      : `Giá cho ${nights} đêm, ${adults} người lớn`);

  const descParts = [];
  if (roomDescription?.bathrooms) {
    descParts.push(`${roomDescription.bathrooms} phòng tắm`);
  }
  if (roomDescription?.livingRooms) {
    descParts.push(`${roomDescription.livingRooms} phòng khách`);
  }
  if (roomDescription?.bedrooms) {
    descParts.push(`${roomDescription.bedrooms} phòng ngủ`);
  }
  if (roomDescription?.isWholeBungalow) {
    descParts.push("Bungalow nguyên căn");
  }
  if (roomDescription?.areaM2) {
    descParts.push(`${roomDescription.areaM2} m²`);
  }
  if (roomDescription?.bedSummary) {
    descParts.push(roomDescription.bedSummary);
  }

  return (
    <article className="card border-primary-subtle shadow-sm mb-3">
      <div className="row g-0">
        {/* Ảnh bên trái */}
        <div className="col-12 col-md-4">
          <div
            className="position-relative h-100"
            style={{ cursor: onViewAvailability ? "pointer" : "default" }}
            onClick={onViewAvailability}
          >
            <img
              src={imageUrl}
              alt={title}
              className="img-fluid h-100 w-100"
              style={{ objectFit: "cover", minHeight: 180 }}
            />
            <button
              type="button"
              className="btn btn-light rounded-circle shadow position-absolute top-0 end-0 m-2 p-2"
              onClick={(e) => {
                e.stopPropagation();
                onToggleFavorite && onToggleFavorite();
              }}
            >
              <i
                className={
                  isFavorite ? "bi bi-heart-fill text-danger" : "bi bi-heart"
                }
              />
            </button>
          </div>
        </div>

        {/* Nội dung bên phải */}
        <div className="col-12 col-md-8">
          <div className="card-body d-flex flex-column h-100">
            {/* Hàng trên: tiêu đề + rating */}
            <div className="d-flex justify-content-between gap-3">
              {/* Bên trái: title + location */}
              <div className="flex-grow-1">
                <div className="d-flex align-items-center flex-wrap gap-2 mb-1">
                  <h5 className="card-title fw-bold mb-0">{title}</h5>

                  {typeof stars === "number" && stars > 0 && (
                    <span className="text-warning small">
                      {"★".repeat(stars)}
                    </span>
                  )}

                  {badgeLabel && (
                    <span className="badge border border-warning text-warning small">
                      {badgeLabel}
                    </span>
                  )}
                </div>

                {/* Location line */}
                <div className="small mb-2">
                  <span className="text-primary">{location}</span>
                  {" · "}
                  <button
                    type="button"
                    className="btn btn-link p-0 small text-decoration-none"
                    onClick={onMapClick}
                  >
                    Xem trên bản đồ
                  </button>
                  {typeof distanceToCenterKm === "number" && (
                    <>
                      {" · "}
                      <span className="text-muted">
                        Cách trung tâm{" "}
                        {distanceToCenterKm.toLocaleString("vi-VN")}km
                      </span>
                    </>
                  )}
                </div>
              </div>

              {/* Bên phải: rating */}
              {(displayScore || ratingLabel || reviewCount) && (
                <div className="text-end" style={{ minWidth: 120 }}>
                  {ratingLabel && (
                    <div className="small fw-semibold">{ratingLabel}</div>
                  )}
                  {typeof reviewCount === "number" && (
                    <div className="small text-muted">
                      {reviewCount.toLocaleString("vi-VN")} đánh giá
                    </div>
                  )}
                  {displayScore != null && (
                    <div className="d-inline-block mt-1">
                      <span
                        className="badge rounded-3 px-2 py-1"
                        style={{
                          backgroundColor: "#003b95",
                          color: "#fff",
                          minWidth: 36,
                        }}
                      >
                        {displayScore.toFixed(1)}
                      </span>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* New label dưới rating */}
            {newLabel && (
              <div className="text-end mt-1">
                <span className="badge bg-warning text-dark small">
                  {newLabel}
                </span>
              </div>
            )}

            <div className="row mt-2">
              {/* Bên trái: thông tin phòng, label */}
              <div className="col-12 col-lg-7">
                {/* Event label */}
                {eventLabel && (
                  <div className="mb-2">
                    <span className="badge bg-success text-white small">
                      {eventLabel}
                    </span>
                  </div>
                )}

                {/* Room name */}
                <div className="fw-semibold mb-1">{roomName}</div>

                {/* Room description */}
                <div className="small text-muted mb-2">
                  {descParts.join(" · ")}
                  {roomDescription?.extraText && (
                    <>
                      <br />
                      {roomDescription.extraText}
                    </>
                  )}
                </div>

                {/* Bao bữa sáng */}
                {includesBreakfast && (
                  <div className="small mb-1 fw-semibold text-success">
                    Bao bữa sáng
                  </div>
                )}

                {/* Miễn phí hủy */}
                {freeCancellation && (
                  <div className="small mb-1 text-success d-flex align-items-start">
                    <i className="bi bi-check-lg me-1" />
                    <span>Miễn phí huỷ</span>
                  </div>
                )}

                {/* Không cần thanh toán trước */}
                {payAtProperty && (
                  <div className="small mb-1 text-success d-flex align-items-start">
                    <i className="bi bi-check-lg me-1" />
                    <span>
                      <span className="fw-semibold">
                        Không cần thanh toán trước
                      </span>{" "}
                      – thanh toán tại chỗ nghỉ
                    </span>
                  </div>
                )}

                {/* Remaining rooms */}
                {remainingRoomsText && (
                  <div className="small text-danger fw-semibold mt-1">
                    {remainingRoomsText}
                  </div>
                )}
              </div>

              {/* Bên phải: giá */}
              <div className="col-12 col-lg-5 text-end d-flex flex-column justify-content-between mt-3 mt-lg-0">
                <div>
                  {/* nights & adults */}
                  <div className="small text-muted mb-1">
                    {nights} đêm, {adults} người lớn
                  </div>

                  {/* price */}
                  <div className="mb-1">
                    {hasDiscount && (
                      <div className="small text-danger text-decoration-line-through">
                        {formatCurrency(basePrice, currency)}
                      </div>
                    )}

                    <div className="fw-bold fs-5 d-inline-flex align-items-center gap-1">
                      {formatCurrency(finalPrice, currency)}
                      {/* info icon */}
                      <span
                        className="text-muted small"
                        title={tooltipText}
                        style={{ cursor: "help" }}
                      >
                        <i className="bi bi-info-circle" />
                      </span>
                    </div>
                  </div>

                  <div className="small text-muted mb-3">
                    Đã bao gồm thuế và phí
                  </div>
                </div>

                <div>
                  <button
                    type="button"
                    className="btn btn-primary w-100 d-flex justify-content-center align-items-center gap-2"
                    onClick={onViewAvailability}
                  >
                    <span>Xem chỗ trống</span>
                    <i className="bi bi-arrow-right-short" />
                  </button>
                </div>
              </div>
            </div>

            {/* Dòng dưới cùng: có thể thêm gì đó nếu cần */}
          </div>
        </div>
      </div>
    </article>
  );
};

export default ListingCard;
