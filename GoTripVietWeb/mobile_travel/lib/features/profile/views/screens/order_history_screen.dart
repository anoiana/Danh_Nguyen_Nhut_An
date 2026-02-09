import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// ViewModels & Utils
import '../../view_models/profile_view_model.dart';
import '../../../../core/utils/image_helper.dart';

// Screens
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách đơn hàng khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileViewModel>(context, listen: false).fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhẹ hiện đại
      appBar: AppBar(
        title: const Text(
          "Lịch sử chuyến đi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor:  const Color(0xFF00897B),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          // 1. Loading
          if (viewModel.isLoadingBookings) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B)),
            );
          }

          // 2. Empty State
          if (viewModel.bookings.isEmpty) {
            return _buildEmptyState();
          }

          // 3. List Data
          return RefreshIndicator(
            onRefresh: viewModel.fetchMyBookings,
            color: const Color(0xFF00897B),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: viewModel.bookings.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final booking = viewModel.bookings[index];
                return _buildModernOrderCard(context, booking);
              },
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET: EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chưa có đơn hàng nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hãy đặt chuyến đi đầu tiên của bạn ngay!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: MODERN ORDER CARD ---
  Widget _buildModernOrderCard(BuildContext context, dynamic booking) {
    // 1. Trích xuất dữ liệu
    final items = booking['items'] as List?;
    final firstItem = (items != null && items.isNotEmpty) ? items[0] : {};
    final snapshot = firstItem['snapshot'] ?? {};

    // Tiêu đề & Ảnh
    final String title =
        snapshot['title'] ?? firstItem['productTitle'] ?? "Tên tour";
    final String rawImage = snapshot['image'] ?? "";
    final String imageUrl = ImageHelper.resolveUrl(rawImage);

    // ID & Ngày
    final String bookingId = booking['_id'] ?? "";
    final String shortId = bookingId.length > 6
        ? bookingId.substring(bookingId.length - 6).toUpperCase()
        : bookingId;

    String bookingDate = "";
    if (booking['createdAt'] != null) {
      bookingDate = DateFormat(
        'HH:mm dd/MM/yyyy',
      ).format(DateTime.parse(booking['createdAt']));
    }

    // Giá
    final num finalPrice = booking['pricing']?['final_price'] ?? 0;

    // Trạng thái
    final String status = booking['status'] ?? "pending";
    final String paymentStatus = booking['payment_status'] ?? "unpaid";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(bookingId: bookingId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // A. HEADER: Ngày & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookingDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),

                // B. BODY: Ảnh & Thông tin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh bo góc
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tên & ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Mã: $shortId",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // C. FOOTER: Giá tiền & Nút Payment Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tổng thanh toán",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi',
                            symbol: 'đ',
                          ).format(finalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ],
                    ),

                    // Payment Status Badge
                    _buildPaymentStatus(paymentStatus),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER: STATUS CHIP ---
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[800]!;
        text = "Chờ xử lý";
        break;
      case 'confirmed':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[800]!;
        text = "Đã xác nhận";
        break;
      case 'completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[800]!;
        text = "Hoàn thành";
        break;
      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[800]!;
        text = "Đã hủy";
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[800]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- HELPER: PAYMENT STATUS ---
  Widget _buildPaymentStatus(String status) {
    bool isPaid = status == 'paid';
    return Row(
      children: [
        Icon(
          isPaid ? Icons.check_circle : Icons.info_outline,
          size: 14,
          color: isPaid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          isPaid ? "Đã thanh toán" : "Chưa thanh toán",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPaid ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
