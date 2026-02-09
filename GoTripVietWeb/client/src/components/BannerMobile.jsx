import React from "react";
import Container from "react-bootstrap/Container";
import "../styles/home.css";

export default function BannerMobile({
  backgroundUrl,
  title,
  subtitle = "Tải ứng dụng để trải nghiệm tiện hơn mọi lúc, mọi nơi",
  qrUrl,
  googlePlayBadgeUrl,
  appStoreBadgeUrl,
}) {
  return (
    <section
      className="gv-banner-mobile d-lg-none"
      style={{ backgroundImage: `url(${backgroundUrl})` }}
    >
      <div className="gv-overlay" />
      <Container className="position-relative py-4">
        <div className="text-white">
          <h2 className="fw-bold mb-2">{title}</h2>
          <p className="mb-3 lead">{subtitle}</p>
          <div className="d-flex align-items-center gap-3">
            {qrUrl && (
              <img src={qrUrl} alt="QR" loading="lazy" className="gv-qr" />
            )}
            <div className="d-flex flex-column gap-2">
              {googlePlayBadgeUrl && (
                <img
                  src={googlePlayBadgeUrl}
                  alt="Google Play"
                  loading="lazy"
                  className="gv-store-badge"
                />
              )}
              {appStoreBadgeUrl && (
                <img
                  src={appStoreBadgeUrl}
                  alt="App Store"
                  loading="lazy"
                  className="gv-store-badge"
                />
              )}
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
}
