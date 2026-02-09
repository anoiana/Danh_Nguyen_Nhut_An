import React from "react";
import "../styles/home.css";

export default function Event({
  backgroundUrl,
  alt = "Event banner",
  ratio = "3/1",
  className = "",
  href,
  onClick,
  target = "_self",
}) {
  const handleClick = (e) => {
    if (onClick) onClick();
    if (!href) e.preventDefault();
  };

  return (
    <a
      href={href || "#"}
      target={target}
      rel={target === "_blank" ? "noopener noreferrer" : undefined}
      onClick={handleClick}
      aria-label={alt}
      className={`d-block rounded-4 overflow-hidden ${className}`}
      style={{ textDecoration: "none", cursor: "pointer" }}
    >
      <div
        style={{
          width: "100%",
          aspectRatio: String(ratio),
          backgroundImage: `url(${backgroundUrl})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          display: "block",
        }}
      />
    </a>
  );
}
