// src/pages/UserLayout.jsx
import React from "react";
import Header from "../components/common/Header.jsx";
import Footer from "../components/common/Footer.jsx";
// Logo
import logoOutlineUrl from "../assets/logos/logo_outline.png";
import logoOutLineBesideUrl from "../assets/logos/logo_outline_beside.png";

const UserLayout = ({ children, activeCategoryIndex, onCategoryChange }) => {
  const handleLogin = () => {
    // sau này bạn có thể thay bằng điều hướng qua container, ở đây tạm thời dùng path local
    window.location.href = "/login";
  };

  const handleRegister = () => {
    window.location.href = "/login";
  };

  return (
    <>
      {/* Header cố định */}
      <Header
        logoSrc={logoOutLineBesideUrl}
        onLogin={handleLogin}
        onRegister={handleRegister}
        categories={[]}
        activeCategoryIndex={activeCategoryIndex}
        onCategoryChange={onCategoryChange}
        // userName="Nguyễn Văn A"
        // avatarUrl="https://example.com/avatar.jpg"
      />

      <main>{children}</main>

      <Footer logoSrc={logoOutlineUrl} />
    </>
  );
};

export default UserLayout;
