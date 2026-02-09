import 'package:flutter/material.dart';
import '../../booking/services/booking_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<dynamic> _bookings = [];
  bool _isLoadingBookings = false;

  List<dynamic> get bookings => _bookings;
  bool get isLoadingBookings => _isLoadingBookings;

  // Fetch data when Profile Screen loads
  Future<void> fetchMyBookings() async {
    _isLoadingBookings = true;
    notifyListeners();

    try {
      final data = await _bookingService.getMyBookings();
      // Sort by newest first (optional)
      _bookings = data;
    } catch (e) {
      print("Profile VM Error: $e");
      _bookings = [];
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  
}