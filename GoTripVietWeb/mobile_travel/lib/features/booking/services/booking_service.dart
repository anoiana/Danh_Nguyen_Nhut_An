import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class BookingService {
  // Kết nối tới Booking Service (Port 3004)
  final ApiClient _client = ApiClient(baseUrl: "${ApiConstants.baseUrl}:3004");

  // 1. Tạo đơn hàng mới
  // Tương ứng: bookingApi.createBooking(data)
  Future<dynamic> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _client.dio.post('/bookings', data: bookingData);
      return response.data; // Trả về object Booking vừa tạo
    } on DioException catch (e) {
      // Ném lỗi chi tiết để ViewModel hiển thị cho user
      throw Exception(e.response?.data['message'] ?? 'Đặt tour thất bại');
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      await _client.dio.post('/bookings/$id/cancel');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getMyBookings() async {
    try {
      final response = await _client.dio.get('/bookings/my-bookings');
      
      // Handle different response formats (Array vs Object with data key)
      if (response.data is List) {
        return response.data;
      } else if (response.data['data'] != null) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching bookings: $e");
      return [];
    }
  }

  // ✅ 3. MATCH WEB: GET /bookings/:id
  Future<dynamic> getBookingDetails(String id) async {
    try {
      final response = await _client.dio.get('/bookings/$id');
      return response.data['data'] ?? response.data;
    } catch (e) {
      rethrow;
    }
  }
}