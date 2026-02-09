import React, { useEffect, useMemo, useRef, useState } from "react";

const EmailOtpModal = ({
  email,
  otpLength = 6,
  demoOtp = "123456",
  onClose,
  onVerified, // gọi khi otp đúng
}) => {
  const [otp, setOtp] = useState(() => Array(otpLength).fill(""));
  const [error, setError] = useState(null);
  const inputRefs = useRef([]);

  const otpValue = useMemo(() => otp.join(""), [otp]);
  const isComplete = useMemo(() => otp.every((x) => x !== ""), [otp]);

  // reset mỗi lần mở modal + focus ô đầu
  useEffect(() => {
    const t = setTimeout(() => {
      inputRefs.current?.[0]?.focus?.();
    }, 0);
    return () => clearTimeout(t);
  }, []);

  const setDigitAt = (index, raw) => {
    const digit = (raw || "").replace(/\D/g, "").slice(0, 1);
    const next = [...otp];
    next[index] = digit;
    setOtp(next);
    setError(null);

    if (digit && index < otpLength - 1) {
      inputRefs.current?.[index + 1]?.focus?.();
    }
  };

  const handleKeyDown = (index, e) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current?.[index - 1]?.focus?.();
    }
  };

  const handlePaste = (index, e) => {
    const text = e.clipboardData?.getData("text") || "";
    const digits = text.replace(/\D/g, "").slice(0, otpLength);
    if (!digits) return;

    e.preventDefault();

    const next = [...otp];
    for (let i = 0; i < otpLength; i++) next[i] = digits[i] || "";
    setOtp(next);
    setError(null);

    const focusIndex = Math.min(digits.length, otpLength) - 1;
    inputRefs.current?.[Math.max(focusIndex, 0)]?.focus?.();
  };

  const handleVerify = () => {
    if (!isComplete) return;

    if (otpValue === demoOtp) {
      setError(null);
      onVerified?.(otpValue);
    } else {
      setError(`Mã OTP không đúng. Vui lòng thử lại (mã demo: ${demoOtp}).`);
    }
  };

  if (!open) return null;

  return (
    <div className="position-fixed top-0 start-0 w-100 h-100 bg-dark bg-opacity-50 d-flex justify-content-center align-items-center">
      <div
        className="bg-white rounded-3 shadow p-4"
        style={{ maxWidth: 420, width: "100%" }}
      >
        <div className="d-flex justify-content-between align-items-start mb-3">
          <h5 className="mb-0">Xác minh địa chỉ email của bạn</h5>
          <button
            type="button"
            className="btn btn-sm btn-link text-muted text-decoration-none"
            onClick={onClose}
          >
            ✕
          </button>
        </div>

        <p className="small mb-3">
          Chúng tôi đã gửi mã xác minh demo đến{" "}
          <strong>{email || "email của bạn"}</strong>. <br />
          Vui lòng nhập mã <strong>{demoOtp}</strong> để test hệ thống.
        </p>

        <div className="d-flex justify-content-between mb-2">
          {Array.from({ length: otpLength }).map((_, index) => (
            <input
              key={index}
              type="text"
              inputMode="numeric"
              maxLength={1}
              className="form-control text-center fs-4"
              style={{ width: 48, height: 56 }}
              value={otp[index]}
              onChange={(e) => setDigitAt(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              onPaste={(e) => handlePaste(index, e)}
              ref={(el) => (inputRefs.current[index] = el)}
            />
          ))}
        </div>

        {error && <p className="small text-danger mb-2">{error}</p>}

        {/* nút sẽ “sáng” khi isComplete=true */}
        <button
          type="button"
          className={`btn w-100 mb-2 ${
            isComplete ? "btn-primary" : "btn-secondary"
          }`}
          disabled={!isComplete}
          onClick={handleVerify}
        >
          Xác minh email
        </button>

        <p className="small text-muted mb-1">
          Bạn chưa nhận được email? Vì đây là mã demo, hãy nhập trực tiếp{" "}
          <strong>{demoOtp}</strong> để tiếp tục.
        </p>

        <button
          type="button"
          className="btn btn-link w-100 mt-2 p-0"
          onClick={onClose}
        >
          Để sau
        </button>

        <hr className="mt-3" />
        <p className="small text-muted mb-0">
          Qua việc đăng nhập hoặc tạo tài khoản, bạn đồng ý với các Điều khoản
          và Điều kiện cũng như Chính sách An toàn và Bảo mật của chúng tôi.
        </p>
      </div>
    </div>
  );
};

export default EmailOtpModal;
