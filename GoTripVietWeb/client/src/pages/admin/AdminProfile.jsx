import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import authApi from "../../api/authApi";

function Modal({ open, title, children, onClose }) {
  if (!open) return null;
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.35)",
        display: "grid",
        placeItems: "center",
        zIndex: 60,
      }}
      onMouseDown={onClose}
    >
      <div
        style={{
          width: "min(640px, 92vw)",
          background: "#fff",
          borderRadius: 16,
          padding: 16,
          boxShadow: "0 10px 30px rgba(0,0,0,0.18)",
        }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ fontWeight: 900, fontSize: 16, flex: 1 }}>{title}</div>
          <button
            onClick={onClose}
            style={{
              border: 0,
              background: "transparent",
              cursor: "pointer",
              fontSize: 18,
            }}
          >
            ✕
          </button>
        </div>
        <div style={{ height: 1, background: "#e5e7eb", margin: "10px 0" }} />
        {children}
      </div>
    </div>
  );
}

function getInitials(name = "") {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return "A";
  const a = parts[0][0] || "";
  const b = parts.length > 1 ? parts[parts.length - 1][0] || "" : "";
  return (a + b).toUpperCase();
}

export default function AdminProfile() {
  const nav = useNavigate();

  const [me, setMe] = useState(null);
  const [loading, setLoading] = useState(true);

  const [editing, setEditing] = useState(false);

  // đổi mật khẩu (chưa có backend -> tạm giữ UI)
  const [pwOpen, setPwOpen] = useState(false);
  const [otp, setOtp] = useState(null);
  const [msg, setMsg] = useState("");

  const handleAuthFail = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    nav("/login");
  };

  const loadMe = async () => {
    setLoading(true);
    try {
      const profile = await authApi.getProfile(); // GET /users/me
      setMe(profile);
    } catch (err) {
      const status = err?.response?.status;
      if (status === 401 || status === 403) return handleAuthFail();
      console.error("Load profile failed:", err);
      setMsg("Không tải được thông tin admin.");
      setTimeout(() => setMsg(""), 2200);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const saveInfo = async (e) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);

    // Backend user-service hiện update profile thường chỉ cho fullName/phone (và có thể email tùy bạn)
    // Avatar/address/dob: nếu backend chưa có field thì gửi lên cũng không lưu.
    const patch = {
      fullName: String(fd.get("fullName") || ""),
      phone: String(fd.get("phone") || ""),
      // Nếu backend cho phép update email thì mở dòng dưới:
      // email: String(fd.get("email") || ""),
      // Các field dưới đây chỉ dùng nếu bạn đã thêm vào model + updateProfile:
      // avatar: String(fd.get("avatar") || ""),
      // address: String(fd.get("address") || ""),
      // dob: String(fd.get("dob") || ""),
    };

    try {
      const updated = await authApi.updateProfile(patch); // PUT /users/me
      setMe(updated);
      setEditing(false);
      setMsg("Đã cập nhật thông tin admin.");
      setTimeout(() => setMsg(""), 2200);
    } catch (err) {
      const status = err?.response?.status;
      if (status === 401 || status === 403) return handleAuthFail();
      setMsg(err?.response?.data?.message || "Cập nhật thất bại.");
      setTimeout(() => setMsg(""), 2500);
    }
  };

  const requestOtp = () => {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    setOtp(code);
    setMsg(`Đã gửi OTP đến email: ${me?.email} (dev OTP: ${code})`);
    setTimeout(() => setMsg(""), 3500);
  };

  const changePassword = (e) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    const oldPw = String(fd.get("oldPw") || "");
    const pw1 = String(fd.get("pw1") || "");
    const pw2 = String(fd.get("pw2") || "");
    const otpInput = String(fd.get("otp") || "");

    if (!oldPw) return setMsg("Vui lòng nhập mật khẩu cũ.");
    if (pw1.length < 6) return setMsg("Mật khẩu mới tối thiểu 6 ký tự.");
    if (pw1 !== pw2) return setMsg("Mật khẩu mới nhập lại không khớp.");
    if (!otp) return setMsg("Vui lòng bấm “Gửi OTP” trước.");
    if (otpInput !== otp) return setMsg("OTP không đúng.");

    // mock success
    setOtp(null);
    setPwOpen(false);
    setMsg("Đổi mật khẩu thành công ✅");
    setTimeout(() => setMsg(""), 2500);
  };

  if (loading) return <div>Đang tải...</div>;
  if (!me) return <div>Không có dữ liệu admin.</div>;

  const avatarNode = me?.avatar ? (
    <img
      src={me.avatar}
      alt="admin"
      style={{ width: 70, height: 70, borderRadius: 18, objectFit: "cover" }}
    />
  ) : (
    <div
      style={{
        width: 70,
        height: 70,
        borderRadius: 18,
        display: "grid",
        placeItems: "center",
        background: "#e5e7eb",
        fontWeight: 900,
        fontSize: 18,
      }}
      title={me?.fullName || "Admin"}
    >
      {getInitials(me?.fullName || me?.email || "Admin")}
    </div>
  );

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        {avatarNode}
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 900, fontSize: 22 }}>{me?.fullName}</div>
          <div style={{ color: "#6b7280" }}>{me?.email}</div>
          {msg ? (
            <div style={{ marginTop: 6, fontWeight: 800 }}>{msg}</div>
          ) : null}
        </div>
        <button
          onClick={() => setEditing(true)}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: 0,
            background: "#0b5fff",
            color: "#fff",
            cursor: "pointer",
            fontWeight: 900,
          }}
        >
          Sửa thông tin
        </button>
        <button
          onClick={() => setPwOpen(true)}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #e5e7eb",
            background: "#fff",
            cursor: "pointer",
            fontWeight: 900,
          }}
        >
          Đổi mật khẩu
        </button>
      </div>

      <div
        style={{
          background: "#fff",
          border: "1px solid #e5e7eb",
          borderRadius: 16,
          padding: 16,
        }}
      >
        <div style={{ fontWeight: 900, fontSize: 18, marginBottom: 10 }}>
          Thông tin admin
        </div>
        <div
          style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
        >
          <Info label="Số điện thoại" value={me?.phone} />
          <Info label="Email" value={me?.email} />
          <Info label="Role" value={(me?.roles || []).join(", ")} />
          <Info label="Trạng thái" value={me?.status || "ACTIVE"} />
          <Info label="Ngày tạo tài khoản" value={me?.createdAt} />
          <Info label="Mật khẩu" value={"••••••••"} />
        </div>
      </div>

      {/* Edit info */}
      <Modal
        open={editing}
        title="Cập nhật thông tin admin"
        onClose={() => setEditing(false)}
      >
        <form
          onSubmit={saveInfo}
          style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
        >
          {/* Nếu backend chưa support avatar/address/dob thì bạn có thể ẩn các field này */}
          {/* <Field name="avatar" label="Avatar URL" defaultValue={me?.avatar || ""} /> */}

          <Field
            name="fullName"
            label="Họ tên"
            defaultValue={me?.fullName || ""}
          />
          <Field
            name="phone"
            label="Số điện thoại"
            defaultValue={me?.phone || ""}
          />

          <Field
            name="email"
            label="Email"
            defaultValue={me?.email || ""}
            disabled
          />

          <div
            style={{
              gridColumn: "1/-1",
              display: "flex",
              justifyContent: "flex-end",
              gap: 10,
            }}
          >
            <button type="button" onClick={() => setEditing(false)} style={btn}>
              Hủy
            </button>
            <button
              type="submit"
              style={{
                ...btn,
                background: "#0b5fff",
                color: "#fff",
                border: 0,
              }}
            >
              Lưu
            </button>
          </div>
        </form>
      </Modal>

      {/* Change password */}
      <Modal
        open={pwOpen}
        title="Đổi mật khẩu"
        onClose={() => setPwOpen(false)}
      >
        <form onSubmit={changePassword} style={{ display: "grid", gap: 12 }}>
          <Field name="oldPw" label="Mật khẩu cũ" type="password" />
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <Field name="pw1" label="Mật khẩu mới" type="password" />
            <Field name="pw2" label="Nhập lại mật khẩu mới" type="password" />
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr auto",
              gap: 10,
              alignItems: "end",
            }}
          >
            <Field name="otp" label="OTP" />
            <button
              type="button"
              onClick={requestOtp}
              style={{ ...btn, height: 42 }}
            >
              Gửi OTP
            </button>
          </div>

          <div style={{ display: "flex", justifyContent: "flex-end", gap: 10 }}>
            <button type="button" onClick={() => setPwOpen(false)} style={btn}>
              Hủy
            </button>
            <button
              type="submit"
              style={{
                ...btn,
                background: "#0b5fff",
                color: "#fff",
                border: 0,
              }}
            >
              Xác nhận đổi
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

function Info({ label, value }) {
  return (
    <div
      style={{
        border: "1px solid #e5e7eb",
        borderRadius: 14,
        padding: 12,
        background: "#fafafa",
      }}
    >
      <div style={{ color: "#6b7280", fontWeight: 800, fontSize: 12 }}>
        {label}
      </div>
      <div style={{ fontWeight: 900, marginTop: 6 }}>{value || "—"}</div>
    </div>
  );
}

function Field({ name, label, defaultValue, type = "text", disabled = false }) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 6 }}>
      <span style={{ fontWeight: 800, fontSize: 13 }}>{label}</span>
      <input
        name={name}
        defaultValue={defaultValue}
        type={type}
        disabled={disabled}
        style={{
          borderRadius: 12,
          border: "1px solid #e5e7eb",
          padding: "10px 12px",
          outline: "none",
          background: disabled ? "#f3f4f6" : "#fff",
        }}
      />
    </label>
  );
}

const btn = {
  padding: "10px 14px",
  borderRadius: 12,
  border: "1px solid #e5e7eb",
  background: "#fff",
  cursor: "pointer",
  fontWeight: 900,
};
