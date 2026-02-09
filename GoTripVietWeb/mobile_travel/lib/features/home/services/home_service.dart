import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart'; // Đảm bảo đã import EventModel
import '../../product/services/inventory_service.dart';

class HomeService {
  final ApiClient _catalogClient = ApiClient(baseUrl: ApiConstants.catalogUrl);

  // Kết nối tới Inventory Service (Port 3003) cho Events
  final ApiClient _inventoryClient = ApiClient(
    baseUrl: "${ApiConstants.baseUrl}:3003",
  );

  final InventoryService _inventoryService = InventoryService();

  // 1. Fetch Newest Tours (Giữ nguyên logic cũ)
  Future<List<ProductModel>> fetchNewestTours() async {
    try {
      final response = await _catalogClient.dio.get(
        '/products',
        queryParameters: {
          'product_type': 'tour',
          'limit': 6,
          'sort': '-createdAt',
        },
      );

      final rawList =
          response.data['products'] ?? response.data['data']['products'] ?? [];
      List<ProductModel> smartList = [];

      // Logic lọc ngày khởi hành (giữ nguyên)
      for (var item in rawList) {
        List<String> validDates = [];
        try {
          final invList = await _inventoryService.getInventoryByProductId(
            item['_id'],
          );
          for (var inv in invList) {
            if (inv['tour_details'] != null &&
                inv['tour_details']['date'] != null) {
              bool isActive = inv['is_active'] ?? true;
              int total = inv['tour_details']['total_slots'] ?? 0;
              int booked = inv['tour_details']['booked_slots'] ?? 0;
              String dateStr = inv['tour_details']['date'];

              if (isActive && (total - booked) > 0) {
                validDates.add(dateStr);
              }
            }
          }
          validDates.sort(
            (a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)),
          );
        } catch (e) {
          print("⚠️ Lỗi lấy lịch: $e");
        }
        item['departure_dates'] = validDates;
        smartList.add(ProductModel.fromJson(item));
      }
      return smartList;
    } catch (e) {
      return [];
    }
  }

  // 2. [MỚI] Fetch Active Events
  Future<List<EventModel>> fetchEvents() async {
    try {
      // Gọi endpoint lấy sự kiện đang diễn ra
      final response = await _inventoryClient.dio.get('/events/active');

      final data = response.data is List
          ? response.data
          : response.data['data'] ?? [];

      // Parse JSON thành List<EventModel>
      return (data as List).map((e) => EventModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ Error fetching events: $e");
      return [];
    }
  }

  // 3. Locations (Giữ nguyên)
  Future<List<dynamic>> fetchLocations() async {
    try {
      final response = await _catalogClient.dio.get('/locations');
      return response.data is List
          ? response.data
          : response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // 4. Categories (Giữ nguyên)
  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await _catalogClient.dio.get('/categories');
      return response.data is List
          ? response.data
          : response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
