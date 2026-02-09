import React, { useState, useEffect } from "react";
import Navbar from "react-bootstrap/Navbar";
import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import Dropdown from "react-bootstrap/Dropdown";
import Button from "react-bootstrap/Button";
import Offcanvas from "react-bootstrap/Offcanvas";
import { useNavigate } from "react-router-dom"; // [MỚI] Để chuyển trang
import authApi from "../../api/authApi"; // [MỚI] Import API lấy thông tin

import "../../styles/layout.css";
import flagVN from "../../assets/flags/flag_vn.png";
import flagEN from "../../assets/flags/flag_en.png";

const DEFAULT_TOPLINKS = [
  { label: "Hỗ trợ", href: "/help" },

  // --- [SỬA DÒNG NÀY] ---
  { label: "Hợp tác với chúng tôi", href: "/partner/register" },
  // ----------------------

  { label: "Mở ứng dụng", href: "#" },
];
export default function Header(props) {
  const {
    logoSrc,
    language = "VI",
    onChangeLanguage,
    topLinks = DEFAULT_TOPLINKS,
    categories = [],
    activeCategoryIndex = 0,
  } = props;

  const navigate = useNavigate();
  const [showMenu, setShowMenu] = useState(false);
  const [user, setUser] = useState(null);
  // Hàm xử lý đăng xuất
  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    setUser(null);
    navigate("/login");
  };
  // Gọi API lấy thông tin user khi component được mount
  useEffect(() => {
    const fetchProfile = async () => {
      const token = localStorage.getItem("token");
      if (!token) return;

      try {
        const userData = await authApi.getProfile();
        setUser(userData);
      } catch (error) {
        console.error("Lỗi lấy thông tin user:", error);
        // Nếu token lỗi thì tự động logout
        if (error.response && error.response.status === 401) {
          handleLogout();
        }
      }
    };

    fetchProfile();
  }, []);

  const handleLogin = () => {
    navigate("/login");
  };

  const handleRegister = () => {
    navigate("/register");
  };

  // --- RENDER USER TRÊN DESKTOP (Dạng Dropdown) ---
  const renderUserDesktop = () => {
    if (!user) return null;

    // Lấy tên hiển thị (ưu tiên fullName, nếu không có thì lấy email)
    const displayName = user.fullName || user.email || "User";
    const initial = displayName.charAt(0).toUpperCase();

    return (
      <Dropdown align="end">
        <Dropdown.Toggle
          as="div" // Render như thẻ div để custom style, không hiện mũi tên mặc định
          className="d-flex align-items-center cursor-pointer"
          style={{ cursor: "pointer" }}
        >
          <div className="bg-white text-primary rounded-pill px-2 py-1 d-flex align-items-center gap-2 shadow-sm">
            <span
              className="small fw-semibold ms-1"
              style={{
                maxWidth: "100px",
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}
            >
              {displayName}
            </span>
            <div
              className="rounded-circle overflow-hidden d-flex align-items-center justify-content-center bg-primary text-white"
              style={{ width: 32, height: 32 }}
            >
              {/* Nếu sau này có avatarUrl thì hiện img, tạm thời hiện chữ cái đầu */}
              <span className="fw-bold">{initial}</span>
            </div>
          </div>
        </Dropdown.Toggle>

        <Dropdown.Menu className="mt-2 shadow border-0 rounded-3">
          <div className="px-3 py-2 border-bottom">
            <div className="fw-bold text-dark">{displayName}</div>
            <div className="small text-muted">{user.email}</div>
          </div>
          <Dropdown.Item href="/profile" className="py-2">
            <i className="bi bi-person-gear me-2"></i>Hồ sơ cá nhân
          </Dropdown.Item>
          <Dropdown.Item href="/my-orders" className="py-2">
            <i className="bi bi-bag-check me-2"></i>Đơn hàng của tôi
          </Dropdown.Item>
          <Dropdown.Divider />
          <Dropdown.Item onClick={handleLogout} className="text-danger py-2">
            <i className="bi bi-box-arrow-right me-2"></i>Đăng xuất
          </Dropdown.Item>
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  // --- RENDER USER TRÊN MOBILE ---
  const renderUserMobile = () => {
    if (!user) return null;

    const displayName = user.fullName || user.email;
    const initial = displayName.charAt(0).toUpperCase();

    return (
      <div className="mb-3 border-bottom pb-3">
        <div className="d-flex align-items-center gap-3 mb-3">
          <div
            className="rounded-circle overflow-hidden d-flex align-items-center justify-content-center bg-primary text-white"
            style={{ width: 50, height: 50, fontSize: "1.2rem" }}
          >
            <span className="fw-bold">{initial}</span>
          </div>
          <div>
            <div className="small text-muted">Xin chào,</div>
            <div className="fw-bold fs-5">{displayName}</div>
          </div>
        </div>
        <Button
          variant="outline-danger"
          size="sm"
          className="w-100"
          onClick={handleLogout}
        >
          Đăng xuất
        </Button>
      </div>
    );
  };

  const isLoggedIn = !!user;

  const isInternalHref = (href) =>
    typeof href === "string" && href.startsWith("/");

  const handleTopLinkClick = (e, href) => {
    if (!href || href === "#") return;
    if (isInternalHref(href)) {
      e.preventDefault();
      navigate(href);
      setShowMenu(false);
    }
  };

  return (
    <header className="gv-header gv-header--blue">
      <Navbar expand="lg" className="py-3">
        <Container>
          <Navbar.Brand href="/" className="me-4">
            <img src={logoSrc} alt="GoTripViet" className="gv-brand" />
          </Navbar.Brand>

          {/* topLinks desktop */}
          <Nav className="ms-auto align-items-center gap-3 d-none d-lg-flex text-white">
            <Dropdown align="end">
              <Dropdown.Toggle
                size="sm"
                className="bg-transparent border-0 text-white px-2 d-flex align-items-center gap-2"
              >
                <img
                  src={language === "EN" ? flagEN : flagVN}
                  alt=""
                  width={18}
                  height={18}
                  style={{ objectFit: "cover", borderRadius: 4 }}
                />
                {language}
              </Dropdown.Toggle>
              <Dropdown.Menu>
                <Dropdown.Item
                  onClick={() => onChangeLanguage && onChangeLanguage("VI")}
                  className="d-flex align-items-center gap-2"
                >
                  <img
                    src={flagVN}
                    alt=""
                    width={18}
                    height={18}
                    style={{ objectFit: "cover", borderRadius: 4 }}
                  />
                  Tiếng Việt
                </Dropdown.Item>
                <Dropdown.Item
                  onClick={() => onChangeLanguage && onChangeLanguage("EN")}
                  className="d-flex align-items-center gap-2"
                >
                  <img
                    src={flagEN}
                    alt=""
                    width={18}
                    height={18}
                    style={{ objectFit: "cover", borderRadius: 4 }}
                  />
                  English
                </Dropdown.Item>
              </Dropdown.Menu>
            </Dropdown>

            {topLinks.map((l, idx) => (
              <a
                key={idx}
                className="text-decoration-none text-white opacity-85 hover-underline d-flex align-items-center gap-1"
                href={l.href || "#"}
                onClick={(e) => handleTopLinkClick(e, l.href)}
              >
                {l.icon}
                {l.label}
              </a>
            ))}

            {/* Auth / User desktop */}
            <div className="d-flex align-items-center gap-2 ms-2">
              {isLoggedIn ? (
                renderUserDesktop()
              ) : (
                <>
                  <Button
                    variant="outline-light"
                    size="sm"
                    onClick={handleLogin}
                  >
                    <i className="bi bi-person me-2" /> Đăng nhập
                  </Button>
                  <Button
                    variant="light"
                    size="sm"
                    className="text-primary fw-semibold"
                    onClick={handleRegister}
                  >
                    Đăng ký
                  </Button>
                </>
              )}
            </div>
          </Nav>

          {/* nút hamburger cho mobile */}
          <button
            type="button"
            className="gv-hamburger d-lg-none"
            aria-label="Mở menu"
            onClick={() => setShowMenu(true)}
          >
            <i className="bi bi-list" />
          </button>
        </Container>
      </Navbar>

      {/* CHỈ HIỆN KHI CÓ categories */}
      {Array.isArray(categories) && categories.length > 0 && (
        <div className="gv-header-cats">
          <Container className="py-2 d-flex flex-wrap align-items-center gap-3">
            {categories.map((c, idx) => (
              <a
                key={idx}
                href={c.href || "#"}
                className={`gv-cat-pill d-flex align-items-center gap-2 ${
                  idx === activeCategoryIndex ? "active" : ""
                }`}
                onClick={(e) => {
                  e.preventDefault();
                  props.onCategoryChange?.(idx);

                  if (location.pathname !== "/") {
                    navigate("/");
                  }

                  setShowMenu(false);
                }}
                role="button"
              >
                {c.icon} <span>{c.label}</span>
              </a>
            ))}
          </Container>
        </div>
      )}

      {/* Offcanvas (mobile toplinks) */}
      <Offcanvas
        placement="end"
        show={showMenu}
        onHide={() => setShowMenu(false)}
      >
        <Offcanvas.Header closeButton>
          <Offcanvas.Title>Menu</Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body>
          {/* User info mobile (nếu đã đăng nhập) */}
          {renderUserMobile()}

          {/* Language */}
          <div className="mb-3">
            <div className="text-muted small mb-2">Ngôn ngữ</div>
            <div className="d-flex gap-2">
              <Button
                variant={language === "VI" ? "primary" : "outline-primary"}
                onClick={() => onChangeLanguage && onChangeLanguage("VI")}
                className="d-flex align-items-center gap-2"
              >
                <img
                  src={flagVN}
                  width={18}
                  height={18}
                  style={{ borderRadius: 4, objectFit: "cover" }}
                  alt="VI"
                />{" "}
                Tiếng Việt
              </Button>
              <Button
                variant={language === "EN" ? "primary" : "outline-primary"}
                onClick={() => onChangeLanguage && onChangeLanguage("EN")}
                className="d-flex align-items-center gap-2"
              >
                <img
                  src={flagEN}
                  width={18}
                  height={18}
                  style={{ borderRadius: 4, objectFit: "cover" }}
                  alt="EN"
                />{" "}
                English
              </Button>
            </div>
          </div>

          {/* Top links */}
          <div className="list-group mb-3">
            {topLinks.map((l, i) => (
              <a
                key={i}
                href={l.href || "#"}
                className="list-group-item list-group-item-action d-flex align-items-center gap-2"
                onClick={(e) => handleTopLinkClick(e, l.href)}
              >
                {l.icon}
                <span>{l.label}</span>
              </a>
            ))}
          </div>

          {/* Auth buttons / user mobile (chỉ hiện khi chưa login) */}
          {!isLoggedIn && (
            <div className="d-flex gap-2">
              <Button
                variant="outline-primary"
                className="flex-fill"
                onClick={handleLogin}
              >
                <i className="bi bi-person me-2" /> Đăng nhập
              </Button>
              <Button
                variant="primary"
                className="flex-fill"
                onClick={handleRegister}
              >
                Đăng ký
              </Button>
            </div>
          )}
        </Offcanvas.Body>
      </Offcanvas>
    </header>
  );
}
