import React, { useMemo, useState } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom"; // [MỚI] Thêm Link
import AuthHeader from "../components/AuthHeader.jsx";
import authApi from "../api/authApi";

function isEmail(v) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

export default function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from?.pathname || "/";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false); // State con mắt
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  const emailValid = useMemo(() => isEmail(email), [email]);

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!emailValid || !password) return;

    setLoading(true);
    setErrorMsg("");

    try {
      const response = await authApi.login({ email, password });

      if (response.token) {
        localStorage.setItem("token", response.token);
        localStorage.setItem("user", JSON.stringify(response.user));

        const roles = response.user?.roles || [];

        // LOGIC ĐIỀU HƯỚNG MỚI
        if (roles.includes("admin")) {
          navigate("/admin/dashboard");
        } else if (roles.includes("partner")) {
          // Nếu là Partner -> Vào dashboard dành riêng cho Partner
          navigate("/partner/dashboard");
        } else {
          // User thường -> Về trang chủ hoặc trang trước đó
          navigate(from, { replace: true });
        }
      }
    } catch (error) {
      console.error("Login failed:", error);
      const message =
        error.response?.data?.message ||
        "Đăng nhập thất bại. Vui lòng kiểm tra email hoặc mật khẩu.";
      setErrorMsg(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <AuthHeader onHelpClick={() => console.log("Help clicked")} />

      <div className="container my-5">
        <div className="row justify-content-center">
          <div className="col-12 col-md-8 col-lg-6">
            <h1 className="fw-bold mb-3">Đăng nhập</h1>
            <p className="text-muted mb-4">
              Hãy đăng nhập bằng tài khoản GoTripViet để trải nghiệm dịch vụ.
            </p>

            {errorMsg && (
              <div className="alert alert-danger" role="alert">
                <i className="bi bi-exclamation-triangle-fill me-2"></i>
                {errorMsg}
              </div>
            )}

            <div className="card shadow-sm border-0 p-4">
              <form onSubmit={submit}>
                <div className="mb-3">
                  <label htmlFor="email" className="form-label fw-semibold">
                    Địa chỉ email
                  </label>
                  <input
                    id="email"
                    type="email"
                    className="form-control form-control-lg"
                    placeholder="name@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>

                <div className="mb-3">
                  <label htmlFor="password" className="form-label fw-semibold">
                    Mật khẩu
                  </label>
                  <div className="position-relative">
                    <input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      className="form-control form-control-lg pe-5"
                      placeholder="Nhập mật khẩu của bạn"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                    />
                    <span
                      onClick={togglePasswordVisibility}
                      style={{
                        position: "absolute",
                        right: "15px",
                        top: "50%",
                        transform: "translateY(-50%)",
                        cursor: "pointer",
                        color: "#6c757d",
                        zIndex: 10,
                      }}
                      title={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                    >
                      <i
                        className={`bi ${showPassword ? "bi-eye-slash-fill" : "bi-eye-fill"
                          } fs-5`}
                      ></i>
                    </span>
                  </div>

                  <div className="d-flex justify-content-end mt-1">
                    <Link
                      to="/forgot-password"
                      className="small text-decoration-none text-muted hover-underline"
                    >
                      Quên mật khẩu?
                    </Link>
                  </div>
                </div>

                <button
                  type="submit"
                  className="btn btn-teal btn-lg w-100 mt-2"
                  disabled={!emailValid || !password || loading}
                  style={{ backgroundColor: "#008080", color: "#fff" }}
                >
                  {loading ? (
                    <span>
                      <span
                        className="spinner-border spinner-border-sm me-2"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Đang xử lý...
                    </span>
                  ) : (
                    "Đăng nhập"
                  )}
                </button>

                {/* --- [MỚI] PHẦN CHUYỂN HƯỚNG ĐĂNG KÝ --- */}
                <div className="text-center mt-3">
                  <span className="text-muted">Bạn chưa có tài khoản? </span>
                  <Link
                    to="/register"
                    className="fw-semibold text-decoration-none"
                    style={{ color: "#008080" }}
                  >
                    Đăng ký ngay
                  </Link>
                </div>
                {/* --------------------------------------- */}
              </form>
            </div>

            <div className="text-divider my-4 text-center text-muted">
              <span>hoặc sử dụng một trong các lựa chọn này</span>
            </div>

            <div className="row g-3">
              <div className="col-12 col-md-6">
                <button
                  type="button"
                  className="btn btn-outline-secondary btn-lg w-100 d-flex align-items-center justify-content-center gap-2"
                >
                  <i className="bi bi-google"></i>
                  <span className="fs-6">Google</span>
                </button>
              </div>
              <div className="col-12 col-md-6">
                <button
                  type="button"
                  className="btn btn-outline-secondary btn-lg w-100 d-flex align-items-center justify-content-center gap-2"
                >
                  <i className="bi bi-facebook"></i>
                  <span className="fs-6">Facebook</span>
                </button>
              </div>
            </div>

            <p className="text-center small mt-4">
              Bằng việc đăng nhập, bạn đồng ý với Điều khoản & Chính sách của
              chúng tôi.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
