import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class PaymentService {
  // Kết nối tới Payment Service (Port 3005)
  final ApiClient _client = ApiClient(baseUrl: "${ApiConstants.baseUrl}:3005");

  // Tạo URL thanh toán VNPAY
  // Tương ứng: paymentApi.createVNPayUrl({...})
  Future<String?> createVNPayUrl({
    required double amount,
    required String bookingId,
    String bankCode = '',
  }) async {
    try {
      final response = await _client.dio.post('/payment/create-vnpay-url', data: {
        'amount': amount,
        'bookingId': bookingId,
        'bankCode': bankCode,
        'language': 'vn',
      });

      // Backend trả về: { paymentUrl: "https://sandbox.vnpayment.vn/..." }
      return response.data['paymentUrl'];
    } catch (e) {
      print("Lỗi tạo link thanh toán: $e");
      throw Exception('Không thể khởi tạo thanh toán');
    }
  }

  Future<bool> verifyPayment(String queryString) async {
    try {
      // Backend API: GET /payment/vnpay-return?vnp_Amount=...&vnp_ResponseCode=...
      // Bạn cần truyền nguyên chuỗi query params mà VNPAY trả về
      final response = await _client.dio.get('/payment/vnpay-return?$queryString');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Verify Payment Error: $e");
      return false;
    }
  }
}