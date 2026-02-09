// src/pages/Register.jsx
import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom"; // [MỚI] Thêm Link vào đây
import AuthHeader from "../components/AuthHeader.jsx";
import authApi from "../api/authApi";

export default function Register() {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        email: "",
        password: "",
        fullName: "",
        phone: ""
    });
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.id]: e.target.value });
    };

    const togglePasswordVisibility = () => {
        setShowPassword(!showPassword);
    };

    const submit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            // Gọi API Đăng ký
            await authApi.register(formData);
            alert("Đăng ký thành công! Vui lòng đăng nhập.");
            navigate("/login");
        } catch (error) {
            alert("Lỗi đăng ký: " + (error.response?.data?.message || error.message));
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            <AuthHeader />
            <div className="container my-5">
                <div className="row justify-content-center">
                    <div className="col-md-6">
                        <h2 className="fw-bold mb-4">Tạo tài khoản mới</h2>
                        <form onSubmit={submit}>
                            <div className="mb-3">
                                <label className="form-label">Họ và tên</label>
                                <input id="fullName" className="form-control" onChange={handleChange} required />
                            </div>
                            <div className="mb-3">
                                <label className="form-label">Email</label>
                                <input id="email" type="email" className="form-control" onChange={handleChange} required />
                            </div>
                            <div className="mb-3">
                                <label className="form-label">Số điện thoại</label>
                                <input id="phone" type="tel" className="form-control" onChange={handleChange} />
                            </div>
                            <div className="mb-4">
                                <label className="form-label fw-semibold">Mật khẩu</label>
                                <div className="position-relative">
                                    <input
                                        id="password"
                                        type={showPassword ? "text" : "password"}
                                        className="form-control form-control-lg pe-5"
                                        onChange={handleChange}
                                        required
                                        placeholder="Tối thiểu 6 ký tự"
                                    />
                                    {/* Icon con mắt */}
                                    <span
                                        onClick={togglePasswordVisibility}
                                        style={{
                                            position: 'absolute',
                                            right: '15px',
                                            top: '50%',
                                            transform: 'translateY(-50%)',
                                            cursor: 'pointer',
                                            color: '#6c757d',
                                            zIndex: 10
                                        }}
                                        title={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                                    >
                                        <i className={`bi ${showPassword ? "bi-eye-slash-fill" : "bi-eye-fill"} fs-5`}></i>
                                    </span>
                                </div>
                            </div>

                            <button type="submit" className="btn btn-teal btn-lg w-100 mt-2" style={{ backgroundColor: "#008080", color: "#fff" }} disabled={loading}>
                                {loading ? "Đang xử lý..." : "Đăng ký"}
                            </button>

                            {/* --- [MỚI] DÒNG CHỮ CHUYỂN VỀ LOGIN --- */}
                            <div className="text-center mt-3">
                                <span className="text-muted">Bạn đã có tài khoản? </span>
                                <Link to="/login" className="fw-semibold text-decoration-none" style={{color: "#008080"}}>
                                    Đăng nhập ngay
                                </Link>
                            </div>
                            {/* -------------------------------------- */}

                        </form>
                    </div>
                </div>
            </div>
        </>
    );
}