import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import Badge from "react-bootstrap/Badge";
import Spinner from "react-bootstrap/Spinner";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";

import BigCard from "../components/home/BigCard.jsx";
import inventoryApi from "../api/inventoryApi";

const formatDDMM = (day, month) => {
  if (!day || !month) return "—";
  const dd = String(day).padStart(2, "0");
  const mm = String(month).padStart(2, "0");
  return `${dd}/${mm}`;
};

const formatDuration = (days) => {
  if (!days || days <= 1) return "Trong ngày";
  return `${days}N${days - 1}Đ`;
};

const formatShortDate = (dateStr) => {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  return `${day}/${month}`;
};

const normalizeImageUrl = (p) => {
  const base = import.meta.env.VITE_API_URL || "http://localhost:3000";

  const rawImg =
    Array.isArray(p?.images) && p.images.length > 0 ? p.images[0] : null;
  const rawUrl =
    typeof rawImg === "string"
      ? rawImg
      : typeof rawImg?.url === "string"
      ? rawImg.url
      : "";

  let validImage = "";
  if (rawUrl) {
    validImage = rawUrl.startsWith("http")
      ? rawUrl
      : `${base}${rawUrl.startsWith("/") ? "" : "/"}${rawUrl}`;
  }

  return validImage || "https://placehold.co/400x300?text=Tour+Image";
};

const mapTourLikeSearchPage = (p) => {
  const tDetails = p?.tour_details || {};

  const fakeCode = p?._id
    ? `TOUR-${String(p._id).slice(-4).toUpperCase()}`
    : "TOUR-CODE";

  const rawDates = Array.isArray(tDetails.departure_times)
    ? [...tDetails.departure_times]
    : [];
  rawDates.sort((a, b) => new Date(a) - new Date(b));

  const departureDates = rawDates.slice(0, 3).map((d) => formatShortDate(d));

  return {
    id: p._id,
    title: p.title,
    imageUrl: normalizeImageUrl(p),

    price: p.base_price,
    originalPrice: p.base_price ? p.base_price * 1.15 : undefined,

    tourCode: fakeCode,
    startPoint: tDetails.start_point || "—",
    duration: formatDuration(tDetails.duration_days),
    transport: tDetails.transport_type || "—",
    departureDates,
  };
};

const formatDiscount = (type, value) => {
  if (!type) return "—";
  if (type === "percentage") return `${Number(value || 0)}%`;
  // fixed_amount
  const v = Number(value || 0);
  return `${v.toLocaleString("vi-VN")}đ`;
};

const discountTypeLabel = (type) => {
  if (type === "percentage") return "Giảm theo %";
  if (type === "fixed_amount") return "Giảm thẳng";
  return "Giảm giá";
};

