import React from "react";
import BookingStepper from "../components/order/stepper";
import { useNavigate } from "react-router-dom";

const ConfirmOrder = () => {
  const navigate = useNavigate();
  const handleCompleteBooking = () => {
    // điều hướng sang trang đặt thành công
    navigate("/order-success", {
      state: {
        payload: {
          source: "hotel",
          orderId: `HT-${Date.now()}`,
          totalPrice: 419717, // bạn thay bằng biến tổng tiền thật của bạn
          email: "biyeo126@gmail.com", // bạn thay bằng email thật user nhập
          summaryText: "Sao Mai Hotel · 17/11/2025 - 18/11/2025",
        },
      },
    });
  };

  return (
    <div className="bg-light min-vh-100 d-flex flex-column">
      {/* Thanh bước đặt phòng */}
      <BookingStepper currentStep={3} />

      {/* Nội dung chính */}
      <div className="container my-4 flex-grow-1">
        <div className="row g-4">
          {/* Cột trái: thông tin khách sạn + giá */}
          <div className="col-lg-4">
            {/* Thông tin khách sạn */}
            <div className="card mb-3">
              <div className="row g-0">
                <div className="col-4">
                  <div
                    className="h-100 w-100 rounded-start"
                    style={{
                      backgroundImage:
                        "url('https://via.placeholder.com/160x120?text=Hotel')",
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }}
                  />
                </div>
                <div className="col-8">
                  <div className="card-body py-3">
                    <h6 className="card-title mb-1">Sao Mai Hotel</h6>
                    <p className="small mb-1">
                      306 An Loi Village, Dong Hoa Hiep, Cái Bè, Việt Nam
                    </p>
                    <div className="d-flex align-items-center justify-content-between">
                      <div className="small text-muted">
                        Vị trí tuyệt vời — 9,4
                      </div>
                      <span className="badge bg-primary text-white">9,4</span>
                    </div>
                    <div className="small text-muted mt-2">
                      WiFi miễn phí • Gần sân bay • Nhà hàng
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Chi tiết đặt phòng */}
            <div className="card mb-3">
              <div className="card-body">
                <h6 className="card-title mb-3">Chi tiết đặt phòng của bạn</h6>
                <div className="d-flex justify-content-between small mb-2">
                  <div>
                    <div className="text-muted">Nhận phòng</div>
                    <div className="fw-semibold">T2, 17 tháng 11 2025</div>
                    <div className="text-muted">Từ 14:00</div>
                  </div>
                  <div className="text-end">
                    <div className="text-muted">Trả phòng</div>
                    <div className="fw-semibold">T3, 18 tháng 11 2025</div>
                    <div className="text-muted">Đến 12:00</div>
                  </div>
                </div>
                <hr />
                <div className="small">
                  <div>Chỉ còn 1 ngày nữa!</div>
                  <div>1 phòng cho 2 người lớn</div>
                </div>
              </div>
            </div>

            {/* Tóm tắt giá */}
            <div className="card mb-3">
              <div className="card-body">
                <h6 className="card-title mb-3">Tóm tắt giá</h6>

                <div className="d-flex justify-content-between small mb-1">
                  <span>Giá gốc</span>
                  <span>VND 466.352</span>
                </div>

                <div className="d-flex justify-content-between small mb-1 text-success">
                  <span>Giảm giá Genius</span>
                  <span>- VND 46.635</span>
                </div>

                <hr />

                <div className="d-flex justify-content-between align-items-end mb-1">
                  <div className="small fw-semibold">Tổng cộng</div>
                  <div className="text-end">
                    <div className="text-decoration-line-through small text-muted">
                      VND 466.352
                    </div>
                    <div className="h5 mb-0 text-danger">VND 419.717</div>
                  </div>
                </div>
                <div className="small text-muted">
                  Đã bao gồm thuế và phí. Bảo gồm VND 49.596 phí và thuế.
                </div>

                <div className="small text-muted mt-2">
                  • 8 % Thuế GTGT — VND 31.090
                  <br />• 5 % Phí dịch vụ — VND 18.506
                </div>

                <button type="button" className="btn btn-link btn-sm px-0 mt-2">
                  Xem chi tiết
                </button>
              </div>
            </div>

            {/* Lịch thanh toán */}
            <div className="card mb-3">
              <div className="card-body small">
                <h6 className="card-title mb-2">Lịch thanh toán của bạn</h6>
                <p className="mb-0">
                  Bạn sẽ phải trả khoản thanh toán trước là 50% tổng tiền phòng
                  sau khi đặt phòng.
                </p>
              </div>
            </div>

            {/* Chi phí huỷ */}
            <div className="card mb-3">
              <div className="card-body small">
                <h6 className="card-title mb-2">Chi phí huỷ bao nhiêu?</h6>
                <p className="mb-0">
                  Nếu hủy, bạn phải thanh toán <strong>VND 209.858</strong>.
                </p>
              </div>
            </div>

            {/* Mã khuyến mại */}
            <div className="card mb-3">
              <div className="card-body small">
                <h6 className="card-title mb-2">Bạn có mã khuyến mại không?</h6>
                <input
                  type="text"
                  className="form-control mb-2"
                  placeholder="Nhập mã khuyến mại"
                />
                <button
                  type="button"
                  className="btn btn-outline-primary btn-sm"
                >
                  Áp dụng
                </button>
              </div>
            </div>
          </div>

          {/* Cột phải: xác nhận đặt phòng */}
          <div className="col-lg-8">
            <div className="card mb-3">
              <div className="card-body">
                <h5 className="card-title mb-3">
                  Không yêu cầu thông tin thanh toán
                </h5>
                <p className="small mb-3">
                  Thanh toán của bạn sẽ do Sao Mai Hotel xử lý, nên bạn không
                  cần nhập thông tin thanh toán cho đơn đặt này.
                </p>

                <div className="form-check mb-3">
                  <input
                    className="form-check-input"
                    type="checkbox"
                    id="marketingEmail"
                    defaultChecked
                  />
                  <label
                    className="form-check-label small"
                    htmlFor="marketingEmail"
                  >
                    Tôi đồng ý nhận email marketing từ GoTripViet, bao gồm
                    khuyến mãi, đề xuất được cá nhân hóa, ấn phẩm thông tin,
                    trải nghiệm du lịch bổ ích và cập nhật về các dịch vụ của
                    GoTripViet.
                  </label>
                </div>

                <p className="small text-muted mb-3">
                  Bạn có thể hủy đăng ký nhận email marketing bất cứ lúc nào
                  bằng cách nhấp vào liên kết huỷ đăng ký trong email. Khi nhấn
                  “Hoàn tất đặt chỗ”, bạn đồng ý với việc chúng tôi xử lý dữ
                  liệu cá nhân của bạn theo Chính sách quyền riêng tư.
                </p>

                <p className="small text-muted mb-4">
                  Đặt phòng của bạn là đặt phòng trực tiếp với Sao Mai Hotel và
                  chịu trách nhiệm thanh toán tại chỗ nghỉ, bạn đồng ý với{" "}
                  <a href="#">điều kiện đặt phòng</a>,{" "}
                  <a href="#">điều khoản chung</a> và{" "}
                  <a href="#">chính sách bảo mật</a> của chúng tôi.
                </p>

                <button
                  type="button"
                  className="btn btn-primary btn-lg mb-3"
                  onClick={handleCompleteBooking}
                >
                  Hoàn tất đặt chỗ
                </button>

                <div>
                  <button type="button" className="btn btn-link p-0 small">
                    Các điều kiện đặt phòng là gì?
                  </button>
                </div>
              </div>
            </div>

            {/* Có thể thêm block FAQ / thông tin thêm sau nếu cần */}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConfirmOrder;
