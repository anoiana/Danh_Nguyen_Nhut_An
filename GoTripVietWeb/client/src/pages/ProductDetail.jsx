// src/pages/ProductDetail.jsx
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Badge from "react-bootstrap/Badge";
import Spinner from "react-bootstrap/Spinner";
import Form from "react-bootstrap/Form";
import Accordion from "react-bootstrap/Accordion";
import Carousel from "react-bootstrap/Carousel";
import catalogApi from "../api/catalogApi";
import inventoryApi from "../api/inventoryApi";
import BigCard from "../components/home/BigCard";

import {
  formatCurrency,
  formatDuration,
  formatDateWithWeekday,
  mapProductToCard,
} from "../utils/formatData";

export default function ProductDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  // --- STATES ---
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [relatedTours, setRelatedTours] = useState([]);

  // Image Gallery State
  const [index, setIndex] = useState(0); // [MỚI] Theo dõi ảnh đang hiển thị

  // Inventory States
  const [inventoryItems, setInventoryItems] = useState([]);
  const [selectedInventory, setSelectedInventory] = useState(null);
  const [selectedDate, setSelectedDate] = useState("");

  // Hàm xử lý khi slide chuyển động (để cập nhật thumbnail active)
  const handleSelect = (selectedIndex) => {
    setIndex(selectedIndex);
  };

  // --- 1. GỌI API LẤY CHI TIẾT ---
  useEffect(() => {
    const fetchProduct = async () => {
      try {
        setLoading(true);
        const res = await catalogApi.getById(id);
        const data = res.data || res;
        setProduct(data);

        // Reset gallery index về 0 khi load tour mới
        setIndex(0);

        // Mặc định chọn ngày đầu tiên
        if (data.tour_details?.departure_times?.length > 0) {
          const sorted = [...data.tour_details.departure_times].sort(
            (a, b) => new Date(a) - new Date(b)
          );
          setSelectedDate(sorted[0]);
        }
        window.scrollTo(0, 0);
      } catch (error) {
        console.error("Lỗi tải tour:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
  }, [id]);

  // --- 2. GỌI API LẤY TOUR LIÊN QUAN ---
  useEffect(() => {
    if (!product || !product.category_ids || product.category_ids.length === 0)
      return;

    const fetchRelated = async () => {
      try {
        const firstCat = product.category_ids[0];
        const categoryId =
          typeof firstCat === "object" ? firstCat._id : firstCat;

        const res = await catalogApi.getAll({
          category_id: categoryId,
          limit: 5,
          product_type: "tour",
        });

        const list = res.products || (res.data && res.data.products) || [];
        const filtered = list
          .filter((p) => p._id !== product._id)
          .slice(0, 4)
          .map((p) => mapProductToCard(p));

        setRelatedTours(filtered);
      } catch (error) {
        console.error("Lỗi tải tour liên quan:", error);
      }
    };
    fetchRelated();
  }, [product]);

  // --- 3. GỌI API LẤY INVENTORY ---
  useEffect(() => {
    if (!id) return;
    const fetchInventory = async () => {
      try {
        const res = await inventoryApi.getInventoryByProductId(id);
        const items = res.data || res;
        setInventoryItems(items);

        if (items.length > 0) {
          setSelectedInventory(items[0]);
          setSelectedDate(items[0].tour_details.date);
        }
      } catch (error) {
        console.error("Lỗi lấy lịch khởi hành:", error);
      }
    };
    fetchInventory();
  }, [id]);

  // --- 4. XỬ LÝ ĐẶT TOUR ---
  const handleBookingClick = () => {
    if (!selectedDate) {
      alert("Vui lòng chọn ngày khởi hành!");
      return;
    }

    const transportType =
      product.tour_details?.transport_type || "Đang cập nhật";
    const schedule = selectedInventory?.tour_details?.transport_schedule || {};

    let transportInfoData = null;

    if (transportType === "Máy bay") {
      transportInfoData = {
        type: "flight",
        details: {
          airline: schedule.airline || "Đang cập nhật",
          depart: {
            date: formatDateWithWeekday(selectedDate),
            time: schedule.departure_time || "Đang cập nhật",
            code: schedule.depart_code || "Đang cập nhật",
          },
          return: {
            date: "Theo lịch trình",
            time: schedule.return_time || "Đang cập nhật",
            code: schedule.return_code || "Đang cập nhật",
          },
        },
      };
    } else if (["Xe du lịch", "Xe giường nằm", "Ô tô"].includes(transportType)) {
      transportInfoData = {
        type: "bus",
        details: {
          vehicle: "Xe du lịch đời mới",
          depart: {
            date: formatDateWithWeekday(selectedDate),
            time: schedule.departure_time || "Đang cập nhật",
            location:
              schedule.pickup_location ||
              product.tour_details?.start_point ||
              "Đang cập nhật",
          },
        },
      };
    } else {
      transportInfoData = {
        type: "other",
        details: {
          vehicle: transportType,
          note: "Vui lòng xem chi tiết trong lịch trình tour",
        },
      };
    }

    navigate("/order", {
      state: {
        product: {
          id: product._id,
          title: product.title,
          image:
            product.images?.[0]?.url ??
            product.images?.[0] ??
            "https://placehold.co/600x400",
          code:
            product.product_code ||
            `TOUR-${product._id.slice(-6).toUpperCase()}`,
          basePrice: selectedInventory
            ? selectedInventory.price
            : product.base_price,
          transportInfo: transportInfoData,
          bookingInfo: {
            inventoryId: selectedInventory._id,
            adults: 1,
            children: 0,
            date: selectedDate,
          },
        },
      },
    });
  };

  const renderMeals = (meals) => {
    if (!meals || meals.length === 0) return "Tự túc";
    const count = String(meals.length).padStart(2, "0");
    const text = meals.join(", ").toLowerCase();
    return `${count} (${text})`;
  };

  if (loading)
    return (
      <div className="text-center py-5">
        <Spinner animation="border" variant="primary" />
      </div>
    );
  if (!product)
    return (
      <div className="text-center py-5">
        <h3>Không tìm thấy tour!</h3>
      </div>
    );

  const t = product.tour_details || {};
  const policies = t.policy_notes || [];
  const midIndex = Math.ceil(policies.length / 2);
  const leftPolicies = policies.slice(0, midIndex);
  const rightPolicies = policies.slice(midIndex);

  return (
    <Container className="py-5">
      {/* HEADER & GALLERY */}
      <div className="mb-4">
        <h1 className="fw-bold text-dark mb-2">{product.title}</h1>
        <div className="d-flex flex-wrap align-items-center gap-3 text-muted mb-3 small">
          <span>
            <i className="bi bi-star-fill text-warning"></i> 5.0 (Tuyệt vời)
          </span>
          <span>|</span>
          <span>
            <i className="bi bi-geo-alt-fill text-danger"></i>{" "}
            {product.location_ids?.[0]?.name || "Đang cập nhật"}
          </span>
          <span>|</span>
          <span className="text-primary fw-bold bg-light px-2 py-1 rounded">
            MÃ: {product._id.slice(-6).toUpperCase()}
          </span>
        </div>

        {/* --- [MỚI] IMAGE GALLERY SECTION --- */}
        <div>
          {/* 1. Ảnh lớn (Main Carousel) */}
          <div
            className="rounded-4 overflow-hidden position-relative shadow-sm mb-3"
            style={{ height: "480px", background: "#f0f0f0" }}
          >
            {product.images && product.images.length > 0 ? (
              <Carousel
                activeIndex={index}
                onSelect={handleSelect}
                interval={null} // Tắt tự động chạy để người dùng dễ xem
                indicators={false} // Ẩn chấm tròn mặc định cho đỡ rối
              >
                {product.images.map((img, idx) => (
                  <Carousel.Item key={idx} style={{ height: "480px" }}>
                    <img
                      src={img.url ?? img}
                      alt={`${product.title} - ${idx + 1}`}
                      className="w-100 h-100 object-fit-cover"
                      onError={(e) => { e.target.src = "https://placehold.co/1200x600?text=No+Image"; }}
                    />
                  </Carousel.Item>
                ))}
              </Carousel>
            ) : (
              <img
                src="https://placehold.co/1200x600?text=No+Image"
                alt={product.title}
                className="w-100 h-100 object-fit-cover"
              />
            )}
          </div>

          {/* 2. Hàng Thumbnail (Ảnh nhỏ bên dưới) */}
          {product.images && product.images.length > 1 && (
            <div
              className="d-flex gap-2 overflow-auto pb-2"
              style={{ whiteSpace: 'nowrap', scrollBehavior: 'smooth' }}
            >
              {product.images.map((img, idx) => (
                <div
                  key={idx}
                  onClick={() => setIndex(idx)} // Bấm vào để chuyển ảnh lớn
                  style={{
                    width: '100px',
                    height: '70px',
                    flexShrink: 0,
                    cursor: 'pointer',
                    borderRadius: '8px',
                    overflow: 'hidden',
                    border: index === idx ? '2px solid #0d6efd' : '2px solid transparent', // Viền xanh khi active
                    opacity: index === idx ? 1 : 0.7,
                    transition: 'all 0.2s ease'
                  }}
                  className="thumbnail-item"
                >
                  <img
                    src={img.url ?? img}
                    alt="thumb"
                    className="w-100 h-100 object-fit-cover"
                  />
                </div>
              ))}
            </div>
          )}
        </div>
        {/* --- HẾT PHẦN IMAGE GALLERY --- */}
      </div>

      <Row>
        <Col lg={8}>
          {/* 1. THÔNG TIN TÓM TẮT */}
          <Card className="border-0 shadow-sm mb-5 bg-light bg-opacity-50">
            <Card.Body className="d-flex justify-content-between align-items-center flex-wrap gap-3 py-4">
              <div className="d-flex align-items-center gap-3">
                <div className="bg-white p-3 rounded-circle text-primary shadow-sm">
                  <i className="bi bi-clock-history fs-4"></i>
                </div>
                <div>
                  <small className="text-muted d-block text-uppercase" style={{ fontSize: "11px" }}>
                    Thời gian
                  </small>
                  <strong>{formatDuration(t.duration_days)}</strong>
                </div>
              </div>
              <div className="d-flex align-items-center gap-3">
                <div className="bg-white p-3 rounded-circle text-success shadow-sm">
                  <i className="bi bi-bus-front-fill fs-4"></i>
                </div>
                <div>
                  <small className="text-muted d-block text-uppercase" style={{ fontSize: "11px" }}>
                    Phương tiện
                  </small>
                  <strong>{t.transport_type}</strong>
                </div>
              </div>
              <div className="d-flex align-items-center gap-3">
                <div className="bg-white p-3 rounded-circle text-warning shadow-sm">
                  <i className="bi bi-building-check fs-4"></i>
                </div>
                <div>
                  <small className="text-muted d-block text-uppercase" style={{ fontSize: "11px" }}>
                    Khách sạn
                  </small>
                  <strong>{t.hotel_rating} sao</strong>
                </div>
              </div>
              <div className="d-flex align-items-center gap-3">
                <div className="bg-white p-3 rounded-circle text-danger shadow-sm">
                  <i className="bi bi-geo-alt fs-4"></i>
                </div>
                <div>
                  <small className="text-muted d-block text-uppercase" style={{ fontSize: "11px" }}>
                    Khởi hành
                  </small>
                  <strong>{t.start_point}</strong>
                </div>
              </div>
            </Card.Body>
          </Card>

          {/* 2. LỊCH KHỞI HÀNH */}
          <div className="mb-5" id="schedule-section">
            <h4 className="fw-bold mb-4 text-uppercase border-start border-4 border-primary ps-3">
              Lịch khởi hành & Giá vé
            </h4>
            {inventoryItems.length > 0 ? (
              <div className="table-responsive shadow-sm rounded-3 border">
                <table className="table table-hover mb-0 align-middle">
                  <thead className="table-light">
                    <tr>
                      <th className="py-3 ps-4">Ngày khởi hành</th>
                      <th>Giá tour</th>
                      <th>Trạng thái</th>
                      <th className="text-end pe-4">Chọn ngày</th>
                    </tr>
                  </thead>
                  <tbody>
                    {inventoryItems.map((item) => {
                      const dateStr = item.tour_details.date;
                      const availableSlots =
                        item.tour_details.total_slots -
                        item.tour_details.booked_slots;
                      const isSelected =
                        selectedInventory && selectedInventory._id === item._id;
                      return (
                        <tr
                          key={item._id}
                          className={isSelected ? "table-primary" : ""}
                        >
                          <td className="ps-4">
                            <div className="fw-bold text-primary">
                              {formatDateWithWeekday(dateStr)}
                            </div>
                          </td>
                          <td className="fw-bold text-danger fs-5">
                            {formatCurrency(item.price)}
                          </td>
                          <td>
                            {availableSlots > 0 ? (
                              <Badge bg="success" className="rounded-pill">
                                Còn {availableSlots} chỗ
                              </Badge>
                            ) : (
                              <Badge bg="secondary">Hết chỗ</Badge>
                            )}
                          </td>
                          <td className="text-end pe-4">
                            <Button
                              variant={isSelected ? "primary" : "outline-primary"}
                              size="sm"
                              className="rounded-pill px-3 fw-bold"
                              disabled={availableSlots <= 0}
                              onClick={() => {
                                setSelectedDate(dateStr);
                                setSelectedInventory(item);
                              }}
                            >
                              {isSelected ? (
                                <>
                                  <i className="bi bi-check2"></i> Đã chọn
                                </>
                              ) : (
                                "Chọn"
                              )}
                            </Button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="alert alert-warning">Chưa có lịch khởi hành.</div>
            )}
          </div>

          {/* 3. LỊCH TRÌNH */}
          <div className="mb-5">
            <h4 className="fw-bold mb-4 text-uppercase border-start border-4 border-primary ps-3">
              Lịch trình chi tiết
            </h4>
            <Accordion
              defaultActiveKey="0"
              className="shadow-sm rounded overflow-hidden custom-accordion"
            >
              {t.itinerary?.map((item, idx) => (
                <Accordion.Item
                  eventKey={idx.toString()}
                  key={idx}
                  className="border-bottom"
                >
                  <Accordion.Header>
                    <div className="fw-bold text-dark">
                      <span className="badge bg-primary rounded-pill me-2">
                        Ngày {item.day}
                      </span>
                      {item.title}
                    </div>
                  </Accordion.Header>
                  <Accordion.Body className="bg-light bg-opacity-10 pt-3 pb-4">
                    <div
                      className="mb-4 text-secondary ps-2 border-start border-2 border-light"
                      style={{
                        whiteSpace: "pre-line",
                        lineHeight: "1.7",
                        textAlign: "justify",
                      }}
                    >
                      {item.details || "Đang cập nhật..."}
                    </div>
                    <div className="d-inline-flex align-items-center gap-2 px-3 py-2 rounded-3 bg-white border shadow-sm">
                      <i className="bi bi-cup-hot-fill text-warning fs-5"></i>
                      <span className="fw-bold text-dark small">Bữa ăn:</span>
                      <span className="text-muted small fw-medium">
                        {renderMeals(item.meals)}
                      </span>
                    </div>
                  </Accordion.Body>
                </Accordion.Item>
              ))}
            </Accordion>
          </div>

          {/* 4. THÔNG TIN THÊM */}
          {t.trip_highlights && (
            <div className="mb-5">
              <h4 className="text-center fw-bold mb-4 text-uppercase border-bottom pb-2">
                THÔNG TIN THÊM VỀ CHUYẾN ĐI
              </h4>
              <Row className="g-4">
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-map text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Điểm tham quan</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.attractions || "Đang cập nhật"}
                    </p>
                  </div>
                </Col>
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-cup-straw text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Ẩm thực</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.cuisine || "Đang cập nhật"}
                    </p>
                  </div>
                </Col>
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-people text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Đối tượng thích hợp</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.suitable_for || "Mọi lứa tuổi"}
                    </p>
                  </div>
                </Col>
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-clock-history text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Thời gian lý tưởng</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.ideal_time || "Quanh năm"}
                    </p>
                  </div>
                </Col>
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-car-front text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Phương tiện</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.transport || t.transport_type}
                    </p>
                  </div>
                </Col>
                <Col md={4} sm={6}>
                  <div className="h-100 p-3 bg-light bg-opacity-50 rounded-3">
                    <i className="bi bi-tag text-primary fs-3 mb-2 d-block"></i>
                    <h6 className="fw-bold text-dark">Khuyến mãi</h6>
                    <p className="text-muted small m-0">
                      {t.trip_highlights.promotion || "Đã bao gồm trong giá"}
                    </p>
                  </div>
                </Col>
              </Row>
            </div>
          )}

          {/* 5. THÔNG TIN CẦN LƯU Ý */}
          {policies.length > 0 && (
            <div className="mb-5">
              <h4 className="text-center fw-bold mb-4 text-uppercase border-bottom pb-2">
                NHỮNG THÔNG TIN CẦN LƯU Ý
              </h4>
              <Row>
                <Col md={6}>
                  <Accordion className="mb-3">
                    {leftPolicies.map((policy, idx) => (
                      <Accordion.Item
                        eventKey={`L-${idx}`}
                        key={idx}
                        className="mb-2 border rounded overflow-hidden"
                      >
                        <Accordion.Header className="fw-bold small bg-white">
                          <span className="fw-bold" style={{ fontSize: "0.95rem" }}>
                            {policy.title}
                          </span>
                        </Accordion.Header>
                        <Accordion.Body className="bg-light small text-secondary">
                          <div style={{ whiteSpace: "pre-line" }}>
                            {policy.content}
                          </div>
                        </Accordion.Body>
                      </Accordion.Item>
                    ))}
                  </Accordion>
                </Col>
                <Col md={6}>
                  <Accordion>
                    {rightPolicies.map((policy, idx) => (
                      <Accordion.Item
                        eventKey={`R-${idx}`}
                        key={idx}
                        className="mb-2 border rounded overflow-hidden"
                      >
                        <Accordion.Header className="fw-bold small bg-white">
                          <span className="fw-bold" style={{ fontSize: "0.95rem" }}>
                            {policy.title}
                          </span>
                        </Accordion.Header>
                        <Accordion.Body className="bg-light small text-secondary">
                          <div style={{ whiteSpace: "pre-line" }}>
                            {policy.content}
                          </div>
                        </Accordion.Body>
                      </Accordion.Item>
                    ))}
                  </Accordion>
                </Col>
              </Row>
            </div>
          )}
        </Col>

        {/* --- CỘT PHẢI: FORM ĐẶT TOUR --- */}
        <Col lg={4}>
          <div className="sticky-top" style={{ top: "20px", zIndex: 10 }}>
            <Card className="border-0 shadow-lg rounded-4 overflow-hidden">
              <div className="bg-primary text-white p-3 text-center bg-gradient">
                <h5 className="m-0 fw-bold text-uppercase">
                  Đặt ngay tour này
                </h5>
              </div>
              <Card.Body className="p-4">
                <div className="mb-4">
                  <label className="fw-bold small mb-2 text-muted">
                    NGÀY KHỞI HÀNH
                  </label>
                  <Form.Select
                    value={selectedDate}
                    onChange={(e) => {
                      const dateVal = e.target.value;
                      const invItem = inventoryItems.find(
                        (i) => i.tour_details.date === dateVal
                      );
                      if (invItem) {
                        setSelectedDate(dateVal);
                        setSelectedInventory(invItem);
                      }
                    }}
                    className="fw-bold text-primary form-select-lg border-primary bg-light"
                  >
                    {inventoryItems.length === 0 && (
                      <option value="" disabled>
                        -- Hết chỗ --
                      </option>
                    )}
                    {inventoryItems.map((item, i) => {
                      const available =
                        item.tour_details.total_slots -
                        item.tour_details.booked_slots;
                      return (
                        <option
                          key={i}
                          value={item.tour_details.date}
                          disabled={available <= 0}
                        >
                          {formatDateWithWeekday(item.tour_details.date)}{" "}
                          {available <= 0 ? "(Hết)" : ""}
                        </option>
                      );
                    })}
                  </Form.Select>
                </div>

                <div className="mb-4 text-center">
                  <div className="small text-muted mb-1">
                    Giá tour trọn gói / khách
                  </div>
                  <div className="fs-1 fw-bold text-danger lh-1">
                    {formatCurrency(
                      selectedInventory
                        ? selectedInventory.price
                        : product.base_price
                    )}
                  </div>
                  <div className="small text-success mt-1">
                    <i className="bi bi-check-circle-fill"></i> Đã bao gồm thuế
                    & phí
                  </div>
                </div>

                <Button
                  variant="danger"
                  size="lg"
                  className="w-100 fw-bold py-3 text-uppercase shadow hover-scale"
                  onClick={handleBookingClick}
                  disabled={!selectedInventory}
                >
                  Yêu cầu đặt tour
                </Button>
              </Card.Body>
            </Card>
          </div>
        </Col>
      </Row>

      {/* RELATED TOURS */}
      {relatedTours.length > 0 && (
        <div className="mt-5 pt-5 border-top">
          <h3 className="fw-bold mb-4 text-dark border-start border-4 border-warning ps-3">
            CÁC CHƯƠNG TRÌNH KHÁC
          </h3>
          <Row>
            {relatedTours.map((item) => (
              <Col key={item.id} xs={12} md={6} lg={3} className="mb-4">
                <BigCard
                  {...item}
                  onClick={() => navigate(`/product/${item.id}`)}
                />
              </Col>
            ))}
          </Row>
        </div>
      )}
    </Container>
  );
}