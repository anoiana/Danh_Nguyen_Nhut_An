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
  if (score == null) return "";
  if (score >= 9) return "Tuyệt hảo";
  if (score >= 8) return "Rất tốt";
  if (score >= 7) return "Tốt";
  return "Đánh giá";
}

const SmallCard = ({
  imageUrl,
  stayType,
  stars,
  name,
  ratingScore,
  reviewCount,
  distanceToCenterKm,
  priceFrom,
  currency = "VND",
  isFavorite,
  onToggleFavorite,
  onClick,
}) => {
  const score =
    typeof ratingScore === "number"
      ? Math.round(ratingScore * 10) / 10
      : undefined;
  const ratingLabel = getRatingLabel(ratingScore);

  return (
    <article
      className="card border-0 shadow-sm h-100"
      style={{
        borderRadius: "1rem",
        overflow: "hidden",
        cursor: onClick ? "pointer" : "default",
      }}
      onClick={onClick}
    >
      {/* Ảnh + heart */}
      <div className="position-relative">
        <img
          src={imageUrl}
          alt={name}
          className="w-100"
          style={{ height: 180, objectFit: "cover" }}
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

      <div className="card-body pb-3">
        {/* Loại lưu trú + sao */}
        <div className="small text-muted mb-1">
          {stayType}
          {typeof stars === "number" && stars > 0 && (
            <>
              <br />
              <span className="text-warning">{"★".repeat(stars)}</span>
            </>
          )}
        </div>

        {/* Tên hotel */}
        <h6 className="fw-bold mb-2 text-dark">{name}</h6>

        {/* Rating */}
        {(score != null || ratingLabel || reviewCount) && (
          <div className="d-flex align-items-center mb-2">
            {score != null && (
              <span
                className="badge rounded-3 me-2"
                style={{
                  backgroundColor: "#003b95",
                  color: "#fff",
                  minWidth: 32,
                  textAlign: "center",
                }}
              >
                {score.toFixed(1)}
              </span>
            )}
            <div className="small">
              {ratingLabel && (
                <span className="fw-semibold">{ratingLabel}</span>
              )}
              {typeof reviewCount === "number" && (
                <span className="text-muted">
                  {" · "}
                  {reviewCount.toLocaleString("vi-VN")} đánh giá
                </span>
              )}
            </div>
          </div>
        )}

        {/* Khoảng cách tới trung tâm */}
        {typeof distanceToCenterKm === "number" && (
          <div className="small text-muted mb-3 d-flex align-items-center">
            <i className="bi bi-geo-alt me-1" />
            <span>
              {distanceToCenterKm.toLocaleString("vi-VN")}km từ trung tâm
            </span>
          </div>
        )}

        {/* Giá bắt đầu từ */}
        <div className="mt-auto small">
          <span className="text-muted">Bắt đầu từ </span>
          <span className="fw-bold text-dark">
            {formatCurrency(priceFrom, currency)}
          </span>
        </div>
      </div>
    </article>
  );
};

export default SmallCard;
