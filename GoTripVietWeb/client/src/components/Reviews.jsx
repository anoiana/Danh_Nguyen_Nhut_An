import React from "react";

const Reviews = ({
  title = "Khách lưu trú ở đây thích điều gì?",
  reviews,
  onViewAll,
  viewAllText = "Đọc tất cả đánh giá",
}) => {
  if (!reviews || !reviews.length) return null;

  return (
    <section className="mt-4">
      <h4 className="fw-bold mb-3">{title}</h4>

      <div className="row g-3">
        {reviews.map((r) => {
          const initial = r.name?.trim()?.charAt(0).toUpperCase() || "?";

          return (
            <div key={r.id} className="col-12 col-md-4">
              <div className="border rounded-3 p-3 h-100 shadow-sm bg-white d-flex flex-column">
                {/* Header: avatar + tên + quốc gia */}
                <div className="d-flex align-items-center mb-2">
                  <div
                    className="me-3 d-flex align-items-center justify-content-center text-white fw-semibold"
                    style={{
                      width: 40,
                      height: 40,
                      borderRadius: "50%",
                      backgroundColor: "#2c7be5",
                      fontSize: 18,
                      flexShrink: 0,
                    }}
                  >
                    {initial}
                  </div>
                  <div>
                    <div className="fw-semibold">{r.name}</div>
                    {(r.countryName || r.countryFlagEmoji) && (
                      <div className="small text-muted d-flex align-items-center gap-1">
                        {r.countryFlagEmoji && (
                          <span style={{ fontSize: 16 }}>
                            {r.countryFlagEmoji}
                          </span>
                        )}
                        {r.countryName && <span>{r.countryName}</span>}
                      </div>
                    )}
                  </div>
                </div>

                {/* Nội dung đánh giá */}
                <div className="flex-grow-1 mb-2">
                  <p
                    className="mb-2 small text-body"
                    style={{
                      display: "-webkit-box",
                      WebkitLineClamp: 6,
                      WebkitBoxOrient: "vertical",
                      overflow: "hidden",
                    }}
                  >
                    “{r.text}”
                  </p>

                  {r.learnMoreUrl && (
                    <a
                      href={r.learnMoreUrl}
                      className="small text-primary text-decoration-none"
                      target="_blank"
                      rel="noreferrer"
                    >
                      Tìm hiểu thêm
                    </a>
                  )}
                </div>

                {/* footer */}
                <div className="small text-muted mt-auto">
                  {r.translatedBy && (
                    <>
                      Được dịch bởi{" "}
                      <span className="fw-semibold">{r.translatedBy}</span>
                    </>
                  )}
                  {r.originalUrl && (
                    <>
                      {" "}
                      ·{" "}
                      <a
                        href={r.originalUrl}
                        className="text-decoration-none"
                        target="_blank"
                        rel="noreferrer"
                      >
                        {r.originalLinkText || "Xem bản gốc"}
                      </a>
                    </>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Nút xem tất cả */}
      <div className="mt-3">
        <button
          type="button"
          className="btn btn-outline-primary btn-sm"
          onClick={onViewAll}
        >
          {viewAllText}
        </button>
      </div>
    </section>
  );
};

export default Reviews;
