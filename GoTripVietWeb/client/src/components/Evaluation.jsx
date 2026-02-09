import React from "react";

const Evaluation = ({
  overallScore,
  overallLabel,
  reviewCount,
  viewAllText = "Đọc tất cả đánh giá",
  categories,
  locationNote,
}) => {
  if (!categories || !categories.length) return null;

  const mid = Math.ceil(categories.length / 2);
  const leftCats = categories.slice(0, mid);
  const rightCats = categories.slice(mid);

  const formatScore = (v) => v.toFixed(1).replace(".", ",");

  const scorePercent = (v) => Math.max(0, Math.min(100, (v / 10) * 100));

  return (
    <section className="bg-white rounded-3 p-3 p-md-4 shadow-sm">
      <h4 className="fw-bold mb-3">Đánh giá của khách</h4>

      {/* Tổng quan */}
      <div className="d-flex flex-wrap align-items-center gap-3 mb-4">
        <div
          className="bg-primary text-white fw-bold rounded-3 d-flex align-items-center justify-content-center"
          style={{ width: 44, height: 44, fontSize: 18 }}
        >
          {formatScore(overallScore)}
        </div>
        <div className="d-flex flex-column flex-sm-row flex-wrap align-items-baseline gap-2">
          <span className="fw-semibold">{overallLabel}</span>
          <span className="text-muted">
            · {reviewCount.toLocaleString("vi-VN")} đánh giá
          </span>
          <button
            type="button"
            className="btn btn-link p-0 ms-sm-2 align-self-start"
          >
            {viewAllText}
          </button>
        </div>
      </div>

      <div className="mb-2 fw-semibold">Hạng mục:</div>

      {/* Các hạng mục */}
      <div className="row">
        <div className="col-12 col-md-6">
          {leftCats.map((c) => (
            <div key={c.id} className="mb-3">
              <div className="d-flex justify-content-between align-items-center mb-1">
                <span>{c.name}</span>
                <span className="fw-semibold">{formatScore(c.score)}</span>
              </div>
              <div
                className="bg-light rounded-pill overflow-hidden"
                style={{ height: 8 }}
              >
                <div
                  className="bg-success"
                  style={{
                    width: `${scorePercent(c.score)}%`,
                    height: "100%",
                  }}
                />
              </div>
            </div>
          ))}
        </div>
        <div className="col-12 col-md-6">
          {rightCats.map((c) => (
            <div key={c.id} className="mb-3">
              <div className="d-flex justify-content-between align-items-center mb-1">
                <span>{c.name}</span>
                <span className="fw-semibold">{formatScore(c.score)}</span>
              </div>
              <div
                className="bg-light rounded-pill overflow-hidden"
                style={{ height: 8 }}
              >
                <div
                  className="bg-success"
                  style={{
                    width: `${scorePercent(c.score)}%`,
                    height: "100%",
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {locationNote && (
        <div className="mt-2 text-success small d-flex align-items-center gap-1">
          <i className="bi bi-arrow-up" />
          <span>{locationNote}</span>
        </div>
      )}
    </section>
  );
};

export default Evaluation;
