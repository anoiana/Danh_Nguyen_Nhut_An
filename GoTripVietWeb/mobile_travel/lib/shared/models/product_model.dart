class ProductModel {
  final String id;
  final String title;
  final String productCode;
  final List<String> images;
  final num basePrice;
  final num price;
  final List<String> categoryIds;
  final String duration;
  final String transport;
  final String startPoint;
  final List<ItineraryItem> itinerary;

  // Thông tin thêm (Highlights)
  final TripHighlights? highlights;

  // [BỔ SUNG] Danh sách ngày khởi hành (Để hiển thị ở Home/TourCard)
  final List<DateTime>? departureDates;

  ProductModel({
    required this.id,
    required this.title,
    required this.productCode,
    required this.images,
    required this.basePrice,
    required this.price,
    required this.categoryIds,
    required this.duration,
    required this.transport,
    required this.startPoint,
    required this.itinerary,
    this.highlights,
    this.departureDates, // Constructor
  });

  // ✅ [SỬA LỖI QUAN TRỌNG] Thêm Getter imageUrl
  // Giúp các file UI (TourCard, BookingScreen) gọi .imageUrl bình thường
  String get imageUrl {
    if (images.isNotEmpty) {
      return images.first;
    }
    return ""; // Trả về rỗng để ImageHelper xử lý hiển thị placeholder
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý Images an toàn
    List<String> imgList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imgList = (json['images'] as List).map((e) {
          if (e is Map && e['url'] != null) return e['url'].toString();
          return e.toString();
        }).toList();
      } else if (json['images'] is String) {
        imgList = [json['images']];
      }
    }

    // 2. Xử lý Tour Details
    final details = json['tour_details'] ?? {};

    // 3. Xử lý Itinerary
    var itineraryList = <ItineraryItem>[];
    if (details['itinerary'] != null && details['itinerary'] is List) {
      itineraryList = (details['itinerary'] as List)
          .map((i) => ItineraryItem.fromJson(i))
          .toList();
    }

    // 4. [BỔ SUNG] Parse Departure Dates (Được inject từ HomeService)
    List<DateTime> dates = [];
    if (json['departure_dates'] != null && json['departure_dates'] is List) {
      dates = (json['departure_dates'] as List)
          .map((e) => DateTime.parse(e.toString()))
          .toList();
    }

    return ProductModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Chưa cập nhật tên',
      productCode: json['product_code'] ?? '',
      images: imgList,
      basePrice: json['base_price'] ?? 0,
      price: json['base_price'] ?? 0,
      categoryIds: json['category_ids'] != null
          ? (json['category_ids'] as List).map((e) => e.toString()).toList()
          : [],
      duration:
          "${details['duration_days'] ?? 0} ngày ${details['duration_nights'] ?? 0} đêm",
      transport: details['transport_type'] ?? 'Ô tô',
      startPoint: details['start_point'] ?? 'Hồ Chí Minh',
      itinerary: itineraryList,

      highlights: details['trip_highlights'] != null
          ? TripHighlights.fromJson(details['trip_highlights'])
          : null,

      departureDates: dates, // Gán vào model
    );
  }
}

// ---------------------------------------------------------------------------
// CLASS ITINERARY ITEM
// ---------------------------------------------------------------------------
class ItineraryItem {
  final String day;
  final String title;
  final String details;
  final List<String> meals;

  ItineraryItem({
    required this.day,
    required this.title,
    required this.details,
    required this.meals,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      day: json['day']?.toString() ?? '',
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      meals: json['meals'] != null ? List<String>.from(json['meals']) : [],
    );
  }
}

// ---------------------------------------------------------------------------
// CLASS TRIP HIGHLIGHTS
// ---------------------------------------------------------------------------
class TripHighlights {
  final String attractions;
  final String cuisine;
  final String suitableFor;
  final String idealTime;
  final String promotion;

  TripHighlights({
    this.attractions = "",
    this.cuisine = "",
    this.suitableFor = "",
    this.idealTime = "",
    this.promotion = "",
  });

  factory TripHighlights.fromJson(Map<String, dynamic> json) {
    return TripHighlights(
      attractions: json['attractions'] ?? "Đa dạng",
      cuisine: json['cuisine'] ?? "Đặc sản địa phương",
      suitableFor: json['suitable_for'] ?? "Mọi lứa tuổi",
      idealTime: json['ideal_time'] ?? "Quanh năm",
      promotion: json['promotion'] ?? "",
    );
  }
}
