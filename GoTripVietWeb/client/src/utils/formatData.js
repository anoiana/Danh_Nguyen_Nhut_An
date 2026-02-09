import { cld } from "./cld";

// 1. Format tiền tệ VNĐ
export const formatCurrency = (amount) => {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
  }).format(amount);
};

// 2. Tính khoảng thời gian
export const formatDuration = (days) => {
  if (!days || days <= 1) return "Trong ngày";
  return `${days}N${days - 1}Đ`;
};

// 3. Format ngày ngắn
export const formatShortDate = (dateStr) => {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  return `${day}/${month}`;
};

// --- [MỚI] HÀM CHỌN ICON PHƯƠNG TIỆN ---
const getTransportIcon = (type) => {
  if (!type) return "bi-bus-front"; // Mặc định là Xe

  const t = type.toLowerCase();
  if (t.includes("bay")) return "bi-airplane-engines"; // Máy bay
  if (t.includes("tàu") && t.includes("hỏa")) return "bi-train-front"; // Tàu hỏa
  if (t.includes("thuyền") || t.includes("thuỷ")) return "bi-water"; // Du thuyền
  if (t.includes("tự túc")) return "bi-person-walking"; // Tự túc

  return "bi-bus-front"; // Xe du lịch / Xe ghế ngồi / Limousine
};

const resolveProductImageUrl = (product) => {
  const raw = product?.images?.[0]?.url ?? product?.images?.[0];
  const fallback = "https://placehold.co/400x300?text=Tour";

  if (typeof raw !== "string" || !raw.trim()) return fallback;

  // Nếu backend lưu full URL cloudinary
  if (raw.startsWith("http")) return raw;

  // Nếu backend lưu đường dẫn uploads nội bộ
  if (raw.startsWith("/uploads") || raw.startsWith("uploads/")) {
    const base = import.meta.env.VITE_API_URL || "http://localhost:3000";
    return `${base}${raw.startsWith("/") ? "" : "/"}${raw}`;
  }

  // Còn lại: coi như cloudinary public_id
  return cld(raw, { w: 800, h: 500, crop: "fill", g: "auto" });
};

export const mapProductToCard = (product) => {
  if (!product) return {};

  const imageUrl = resolveProductImageUrl(product);

  return {
    id: product._id,
    title: product.title,
    imageUrl,

    // --- [SỬA TẠI ĐÂY] ---
    // Nếu Backend có product_code thì dùng, nếu không thì lấy 6 ký tự cuối của ID làm mã tạm
    tourCode:
      product.product_code || `TOUR-${product._id.slice(-6).toUpperCase()}`,

    startPoint: product.tour_details?.start_point || "Hồ Chí Minh",
    duration: `${product.tour_details?.duration_days || 1} ngày`,
    transport: product.tour_details?.transport_type || "Xe du lịch",

    // Map icon tương ứng
    transportIcon: getTransportIcon(product.tour_details?.transport_type),

    departureDates: product.departure_dates
      ? product.departure_dates
      : (Array.isArray(product?.tour_details?.departure_times) ? product.tour_details.departure_times : []),
    price: product?.base_price || 0,
    originalPrice: (product?.base_price || 0) * 1.2,
  };
};

export const formatDateWithWeekday = (dateStr) => {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  const options = {
    weekday: "long",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  };
  return d.toLocaleDateString("vi-VN", options);
};