export default function EventDetail() {
  const { id } = useParams(); // dùng id hoặc slug đều được (tuỳ route)
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [event, setEvent] = useState(null);
  const [tours, setTours] = useState([]);
  const [error, setError] = useState("");

  const dateRangeText = useMemo(() => {
    if (!event) return "—";
    const s = formatDDMM(event?.start_day, event?.start_month);
    const e = formatDDMM(event?.end_day, event?.end_month);
    return `${s} → ${e}`;
  }, [event]);

  const discountText = useMemo(() => {
    if (!event) return "—";
    return formatDiscount(event?.discount_type, event?.discount_value);
  }, [event]);

  useEffect(() => {
    let alive = true;

    const run = async () => {
      setLoading(true);
      setError("");

      try {
        // 1) Lấy event từ inventory-service
        const evRes = await inventoryApi.getPublicEventByIdOrSlug(id);
        const ev = evRes.data;

        if (!alive) return;
        setEvent(ev);

        // 2) Lấy tours áp dụng từ inventory-service
        const toursRes = await inventoryApi.getPublicEventTours(id);
        const data = toursRes.data;

        const list = Array.isArray(data)
          ? data
          : Array.isArray(data?.products)
          ? data.products
          : Array.isArray(data?.tours)
          ? data.tours
          : Array.isArray(data?.items)
          ? data.items
          : Array.isArray(data?.data)
          ? data.data
          : [];

        const mappedList = list.map((p) => mapTourLikeSearchPage(p));
        if (!alive) return;
        setTours(mappedList);
      } catch (err) {
        if (!alive) return;
        setError("Không tải được Event. Vui lòng thử lại.");
      } finally {
        if (alive) setLoading(false);
      }
    };

    run();

    return () => {
      alive = false;
    };
  }, [id]);

  if (loading) {
    return (
      <Container className="py-4">
        <div className="d-flex align-items-center gap-2">
          <Spinner animation="border" size="sm" />
          <span className="text-muted">Đang tải Event...</span>
        </div>
      </Container>
    );
  }

  if (error || !event) {
    return (
      <Container className="py-4">
        <Alert variant="danger" className="rounded-4">
          {error || "Event không tồn tại."}
        </Alert>
        <Button
          variant="outline-primary"
          className="rounded-pill"
          onClick={() => navigate("/")}
        >
          Về trang chủ
        </Button>
      </Container>
    );
  }

  return (
    <Container className="py-4">
      {/* Ảnh event to nhất */}
      <div className="rounded-4 overflow-hidden shadow-sm mb-4">
        <div
          style={{
            width: "100%",
            aspectRatio: "16/7",
            backgroundImage: `url(${
              event?.image?.url || "https://placehold.co/1200x525?text=Event"
            })`,
            backgroundSize: "cover",
            backgroundPosition: "center",
          }}
        />
      </div>

      {/* Tên + mô tả */}
      <Row className="g-4 align-items-start">
        <Col lg={8}>
          <h2 className="fw-bold mb-2">{event?.name}</h2>
          {event?.description ? (
            <p className="text-secondary mb-0" style={{ lineHeight: 1.6 }}>
              {event.description}
            </p>
          ) : (
            <p className="text-muted fst-italic mb-0">Chưa có mô tả.</p>
          )}
        </Col>

        {/* Box thông tin đặc biệt */}
        <Col lg={4}>
          <div className="border rounded-4 p-3 shadow-sm bg-white">
            <div className="d-flex align-items-center justify-content-between mb-2">
              <div className="fw-bold">Ưu đãi</div>
              <Badge bg="primary" pill>
                {discountTypeLabel(event?.discount_type)}
              </Badge>
            </div>

            <div className="d-flex align-items-end justify-content-between">
              <div className="text-muted small">Giá trị</div>
              <div className="fs-3 fw-bold">{discountText}</div>
            </div>

            <hr className="my-3" />

            <div className="d-flex align-items-center justify-content-between">
              <div className="text-muted small">Thời gian</div>
              <div className="fw-semibold">{dateRangeText}</div>
            </div>

            <div className="mt-3 d-flex flex-wrap gap-2">
              {event?.is_active ? (
                <Badge bg="success" pill>
                  Đang hoạt động
                </Badge>
              ) : (
                <Badge bg="secondary" pill>
                  Tạm tắt
                </Badge>
              )}

              {event?.is_yearly ? (
                <Badge bg="info" pill>
                  Lặp hằng năm
                </Badge>
              ) : (
                <Badge bg="dark" pill>
                  Một lần
                </Badge>
              )}

              {event?.apply_to_all_tours ? (
                <Badge bg="warning" text="dark" pill>
                  Áp dụng tất cả tour
                </Badge>
              ) : (
                <Badge bg="warning" text="dark" pill>
                  Áp dụng tour chọn lọc
                </Badge>
              )}
            </div>
          </div>
        </Col>
      </Row>

      {/* Danh sách tour áp dụng */}
      <div className="mt-5">
        <div className="d-flex align-items-center justify-content-between mb-3">
          <h4 className="fw-bold mb-0">Tour đang áp dụng</h4>
          <span className="text-muted small">{tours.length} tour</span>
        </div>

        {tours.length === 0 ? (
          <Alert variant="light" className="border rounded-4">
            Chưa có tour nào được gán cho Event này.
          </Alert>
        ) : (
          <Row className="g-3">
            {tours.map((item) => (
              <Col key={item.id || item.title} xs={12} md={6} lg={4}>
                <BigCard
                  {...item}
                  onClick={() => navigate(`/product/${item.id}`)}
                />
              </Col>
            ))}
          </Row>
        )}
      </div>
    </Container>
  );
}
