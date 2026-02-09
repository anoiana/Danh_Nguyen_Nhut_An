// src/pages/ForgotPassword.jsx
import React, { useState } from "react";
import { Link } from "react-router-dom";
import AuthHeader from "../components/AuthHeader.jsx";
import authApi from "../api/authApi";

function isEmail(v) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  
  // State quản lý thông báo (Success hoặc Error)
  const [message, setMessage] = useState({ type: "", content: "" });

  const submit = async (e) => {
    e.preventDefault();
    if (!isEmail(email)) return;

    setLoading(true);
    setMessage({ type: "", content: "" });

    try {
      // Gọi API
      await authApi.forgotPassword(email);
      
      // Thành công
      setMessage({
        type: "success",
        content: "Chúng tôi đã gửi link đặt lại mật khẩu vào email của bạn. Vui lòng kiểm tra hộp thư (kể cả mục Spam)."
      });
    } catch (error) {
      // Thất bại
      const errorMsg = error.response?.data?.message || "Không thể gửi yêu cầu. Vui lòng thử lại sau.";
      setMessage({ type: "danger", content: errorMsg });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <AuthHeader />
      
      <div className="container my-5">
        <div className="row justify-content-center">
          <div className="col-12 col-md-6 col-lg-5">
            <div className="card shadow-sm border-0 p-4">
              <div className="text-center mb-4">
                <h3 className="fw-bold text-primary">Quên mật khẩu?</h3>
                <p className="text-muted small">
                  Đừng lo! Hãy nhập email bạn đã đăng ký, chúng tôi sẽ giúp bạn lấy lại mật khẩu.
                </p>
              </div>

              {/* Hiển thị thông báo */}
              {message.content && (
                <div className={`alert alert-${message.type} small`} role="alert">
                  {message.type === "success" ? (
                    <i className="bi bi-check-circle-fill me-2"></i>
                  ) : (
                    <i className="bi bi-exclamation-triangle-fill me-2"></i>
                  )}
                  {message.content}
                </div>
              )}

              <form onSubmit={submit}>
                <div className="mb-4">
                  <label htmlFor="email" className="form-label fw-semibold">Địa chỉ Email</label>
                  <input
                    id="email"
                    type="email"
                    className="form-control form-control-lg"
                    placeholder="name@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    disabled={loading || message.type === "success"} 
                  />
                </div>

                <button 
                  type="submit" 
                  className="btn btn-primary btn-lg w-100 mb-3"
                  style={{ backgroundColor: "#008080", borderColor: "#008080" }}
                  disabled={!email || loading || message.type === "success"}
                >
                  {loading ? (
                    <span>
                      <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                      Đang gửi...
                    </span>
                  ) : (
                    "Gửi hướng dẫn"
                  )}
                </button>
              </form>

              <div className="text-center">
                <Link to="/login" className="text-decoration-none fw-semibold text-secondary">
                  <i className="bi bi-arrow-left me-1"></i> Quay lại Đăng nhập
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}