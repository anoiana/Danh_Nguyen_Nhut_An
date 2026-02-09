// user-service/utils/mailer.js
const nodemailer = require("nodemailer");

const port = Number(process.env.SMTP_PORT || 587);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port,
  secure: port === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: (process.env.SMTP_PASS || "").replace(/\s/g, ""),
  },
});

// verify lúc start để biết SMTP ok chưa
transporter
  .verify()
  .then(() => console.log("✅ [UserService] SMTP transporter ready"))
  .catch((err) =>
    console.error("❌ [UserService] SMTP verify failed:", err.message)
  );

function escapeHtml(str = "") {
  return String(str)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function sendRegisterSuccessEmail({ to, user }) {
  const fullName = escapeHtml(user?.fullName || "");
  const roles = Array.isArray(user?.roles) ? user.roles : [];
  const isPartner = roles.includes("partner");

  const subject = isPartner
    ? "[GoTripViet] Đăng ký đối tác thành công"
    : "[GoTripViet] Đăng ký thành công";

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
      <div style="max-width:680px;margin:0 auto;padding:20px">
        <h2 style="margin:0 0 8px">Đăng ký thành công ✅</h2>
        <p style="margin:0 0 14px">
          Chào ${
            fullName || "bạn"
          }, tài khoản của bạn đã được tạo thành công trên <b>GoTripViet</b>.
        </p>

        <div style="background:#fafafa;border:1px solid #eee;border-radius:10px;padding:14px;margin:0 0 14px">
          <div><b>Email:</b> ${escapeHtml(to)}</div>
          <div><b>Loại tài khoản:</b> ${
            isPartner ? "Đối tác (Partner)" : "Người dùng (User)"
          }</div>
          ${
            isPartner
              ? `<div><b>Trạng thái đối tác:</b> Đang chờ Admin duyệt</div>`
              : ""
          }
        </div>

        <p style="margin:0 0 8px">
          ${
            isPartner
              ? "Bạn đã gửi yêu cầu đăng ký đối tác. Sau khi được duyệt, bạn có thể đăng tour và quản lý đơn hàng."
              : "Bạn có thể đăng nhập và bắt đầu tìm tour phù hợp ngay bây giờ."
          }
        </p>

        <p style="margin:16px 0 0;color:#666;font-size:12px">
          Email này được gửi tự động. Nếu bạn không thực hiện đăng ký, vui lòng bỏ qua.
        </p>
      </div>
    </div>
  `;

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });
}

async function sendRegisterSuccessEmail({ to, user }) {
  const roles = Array.isArray(user?.roles) ? user.roles : [];
  const isPartner = roles.includes("partner");

  const subject = isPartner
    ? "[GoTripViet] Đăng ký đối tác thành công"
    : "[GoTripViet] Đăng ký thành công";

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
      <div style="max-width:680px;margin:0 auto;padding:20px">
        <h2 style="margin:0 0 8px">Đăng ký thành công ✅</h2>
        <p>Chào <b>${escapeHtml(
          user?.fullName || "bạn"
        )}</b>, tài khoản của bạn đã được tạo thành công trên GoTripViet.</p>

        <div style="background:#fafafa;border:1px solid #eee;border-radius:10px;padding:14px">
          <div><b>Email:</b> ${escapeHtml(to)}</div>
          <div><b>Loại tài khoản:</b> ${
            isPartner ? "Đối tác (Partner)" : "Người dùng (User)"
          }</div>
          ${
            isPartner
              ? `<div><b>Trạng thái đối tác:</b> Đang chờ Admin duyệt</div>`
              : ""
          }
        </div>

        <p style="margin-top:16px;color:#666;font-size:12px">
          Email này được gửi tự động. Nếu bạn không thực hiện đăng ký, vui lòng bỏ qua.
        </p>
      </div>
    </div>
  `;

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });
}

async function sendPartnerApprovedEmail({ to, user }) {
  const subject = "[GoTripViet] Đối tác đã được duyệt ✅";

  const company =
    user?.partner_details?.company_name || user?.fullName || "Đối tác";

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
      <div style="max-width:680px;margin:0 auto;padding:20px">
        <h2 style="margin:0 0 8px">Đã duyệt đối tác ✅</h2>
        <p>Chúc mừng <b>${escapeHtml(
          company
        )}</b>! Admin GoTripViet đã duyệt tài khoản đối tác của bạn.</p>

        <div style="background:#fafafa;border:1px solid #eee;border-radius:10px;padding:14px">
          <div><b>Email:</b> ${escapeHtml(to)}</div>
          <div><b>Trạng thái:</b> Đã duyệt</div>
          <div><b>Thời điểm:</b> ${new Date().toLocaleString("vi-VN")}</div>
        </div>

        <p style="margin-top:16px">
          Bạn có thể bắt đầu hợp tác: đăng tour/sản phẩm, quản lý booking và theo dõi doanh thu.
        </p>

        <p style="margin-top:16px;color:#666;font-size:12px">
          Email này được gửi tự động. Nếu có thắc mắc, vui lòng liên hệ GoTripViet.
        </p>
      </div>
    </div>
  `;

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });
}

module.exports = {
  sendRegisterSuccessEmail,
  sendPartnerApprovedEmail,
};
