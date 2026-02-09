import React from "react";
import Modal from "react-bootstrap/Modal";
import Carousel from "react-bootstrap/Carousel";
import "../styles/product.css";

const Album = ({ images, maxGridImages = 7, className }) => {
  const [showModal, setShowModal] = React.useState(false);
  const [currentIndex, setCurrentIndex] = React.useState(0);

  if (!images || !images.length) return null;

  const openAt = (index) => {
    setCurrentIndex(index);
    setShowModal(true);
  };

  const close = () => setShowModal(false);

  const total = images.length;
  const gridImages = images.slice(0, maxGridImages);
  const remainingCount = total > maxGridImages ? total - maxGridImages : 0;

  const big = gridImages[0];
  const rightTop = gridImages[1];
  const rightBottom = gridImages[2];
  const bottomRow = gridImages.slice(3);

  return (
    <>
      {/* GRID VIEW */}
      <div className={`album-grid ${className || ""}`}>
        <div className="album-grid-top">
          {/* Big left image */}
          {big && (
            <button
              type="button"
              className="album-img-btn album-img-big"
              onClick={() => openAt(0)}
            >
              <img
                src={big.url}
                alt={big.alt || "Ảnh 1"}
                className="album-img"
              />
            </button>
          )}

          {/* Right two images */}
          <div className="album-grid-right">
            {rightTop && (
              <button
                type="button"
                className="album-img-btn album-img-half"
                onClick={() => openAt(1)}
              >
                <img
                  src={rightTop.url}
                  alt={rightTop.alt || "Ảnh 2"}
                  className="album-img"
                />
              </button>
            )}
            {rightBottom && (
              <button
                type="button"
                className="album-img-btn album-img-half"
                onClick={() => openAt(2)}
              >
                <img
                  src={rightBottom.url}
                  alt={rightBottom.alt || "Ảnh 3"}
                  className="album-img"
                />
              </button>
            )}
          </div>
        </div>

        {/* Bottom thumbnails */}
        {bottomRow.length > 0 && (
          <div className="album-grid-bottom">
            {bottomRow.map((img, idx) => {
              const globalIndex = 3 + idx;
              const isLastThumb = idx === bottomRow.length - 1;
              return (
                <button
                  key={globalIndex}
                  type="button"
                  className="album-img-btn album-img-thumb"
                  onClick={() => openAt(globalIndex)}
                >
                  <img
                    src={img.url}
                    alt={img.alt || `Ảnh ${globalIndex + 1}`}
                    className="album-img"
                  />
                  {isLastThumb && remainingCount > 0 && (
                    <div className="album-overlay">+{remainingCount} ảnh</div>
                  )}
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* MODAL SLIDESHOW */}
      <Modal
        show={showModal}
        onHide={close}
        centered
        size="lg"
        contentClassName="bg-black border-0"
      >
        <Modal.Body className="p-0">
          <Carousel
            activeIndex={currentIndex}
            onSelect={(idx) => setCurrentIndex(idx)}
            indicators={total > 1}
            controls={total > 1}
            interval={null}
            className="album-carousel"
          >
            {images.map((img, idx) => (
              <Carousel.Item key={idx}>
                <div className="album-slide-wrapper">
                  <img
                    src={img.url}
                    alt={img.alt || `Ảnh ${idx + 1}`}
                    className="album-slide-img"
                  />
                </div>
              </Carousel.Item>
            ))}
          </Carousel>
        </Modal.Body>
      </Modal>
    </>
  );
};

export default Album;
