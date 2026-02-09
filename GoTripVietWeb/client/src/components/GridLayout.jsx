import React from "react";

const GridLayout = ({
  title,
  description,
  items,
  maxItems,
  className,
  onItemClick,
  renderItem,
  columnsLg = 3,
}) => {
  const visibleItems =
    maxItems && maxItems > 0 ? items.slice(0, maxItems) : items;
  const lgColClass =
    columnsLg === 4
      ? "col-lg-3"
      : columnsLg === 3
      ? "col-lg-4"
      : columnsLg === 2
      ? "col-lg-6"
      : "col-lg-4";
  return (
    <section className={className}>
      {(title || description) && (
        <header className="mb-3">
          {title && <h4 className="fw-bold mb-1">{title}</h4>}
          {description && (
            <p className="text-muted small mb-0">{description}</p>
          )}
        </header>
      )}

      <div className="row g-3">
        {visibleItems.map((item) => (
          <div key={item.id} className={`col-12 col-md-6 ${lgColClass}`}>
            {typeof renderItem === "function" ? (
              renderItem(item)
            ) : (
              <button
                type="button"
                className="w-100 p-0 border-0 bg-transparent text-start"
                onClick={() => onItemClick && onItemClick(item)}
              >
                <div
                  className="position-relative rounded-4 overflow-hidden"
                  style={{ minHeight: 180 }}
                >
                  <img
                    src={item.imageUrl}
                    alt={item.title}
                    className="w-100 h-100"
                    style={{ objectFit: "cover" }}
                  />

                  <div
                    className="position-absolute top-0 start-0 w-100 h-100"
                    style={{
                      backgroundImage:
                        "linear-gradient(to bottom, rgba(0,0,0,0.6), rgba(0,0,0,0.1) 35%, rgba(0,0,0,0.4))",
                    }}
                  />

                  <div className="position-absolute top-0 start-0 w-100 h-100 d-flex">
                    <div className="p-3 align-self-start">
                      <div className="text-white fw-bold fs-5 mb-1">
                        {item.title}
                      </div>
                      {item.description && (
                        <div className="text-white-50 small">
                          {item.description}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </button>
            )}
          </div>
        ))}
      </div>
    </section>
  );
};

export default GridLayout;
