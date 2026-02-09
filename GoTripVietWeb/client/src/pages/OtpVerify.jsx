import React, { useEffect, useMemo, useRef, useState } from "react";
import "../styles/otp.css";
import AuthHeader from "../components/AuthHeader.jsx";

export default function OtpVerify({
  email,
  length = 6,
  onSubmit,
  onResend,
  onBackToLogin,
  resendSeconds = 60,
}) {
  const [values, setValues] = useState(Array.from({ length }, () => ""));
  const [resendLeft, setResendLeft] = useState(resendSeconds);
  const inputsRef = useRef([]);

  // focus ô đầu tiên
  useEffect(() => {
    if (inputsRef.current[0]) {
      inputsRef.current[0].focus();
    }
  }, []);

  // đếm ngược resend
  useEffect(() => {
    if (resendLeft <= 0) return;
    const t = setInterval(() => setResendLeft((s) => s - 1), 1000);
    return () => clearInterval(t);
  }, [resendLeft]);

  const code = useMemo(() => values.join(""), [values]);
  const isComplete = code.length === length && /^[0-9]+$/.test(code);

  const setAt = (idx, ch) => {
    setValues((prev) => {
      const next = [...prev];
      next[idx] = ch;
      return next;
    });
  };

  const handleChange = (idx, v) => {
    const digit = v.replace(/\D/g, "").slice(-1) || "";
    setAt(idx, digit);
    if (digit && idx < length - 1 && inputsRef.current[idx + 1]) {
      inputsRef.current[idx + 1].focus();
    }
  };

  const handleKeyDown = (idx, e) => {
    if (e.key === "Backspace") {
      if (values[idx]) {
        setAt(idx, "");
        return;
      }
      if (idx > 0) {
        if (inputsRef.current[idx - 1]) {
          inputsRef.current[idx - 1].focus();
        }
        setAt(idx - 1, "");
      }
    }
    if (e.key === "ArrowLeft" && idx > 0 && inputsRef.current[idx - 1]) {
      inputsRef.current[idx - 1].focus();
    }
    if (
      e.key === "ArrowRight" &&
      idx < length - 1 &&
      inputsRef.current[idx + 1]
    ) {
      inputsRef.current[idx + 1].focus();
    }
  };

  const handlePaste = (idx, e) => {
    e.preventDefault();
    const text = e.clipboardData.getData("text").replace(/\D/g, "");
    if (!text) return;
    const chars = text.slice(0, length - idx).split("");
    setValues((prev) => {
      const next = [...prev];
      chars.forEach((c, i) => {
        next[idx + i] = c;
      });
      return next;
    });
    const last = Math.min(idx + chars.length, length - 1);
    if (inputsRef.current[last]) {
      inputsRef.current[last].focus();
    }
  };

  const submit = (e) => {
    e.preventDefault();
    if (!isComplete) return;
    if (onSubmit) onSubmit(code);
  };

  return (
    <>
      {/* Header auth dùng chung */}
      <AuthHeader onHelpClick={() => console.log("Help clicked from OTP")} />

      {/* Nội dung OTP */}
      <div className="container my-5">
        <div className="row justify-content-center">
          <div className="col-12 col-md-8 col-lg-6">
            <h1 className="fw-bold mb-3">Kiểm tra hộp thư của bạn</h1>
            <p className="text-muted mb-4">
              Mã xác minh đã được gửi đến <strong>{email}</strong>. Vui lòng
              nhập mã này để tiếp tục.
            </p>

            <form onSubmit={submit}>
              <div className="d-flex justify-content-center gap-3 mb-4">
                {values.map((val, i) => (
                  <input
                    key={i}
                    ref={(el) => {
                      inputsRef.current[i] = el;
                    }}
                    inputMode="numeric"
                    pattern="[0-9]*"
                    maxLength={1}
                    className="otp-input form-control text-center"
                    value={val}
                    onChange={(e) => handleChange(i, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(i, e)}
                    onPaste={(e) => handlePaste(i, e)}
                    aria-label={`Ký tự OTP ${i + 1}`}
                  />
                ))}
              </div>

              <button
                type="submit"
                className="btn btn-teal btn-lg w-100"
                disabled={!isComplete}
              >
                Tiếp tục
              </button>
            </form>

            <div className="text-center my-3">
              {resendLeft > 0 ? (
                <span className="text-muted">
                  Yêu cầu mã mới sau {resendLeft}s
                </span>
              ) : (
                <button
                  className="btn btn-link text-decoration-none fw-semibold"
                  onClick={() => {
                    setValues(Array.from({ length }, () => ""));
                    setResendLeft(resendSeconds);
                    if (onResend) onResend();
                    if (inputsRef.current[0]) {
                      inputsRef.current[0].focus();
                    }
                  }}
                >
                  Yêu cầu mã mới
                </button>
              )}
            </div>

            <div className="text-center mb-4">
              <button
                className="btn btn-link text-decoration-none fw-semibold text-danger"
                onClick={() => onBackToLogin && onBackToLogin()}
              >
                Quay lại trang đăng nhập
              </button>
            </div>

            <hr />
            <p className="text-center small mt-4">
              Bằng việc đăng nhập hoặc tạo tài khoản, bạn xác nhận đã đọc và
              đồng ý với{" "}
              <a href="#" className="fw-bold link-danger text-decoration-none">
                Điều khoản &amp; Điều kiện
              </a>{" "}
              cùng{" "}
              <a href="#" className="fw-bold link-danger text-decoration-none">
                Chính sách An toàn &amp; Bảo mật
              </a>
              .
            </p>
            <p className="text-center text-muted">Bản quyền – GoTripViet</p>
          </div>
        </div>
      </div>
    </>
  );
}
