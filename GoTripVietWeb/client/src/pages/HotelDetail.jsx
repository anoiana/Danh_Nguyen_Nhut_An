import React from "react";
import { Container, Row, Col, Badge } from "react-bootstrap";
import Album from "../components/Album.jsx";
import Rooms from "../components/Room.jsx";
import Evaluation from "../components/Evaluation.jsx";
import Reviews from "../components/Reviews.jsx";
import "bootstrap-icons/font/bootstrap-icons.css";

import {
  HOTEL_NAME,
  HOTEL_ADDRESS,
  HOTEL_SCORE,
  HOTEL_SCORE_LABEL,
  HOTEL_REVIEW_COUNT,
  HOTEL_LOCATION_NOTE,
  HOTEL_IMAGES,
  HOTEL_ROOMS,
  HOTEL_EVALUATION_CATEGORIES,
  HOTEL_REVIEWS,
} from "../data/HotelData.jsx";

const HotelDetail = () => {
  return (
    <Container className="my-4">
      {/* Tiêu đề + rating tổng quan */}
      <header className="mb-3">
        <h2 className="fw-bold mb-2">{HOTEL_NAME}</h2>
        <div className="d-flex flex-wrap align-items-center gap-2 small text-muted mb-2">
          <span>
            <i className="bi bi-geo-alt-fill me-1 text-primary" />
            {HOTEL_ADDRESS}
          </span>
          <span>·</span>
          <button type="button" className="btn btn-link p-0 small">
            Xem trên bản đồ
          </button>
        </div>

        <div className="d-flex flex-wrap align-items-center gap-3">
          <div className="d-flex align-items-center gap-2">
            <span className="bg-primary text-white fw-bold rounded-3 px-2 py-1">
              {HOTEL_SCORE.toFixed(1).replace(".", ",")}
            </span>
            <div className="d-flex flex-column">
              <span className="fw-semibold">{HOTEL_SCORE_LABEL}</span>
              <span className="small text-muted">
                {HOTEL_REVIEW_COUNT} đánh giá
              </span>
            </div>
          </div>
          <Badge bg="success" pill>
            Giá tốt cho kỳ nghỉ ở Cái Bè
          </Badge>
        </div>
      </header>

      {/* Album + mô tả tổng quan */}
      <Row className="g-4 mb-4">
        <Col lg={8}>
          <Album images={HOTEL_IMAGES} />
        </Col>
        <Col lg={4}>
          <div className="bg-white rounded-3 shadow-sm p-3 h-100">
            <h5 className="fw-semibold mb-2">Giới thiệu về chỗ nghỉ</h5>
            <p className="small mb-2">
              Sao Mai Hotel là nơi nghỉ gần gũi với thiên nhiên ở Cái Bè, Tiền
              Giang, cách trung tâm khoảng 3km. Chỗ nghỉ cung cấp WiFi miễn phí,
              sân hiên nhìn ra vườn và các hoạt động trải nghiệm địa phương như
              đi thuyền, đạp xe, tham quan chợ nổi...
            </p>
            <ul className="small mb-2">
              <li>Bữa sáng rất được khách yêu thích</li>
              <li>Dịch vụ đưa đón sân bay theo yêu cầu</li>
              <li>Chủ nhà thân thiện, hỗ trợ đặt tour</li>
            </ul>
            <button className="btn btn-outline-primary btn-sm">
              Tìm hiểu thêm
            </button>
          </div>
        </Col>
      </Row>

      {/* Phòng trống */}
      <div className="mb-4">
        <Rooms rooms={HOTEL_ROOMS} />
      </div>

      {/* Đánh giá của khách */}
      <div className="mb-4">
        <Evaluation
          overallScore={HOTEL_SCORE}
          overallLabel={HOTEL_SCORE_LABEL}
          reviewCount={HOTEL_REVIEW_COUNT}
          categories={HOTEL_EVALUATION_CATEGORIES}
          locationNote={HOTEL_LOCATION_NOTE}
        />
      </div>

      {/* Khách lưu trú ở đây thích điều gì? */}
      <div className="mb-4">
        <Reviews
          reviews={HOTEL_REVIEWS}
          onViewAll={() => {
            console.log("Xem tất cả đánh giá");
          }}
        />
      </div>
    </Container>
  );
};

export default HotelDetail;
