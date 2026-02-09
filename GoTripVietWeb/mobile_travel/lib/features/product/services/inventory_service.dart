import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class InventoryService {
  // Kết nối tới Inventory Service (Port 3003)
  final ApiClient _client = ApiClient(baseUrl: "${ApiConstants.baseUrl}:3003");

  // Lấy lịch khởi hành theo ID sản phẩm
  // Tương ứng: inventoryApi.getInventoryByProductId(id)
  // Fetch all inventory slots for a specific product
  Future<List<dynamic>> getInventoryByProductId(String productId) async {
    try {
      // Endpoint matches your backend: /inventory/product/:id
      final response = await _client.dio.get('/inventory/product/$productId');
      
      // Handle different response structures (Array vs Object)
      if (response.data is List) {
        return response.data;
      } else if (response.data['data'] != null) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print("Inventory Error for $productId: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>?> checkPromotion(String code) async {
    try {
      final response = await _client.dio.get('/promotions/code/$code'); // Adjust endpoint if needed
      return response.data;
    } catch (e) {
      // Return null if code is invalid
      return null; 
    }
  }
}