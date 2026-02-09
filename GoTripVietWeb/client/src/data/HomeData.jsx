import React from "react";
import { cld } from "../utils/cld.js";

// ====== Dummy data (có thể thay thế bằng API) ======
export const events = [
  {
    backgroundUrl: cld("event_boxingday_iusunh", {
      w: 1200,
      h: 450,
      crop: "fill",
      g: "auto",
    }),
    title: (
      <>
        Boxing Day <small>SALE</small>
      </>
    ),
    subtitle: "Giảm 75% • Chỉ trong hôm nay",
    ctaLabel: "Xem ưu đãi",
  },
  {
    backgroundUrl: cld("event_christmas_rtgy7r", {
      w: 1200,
      h: 450,
      crop: "fill",
      g: "auto",
    }),
    title: (
      <>
        Payday <small>Sale</small>
      </>
    ),
    subtitle: "Giáng sinh rộn ràng - Giảm đến 50%",
    ctaLabel: "Xem ưu đãi",
  },
  {
    backgroundUrl: cld("event_1212_aalgkx", {
      w: 1200,
      h: 450,
      crop: "fill",
      g: "auto",
    }),
    title: (
      <>
        Payday <small>Sale</small>
      </>
    ),
    subtitle: "Ngày 12.12 - Giảm đến 50%",
    ctaLabel: "Xem ưu đãi",
  },
  {
    backgroundUrl: cld("event_blackfriday_jbzpet", {
      w: 1200,
      h: 450,
      crop: "fill",
      g: "auto",
    }),
    title: (
      <>
        Payday <small>Sale</small>
      </>
    ),
    subtitle: "Black Friday - Giảm đến 50%",
    ctaLabel: "Xem ưu đãi",
  },
];

export const cities = [
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh",
    staysCount: 6461,
  },
  {
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    title: "Nha Trang",
    staysCount: 2217,
  },
  {
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "Đà Lạt",
    staysCount: 5543,
  },
  {
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "Sa pa",
    staysCount: 2006,
  },
  {
    imageUrl: cld("cities_hanoi_ouguno", { w: 360, h: 270 }),
    title: "Hà Nội",
    staysCount: 1804,
  },
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "Hải Phòng",
    staysCount: 1094,
  },
];

export const nearby_cities = [
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh",
    distanceKm: 80,
  },
  {
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    title: "Nha Trang",
    distanceKm: 103,
  },
  {
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "Đà Lạt",
    distanceKm: 511,
  },
  {
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "Sa pa",
    distanceKm: 540,
  },
  {
    imageUrl: cld("cities_hanoi_ouguno", { w: 360, h: 270 }),
    title: "Hà Nội",
    distanceKm: 547,
  },
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "Hải Phòng",
    distanceKm: 640,
  },
];

