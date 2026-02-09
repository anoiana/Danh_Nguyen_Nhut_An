import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../../booking/services/booking_service.dart'; // Import Booking Service

class PaymentViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService =
      BookingService(); // Reuse existing service

  bool _isLoading = true; // Start as true to fetch data
  bool _isProcessing = false; // For the payment button
  String _errorMessage = '';

  Map<String, dynamic>? _bookingDetails; // Store full booking object

  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get bookingDetails => _bookingDetails;

  // 1. [NEW] Fetch Booking Details (Matches React useEffect)
  Future<void> loadBookingDetails(String bookingId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _bookingService.getBookingDetails(bookingId);
      _bookingDetails = data;
    } catch (e) {
      _errorMessage = "Không thể tải thông tin đơn hàng: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Get Payment URL (Updated)
  Future<String?> getPaymentUrl() async {
    if (_bookingDetails == null) return null;

    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Logic matches React: Use final_price
      final amount = (_bookingDetails!['pricing']['final_price'] as num)
          .toDouble();
      final bookingId = _bookingDetails!['_id'];

      final url = await _paymentService.createVNPayUrl(
        amount: amount,
        bookingId: bookingId,
        bankCode: '', // Default to empty for gateway selection
      );

      _isProcessing = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmPaymentSuccess(String fullUrl) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Tách lấy phần query string sau dấu ?
      final uri = Uri.parse(fullUrl);
      final queryString = uri.query; // vnp_Amount=...&vnp_ResponseCode=00...

      final isSuccess = await _paymentService.verifyPayment(queryString);
      return isSuccess;
    } catch (e) {
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
