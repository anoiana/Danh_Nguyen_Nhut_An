import 'package:flutter/material.dart';
import 'package:mobile/features/product/services/promotion_service.dart';
import 'package:mobile/shared/models/promotion_model.dart';
import '../services/booking_service.dart';
import '../../product/services/inventory_service.dart';

// Helper class for Passenger Details
class PassengerInfo {
  String fullName = '';
  String gender = 'Nam';
  String type; // adult, child, toddler, infant
  DateTime? dob;

  PassengerInfo({required this.type});
}

class BookingViewModel extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final InventoryService _inventoryService = InventoryService();
  final PromotionService _promotionService = PromotionService();
  bool _isLoading = false;
  String _errorMessage = '';

  // Passenger Counts
  int _adults = 1;
  int _children = 0;
  int _toddlers = 0; // 2-4 years
  int _infants = 0; // < 2 years

  // Passenger Detail List
  List<PassengerInfo> _passengers = [PassengerInfo(type: 'adult')];
  List<PromotionModel> _availablePromos = [];
  List<PromotionModel> get availablePromos => _availablePromos;
  // Promo Code
  String _promoCode = '';
  Map<String, dynamic>? _appliedPromo;
  String _promoError = '';

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get adults => _adults;
  int get children => _children;
  int get toddlers => _toddlers;
  int get infants => _infants;
  List<PassengerInfo> get passengers => _passengers;
  Map<String, dynamic>? get appliedPromo => _appliedPromo;
  String get promoError => _promoError;

  // --- 1. HANDLE COUNTS & PASSENGER LIST ---
  void updateCount(String type, int delta) {
    if (type == 'adult') {
      if (_adults + delta < 1) return;
      _adults += delta;
    } else if (type == 'child') {
      if (_children + delta < 0) return;
      _children += delta;
    } else if (type == 'toddler') {
      if (_toddlers + delta < 0) return;
      _toddlers += delta;
    } else if (type == 'infant') {
      if (_infants + delta < 0) return;
      _infants += delta;
    }

    _regeneratePassengerList();
    notifyListeners();
  }

  // Rebuild the list of forms (Keep existing data if possible)
  void _regeneratePassengerList() {
    List<PassengerInfo> newList = [];

    void addType(int count, String type) {
      for (int i = 0; i < count; i++) {
        // Try to find existing data to preserve user input
        var existing = _passengers.where((p) => p.type == type).toList();
        if (i < existing.length) {
          newList.add(existing[i]);
        } else {
          newList.add(PassengerInfo(type: type));
        }
      }
    }

    addType(_adults, 'adult');
    addType(_children, 'child');
    addType(_toddlers, 'toddler');
    addType(_infants, 'infant');

    _passengers = newList;
  }

  void updatePassengerInfo(
    int index, {
    String? name,
    String? gender,
    DateTime? dob,
  }) {
    if (name != null) _passengers[index].fullName = name;
    if (gender != null) _passengers[index].gender = gender;
    if (dob != null) _passengers[index].dob = dob;
    notifyListeners();
  }

  // --- 2. PROMO CODE LOGIC ---
  Future<bool> applyPromoCode(String code, double currentSubTotal) async {
    _isLoading = true;
    _promoError = '';
    notifyListeners();

    try {
      final result = await _inventoryService.checkPromotion(code);
      if (result == null) {
        _appliedPromo = null;
        _promoError = 'Mã giảm giá không hợp lệ';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final minSpend = result['rules']?['min_spend'] ?? 0;
      if (currentSubTotal < minSpend) {
        _appliedPromo = null;
        _promoError = 'Đơn hàng chưa đủ điều kiện (Tối thiểu $minSpend)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _appliedPromo = result;
      _promoError = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _appliedPromo = null;
      _promoError = 'Lỗi kiểm tra mã: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void removePromo() {
    _appliedPromo = null;
    _promoError = '';
    notifyListeners();
  }

  // --- 3. PRICE CALCULATION ---
  Map<String, double> calculatePrice(double basePrice) {
    double subTotal = 0;
    subTotal += _adults * basePrice;
    subTotal += _children * (basePrice * 0.8);
    subTotal += _toddlers * (basePrice * 0.5);
    subTotal += _infants * (basePrice * 0.1);

    double discount = 0;
    if (_appliedPromo != null) {
      if (_appliedPromo!['type'] == 'percentage') {
        discount = subTotal * ((_appliedPromo!['value'] ?? 0) / 100);
      } else {
        discount = (_appliedPromo!['value'] ?? 0).toDouble();
      }
      if (discount > subTotal) discount = subTotal;
    }

    return {
      'subTotal': subTotal,
      'discount': discount,
      'final': subTotal - discount,
    };
  }

  // --- 4. SUBMIT ---
  Future<dynamic> submitBooking({
    required String productId,
    required String productTitle,
    required String productImage,
    required dynamic inventoryItem,
    required String userId,
    required Map<String, dynamic> contactInfo,
    required double basePrice,
    required Map<String, double> priceData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> passengerPayload = _passengers
          .map(
            (p) => {
              'fullName': p.fullName,
              'gender': p.gender,
              'type': p.type,
              'dateOfBirth': p.dob?.toIso8601String(),
            },
          )
          .toList();

      List<Map<String, dynamic>> items = [
        {
          "productId": productId,
          "inventoryId": inventoryItem['_id'],
          "productType": "tour",
          "quantity": _adults + _children + _toddlers + _infants,
          "unitPrice": basePrice,
          "productTitle": productTitle,
          "image": productImage,
          "currency": "VND",
          "detailsText": "Ngày đi: ${inventoryItem['tour_details']['date']}",
        },
      ];

      final bookingData = {
        'product': productId,
        'inventory_id': inventoryItem['_id'],
        'items': items,
        'promotionCode': _appliedPromo != null ? _appliedPromo!['code'] : null,
        'passengers': passengerPayload,
        'contactInfo': contactInfo,
        'total_price': priceData['final'],
        'user': userId,
        'status': 'pending',
        'payment_status': 'unpaid',
      };

      print("📦 Payload gửi đi: $bookingData");

      final result = await _bookingService.createBooking(bookingData);

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print("❌ Lỗi Booking: $e");
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchPromotions() async {
    try {
      final allPromos = await _promotionService.getAllPromotions();
      final now = DateTime.now();

      // Lọc mã: Đang active + Còn hạn + Còn lượt dùng
      _availablePromos = allPromos.filter((p) {
        final isValidDate =
            (p.startDate == null || p.startDate!.isBefore(now)) &&
            (p.endDate == null || p.endDate!.isAfter(now));
        final hasQuantity = (p.totalQuantity - p.usedQuantity) > 0;

        return p.isActive && isValidDate && hasQuantity;
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Lỗi load promo VM: $e");
    }
  }

  void selectPromoFromList(PromotionModel promo, double currentSubTotal) {
    if (currentSubTotal < promo.minSpend) {
      // Logic xử lý UI sẽ check điều kiện này, ở đây ta chỉ set nếu hợp lệ hoặc báo lỗi
      return;
    }

    // Convert PromotionModel sang Map để dùng lại logic cũ (vì _appliedPromo đang là Map)
    // Hoặc tốt hơn là sửa _appliedPromo thành PromotionModel, nhưng để nhanh ta convert tạm:
    _appliedPromo = {
      'code': promo.code,
      'type': promo.type,
      'value': promo.value,
      'rules': {'min_spend': promo.minSpend, 'max_discount': promo.maxDiscount},
    };
    _promoCode = promo.code; // Update text field
    _promoError = '';
    notifyListeners();
  }
}

extension FilterList<E> on List<E> {
  List<E> filter(bool Function(E) test) => where(test).toList();
}
