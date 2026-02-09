import { CLOUDINARY_CLOUD } from "../config/cloudinary.js";

/**
 * Tạo URL Cloudinary cho hình ảnh
 * @param {string} publicId  public id trên Cloudinary (ví dụ: "hotel_saigon_g9dkyk")
 * @param {Object} [opts]
 * @param {number} [opts.w]  width
 * @param {number} [opts.h]  height
 * @param {"fill"|"fit"|"scale"|"thumb"} [opts.crop]
 * @param {number|"auto"} [opts.q]
 * @param {"auto"|"webp"|"avif"|"jpg"|"png"} [opts.f]
 * @param {"auto"|number} [opts.dpr]
 * @param {"auto"|"center"|"faces"} [opts.g]
 * @returns {string}
 */
export function cld(publicId, opts = {}) {
  const t = [
    `f_${opts.f ?? "auto"}`,
    `q_${opts.q ?? "auto"}`,
    `dpr_${opts.dpr ?? "auto"}`,
    opts.w ? `w_${opts.w}` : "",
    opts.h ? `h_${opts.h}` : "",
    `c_${opts.crop ?? "fill"}`,
    `g_${opts.g ?? "auto"}`,
  ]
    .filter(Boolean)
    .join(",");

  return `https://res.cloudinary.com/${CLOUDINARY_CLOUD}/image/upload/${t}/${publicId}`;
}
