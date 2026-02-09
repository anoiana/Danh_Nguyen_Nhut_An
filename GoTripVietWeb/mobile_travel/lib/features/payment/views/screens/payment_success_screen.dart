import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/booking/services/booking_service.dart';
import 'package:mobile/features/profile/views/screens/order_detail_screen.dart';
import '../../../home/views/screens/home_screen.dart';
import '../../../../core/utils/image_helper.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String bookingId;

  const PaymentSuccessScreen({Key? key, required this.bookingId})
    : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final BookingService _bookingService = BookingService();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingInfo();
  }

  // Gọi API lấy thông tin đơn hàng để hiển thị "Hóa đơn"
  Future<void> _fetchBookingInfo() async {
    try {
      final data = await _bookingService.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Nếu lỗi thì vẫn hiện màn hình success nhưng không có chi tiết
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi lấy thông tin booking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse Data
    final items = _bookingData?['items'] as List? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : {};
    final snapshot = firstItem['snapshot'] ?? {};
    final pricing = _bookingData?['pricing'] ?? {};

    // Tour Info
    final String tourTitle =
        snapshot['title'] ??
        firstItem['productTitle'] ??
        "Đang tải tên tour...";
    final String imageUrl = ImageHelper.resolveUrl(
      snapshot['image'] ?? firstItem['image'],
    );
    final num finalPrice = pricing['final_price'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // 1. Success Icon & Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ĐẶT TOUR THÀNH CÔNG!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mã đơn: ${widget.bookingId.substring(widget.bookingId.length - 6).toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Cảm ơn quý khách đã tin tưởng GoTripViet.\nVé điện tử đã được gửi đến email.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 32),

                  // 2. Tour Summary Card (Giống Web)
                  if (_bookingData != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: Colors.grey[200]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tourTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${firstItem['quantity'] ?? 1} Khách",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng thanh toán",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'vi',
                                  symbol: 'đ',
                                ).format(finalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Phương thức",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.qr_code,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "VNPAY",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // 3. Action Buttons (2 Nút giống Web)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset về Home
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Về trang chủ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Chuyển sang xem chi tiết đơn hàng
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  bookingId: widget.bookingId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Xem đơn hàng",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
