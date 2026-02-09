import React, { useMemo } from "react";
import { useLocation, useNavigate } from "react-router-dom";

const formatVND = (v) =>
  (v || 0).toLocaleString("vi-VN", { style: "currency", currency: "VND" });

function makeOrderId() {
  const rand = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `GTV-${rand}`;
}

export default function OrderSuccess() {
  const navigate = useNavigate();
  const location = useLocation();

  // bạn có thể pass state theo 2 kiểu:
  // navigate("/order-success", { state: { payload: {...} } })
  // hoặc navigate("/order-success", { state: {...} })
  const payload = location.state?.payload || location.state || {};

  const orderId = useMemo(
    () => payload.orderId || makeOrderId(),
    [payload.orderId]
  );

  const title =
    payload.source === "flight"
      ? "Đặt vé máy bay thành công"
      : payload.source === "hotel"
      ? "Đặt phòng thành công"
      : "Thanh toán thành công";

  return (
    <div className="container py-4 py-lg-5">
      <div className="row justify-content-center">
        <div className="col-12 col-lg-9 col-xl-8">
          <div className="card border-0 shadow-sm">
            <div className="card-body p-4 p-lg-5">
              <div className="d-flex align-items-start gap-3">
                <div
                  className="rounded-circle d-inline-flex align-items-center justify-content-center"
                  style={{
                    width: 44,
                    height: 44,
                    background: "#EAF7F0",
                    color: "#198754",
                  }}
                >
                  {/* bootstrap icon (nếu bạn có bootstrap-icons). không có thì vẫn ok */}
                  <i className="bi bi-check-lg" style={{ fontSize: 22 }} />
                </div>

                <div className="flex-grow-1">
                  <div className="h4 fw-bold mb-1">{title}</div>
                  <div className="text-muted">
                    Cảm ơn bạn. Đơn của bạn đã được ghi nhận và đang được xử lý.
                  </div>
                </div>
              </div>

              <hr className="my-4" />

              <div className="row g-3">
                <div className="col-12 col-md-6">
                  <div className="small text-muted">Mã đơn</div>
                  <div className="fw-semibold">{orderId}</div>
                </div>

                <div className="col-12 col-md-6">
                  <div className="small text-muted">Tổng thanh toán</div>
                  <div className="fw-semibold">
                    {payload.totalPrice != null
                      ? formatVND(payload.totalPrice)
                      : "—"}
                  </div>
                </div>

                <div className="col-12">
                  <div className="small text-muted">Email nhận xác nhận</div>
                  <div className="fw-semibold">{payload.email || "—"}</div>
                </div>

                {!!payload.summaryText && (
                  <div className="col-12">
                    <div className="small text-muted">Tóm tắt</div>
                    <div className="fw-semibold">{payload.summaryText}</div>
                  </div>
                )}
              </div>

              <div className="alert alert-light border mt-4 mb-0">
                <div className="fw-semibold mb-1">Tiếp theo</div>
                <div className="text-muted">
                  Bạn có thể kiểm tra email để xem xác nhận. Nếu chưa thấy, hãy
                  xem trong Spam/Quảng cáo.
                </div>
              </div>

              <div className="d-flex flex-column flex-sm-row gap-2 justify-content-end mt-4">
                <button
                  type="button"
                  className="btn btn-outline-primary"
                  onClick={() => navigate("/", { replace: true })}
                >
                  Về trang chủ
                </button>

                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={() => {
                    // sau này bạn có thể điều hướng sang trang "đơn của tôi"
                    // tạm thời quay về trang chủ
                    navigate("/", { replace: true });
                  }}
                >
                  Xem đơn của tôi
                </button>
              </div>
            </div>
          </div>

          <div className="text-center text-muted small mt-3">
            Nếu cần hỗ trợ, vui lòng liên hệ GoTripViet.
          </div>
        </div>
      </div>
    </div>
  );
}
