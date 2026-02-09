const nodemailer = require("nodemailer");

const port = Number(process.env.SMTP_PORT || 587);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port,
  secure: port === 465, // ✅ 465 => true, 587 => false
  auth: {
    user: process.env.SMTP_USER,
    pass: (process.env.SMTP_PASS || "").replace(/\s/g, ""), // ✅ bỏ khoảng trắng App Password
  },
});

// (khuyến nghị) verify SMTP khi service start
transporter
  .verify()
  .then(() => console.log("✅ SMTP transporter ready"))
  .catch((err) => console.error("❌ SMTP verify failed:", err.message));

function formatMoney(v = 0) {
  return Number(v || 0).toLocaleString("vi-VN") + " VND";
}

function formatDate(d) {
  if (!d) return "";
  const date = new Date(d);
  return new Intl.DateTimeFormat("vi-VN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function escapeHtml(str = "") {
  return String(str)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function sendPaymentSuccessEmail({ to, booking, paymentInfo }) {
  const bookingCode = booking._id.toString().slice(-6).toUpperCase();

  const items = Array.isArray(booking.items) ? booking.items : [];
  const itemRowsHtml = items
    .map((it) => {
      const title = escapeHtml(it?.snapshot?.title || "Tour");
      const qty = Number(it?.quantity || 0);
      const unit = Number(it?.unit_price || 0);
      const line = qty * unit;

      return `
      <tr>
        <td style="padding:10px;border-bottom:1px solid #eee">${title}</td>
        <td style="padding:10px;text-align:center;border-bottom:1px solid #eee">${qty}</td>
        <td style="padding:10px;text-align:right;border-bottom:1px solid #eee">${formatMoney(
          unit,
        )}</td>
        <td style="padding:10px;text-align:right;border-bottom:1px solid #eee">${formatMoney(
          line,
        )}</td>
      </tr>
    `;
    })
    .join("");

  const totalBefore = booking?.pricing?.total_price_before_discount ?? 0;
  const discount = booking?.pricing?.discount_amount ?? 0;
  const finalPrice = booking?.pricing?.final_price ?? 0;

  const customer = booking?.customer_details || {};
  const startDate = formatDate(booking?.start_date);
  const endDate = formatDate(booking?.end_date);

  const gateway = paymentInfo?.gateway || "vnpay";
  const txId = paymentInfo?.gateway_transaction_id || "";

  // (optional) Link xem chi tiết booking trên FE (nếu bạn có)
  const frontendUrl = process.env.FRONTEND_URL;
  const detailLink = frontendUrl
    ? `${frontendUrl}/booking/${booking._id}`
    : null;

  const subject = `[GoTripViet] Thanh toán thành công • Booking #${bookingCode}`;

  const html = `
  <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
    <div style="max-width:720px;margin:0 auto;padding:20px">
      <h2 style="margin:0 0 8px">Thanh toán thành công ✅</h2>
      <p style="margin:0 0 16px">
        Booking <b>#${bookingCode}</b> đã được xác nhận.
      </p>

      <div style="background:#fafafa;border:1px solid #eee;border-radius:10px;padding:14px;margin:0 0 16px">
        <div><b>Trạng thái:</b> ${escapeHtml(booking?.status || "")}</div>
        <div><b>Thanh toán:</b> ${escapeHtml(
          booking?.payment_status || "",
        )}</div>
        <div><b>Ngày đi:</b> ${startDate} &nbsp;&nbsp; <b>Ngày về:</b> ${endDate}</div>
        <div><b>Cổng thanh toán:</b> ${escapeHtml(gateway)}</div>
        ${txId ? `<div><b>Mã giao dịch:</b> ${escapeHtml(txId)}</div>` : ""}
      </div>

      <h3 style="margin:18px 0 10px">Thông tin đơn hàng</h3>
      <table style="width:100%;border-collapse:collapse;border:1px solid #eee;border-radius:10px;overflow:hidden">
        <thead>
          <tr style="background:#f3f4f6">
            <th style="text-align:left;padding:10px;border-bottom:1px solid #eee">Sản phẩm</th>
            <th style="text-align:center;padding:10px;border-bottom:1px solid #eee">SL</th>
            <th style="text-align:right;padding:10px;border-bottom:1px solid #eee">Đơn giá</th>
            <th style="text-align:right;padding:10px;border-bottom:1px solid #eee">Tạm tính</th>
          </tr>
        </thead>
        <tbody>
          ${
            itemRowsHtml ||
            `<tr><td colspan="4" style="padding:10px">Không có dữ liệu sản phẩm</td></tr>`
          }
        </tbody>
      </table>

      <div style="margin:14px 0 18px;display:flex;justify-content:flex-end">
        <div style="min-width:320px">
          <div style="display:flex;justify-content:space-between;padding:6px 0">
            <span>Tổng trước giảm: </span><b>${formatMoney(totalBefore)}</b>
          </div>
          <div style="display:flex;justify-content:space-between;padding:6px 0">
            <span>Giảm giá: </span><b>${formatMoney(discount)}</b>
          </div>
          <div style="display:flex;justify-content:space-between;padding:10px 0;border-top:1px solid #eee">
            <span><b>Thanh toán: </b></span><b>${formatMoney(finalPrice)}</b>
          </div>
        </div>
      </div>

      <h3 style="margin:18px 0 10px">Thông tin khách hàng</h3>
      <div style="background:#fff;border:1px solid #eee;border-radius:10px;padding:14px">
        <div><b>Họ tên:</b> ${escapeHtml(customer.fullName || "")}</div>
        <div><b>Email:</b> ${escapeHtml(customer.email || to)}</div>
        <div><b>SĐT:</b> ${escapeHtml(customer.phone || "")}</div>
        ${
          customer.address
            ? `<div><b>Địa chỉ:</b> ${escapeHtml(customer.address)}</div>`
            : ""
        }
        ${
          customer.note
            ? `<div><b>Ghi chú:</b> ${escapeHtml(customer.note)}</div>`
            : ""
        }
      </div>

      ${
        detailLink
          ? `
        <div style="margin:18px 0 0">
          <a href="${detailLink}" style="display:inline-block;padding:10px 14px;background:#111;color:#fff;text-decoration:none;border-radius:8px">
            Xem chi tiết booking
          </a>
        </div>
      `
          : ""
      }

      <p style="margin:18px 0 0;color:#666;font-size:12px">
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

// utils/mailer.js

async function sendPaidCancellationEmail({ to, booking }) {
  const bookingCode = booking._id.toString().slice(-6).toUpperCase();

  const items = Array.isArray(booking.items) ? booking.items : [];
  const itemRowsHtml = items
    .map((it) => {
      const title = escapeHtml(it?.snapshot?.title || "Tour");
      const qty = Number(it?.quantity || 0);
      const unit = Number(it?.unit_price || 0);
      const line = qty * unit;

      return `
        <tr>
          <td style="padding:10px;border-bottom:1px solid #eee">${title}</td>
          <td style="padding:10px;text-align:center;border-bottom:1px solid #eee">${qty}</td>
          <td style="padding:10px;text-align:right;border-bottom:1px solid #eee">${formatMoney(unit)}</td>
          <td style="padding:10px;text-align:right;border-bottom:1px solid #eee">${formatMoney(line)}</td>
        </tr>
      `;
    })
    .join("");

  const totalBefore = booking?.pricing?.total_price_before_discount ?? 0;
  const discount = booking?.pricing?.discount_amount ?? 0;
  const finalPrice = booking?.pricing?.final_price ?? 0;

  const customer = booking?.customer_details || {};
  const startDate = formatDate(booking?.start_date);
  const endDate = formatDate(booking?.end_date);

  const frontendUrl = process.env.FRONTEND_URL;
  const detailLink = frontendUrl
    ? `${frontendUrl}/booking/${booking._id}`
    : null;

  const subject = `[GoTripViet] Xác nhận hủy tour • Booking #${bookingCode}`;

  const html = `
  <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
    <div style="max-width:720px;margin:0 auto;padding:20px">
      <h2 style="margin:0 0 8px">Xác nhận hủy tour ✅</h2>
      <p style="margin:0 0 12px">
        Booking <b>#${bookingCode}</b> đã được hủy theo yêu cầu của bạn.
      </p>

      <div style="background:#fff3f3;border:1px solid #ffd6d6;border-radius:10px;padding:14px;margin:0 0 16px">
        <div style="font-weight:700;margin:0 0 6px">Thông báo hoàn tiền</div>
        <div>
          GoTripViet sẽ <b>hoàn tiền</b> lại cho bạn sau <b>ít phút</b> về đúng phương thức thanh toán.
        </div>
      </div>

      <div style="background:#fafafa;border:1px solid #eee;border-radius:10px;padding:14px;margin:0 0 16px">
        <div><b>Trạng thái:</b> ${escapeHtml(booking?.status || "")}</div>
        <div><b>Thanh toán:</b> ${escapeHtml(booking?.payment_status || "")}</div>
        <div><b>Ngày đi:</b> ${startDate} &nbsp;&nbsp; <b>Ngày về:</b> ${endDate}</div>
      </div>

      <h3 style="margin:18px 0 10px">Thông tin tour</h3>
      <table style="width:100%;border-collapse:collapse;border:1px solid #eee;border-radius:10px;overflow:hidden">
        <thead>
          <tr style="background:#f5f5f5">
            <th style="padding:10px;text-align:left">Tour</th>
            <th style="padding:10px;text-align:center">SL</th>
            <th style="padding:10px;text-align:right">Đơn giá</th>
            <th style="padding:10px;text-align:right">Thành tiền</th>
          </tr>
        </thead>
        <tbody>
          ${itemRowsHtml || `<tr><td colspan="4" style="padding:10px">—</td></tr>`}
        </tbody>
      </table>

      <div style="margin:14px 0 0;background:#fff;border:1px solid #eee;border-radius:10px;padding:14px">
        <div style="display:flex;justify-content:space-between;padding:6px 0">
          <span><b>Tạm tính:</b></span><span>${formatMoney(totalBefore)}</span>
        </div>
        <div style="display:flex;justify-content:space-between;padding:6px 0">
          <span><b>Giảm giá:</b></span><span>-${formatMoney(discount)}</span>
        </div>
        <div style="display:flex;justify-content:space-between;padding:10px 0;border-top:1px solid #eee">
          <span><b>Số tiền hoàn:</b></span><b>${formatMoney(finalPrice)}</b>
        </div>
      </div>

      <h3 style="margin:18px 0 10px">Thông tin khách hàng</h3>
      <div style="background:#fff;border:1px solid #eee;border-radius:10px;padding:14px">
        <div><b>Họ tên:</b> ${escapeHtml(customer.fullName || "")}</div>
        <div><b>Email:</b> ${escapeHtml(customer.email || to)}</div>
        <div><b>SĐT:</b> ${escapeHtml(customer.phone || "")}</div>
        ${
          customer.address
            ? `<div><b>Địa chỉ:</b> ${escapeHtml(customer.address)}</div>`
            : ""
        }
      </div>

      ${
        detailLink
          ? `
        <div style="margin:18px 0 0">
          <a href="${detailLink}" style="display:inline-block;padding:10px 14px;background:#111;color:#fff;text-decoration:none;border-radius:8px">
            Xem chi tiết booking
          </a>
        </div>
      `
          : ""
      }

      <p style="margin:18px 0 0;color:#666;font-size:12px">
        Email này được gửi tự động. Nếu cần hỗ trợ, vui lòng liên hệ GoTripViet.
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

// sửa export cuối file:
module.exports = { sendPaymentSuccessEmail, sendPaidCancellationEmail };