export const flights = [
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Bangkok",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
  {
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Kuta",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
  {
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Singapore",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
  {
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Siem Reap",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
  {
    imageUrl: cld("cities_hanoi_ouguno", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Tokyo",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh đến Phuket",
    subtitle: "15 tháng 11 - 16 tháng 11 · Khứ hồi",
  },
];

export const hotelsTopRated = [
  {
    imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
    title: "Saigon Boutique",
    address: "TP. Hồ Chí Minh, Việt Nam",
    rating: 9.2,
    reviews: 1250,
    extra: {
      kind: "A",
      category: "Khách sạn",
      stars: 5,
      badges: ["Genius"],
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Vũng Tàu View Hotel",
    address: "Vũng Tàu, Việt Nam",
    rating: 8.8,
    reviews: 876,
    extra: { kind: "A", category: "Resort", stars: 4 },
  },
  {
    imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
    title: "Quy Nhơn Cliff",
    address: "Quy Nhơn, Việt Nam",
    rating: 9.1,
    reviews: 642,
    extra: {
      kind: "A",
      category: "Khách sạn",
      stars: 5,
      badges: ["Ưu đãi"],
    },
  },
  {
    imageUrl: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    title: "Saigon Boutique",
    address: "TP. Hồ Chí Minh, Việt Nam",
    rating: 9.2,
    reviews: 1250,
    extra: {
      kind: "A",
      category: "Khách sạn",
      stars: 5,
      badges: ["Genius"],
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Vũng Tàu View Hotel",
    address: "Vũng Tàu, Việt Nam",
    rating: 8.8,
    reviews: 876,
    extra: { kind: "A", category: "Resort", stars: 4 },
  },
  {
    imageUrl: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    title: "Quy Nhơn Cliff",
    address: "Quy Nhơn, Việt Nam",
    rating: 9.1,
    reviews: 642,
    extra: {
      kind: "A",
      category: "Khách sạn",
      stars: 5,
      badges: ["Ưu đãi"],
    },
  },
];

export const hotels = [
  {
    imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
    title: "Mekong Lodge Resort",
    address: "Cái Bè, Việt Nam",
    rating: 8.7,
    reviews: 1114,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      price: "2.136.000 VND",
      eventLabel: "Genius",
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Green Bamboo Lodge Resort",
    address: "Cát Tiên, Việt Nam",
    rating: 8.6,
    reviews: 688,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      price: "836.000 VND",
    },
  },
  {
    imageUrl: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    title: "Vedana Lagoon Resort & Spa",
    address: "Huế, Việt Nam",
    rating: 9.3,
    reviews: 711,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      price: "5.081.718 VND",
    },
  },
  {
    imageUrl: cld("hotel_nhatrang_ldsrxe", { w: 640, h: 480 }),
    title: "Chez Beo Homestay",
    address: "Ninh Bình, Việt Nam",
    rating: 9.0,
    reviews: 546,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      price: "1.675.372 VND",
    },
  },
];

export const discount_hotels = [
  {
    imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
    title: "Mekong Lodge Resort",
    address: "Cái Bè, Việt Nam",
    rating: 8.7,
    reviews: 1114,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      oldPrice: "6.000.000 VND",
      price: "2.136.000 VND",
      eventLabel: "Ưu đãi",
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Green Bamboo Lodge Resort",
    address: "Cát Tiên, Việt Nam",
    rating: 8.6,
    reviews: 688,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      oldPrice: "950.000 VND",
      price: "836.000 VND",
      eventLabel: "Ưu đãi",
    },
  },
  {
    imageUrl: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    title: "Vedana Lagoon Resort & Spa",
    address: "Huế, Việt Nam",
    rating: 9.3,
    reviews: 711,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      oldPrice: "8.054.712 VND",
      price: "5.081.718 VND",
      eventLabel: "Ưu đãi",
    },
  },
  {
    imageUrl: cld("hotel_nhatrang_ldsrxe", { w: 640, h: 480 }),
    title: "Chez Beo Homestay",
    address: "Ninh Bình, Việt Nam",
    rating: 9.0,
    reviews: 546,
    extra: {
      kind: "B",
      note: "Bắt đầu từ",
      oldPrice: "2.260.000 VND",
      price: "1.675.372 VND",
      eventLabel: "Ưu đãi",
    },
  },
];

export const hotelCategories = [
  {
    id: "hotel_domestic",
    label: "Thành phố trong nước",
    items: [
      { id: 1, title: "Khách sạn Hà Nội" },
      { id: 2, title: "Khách sạn TP. Hồ Chí Minh" },
      { id: 3, title: "Khách sạn Đà Nẵng" },
      { id: 4, title: "Khách sạn Nha Trang" },
      { id: 5, title: "Khách sạn Phú Quốc" },
      { id: 6, title: "Khách sạn Đà Lạt" },
      { id: 7, title: "Khách sạn Hội An" },
      { id: 8, title: "Khách sạn Vũng Tàu" },
      { id: 9, title: "Khách sạn Cần Thơ" },
      { id: 10, title: "Khách sạn Huế" },
      { id: 11, title: "Khách sạn Sapa" },
      { id: 12, title: "Khách sạn Quy Nhơn" },
      { id: 13, title: "Khách sạn Cát Bà" },
      { id: 14, title: "Khách sạn Hạ Long" },
      { id: 15, title: "Khách sạn Mũi Né" },
      { id: 16, title: "Khách sạn Phan Thiết" },
      { id: 17, title: "Khách sạn Vĩnh Phúc" },
      { id: 18, title: "Khách sạn Bắc Ninh" },
      { id: 19, title: "Khách sạn Hải Phòng" },
      { id: 20, title: "Khách sạn Thanh Hóa" },
      { id: 21, title: "Khách sạn Quảng Ninh" },
      { id: 22, title: "Khách sạn Thái Nguyên" },
    ],
  },
  {
    id: "hotel_international",
    label: "Thành phố nước ngoài",
    items: [
      { id: 1, title: "Khách sạn Quảng Châu", description: "Trung Quốc" },
      { id: 2, title: "Khách sạn Bangkok", description: "Thái Lan" },
      { id: 3, title: "Khách sạn Singapore", description: "Singapore" },
      { id: 4, title: "Khách sạn Kuala Lumpur", description: "Malaysia" },
      { id: 5, title: "Khách sạn Đài Bắc", description: "Đài Loan" },
      { id: 6, title: "Khách sạn Tokyo", description: "Nhật Bản" },
      { id: 7, title: "Khách sạn Seoul", description: "Hàn Quốc" },
      { id: 8, title: "Khách sạn Bali", description: "Indonesia" },
      { id: 9, title: "Khách sạn Manila", description: "Philippines" },
      { id: 10, title: "Khách sạn Sydney", description: "Úc" },
      { id: 11, title: "Khách sạn Los Angeles", description: "Mỹ" },
      { id: 12, title: "Khách sạn Paris", description: "Pháp" },
      { id: 13, title: "Khách sạn London", description: "Anh" },
      { id: 14, title: "Khách sạn Rome", description: "Ý" },
      { id: 15, title: "Khách sạn Berlin", description: "Đức" },
      { id: 16, title: "Khách sạn Moscow", description: "Nga" },
      { id: 17, title: "Khách sạn Cairo", description: "Ai Cập" },
      { id: 18, title: "Khách sạn Dubai", description: "UAE" },
      { id: 19, title: "Khách sạn Istanbul", description: "Thổ Nhĩ Kỳ" },
      { id: 20, title: "Khách sạn Athens", description: "Hy Lạp" },
      { id: 21, title: "Khách sạn Barcelona", description: "Tây Ban Nha" },
      { id: 22, title: "Khách sạn Amsterdam", description: "Hà Lan" },
    ],
  },
  {
    id: "hotel_area",
    label: "Khu vực",
    items: [
      { id: 1, title: "Khu vực TP. Hồ Chí Minh" },
      { id: 2, title: "Khu vực Hà Nội" },
      { id: 3, title: "Khu vực Đà Nẵng" },
      { id: 4, title: "Khu vực Nha Trang" },
      { id: 5, title: "Khu vực Phú Quốc" },
      { id: 6, title: "Khu vực Đà Lạt" },
      { id: 7, title: "Khu vực Hội An" },
      { id: 8, title: "Khu vực Vũng Tàu" },
      { id: 9, title: "Khu vực Cần Thơ" },
      { id: 10, title: "Khu vực Huế" },
      { id: 11, title: "Khu vực Sapa" },
    ],
  },
];

export const planeCategories = [
  {
    id: "plane_popular",
    label: "Thành phố trong nước",
    items: [
      {
        id: 1,
        title: "TP. Hồ Chí Minh -> Đà Nẵng",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 2,
        title: "TP. Hồ Chí Minh -> Phú Quốc",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 3,
        title: "TP. Hồ Chí Minh -> Singapore",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 4,
        title: "TP. Hồ Chí Minh -> Bangkok",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 5,
        title: "TP. Hồ Chí Minh -> Kuta",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 6,
        title: "TP. Hồ Chí Minh -> Tokyo",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 7,
        title: "TP. Hồ Chí Minh -> Siem Reap",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 8,
        title: "TP. Hồ Chí Minh -> Đài Bắc",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 9,
        title: "TP. Hồ Chí Minh -> Seoul",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 10,
        title: "TP. Hồ Chí Minh -> Kuala Lumpur",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
    ],
  },
  {
    id: "city",
    label: "Thành phố",
    items: [
      {
        id: 1,
        title: "TP. Hồ Chí Minh",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 2,
        title: "Hà Nội",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 3,
        title: "Đà Nẵng",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 4,
        title: "Nha Trang",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 5,
        title: "Phú Quốc",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 6,
        title: "Đà Lạt",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 7,
        title: "Hải Phòng",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 8,
        title: "Cần Thơ",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 9,
        title: "Huế",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 10,
        title: "Vũng Tàu",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 11,
        title: "Quy Nhơn",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
    ],
  },
  {
    id: "Nation",
    label: "Quốc gia",
    items: [
      {
        id: 1,
        title: "Thái Lan",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 2,
        title: "Singapore",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 3,
        title: "Malaysia",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 4,
        title: "Đài Loan",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 5,
        title: "Nhật Bản",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 6,
        title: "Hàn Quốc",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 7,
        title: "Indonesia",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 8,
        title: "Philippines",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 9,
        title: "Úc",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
      {
        id: 10,
        title: "Mỹ",
        imageUrl: cld("hotel_hanoi_x6by5r", { w: 640, h: 480 }),
      },
    ],
  },
];

export const activitiesCategories = [
  {
    id: "tour",
    label: "Tour",
    items: [
      { id: 1, title: "Tour văn hóa", description: "Hà Nội" },
      { id: 2, title: "Tour ẩm thực", description: "TP. Hồ Chí Minh" },
      { id: 3, title: "Tour mạo hiểm", description: "Đà Nẵng" },
      { id: 4, title: "Tour thiên nhiên", description: "Nha Trang" },
      { id: 5, title: "Tour thành phố", description: "Phú Quốc" },
      { id: 6, title: "Tour lịch sử", description: "Huế" },
      { id: 7, title: "Tour nghệ thuật", description: "Hội An" },
      { id: 8, title: "Tour giải trí", description: "Đà Lạt" },
    ],
  },
  {
    id: "tour_city",
    label: "Tour tham quan thành phố",
    items: [
      { id: 1, title: "Tour đi thuyền", description: "Hà Nội" },
      { id: 2, title: "Tour xe đạp", description: "TP. Hồ Chí Minh" },
      { id: 3, title: "Tour đi bộ", description: "Đà Nẵng" },
      { id: 4, title: "Tour xe máy", description: "Nha Trang" },
      { id: 5, title: "Tour xe buýt", description: "Phú Quốc" },
      { id: 6, title: "Tour xe điện", description: "Huế" },
      { id: 7, title: "Tour xe ngựa", description: "Hội An" },
      { id: 8, title: "Tour xe trượt", description: "Đà Lạt" },
    ],
  },
  {
    id: "outside_activities",
    label: "Quốc gia",
    items: [
      { id: 1, title: "Công viên thiên nhiên", description: "Hà Nội" },
      {
        id: 2,
        title: "Khu bảo tồn động vật",
        description: "TP. Hồ Chí Minh",
      },
      { id: 3, title: "Vườn quốc gia", description: "Đà Nẵng" },
      {
        id: 4,
        title: "Khu du lịch sinh thái",
        description: "Nha Trang",
      },
      { id: 5, title: "Khu cắm trại", description: "Phú Quốc" },
      { id: 6, title: "Khu leo núi", description: "Huế" },
      { id: 7, title: "Khu lặn biển", description: "Hội An" },
      {
        id: 8,
        title: "Khu thể thao dưới nước",
        description: "Đà Lạt",
      },
    ],
  },
];

export const activities = [
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "Lon Don",
    subtitle: "3889 Hoạt động",
  },
  {
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    title: "New York",
    subtitle: "3889 Hoạt động",
  },
  {
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "Singapore",
    subtitle: "3889 Hoạt động",
  },
  {
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "Siem Reap",
    subtitle: "3889 Hoạt động",
  },
  {
    imageUrl: cld("cities_hanoi_ouguno", { w: 360, h: 270 }),
    title: "TP. Hồ Chí Minh ",
    subtitle: "3889 Hoạt động",
  },
  {
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "Phuket",
    subtitle: "3889 Hoạt động",
  },
];

export const TAXI_FAQ_ITEMS = [
  {
    id: "flight-delay",
    question: "Nếu chuyến bay của tôi đến sớm hoặc bị hoãn thì sao?",
    answer: (
      <>
        Dịch vụ Meet &amp; Greet của chúng tôi bao gồm việc tài xế sẽ theo dõi
        chuyến bay của bạn và điều chỉnh thời điểm đón dựa vào giờ hạ cánh thực
        tế. Thông thường, tài xế sẽ đợi bạn đến 45 phút sau khi máy bay hạ cánh
        để bạn hoàn tất thủ tục hải quan, nhận hành lý và di chuyển ra khu vực
        đón khách.
      </>
    ),
  },
  {
    id: "price-include",
    question: "Giá đã bao gồm những gì?",
    answer: (
      <>
        Giá hiển thị đã bao gồm mọi chi phí cơ bản như lệ phí cầu đường, phụ
        phí, tiền tip và phí đường bộ. Nếu bạn đặt gói Meet &amp; Greet tiêu
        chuẩn, giá cũng bao gồm thời gian chờ lên đến 45 phút kể từ khi chuyến
        bay hạ cánh. Một số yêu cầu đặc biệt hoặc hành trình khác có thể phát
        sinh phụ phí riêng.
      </>
    ),
  },
  {
    id: "payment",
    question: "Tôi thanh toán bằng cách nào?",
    answer: (
      <>
        Tất cả dịch vụ xe riêng đều được thanh toán trước bằng thẻ hoặc ví điện
        tử khi đặt xe trực tuyến. Thanh toán được xử lý an toàn, chúng tôi chấp
        nhận hầu hết các loại thẻ tín dụng và ghi nợ phổ biến cũng như các hình
        thức thanh toán hợp lệ khác được hiển thị trên trang thanh toán.
      </>
    ),
  },
  {
    id: "cancel",
    question: "Tôi có thể hủy đặt xe của mình không?",
    answer: (
      <>
        Bạn thường có thể hủy đặt xe miễn phí cho tới 24 giờ trước thời điểm đón
        khách. Một số đối tác có thể cho phép hủy miễn phí trong khoảng thời
        gian ngắn hơn. Hãy kiểm tra lại điều kiện hủy trong email xác nhận đặt
        xe của bạn để biết chi tiết.
      </>
    ),
  },
];

export const RENTCAR_FAQ_ITEMS = [
  {
    id: "why-book-here",
    question: "Tại sao tôi nên đặt thuê xe ở Việt Nam với GoTripViet?",
    answer: (
      <>
        <p>
          Chúng tôi giúp bạn dễ dàng tìm được chiếc xe phù hợp với nhu cầu của
          mình, với nhiều lựa chọn và mức giá linh hoạt.
        </p>
        <ul>
          <li>Bộ sưu tập xe đa dạng – từ xe nhỏ gọn đến SUV.</li>
          <li>Đối tác thuê xe tại nhiều thành phố và sân bay.</li>
          <li>
            Chính sách hủy linh hoạt – thường có thể hủy miễn phí trước giờ nhận
            xe theo điều kiện của từng đơn vị cho thuê.
          </li>
        </ul>
      </>
    ),
  },
  {
    id: "what-to-prepare",
    question: "Tôi cần chuẩn bị gì để thuê một chiếc xe?",
    answer: (
      <>
        <p>
          Để đặt xe trực tuyến, thông thường bạn chỉ cần một thẻ thanh toán hợp
          lệ. Khi đến quầy nhận xe, nhà cung cấp có thể yêu cầu:
        </p>
        <ul>
          <li>Hộ chiếu hoặc giấy tờ tùy thân có ảnh.</li>
          <li>Voucher hoặc xác nhận đặt xe.</li>
          <li>Bằng lái xe còn hiệu lực của từng người lái.</li>
          <li>
            Thẻ tín dụng mang tên người lái chính (để đặt cọc hoặc thanh toán
            các chi phí phát sinh, tùy nhà cung cấp).
          </li>
        </ul>
        <p className="mt-2">
          Lưu ý: Một số hãng có thể có thêm yêu cầu riêng, bạn nên kiểm tra kỹ
          điều kiện thuê xe trước khi hoàn tất đặt chỗ.
        </p>
      </>
    ),
  },
  {
    id: "age-limit",
    question: "Tôi có đủ tuổi để thuê xe?",
    answer: (
      <>
        <p>
          Phần lớn các công ty cho thuê xe yêu cầu người lái từ 21 tuổi trở lên;
          một số nơi có thể áp dụng độ tuổi tối thiểu hoặc tối đa khác nhau.
        </p>
        <p>
          Nếu người lái dưới một ngưỡng tuổi nhất định (ví dụ 25 tuổi), nhà cung
          cấp có thể tính thêm phụ phí tài xế trẻ tùy điều kiện cụ thể.
        </p>
      </>
    ),
  },
  {
    id: "book-for-others",
    question:
      "Tôi có thể đặt xe cho bạn đời, bạn bè, đồng nghiệp, v.v. của mình không?",
    answer: (
      <>
        <p>
          Hoàn toàn được. Bạn có thể đặt xe giúp người khác, chỉ cần điền đúng
          thông tin của người lái xe trong mẫu đặt xe.
        </p>
        <p>
          Hãy đảm bảo người lái đáp ứng đầy đủ yêu cầu về bằng lái, độ tuổi và
          giấy tờ do đơn vị cho thuê xe quy định.
        </p>
      </>
    ),
  },
  {
    id: "how-to-choose-car",
    question: "Tôi cần xem xét những gì khi lựa chọn một chiếc xe?",
    answer: (
      <>
        <strong>Nơi và mục đích sử dụng:</strong> Nếu chủ yếu đi trong nội
        thành, xe nhỏ gọn dễ đỗ và tiết kiệm nhiên liệu sẽ phù hợp. Nếu đi đường
        dài hoặc nhiều người, có thể cân nhắc xe rộng rãi hoặc SUV.
        <strong>Số người và hành lý:</strong> Hãy chọn xe đủ chỗ cho tất cả hành
        khách và hành lý của bạn.
        <strong>Điều kiện đường xá:</strong> Với các tuyến đường đèo, địa hình
        khó, hãy chọn xe mạnh hơn hoặc xe gầm cao nếu cần.
        <strong>Hộp số và nhiên liệu:</strong> Nếu quen lái số tự động, hãy chọn
        đúng loại hộp số; cân nhắc mức tiêu hao nhiên liệu cho hành trình dài.
      </>
    ),
  },
  {
    id: "fees-included",
    question: "Tất cả các loại phí có được bao gồm trong giá thuê xe không?",
    answer: (
      <>
        <p>
          Giá hiển thị thường đã bao gồm phí thuê xe cơ bản và các loại thuế,
          phụ phí bắt buộc theo gói mà bạn chọn. Một số dịch vụ bổ sung có thể
          được tính riêng, ví dụ: ghế trẻ em, thiết bị GPS, tài xế bổ sung hoặc
          bảo hiểm mở rộng.
        </p>
        <p>
          Những khoản chưa bao gồm (nếu có) sẽ được ghi rõ ở bước đặt xe hoặc
          trên trang thanh toán. Bạn nên kiểm tra kỹ chi tiết giá trước khi xác
          nhận.
        </p>
      </>
    ),
  },
];

export const popularDestinations = [
  {
    id: "danang",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "Đà Nẵng",
    description: "Việt Nam",
  },
  {
    id: "vungtau",
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    title: "Vũng Tàu",
    description: "Việt Nam",
  },
  {
    id: "phuquoc",
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    title: "Phú Quốc",
    description: "Việt Nam",
  },
  {
    id: "longhai",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    title: "Long Hải",
    description: "Việt Nam",
  },
  {
    id: "nhatrang",
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "Nha Trang",
    description: "Việt Nam",
  },
  {
    id: "sapa",
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    title: "Nha Trang",
    description: "Việt Nam",
  },
];

export const FLIGHT_FAQ_ITEMS = [
  {
    id: "f1",
    question: "Làm sao để tìm chuyến bay rẻ nhất trên GoTripViet?",
    answer:
      "Bạn có thể sắp xếp theo giá để xem từ rẻ đến đắt. Ngoài ra, hãy cân nhắc thời điểm đặt vé và thời gian bay để có mức giá tốt hơn.",
  },
  {
    id: "f2",
    question: "Tôi có thể đặt vé máy bay một chiều trên GoTripViet không?",
    answer:
      "Có. Bạn có thể đặt vé một chiều, khứ hồi hoặc nhiều chặng tuỳ nhu cầu.",
  },
  {
    id: "f3",
    question: "Tôi có thể đặt chuyến bay trước bao lâu?",
    answer:
      "Thông thường bạn có thể đặt chuyến bay trước tối đa khoảng 1 năm so với ngày khởi hành (tuỳ hãng bay).",
  },
  {
    id: "f4",
    question: "Vé máy bay có rẻ hơn khi gần ngày bay không?",
    answer:
      "Thông thường giá vé có xu hướng tăng khi càng gần ngày khởi hành. Tuy đôi khi vẫn có ưu đãi, nhưng không phổ biến.",
  },
  {
    id: "f5",
    question: "Vé linh hoạt là gì?",
    answer:
      "Vé linh hoạt cho phép bạn đổi chuyến bay (thường cùng hãng) bằng cách trả chênh lệch giá vé và/hoặc phí đổi vé. Điều kiện áp dụng tuỳ từng hãng.",
  },
  {
    id: "f6",
    question: "GoTripViet có thu phí thẻ tín dụng không?",
    answer:
      "GoTripViet không thu thêm phí thẻ tín dụng. Bạn luôn có thể xem chi tiết bạn đang trả cho những gì trong phần tổng giá khi kiểm tra đặt chỗ.",
  },
];

// Listing Cities for Flights
export const CITY_DEALS = [
  {
    id: "dn",
    title: "Đà Nẵng",
    country: "Việt Nam",
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    price: 9266147,
    popularScore: 99,
    minStops: 0,
    fastestHours: 1.6,
  },
  {
    id: "hn",
    title: "Hà Nội",
    country: "Việt Nam",
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    price: 3513294,
    popularScore: 95,
    minStops: 0,
    fastestHours: 2.1,
  },
  {
    id: "pq",
    title: "Phú Quốc",
    country: "Việt Nam",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    price: 2897432,
    popularScore: 90,
    minStops: 0,
    fastestHours: 1.2,
  },
  {
    id: "nt",
    title: "Nha Trang",
    country: "Việt Nam",
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    price: 3266147,
    popularScore: 99,
    minStops: 0,
    fastestHours: 1.6,
  },
  {
    id: "dl",
    title: "Đà Lạt",
    country: "Việt Nam",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    price: 3513294,
    popularScore: 95,
    minStops: 0,
    fastestHours: 2.1,
  },
  {
    id: "sp",
    title: "Sapa",
    country: "Việt Nam",
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    price: 2897432,
    popularScore: 90,
    minStops: 0,
    fastestHours: 1.2,
  },
  {
    id: "dn",
    title: "Đà Nẵng",
    country: "Việt Nam",
    imageUrl: cld("cities_hcm_yagc7o", { w: 360, h: 270 }),
    price: 3266147,
    popularScore: 99,
    minStops: 0,
    fastestHours: 1.6,
  },
  {
    id: "hn",
    title: "Hà Nội",
    country: "Việt Nam",
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    price: 3513294,
    popularScore: 95,
    minStops: 0,
    fastestHours: 2.1,
  },
  {
    id: "pq",
    title: "Phú Quốc",
    country: "Việt Nam",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    price: 2897432,
    popularScore: 90,
    minStops: 0,
    fastestHours: 1.2,
  },
  {
    id: "nt",
    title: "Nha Trang",
    country: "Việt Nam",
    imageUrl: cld("cities_nhatrang_di00lv", { w: 360, h: 270 }),
    price: 3266147,
    popularScore: 99,
    minStops: 0,
    fastestHours: 1.6,
  },
  {
    id: "dl",
    title: "Đà Lạt",
    country: "Việt Nam",
    imageUrl: cld("cities_dalat_ipb25j", { w: 360, h: 270 }),
    price: 3513294,
    popularScore: 95,
    minStops: 0,
    fastestHours: 2.1,
  },
  {
    id: "sp",
    title: "Sapa",
    country: "Việt Nam",
    imageUrl: cld("cities_sapa_spnoq3", { w: 360, h: 270 }),
    price: 2897432,
    popularScore: 90,
    minStops: 0,
    fastestHours: 1.2,
  },
];

export const CITY_OFFERS = {
  dn: [
    {
      id: "dn-1",
      airlines: ["Vietravel Airlines", "VietJet Aviation"],
      airports: ["SGN", "DAD"],
      direct: true,
      tripType: "Khứ hồi",
      durationText: "1 giờ 20 phút",
      price: 2332182,
    },
    {
      id: "dn-2",
      airlines: ["Vietnam Airlines", "Bamboo Airways"],
      airports: ["SGN", "DAD"],
      direct: false,
      tripType: "Một chiều",
      durationText: "2 giờ 15 phút",
      price: 1987654,
    },
  ],
  hn: [
    {
      id: "hn-1",
      airlines: ["Vietnam Airlines", "VietJet Aviation"],
      airports: ["SGN", "HAN"],
      direct: true,
      tripType: "Khứ hồi",
      durationText: "2 giờ 5 phút",
      price: 9765432,
    },
    {
      id: "hn-2",
      airlines: ["Bamboo Airways", "Vietravel Airlines"],
      airports: ["SGN", "HAN"],
      direct: false,
      tripType: "Một chiều",
      durationText: "3 giờ 10 phút",
      price: 2456789,
    },
  ],
  pq: [
    {
      id: "pq-1",
      airlines: ["VietJet Aviation", "Bamboo Airways"],
      airports: ["SGN", "PQC"],
      direct: true,
      tripType: "Khứ hồi",
      durationText: "1 giờ 10 phút",
      price: 1987654,
    },
    {
      id: "pq-2",
      airlines: ["Vietnam Airlines", "Vietravel Airlines"],
      airports: ["SGN", "PQC"],
      direct: false,
      tripType: "Một chiều",
      durationText: "2 giờ 5 phút",
      price: 1765432,
    },
  ],
};
