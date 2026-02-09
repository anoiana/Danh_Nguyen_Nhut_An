import React from "react";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import "../../styles/layout.css";

export default function Footer({
  logoSrc,
  columns = [
    {
      title: "Sản phẩm",
      links: [
        { label: "Lưu trú" },
        { label: "Chuyến bay" },
        { label: "Chuyến bay & Khách sạn" },
        { label: "Đưa đón sân bay" },
        { label: "Thuê xe" },
        { label: "Hoạt động" },
      ],
    },
    {
      title: "Về chúng tôi",
      links: [
        { label: "Về GoTripViet" },
        { label: "Cách đặt chỗ" },
        { label: "Liên hệ chúng tôi" },
        { label: "Trợ giúp" },
      ],
    },
    {
      title: "Điều khoản và cài đặt",
      links: [
        { label: "Bảo mật và Cookie" },
        { label: "Điều khoản dịch vụ" },
        { label: "Tranh chấp đối tác" },
      ],
    },
  ],
  note = "GoTripViet là sản phẩm dự án công nghệ thông tin của sinh viên Lê Công Tuấn 52200033 - Danh Nguyễn Nhựt An 52200008",
  copyright = "Copyright © 2025 GoTripViet. All rights reserved",
}) {
  return (
    <footer className="gv-footer text-white mt-5 pt-5">
      <Container>
        <Row className="gy-4">
          <Col
            md={3}
            className="d-flex justify-content-center align-items-center"
          >
            <img src={logoSrc} alt="GoTripViet" className="gv-footer-logo" />
          </Col>
          {columns.map((col, i) => (
            <Col key={i} md={3}>
              <h5 className="fw-bold mb-3">{col.title}</h5>
              <ul className="list-unstyled d-grid gap-2">
                {col.links.map((l, j) => (
                  <li key={j}>
                    <a
                      className="text-white text-decoration-none opacity-85"
                      href={l.href || "#"}
                    >
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </Col>
          ))}
        </Row>
        <hr className="border-light border-opacity-50" />
        <div className="text-center">
          <p className="opacity-75 small mb-0">{note}</p>
          <p className="text-center m-0 fw-semibold">{copyright}</p>
        </div>
      </Container>
    </footer>
  );
}
