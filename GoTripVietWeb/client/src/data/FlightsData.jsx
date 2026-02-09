import { cld } from "../utils/cld.js";

// helpers (để data tự có departMin/arriveMin)
export const timeToMinutes = (t) => {
  const [hh, mm] = String(t || "0:0")
    .split(":")
    .map(Number);
  return hh * 60 + mm;
};

// (tuỳ bạn) map code -> logo cloudinary (thay publicId thật của bạn)
export const AIRLINE_LOGO = {
  VJ: cld("airline_ana_e88cvc", { w: 48, h: 48, crop: "fill", g: "auto" }),
  UO: cld("airline_vietnamairline_ztwjvt", {
    w: 48,
    h: 48,
    crop: "fill",
    g: "auto",
  }),
  MU: cld("airline_vietjet_vjjhka", { w: 48, h: 48, crop: "fill", g: "auto" }),
  CM: cld("airline_american_ssbjyv", { w: 48, h: 48, crop: "fill", g: "auto" }),
  NH: cld("airline_hkexpress_myf16j", {
    w: 48,
    h: 48,
    crop: "fill",
    g: "auto",
  }),
  AA: cld("airline_ana_e88cvc", { w: 48, h: 48, crop: "fill", g: "auto" }),
  VN: cld("airline_vietjet_vjjhka", { w: 48, h: 48, crop: "fill", g: "auto" }),
  AK: cld("airline_vietjet_vjjhka", { w: 48, h: 48, crop: "fill", g: "auto" }),
  LA: cld("airline_american_ssbjyv", { w: 48, h: 48, crop: "fill", g: "auto" }),
  SQ: cld("airline_hkexpress_myf16j", {
    w: 48,
    h: 48,
    crop: "fill",
    g: "auto",
  }),
  JL: cld("airline_vietnamairline_ztwjvt", {
    w: 48,
    h: 48,
    crop: "fill",
    g: "auto",
  }),
  CX: cld("airline_american_ssbjyv", { w: 48, h: 48, crop: "fill", g: "auto" }),
  KE: cld("airline_ana_e88cvc", { w: 48, h: 48, crop: "fill", g: "auto" }),
  QH: cld("airline_vietjet_vjjhka", { w: 48, h: 48, crop: "fill", g: "auto" }),
};

export const airlineLogosFromCodes = (codes = []) =>
  [...new Set(codes)].map((c) => AIRLINE_LOGO[c]).filter(Boolean);

