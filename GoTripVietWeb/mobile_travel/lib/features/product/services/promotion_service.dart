import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/promotion_model.dart';

class PromotionService {
  // Logic lấy URL giống HomeService để trỏ đúng port 3003
  String _getInventoryUrl() {
    String url = ApiConstants.baseUrl;
    if (url.contains(':3000')) return url.replaceAll(':3000', ':3003');
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return "$url:3003";
  }

  late final ApiClient _client;

  PromotionService() {
    _client = ApiClient(baseUrl: _getInventoryUrl());
  }

  // Lấy tất cả mã giảm giá
  Future<List<PromotionModel>> getAllPromotions() async {
    try {
      final response = await _client.dio.get('/promotions');
      final data = response.data is List ? response.data : response.data['data'] ?? [];
      
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching promotions: $e");
      return [];
    }
  }
}