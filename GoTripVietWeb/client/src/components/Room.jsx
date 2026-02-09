import React from "react";
import {
  Row,
  Col,
  Form,
  Button,
  OverlayTrigger,
  Tooltip,
} from "react-bootstrap";

const formatMoney = (value, currency = "USD") =>
  value.toLocaleString("vi-VN", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  });

const tickLine = (label) =>
  !label ? null : (
    <div className="d-flex align-items-start mb-1">
      <span
        className="text-success me-2"
        style={{ fontSize: 14, marginTop: 2 }}
      >
        ✓
      </span>
      <span className="small">{label}</span>
    </div>
  );

const Rooms = ({ rooms, onChangeSelection }) => {
  const [selected, setSelected] = React.useState({});

  const handleChangeRoomQty = (roomId, qty) => {
    setSelected((prev) => {
      const next = { ...prev, [roomId]: qty };
      if (onChangeSelection) onChangeSelection(next);
      return next;
    });
  };

  if (!rooms || !rooms.length) return null;

  return (
    <section className="bg-white rounded-3 shadow-sm p-3 p-md-4">
      <h4 className="fw-bold mb-3">Phòng trống</h4>

      {/* Header row */}
      <div className="bg-primary text-white fw-semibold py-2 px-2 rounded-2 mb-2 d-none d-md-flex">
        <div className="flex-grow-1">Loại chỗ nghỉ</div>
        <div style={{ width: "9rem" }}>Số lượng khách</div>
        <div style={{ width: "11rem" }}>Giá hôm nay</div>
        <div style={{ width: "14rem" }}>Các lựa chọn</div>
        <div style={{ width: "8rem" }}>Chọn phòng</div>
      </div>

      {rooms.map((room) => {
        const {
          id,
          title,
          bedDescription,
          facilities,
          amenities,
          maxGuests,
          price,
          options,
        } = room;

        const currency = price.currency || "USD";
        const perNightLabel = price.perNightLabel || "1 đêm";
        const isDiscounted =
          price.discountedPrice != null &&
          price.discountedPrice < price.originalPrice;

        const displayPrice = isDiscounted
          ? price.discountedPrice
          : price.originalPrice;

        const remaining = options.remainingRooms || 0;
        const selectedQty = selected[id] || 0;

        return (
          <div
            key={id}
            className="border rounded-3 mb-3 overflow-hidden"
            style={{ borderColor: "#d0e4ff" }}
          >
            <Row className="g-0">
              {/* Loại chỗ nghỉ */}
              <Col md={5} className="border-end p-3">
                <div className="mb-2">
                  <div className="fw-bold text-primary">{title}</div>
                  <div className="small text-muted">{bedDescription}</div>
                </div>

                {/* Thông tin cơ bản */}
                <div className="small mb-2">
                  {facilities.sizeM2 && (
                    <div className="mb-1">
                      <span className="me-2">📏</span>
                      {facilities.sizeM2} m²
                    </div>
                  )}
                  {facilities.hasView && (
                    <div className="mb-1">
                      <span className="me-2">🌄</span>
                      Tầm nhìn ra khung cảnh
                    </div>
                  )}
                  {facilities.hasAirConditioner && (
                    <div className="mb-1">
                      <span className="me-2">❄️</span>
                      Điều hòa không khí
                    </div>
                  )}
                  {facilities.hasPrivateBathroom && (
                    <div className="mb-1">
                      <span className="me-2">🚿</span>
                      Phòng tắm riêng
                    </div>
                  )}
                  {facilities.hasFlatTV && (
                    <div className="mb-1">
                      <span className="me-2">📺</span>
                      TV màn hình phẳng
                    </div>
                  )}
                  {facilities.hasMinibar && (
                    <div className="mb-1">
                      <span className="me-2">🍹</span>
                      Minibar
                    </div>
                  )}
                  {facilities.hasWifi && (
                    <div className="mb-1">
                      <span className="me-2">📶</span>
                      WiFi miễn phí
                    </div>
                  )}
                </div>

                {/* Đồ dùng sinh hoạt */}
                <div className="mt-2">
                  {tickLine(
                    amenities.toiletries && "Đồ vệ sinh cá nhân miễn phí"
                  )}
                  {tickLine(amenities.shower && "Vòi sen")}
                  {tickLine(amenities.toilet && "Nhà vệ sinh")}
                  {tickLine(amenities.towels && "Khăn tắm")}
                  {tickLine(
                    amenities.tiledFloor && "Sàn lát gạch/ đá cẩm thạch"
                  )}
                  {tickLine(amenities.tv && "TV")}
                  {tickLine(amenities.slippers && "Dép")}
                  {tickLine(amenities.fridge && "Tủ lạnh")}
                  {tickLine(amenities.telephone && "Điện thoại")}
                  {tickLine(amenities.fan && "Quạt máy")}
                  {tickLine(
                    amenities.extraLongBed && "Giường cực dài (> 2 mét)"
                  )}
                  {tickLine(amenities.cableChannels && "Truyền hình cáp")}
                  {tickLine(amenities.wardrobe && "Tủ hoặc phòng để quần áo")}
                  {tickLine(amenities.diningArea && "Khu vực phòng ăn")}
                  {tickLine(amenities.diningTable && "Bàn ăn")}
                  {tickLine(amenities.clothesRack && "Giá treo quần áo")}
                </div>
              </Col>

              {/* Số lượng khách */}
              <Col
                md={1}
                className="border-end p-3 d-flex justify-content-center align-items-start"
              >
                <div className="text-center mt-1">
                  {Array.from({ length: maxGuests }).map((_, i) => (
                    <span key={i} className="me-1" style={{ fontSize: 16 }}>
                      👤
                    </span>
                  ))}
                </div>
              </Col>

              {/* Giá hôm nay */}
              <Col md={2} className="border-end p-3">
                <div className="small text-muted mb-1">
                  {isDiscounted && (
                    <div className="text-danger text-decoration-line-through">
                      {formatMoney(price.originalPrice, currency)}
                    </div>
                  )}

                  <OverlayTrigger
                    placement="top"
                    overlay={
                      isDiscounted ? (
                        <Tooltip id={`tooltip-price-${id}`}>
                          Giá gốc: {formatMoney(price.originalPrice, currency)}
                          <br />
                          Giảm giá: -
                          {formatMoney(
                            price.originalPrice - displayPrice,
                            currency
                          )}
                          <br />
                          <strong>
                            Tổng cộng: {formatMoney(displayPrice, currency)}
                          </strong>
                        </Tooltip>
                      ) : (
                        <></>
                      )
                    }
                  >
                    <div
                      className="fw-bold fs-5"
                      style={{ cursor: isDiscounted ? "pointer" : "default" }}
                    >
                      {formatMoney(displayPrice, currency)}
                    </div>
                  </OverlayTrigger>
                </div>

                <div className="small text-muted mb-2">{perNightLabel}</div>

                {price.serviceFeePercent != null && (
                  <div className="small">
                    <span className="fw-semibold">Bao gồm:</span>{" "}
                    {price.serviceFeePercent}% phí dịch vụ
                  </div>
                )}
                {price.vatPercent != null && (
                  <div className="small">
                    <span className="fw-semibold">Không bao gồm:</span>{" "}
                    {price.vatPercent}% Thuế GTGT
                  </div>
                )}
              </Col>

              {/* Các lựa chọn */}
              <Col md={2} className="border-end p-3 small">
                {options.breakfastPrice != null && (
                  <div className="mb-2">
                    <span className="fw-semibold">Bữa sáng</span> –{" "}
                    {formatMoney(
                      options.breakfastPrice,
                      options.breakfastCurrency || currency
                    )}
                  </div>
                )}

                {options.partialRefund && (
                  <div className="mb-1 fw-semibold">Hoàn tiền một phần</div>
                )}

                {options.prepayBeforeArrival && (
                  <div className="mb-1">
                    Thanh toán cho chỗ nghỉ trước khi đến
                  </div>
                )}

                {options.noCreditCardNeeded && (
                  <div className="mb-1 text-success">
                    <span className="me-1">💳</span>
                    Không cần thẻ tín dụng
                  </div>
                )}

                {options.hasGeniusDiscount && (
                  <div className="mb-1 text-primary fw-semibold">
                    Có thể được áp dụng giảm giá đặc biệt
                  </div>
                )}

                {remaining > 0 && (
                  <div className="mb-1 text-danger small">
                    Chúng tôi còn {remaining} phòng
                  </div>
                )}
              </Col>

              {/* Chọn phòng + nút đặt */}
              <Col md={2} className="p-3">
                <div className="d-flex align-items-center mb-3">
                  <Form.Select
                    size="sm"
                    value={selectedQty}
                    onChange={(e) =>
                      handleChangeRoomQty(id, Number(e.target.value))
                    }
                  >
                    <option value={0}>0</option>
                    {Array.from({ length: remaining || 0 }).map((_, i) => {
                      const qty = i + 1;
                      const total = displayPrice * qty;
                      return (
                        <option key={qty} value={qty}>
                          {qty} phòng ({formatMoney(total, currency)})
                        </option>
                      );
                    })}
                  </Form.Select>
                </div>

                <Button
                  variant="primary"
                  className="w-100 mb-1"
                  size="sm"
                  disabled={remaining === 0}
                >
                  Tôi sẽ đặt
                </Button>
                <div className="small text-muted">
                  Chỉ mất có 2 phút
                  <br />
                  Bạn sẽ không bị trừ tiền ngay
                </div>
              </Col>
            </Row>
          </div>
        );
      })}
    </section>
  );
};

export default Rooms;
