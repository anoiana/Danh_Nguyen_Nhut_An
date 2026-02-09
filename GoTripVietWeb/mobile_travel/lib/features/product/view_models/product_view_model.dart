import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';
import '../../../core/network/api_client.dart'; // Để gọi API lấy related
import '../../../core/constants/api_constants.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final ApiClient _catalogClient = ApiClient(baseUrl: ApiConstants.catalogUrl);

  ProductModel? _product;
  List<dynamic> _inventoryItems = [];
  dynamic _selectedInventory; 
  List<ProductModel> _relatedTours = []; // [MỚI] Danh sách tour liên quan

  bool _isLoading = true;
  String _error = '';

  ProductModel? get product => _product;
  List<dynamic> get inventoryItems => _inventoryItems;
  dynamic get selectedInventory => _selectedInventory;
  List<ProductModel> get relatedTours => _relatedTours;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Lấy chi tiết Product + Inventory + Related
  Future<void> loadProductDetails(String id) async {
    _isLoading = true;
    _error = '';
    _product = null;
    _inventoryItems = [];
    _relatedTours = [];
    notifyListeners();

    try {
      // 1. Gọi song song chi tiết & lịch
      final results = await Future.wait([
        _productService.getProductDetail(id),
        _inventoryService.getInventoryByProductId(id),
      ]);

      // 2. Parse Product
      final productData = results[0] as Map<String, dynamic>;
      _product = ProductModel.fromJson(productData);
      
      // 3. Parse Inventory & Sort
      var rawInventory = results[1] as List<dynamic>;
      // Lọc những ngày còn active
      rawInventory = rawInventory.where((i) => i['is_active'] == true).toList();
      
      // Sắp xếp ngày tăng dần
      rawInventory.sort((a, b) => 
        DateTime.parse(a['tour_details']['date']).compareTo(DateTime.parse(b['tour_details']['date']))
      );
      _inventoryItems = rawInventory;

      // Mặc định chọn ngày đầu tiên có chỗ
      if (_inventoryItems.isNotEmpty) {
        // Tìm ngày đầu tiên còn chỗ (total - booked > 0)
        final availableItem = _inventoryItems.firstWhere(
          (i) => (i['tour_details']['total_slots'] - i['tour_details']['booked_slots']) > 0,
          orElse: () => _inventoryItems[0]
        );
        _selectedInventory = availableItem;
      }

      // 4. [MỚI] Load Related Tours (Dựa vào category_id đầu tiên)
      if (productData['category_ids'] != null && (productData['category_ids'] as List).isNotEmpty) {
        final catId = productData['category_ids'][0]; 
        final String categoryId = (catId is Map) ? catId['_id'] : catId;
        
        await _fetchRelatedTours(categoryId, id);
      }

    } catch (e) {
      _error = e.toString();
      print("Detail Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logic gọi API lấy tour liên quan
  Future<void> _fetchRelatedTours(String categoryId, String currentProductId) async {
    try {
      final response = await _catalogClient.dio.get('/products', queryParameters: {
        'category_id': categoryId,
        'product_type': 'tour',
        'limit': 5
      });
      
      final list = response.data['products'] ?? response.data['data']['products'] ?? [];
      
      _relatedTours = (list as List)
          .where((p) => p['_id'] != currentProductId) // Loại trừ tour hiện tại
          .take(4) // Lấy tối đa 4 tour
          .map((e) => ProductModel.fromJson(e))
          .toList();
          
    } catch (e) {
      print("Related Tours Error: $e");
    }
  }

  void selectDate(dynamic inventoryItem) {
    _selectedInventory = inventoryItem;
    notifyListeners();
  }
}