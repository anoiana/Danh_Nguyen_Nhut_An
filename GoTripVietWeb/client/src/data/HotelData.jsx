import { cld } from "../utils/cld.js";

export const HOTEL_NAME = "Sao Mai Hotel";

export const HOTEL_ADDRESS =
  "Ấp An Thạnh, xã Đông Hòa Hiệp, Cái Bè, Tiền Giang, Việt Nam";

export const HOTEL_SCORE = 9.7;
export const HOTEL_SCORE_LABEL = "Xuất sắc";
export const HOTEL_REVIEW_COUNT = 312;
export const HOTEL_LOCATION_NOTE = "Điểm cao ở Cái Bè";

export const HOTEL_IMAGES = [
  {
    url: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    alt: "Mặt tiền khách sạn",
  },
  {
    url: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    alt: "Phòng giường đôi",
  },
  {
    url: cld("hotel_nhatrang_ldsrxe", { w: 640, h: 480 }),
    alt: "Phòng tắm riêng",
  },
  {
    url: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    alt: "Khu vườn",
  },
  {
    url: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    alt: "Khu vực ăn uống",
  },
  {
    url: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    alt: "Phòng 4 người",
  },
  {
    url: cld("hotel_saigon_g9dkyk", { w: 640, h: 480 }),
    alt: "Phòng có ban công",
  },
  {
    url: cld("hotel_nhatrang_ldsrxe", { w: 640, h: 480 }),
    alt: "Phòng tắm",
  },
];

export const HOTEL_ROOMS = [
  {
    id: "double",
    title: "Phòng Giường Đôi",
    bedDescription: "1 giường đôi lớn",
    maxGuests: 2,
    facilities: {
      sizeM2: 26,
      hasView: true,
      hasAirConditioner: true,
      hasPrivateBathroom: true,
      hasFlatTV: true,
      hasMinibar: true,
      hasWifi: true,
    },
    amenities: {
      toiletries: true,
      shower: true,
      toilet: true,
      towels: true,
      tiledFloor: true,
      tv: true,
      slippers: true,
      fridge: true,
      telephone: true,
      fan: true,
      extraLongBed: true,
      cableChannels: true,
      wardrobe: true,
      diningArea: true,
      diningTable: true,
      clothesRack: true,
    },
    price: {
      originalPrice: 25,
      discountedPrice: 16,
      currency: "USD",
      perNightLabel: "US$16 mỗi đêm · 1 đêm",
      serviceFeePercent: 5,
      vatPercent: 8,
    },
    options: {
      breakfastPrice: 2,
      breakfastCurrency: "USD",
      partialRefund: true,
      prepayBeforeArrival: true,
      noCreditCardNeeded: true,
      hasGeniusDiscount: true,
      remainingRooms: 3,
    },
  },
  {
    id: "quad",
    title: "Phòng 4 Người",
    bedDescription: "2 giường đôi lớn",
    maxGuests: 4,
    facilities: {
      sizeM2: 30,
      hasView: true,
      hasAirConditioner: true,
      hasPrivateBathroom: true,
      hasFlatTV: true,
      hasMinibar: true,
      hasWifi: true,
    },
    amenities: {
      toiletries: true,
      shower: true,
      toilet: true,
      towels: true,
      tiledFloor: true,
      tv: true,
      slippers: true,
      fridge: true,
      telephone: true,
      fan: true,
      cableChannels: true,
      wardrobe: true,
      diningArea: true,
      diningTable: true,
    },
    price: {
      originalPrice: 30,
      discountedPrice: 25,
      currency: "USD",
      perNightLabel: "US$25 mỗi đêm · 1 đêm",
      serviceFeePercent: 5,
      vatPercent: 8,
    },
    options: {
      breakfastPrice: 2,
      breakfastCurrency: "USD",
      partialRefund: true,
      prepayBeforeArrival: true,
      noCreditCardNeeded: true,
      hasGeniusDiscount: true,
      remainingRooms: 2,
    },
  },
];

export const HOTEL_EVALUATION_CATEGORIES = [
  { id: "staff", name: "Nhân viên phục vụ", score: 10 },
  { id: "comfort", name: "Thoải mái", score: 9.3 },
  { id: "wifi", name: "WiFi miễn phí", score: 8.3 },
  { id: "facilities", name: "Tiện nghi", score: 9.0 },
  { id: "value", name: "Đáng giá tiền", score: 9.8 },
  { id: "cleanliness", name: "Sạch sẽ", score: 9.4 },
  { id: "location", name: "Địa điểm", score: 9.4 },
];

