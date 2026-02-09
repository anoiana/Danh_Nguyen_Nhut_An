import React from "react";
import Navbar from "react-bootstrap/Navbar";
import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import Dropdown from "react-bootstrap/Dropdown";
import Offcanvas from "react-bootstrap/Offcanvas";
import Button from "react-bootstrap/Button";
import "bootstrap-icons/font/bootstrap-icons.css";

import logoUrl from "../assets/logos/logo_border.png";
import flagViUrl from "../assets/flags/flag_vn.png";
import "../styles/auth.css";

export default function AuthHeader({ onHelpClick, onLogoClick }) {
  const handleLogoClick = (e) => {
    e.preventDefault();

    if (onLogoClick) {
      onLogoClick();
    } else {
      // mặc định: quay về Home của container
      window.location.href = "/";
    }
  };

  return (
    <Navbar className="auth-navbar" expand="md" data-bs-theme="light">
      <Container>
        <Navbar.Brand href="/" onClick={handleLogoClick}>
          <img className="brand-logo" src={logoUrl} alt="GoTripViet" />
        </Navbar.Brand>

        <div className="d-md-none ms-auto">
          <Navbar.Toggle aria-controls="auth-offcanvas" />
        </div>

        <Navbar.Offcanvas id="auth-offcanvas" placement="end">
          <Offcanvas.Header closeButton>
            <Offcanvas.Title>Tùy chọn</Offcanvas.Title>
          </Offcanvas.Header>
          <Offcanvas.Body>
            <Nav className="ms-auto gap-3">
              <Dropdown align="end">
                <Dropdown.Toggle
                  variant="light"
                  className="d-flex align-items-center gap-2"
                  id="lang-switch-mobile"
                >
                  <img
                    src={flagViUrl}
                    alt="Tiếng Việt"
                    width={24}
                    height={16}
                  />
                  <span>VI</span>
                </Dropdown.Toggle>
                <Dropdown.Menu>
                  <Dropdown.Item>Tiếng Việt</Dropdown.Item>
                  <Dropdown.Item>English</Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>

              <Button
                variant="outline-dark"
                className="rounded-circle p-0 d-flex align-items-center justify-content-center"
                style={{ width: 38, height: 38 }}
                aria-label="Trợ giúp"
                title="Trợ giúp"
                onClick={onHelpClick}
              >
                <i className="bi bi-question-lg" />
              </Button>
            </Nav>
          </Offcanvas.Body>
        </Navbar.Offcanvas>
      </Container>
    </Navbar>
  );
}
