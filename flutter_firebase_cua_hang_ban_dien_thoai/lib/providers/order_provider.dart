import 'package:flutter/foundation.dart';

import '../models/order_status.dart' as models;
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<models.Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<models.Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách đơn hàng của user
  Future<void> fetchUserOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orderService
          .getUserOrders(userId)
          .listen(
            (orders) {
              _orders = orders;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _error = error.toString();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy chi tiết đơn hàng
  Future<models.Order?> getOrderDetails(String orderId) async {
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      // Không cần fetch lại vì đã có stream listener
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Hủy đơn hàng
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _orderService.cancelOrder(orderId, reason: reason);
      // Không cần fetch lại vì đã có stream listener
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