export const DUMMY_FLIGHTS = [
  {
    id: "f1",
    tags: ["Rẻ nhất", "Có thể nâng lên thành vé linh hoạt"],
    flexible: true,
    best: false,
    price: 29199642,

    // dùng cho icon hành lý + tooltip
    baggage: { personal: true, carryOn: true, checked: true },

    // ✅ FilterBar thống kê theo danh sách này
    airlines: ["AirAsia", "LATAM"],

    totalDurationHours: 54,
    stopsMax: 1,

    // ✅ lọc theo giờ bay
    departMin: timeToMinutes("14:50"),
    arriveMin: timeToMinutes("22:45"),

    // ✅ FlightCard + DetailFlightCard
    lines: [
      // OUTBOUND
      {
        depTime: "14:50",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "22:45",
        arrAirport: "HND",
        arrDate: "18 tháng 1",
        durationText: "29 giờ 55 phút",
        processTag: { type: "stops", label: "1 điểm dừng" },

        // ✅ từng lần bay (segment)
        segments: [
          {
            airlineName: "AirAsia",
            airlineLogo: airlineLogosFromCodes(["AK"])[0],
            cabinClass: "Hạng phổ thông",

            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "14:50",
            departDate: "T7, 17 tháng 1",

            toIata: "HKG",
            toName: "Sân bay Quốc tế Hồng Kông",
            arriveTime: "20:30",
            arriveDate: "T7, 17 tháng 1",

            durationText: "5 giờ 40 phút",
          },
          {
            airlineName: "LATAM",
            airlineLogo: airlineLogosFromCodes(["LA"])[0],
            cabinClass: "Hạng phổ thông",

            fromIata: "HKG",
            fromName: "Sân bay Quốc tế Hồng Kông",
            departTime: "22:10",
            departDate: "T7, 17 tháng 1",

            toIata: "HND",
            toName: "Tokyo Haneda Airport",
            arriveTime: "22:45",
            arriveDate: "CN, 18 tháng 1",

            durationText: "24 giờ 15 phút",
          },
        ],

        // ✅ quá cảnh dạng A
        layovers: [
          {
            afterIndex: 0,
            type: "self_transfer",
            durationText: "2 giờ 05 phút",
          },
        ],
      },

      // RETURN
      {
        depTime: "08:40",
        depAirport: "HND",
        depDate: "22 tháng 1",
        arrTime: "06:30",
        arrAirport: "SGN",
        arrDate: "23 tháng 1",
        durationText: "33 giờ 50 phút",
        processTag: { type: "direct", label: "Bay thẳng" },

        segments: [
          {
            airlineName: "AirAsia",
            airlineLogo: airlineLogosFromCodes(["AK"])[0],
            cabinClass: "Hạng phổ thông",

            fromIata: "HND",
            fromName: "Tokyo Haneda Airport",
            departTime: "08:40",
            departDate: "T7, 22 tháng 1",

            toIata: "SGN",
            toName: "Sân bay Quốc tế Tân Sơn Nhất",
            arriveTime: "06:30",
            arriveDate: "CN, 23 tháng 1",

            durationText: "33 giờ 50 phút",
          },
        ],
      },
    ],

    operatedBy: "AirAsia, LATAM",

    // ✅ phần detail: hành lý / điều kiện / dịch vụ
    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 5 kg",
      },
      checked: { title: "1 hành lý ký gửi", desc: "Trọng lượng tối đa 23 kg" },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-luggage",
        title: "Hành lý ký gửi",
        sub: "Từ VND 560.489,98",
        note: "Có ở các bước tiếp theo",
      },
      {
        icon: "bi-calendar2-check",
        title: "Vé linh động",
        sub: "Có thể đổi ngày + VND 310.868,87 cho tất cả hành khách",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },

  {
    id: "f2",
    tags: ["Nhanh nhất", "Bay thẳng rẻ nhất"],
    flexible: false,
    best: true,
    price: 48097414,

    baggage: { personal: true, carryOn: true, checked: false },

    airlines: ["AirAsia", "LATAM"],
    totalDurationHours: 35,
    stopsMax: 1,

    departMin: timeToMinutes("10:35"),
    arriveMin: timeToMinutes("22:40"),

    lines: [
      {
        depTime: "10:35",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "22:40",
        arrAirport: "HND",
        arrDate: "17 tháng 1",
        durationText: "10 giờ 05 phút",
        processTag: { type: "stops", label: "1 điểm dừng" },

        segments: [
          {
            airlineName: "AirAsia",
            airlineLogo: airlineLogosFromCodes(["AK"])[0],
            cabinClass: "Hạng phổ thông",

            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "10:35",
            departDate: "T7, 17 tháng 1",

            toIata: "HND",
            toName: "Tokyo Haneda Airport",
            arriveTime: "22:40",
            arriveDate: "T7, 17 tháng 1",

            durationText: "10 giờ 05 phút",
          },
          {
            airlineName: "LATAM",
            airlineLogo: airlineLogosFromCodes(["LA"])[0],
            cabinClass: "Hạng phổ thông",

            fromIata: "HND",
            fromName: "Tokyo Haneda Airport",
            departTime: "17:05",
            departDate: "T4, 24 tháng 1",

            toIata: "GRU",
            toName: "Sân bay Quốc tế Guarulhos",
            arriveTime: "05:40",
            arriveDate: "T5, 25 tháng 1",

            durationText: "24 giờ 35 phút",
          },
        ],

        // ✅ quá cảnh dạng B (chỉ 1 dòng)
        layovers: [
          {
            afterIndex: 0,
            type: "normal",
            durationText: "1 giờ 20 phút",
          },
        ],
      },
    ],

    operatedBy:
      "Air Asia, AirasiaX SDN BHD, LATAM, điều hành bởi Japan Airlines For Latam Airlines Group",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 5 kg",
      },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-luggage",
        title: "Hành lý ký gửi",
        sub: "Từ VND 560.489,98",
        note: "Có ở các bước tiếp theo",
      },
      {
        icon: "bi-calendar2-check",
        title: "Vé linh động",
        sub: "Có thể đổi ngày + VND 310.868,87 cho tất cả hành khách",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
  {
    id: "f3",
    tags: ["Tốt nhất", "Bay thẳng rẻ nhất"],
    flexible: false,
    best: true,
    price: 2391299,

    baggage: { personal: true, carryOn: true, checked: false },
    airlines: ["Vietnam Airlines"],

    totalDurationHours: 1.5,
    stopsMax: 0,

    departMin: timeToMinutes("19:10"),
    arriveMin: timeToMinutes("20:30"),

    lines: [
      {
        depTime: "19:10",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "20:30",
        arrAirport: "DAD",
        arrDate: "17 tháng 1",
        durationText: "1 giờ 20 phút",
        processTag: { type: "direct", label: "Bay thẳng" },

        segments: [
          {
            airlineName: "Vietnam Airlines",
            airlineLogo: airlineLogosFromCodes(["VN"])[0],
            flightNo: "VN123",
            cabinClass: "Hạng phổ thông",

            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "19:10",
            departDate: "T7, 17 tháng 1",

            toIata: "DAD",
            toName: "Sân bay Quốc tế Đà Nẵng",
            arriveTime: "20:30",
            arriveDate: "T7, 17 tháng 1",

            durationText: "1 giờ 20 phút",
          },
        ],
      },
    ],

    operatedBy: "Vietnam Airlines",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 7 kg",
      },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-luggage",
        title: "Hành lý ký gửi",
        sub: "Từ VND 220.000",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
  {
    id: "f4",
    tags: ["Rẻ nhất", "Có thể nâng lên thành vé linh hoạt"],
    flexible: true,
    best: false,
    price: 29199642,

    baggage: { personal: true, carryOn: true, checked: true },
    airlines: ["AirAsia", "Cathay Pacific"],

    totalDurationHours: 12,
    stopsMax: 1,

    departMin: timeToMinutes("10:35"),
    arriveMin: timeToMinutes("22:40"),

    lines: [
      {
        depTime: "10:35",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "22:40",
        arrAirport: "HND",
        arrDate: "17 tháng 1",
        durationText: "10 giờ 05 phút",
        processTag: { type: "stops", label: "1 điểm dừng" },

        segments: [
          {
            airlineName: "AirAsia",
            airlineLogo: airlineLogosFromCodes(["AK"])[0],
            flightNo: "AK529",
            cabinClass: "Hạng phổ thông",

            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "10:35",
            departDate: "T7, 17 tháng 1",

            toIata: "KUL",
            toName: "Sân bay Quốc tế Kuala Lumpur",
            arriveTime: "13:35",
            arriveDate: "T7, 17 tháng 1",

            durationText: "2 giờ",
          },
          {
            airlineName: "Cathay Pacific",
            airlineLogo: airlineLogosFromCodes(["CX"])[0],
            flightNo: "CX768",
            cabinClass: "Hạng phổ thông",

            fromIata: "KUL",
            fromName: "Sân bay Quốc tế Kuala Lumpur",
            departTime: "14:50",
            departDate: "T7, 17 tháng 1",

            toIata: "HND",
            toName: "Tokyo Haneda Airport",
            arriveTime: "22:40",
            arriveDate: "T7, 17 tháng 1",

            durationText: "6 giờ 50 phút",
          },
        ],

        layovers: [
          {
            afterIndex: 0,
            type: "self_transfer",
            durationText: "1 giờ 15 phút",
          },
        ],
      },
    ],

    operatedBy: "AirAsia, Cathay Pacific",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 7 kg",
      },
      checked: { title: "1 hành lý ký gửi", desc: "Trọng lượng tối đa 23 kg" },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-luggage",
        title: "Hành lý ký gửi",
        sub: "Từ VND 560.489",
        note: "Có ở các bước tiếp theo",
      },
      {
        icon: "bi-calendar2-check",
        title: "Vé linh động",
        sub: "Có thể đổi ngày",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
  {
    id: "f5",
    tags: ["Nhanh nhất"],
    flexible: false,
    best: false,
    price: 30178374,

    baggage: { personal: true, carryOn: true, checked: true },
    airlines: ["Singapore Airlines", "Japan Airlines", "LATAM"],

    totalDurationHours: 28,
    stopsMax: 2,

    departMin: timeToMinutes("05:50"),
    arriveMin: timeToMinutes("22:45"),

    lines: [
      {
        depTime: "05:50",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "22:45",
        arrAirport: "GRU",
        arrDate: "17 tháng 1",
        durationText: "14 giờ 55 phút",
        processTag: { type: "stops", label: "2 điểm dừng" },

        segments: [
          {
            airlineName: "Singapore Airlines",
            airlineLogo: airlineLogosFromCodes(["SQ"])[0],
            flightNo: "SQ183",
            cabinClass: "Hạng phổ thông",
            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "05:50",
            departDate: "T7, 17 tháng 1",
            toIata: "SIN",
            toName: "Sân bay Changi",
            arriveTime: "09:10",
            arriveDate: "T7, 17 tháng 1",
            durationText: "2 giờ 20 phút",
          },
          {
            airlineName: "Japan Airlines",
            airlineLogo: airlineLogosFromCodes(["JL"])[0],
            flightNo: "JL36",
            cabinClass: "Hạng phổ thông",
            fromIata: "SIN",
            fromName: "Sân bay Changi",
            departTime: "10:40",
            departDate: "T7, 17 tháng 1",
            toIata: "HND",
            toName: "Tokyo Haneda Airport",
            arriveTime: "18:20",
            arriveDate: "T7, 17 tháng 1",
            durationText: "6 giờ 40 phút",
          },
          {
            airlineName: "LATAM",
            airlineLogo: airlineLogosFromCodes(["LA"])[0],
            flightNo: "LA8087",
            cabinClass: "Hạng phổ thông",
            fromIata: "HND",
            fromName: "Tokyo Haneda Airport",
            departTime: "19:30",
            departDate: "T7, 17 tháng 1",
            toIata: "GRU",
            toName: "Sân bay Quốc tế Guarulhos",
            arriveTime: "22:45",
            arriveDate: "CN, 18 tháng 1",
            durationText: "11 giờ 50 phút",
          },
        ],

        layovers: [
          { afterIndex: 0, type: "normal", durationText: "1 giờ 30 phút" }, // giữa seg0 -> seg1
          {
            afterIndex: 1,
            type: "self_transfer",
            durationText: "2 giờ 05 phút",
          }, // giữa seg1 -> seg2 (demo kiểu A)
        ],
      },
    ],

    operatedBy: "Singapore Airlines, Japan Airlines, LATAM",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 7 kg",
      },
      checked: { title: "1 hành lý ký gửi", desc: "Trọng lượng tối đa 23 kg" },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-calendar2-check",
        title: "Vé linh động",
        sub: "Có thể đổi ngày",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
  {
    id: "f6",
    tags: ["Tốt nhất"],
    flexible: false,
    best: true,
    price: 3529364,

    baggage: { personal: true, carryOn: true, checked: true },
    airlines: ["Bamboo Airways", "Korean Air"],

    totalDurationHours: 20,
    stopsMax: 1,

    departMin: timeToMinutes("07:15"),
    arriveMin: timeToMinutes("11:05"),

    lines: [
      {
        depTime: "07:15",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "09:00",
        arrAirport: "HAN",
        arrDate: "17 tháng 1",
        durationText: "1 giờ 45 phút",
        processTag: { type: "direct", label: "Bay thẳng" },
        segments: [
          {
            airlineName: "Bamboo Airways",
            airlineLogo: airlineLogosFromCodes(["QH"])[0],
            flightNo: "QH201",
            cabinClass: "Hạng phổ thông",
            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "07:15",
            departDate: "T7, 17 tháng 1",
            toIata: "HAN",
            toName: "Sân bay Quốc tế Nội Bài",
            arriveTime: "09:00",
            arriveDate: "T7, 17 tháng 1",
            durationText: "1 giờ 45 phút",
          },
        ],
      },
      {
        depTime: "17:10",
        depAirport: "HAN",
        depDate: "24 tháng 1",
        arrTime: "23:55",
        arrAirport: "SGN",
        arrDate: "24 tháng 1",
        durationText: "6 giờ 45 phút",
        processTag: { type: "stops", label: "1 điểm dừng" },
        segments: [
          {
            airlineName: "Korean Air",
            airlineLogo: airlineLogosFromCodes(["KE"])[0],
            flightNo: "KE680",
            cabinClass: "Hạng phổ thông",
            fromIata: "HAN",
            fromName: "Sân bay Quốc tế Nội Bài",
            departTime: "17:10",
            departDate: "T7, 24 tháng 1",
            toIata: "ICN",
            toName: "Sân bay Incheon",
            arriveTime: "21:20",
            arriveDate: "T7, 24 tháng 1",
            durationText: "4 giờ 10 phút",
          },
          {
            airlineName: "Korean Air",
            airlineLogo: airlineLogosFromCodes(["KE"])[0],
            flightNo: "KE693",
            cabinClass: "Hạng phổ thông",
            fromIata: "ICN",
            fromName: "Sân bay Incheon",
            departTime: "22:30",
            departDate: "T7, 24 tháng 1",
            toIata: "SGN",
            toName: "Sân bay Quốc tế Tân Sơn Nhất",
            arriveTime: "23:55",
            arriveDate: "T7, 24 tháng 1",
            durationText: "1 giờ 25 phút",
          },
        ],
        layovers: [
          {
            afterIndex: 0,
            type: "normal",
            durationText: "1 giờ 10 phút",
          },
        ],
      },
    ],

    operatedBy: "Bamboo Airways, Korean Air",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 7 kg",
      },
      checked: { title: "1 hành lý ký gửi", desc: "Trọng lượng tối đa 20 kg" },
    },
    ticketRules: [
      {
        icon: "bi-arrow-repeat",
        text: "Bạn được phép đổi chuyến bay này, có trả phí",
      },
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-luggage",
        title: "Hành lý ký gửi",
        sub: "Từ VND 350.000",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
  {
    id: "f7",
    tags: ["Rẻ nhất"],
    flexible: false,
    best: false,
    price: 19919642,

    baggage: { personal: true, carryOn: true, checked: false },
    airlines: ["VietJet"],

    totalDurationHours: 6,
    stopsMax: 0,

    departMin: timeToMinutes("23:50"),
    arriveMin: timeToMinutes("05:10"),

    lines: [
      {
        depTime: "23:50",
        depAirport: "SGN",
        depDate: "17 tháng 1",
        arrTime: "05:10",
        arrAirport: "HAN",
        arrDate: "18 tháng 1",
        durationText: "5 giờ 20 phút",
        processTag: { type: "direct", label: "Bay thẳng" },

        segments: [
          {
            airlineName: "VietJet",
            airlineLogo: airlineLogosFromCodes(["VJ"])[0],
            flightNo: "VJ112",
            cabinClass: "Hạng phổ thông",
            fromIata: "SGN",
            fromName: "Sân bay Quốc tế Tân Sơn Nhất",
            departTime: "23:50",
            departDate: "T7, 17 tháng 1",
            toIata: "HAN",
            toName: "Sân bay Quốc tế Nội Bài",
            arriveTime: "05:10",
            arriveDate: "CN, 18 tháng 1",
            durationText: "5 giờ 20 phút",
          },
        ],
      },
    ],

    operatedBy: "VietJet",

    baggageDetails: {
      personal: {
        title: "1 túi xách nhỏ",
        desc: "Phải vừa với gầm ghế phía trước chỗ ngồi của bạn",
      },
      carryOn: {
        title: "1 hành lý cabin",
        desc: "23 x 36 x 56 cm · Trọng lượng tối đa 7 kg",
      },
    },
    ticketRules: [
      {
        icon: "bi-x-circle",
        text: "Bạn được phép huỷ chuyến bay này, có trả phí",
      },
    ],
    extras: [
      {
        icon: "bi-calendar2-check",
        title: "Vé linh động",
        sub: "Có thể đổi ngày",
        note: "Có ở các bước tiếp theo",
      },
    ],
  },
];

// default filter (mình tách thành function để Set luôn đúng)
export const createDefaultFlightFilters = (airlineNames = []) => ({
  stops: "any",
  durationMax: 54,
  timeTab: "outbound",
  departBins: new Set(),
  arriveBins: new Set(),
  airlines: new Set(airlineNames), // tick hết
});