export const HOTEL_REVIEWS = [
  {
    id: 1,
    name: "Roger",
    countryName: "Vương Quốc Anh",
    countryFlagEmoji: "🇬🇧",
    text: "Không khí trong lành với bầu không khí thoải mái. Thích hợp cho kỳ nghỉ ngắn hoặc dài ngày. Chủ nhà rất hữu ích trong việc sắp xếp xe buýt, v.v...",
    learnMoreUrl: "#",
    translatedBy: "Google",
    originalUrl: "#",
  },
  {
    id: 2,
    name: "Joachim",
    countryName: "Đức",
    countryFlagEmoji: "🇩🇪",
    text: "Chủ nhà, anh Vũ, thật tuyệt vời. Anh ấy đón tôi bằng xe máy khi xe buýt không dừng ở Cái Bè. Phòng rộng, có điều hòa, giường thoải mái...",
    learnMoreUrl: "#",
    translatedBy: "Google",
    originalUrl: "#",
  },
  {
    id: 3,
    name: "Janet",
    countryName: "Vương Quốc Anh",
    countryFlagEmoji: "🇬🇧",
    text: "Vị trí tuyệt vời nhìn ra sông. Đây là khách sạn do gia đình quản lý, bữa sáng ngon và có trải nghiệm tour địa phương rất thú vị...",
    learnMoreUrl: "#",
    translatedBy: "Google",
    originalUrl: "#",
  },
];
/* =========================
   LISTING DATA (moved here)
   ========================= */

export const SIMILAR_STAYS = [
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    stayType: "Nhà nghỉ giữa thiên nhiên",
    stars: 2,
    name: "Green Hope Lodge",
    ratingScore: 9.0,
    reviewCount: 728,
    distanceToCenterKm: 3.1,
    priceFrom: 770000,
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    stayType: "Nhà khách",
    name: "Forest Side Ecolodge",
    ratingScore: 8.8,
    reviewCount: 130,
    distanceToCenterKm: 3.3,
    priceFrom: 489888,
  },
  {
    imageUrl: "/assets/hotels/cat-tien-jungle.jpg",
    stayType: "Khách sạn",
    name: "Cat Tien Jungle Lodge",
    ratingScore: 7.4,
    reviewCount: 34,
    distanceToCenterKm: 3.3,
    priceFrom: 1400000,
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    stayType: "Nhà nghỉ giữa thiên nhiên",
    name: "Thuy Tien Ecolodge",
    ratingScore: 9.2,
    reviewCount: 259,
    distanceToCenterKm: 3.2,
    priceFrom: 500000,
  },
];

export const LISTING_HOTELS = [
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Green Bamboo Lodge Resort",
    stars: 3,
    badgeLabel: "Nổi bật",
    location: "Cát Tiên",
    distanceToCenterKm: 3.4,
    ratingScore: 8.6,
    reviewCount: 689,
    eventLabel: "Ưu đãi cuối năm",
    roomName: "Chalet",
    roomDescription: {
      bathrooms: 1,
      bedrooms: 1,
      areaM2: 25,
      bedSummary: "1 giường đôi lớn",
      extraText: "Phù hợp cho 2 người lớn",
    },
    includesBreakfast: true,
    freeCancellation: true,
    payAtProperty: true,
    remainingRoomsText: "Chỉ còn 1 phòng với giá này trên trang của chúng tôi",
    priceInfo: {
      basePrice: 900000,
      discountedPrice: 665000,
      currency: "VND",
      nights: 1,
      adults: 2,
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Green Hope Lodge",
    stars: 2,
    location: "Cát Tiên",
    distanceToCenterKm: 3.1,
    ratingScore: 9.0,
    reviewCount: 728,
    roomName: "Phòng Superior 4 Người Nhìn ra Dòng sông",
    roomDescription: {
      bathrooms: 1,
      bedrooms: 1,
      bedSummary: "2 giường đôi",
      extraText: "Ban công · Tầm nhìn ra sông",
    },
    includesBreakfast: true,
    freeCancellation: true,
    payAtProperty: true,
    remainingRoomsText: "Chỉ còn 3 phòng với giá này trên trang của chúng tôi",
    priceInfo: {
      basePrice: 770000,
      currency: "VND",
      nights: 1,
      adults: 2,
    },
  },
  {
    imageUrl: cld("hotel_danang_pwadaf", { w: 640, h: 480 }),
    title: "Lava Rock Viet Nam Lodge",
    stars: 3,
    location: "Cát Tiên",
    distanceToCenterKm: 1.2,
    ratingScore: 8.3,
    reviewCount: 123,
    roomName: "Bungalow Nhìn ra Vườn",
    roomDescription: {
      bathrooms: 1,
      isWholeBungalow: true,
      bedSummary: "1 giường đôi lớn",
    },
    includesBreakfast: true,
    freeCancellation: true,
    priceInfo: {
      basePrice: 950000,
      currency: "VND",
      nights: 1,
      adults: 2,
    },
  },
];
