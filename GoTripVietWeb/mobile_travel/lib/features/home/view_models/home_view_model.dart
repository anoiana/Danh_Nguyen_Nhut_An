import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart'; // Import Model Sự kiện
import '../services/home_service.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeService _homeService = HomeService();

  // Các biến dữ liệu
  List<ProductModel> _tours = [];
  List<dynamic> _locations = [];
  List<dynamic> _categories = [];
  List<EventModel> _events = []; // [MỚI] Danh sách sự kiện

  bool _isLoading = false;

  // Getters
  List<ProductModel> get tours => _tours;
  List<dynamic> get locations => _locations;
  List<dynamic> get categories => _categories;
  List<EventModel> get events => _events; // [MỚI] Getter cho sự kiện
  bool get isLoading => _isLoading;

  // Hàm tải toàn bộ dữ liệu Home
  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Gọi song song tất cả API để tiết kiệm thời gian
      final results = await Future.wait([
        _homeService.fetchNewestTours(),
        _homeService.fetchLocations(),
        _homeService.fetchCategories(),
        _homeService.fetchEvents(), // [MỚI] Gọi API Events
      ]);

      // Gán kết quả vào biến
      _tours = results[0] as List<ProductModel>;
      _locations = results[1] as List<dynamic>;
      _categories = results[2] as List<dynamic>;
      _events = results[3] as List<EventModel>; // [MỚI] Gán dữ liệu Events
    } catch (e) {
      print("Error loading home data: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Cập nhật UI
    }
  }
}
