import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../booking/services/booking_service.dart';
import '../../../payment/views/screens/payment_screen.dart'; // Import màn hình thanh toán

class OrderDetailScreen extends StatefulWidget {
  final String bookingId;

  const OrderDetailScreen({Key? key, required this.bookingId})
    : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final BookingService _bookingService = BookingService();

  bool _isLoading = true;
  bool _isCancelling = false; // Trạng thái đang xử lý hủy
  Map<String, dynamic>? _booking;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetail();
  }

  // 1. Lấy dữ liệu chi tiết đơn hàng
  Future<void> _fetchBookingDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _bookingService.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Không thể tải thông tin đơn hàng.";
          _isLoading = false;
        });
      }
    }
  }

  // 2. Xử lý Hủy đơn hàng (Giống logic Web)
  Future<void> _handleCancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy đơn hàng?"),
        content: const Text(
          "Bạn có chắc chắn muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.\n\nTiền sẽ được hoàn lại theo chính sách của chúng tôi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Không"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Hủy đơn",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      try {
        await _bookingService.cancelBooking(widget.bookingId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã hủy đơn hàng thành công")),
        );
        _fetchBookingDetail(); // Tải lại dữ liệu để cập nhật trạng thái mới
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00897B)),
        ),
      );
    if (_errorMessage != null)
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết")),
        body: Center(child: Text(_errorMessage!)),
      );
    if (_booking == null) return const Scaffold();
    final String? rawDate = _booking!['start_date'] ?? "N/A";
    // --- PARSE DỮ LIỆU TỪ API ---
    final status = _booking!['status'] ?? 'pending';
    final paymentStatus = _booking!['payment_status'] ?? 'unpaid';

    // Lấy thông tin Tour (Item đầu tiên)
    final items = _booking!['items'] as List? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : {};
    final snapshot = firstItem['snapshot'] ?? {}; // Snapshot lưu lúc đặt

    // Lấy thông tin khác
    final contact =
        _booking!['customer_details'] ?? _booking!['contact_info'] ?? {};
    final pricing = _booking!['pricing'] ?? {};
    final passengers = _booking!['passengers'] as List? ?? [];
    final payments =
        _booking!['payments'] as List? ?? []; // [MỚI] Lịch sử giao dịch
    final String? note = contact['note'];

    // Pricing
    final num totalPrice = pricing['total_price_before_discount'] ?? 0;
    final num discount = pricing['discount_amount'] ?? 0;
    final num finalPrice = pricing['final_price'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          // Nút Refresh thủ công
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchBookingDetail,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookingDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER + STEPPER (ĐỒNG BỘ WEB) ---
              _buildOrderHeader(widget.bookingId, status, paymentStatus),
              const SizedBox(height: 20),

              // --- 2. THÔNG TIN TOUR ---
              _buildSectionTitle("Thông tin chuyến đi"),
              _buildProductCard(snapshot, firstItem, rawDate), 
              const SizedBox(height: 20),

              // --- 3. LIÊN HỆ & GHI CHÚ ---
              _buildSectionTitle("Thông tin liên hệ"),
              _buildContactCard(contact, note),
              const SizedBox(height: 20),

              // --- 4. DANH SÁCH KHÁCH ---
              if (passengers.isNotEmpty) ...[
                _buildSectionTitle(
                  "Danh sách hành khách (${passengers.length})",
                ),
                _buildPassengersList(passengers),
                const SizedBox(height: 20),
              ],

              // --- 5. LỊCH SỬ GIAO DỊCH (TÍNH NĂNG MỚI) ---
              if (payments.isNotEmpty) ...[
                _buildSectionTitle("Lịch sử giao dịch"),
                _buildTransactionHistory(payments),
                const SizedBox(height: 20),
              ],

              // --- 6. CHI PHÍ ---
              _buildSectionTitle("Chi phí"),
              _buildPricingCard(
                totalPrice,
                discount,
                finalPrice,
                paymentStatus,
              ),
              const SizedBox(height: 30),

              // --- 7. NÚT HÀNH ĐỘNG ---
              _buildActionButtons(status, paymentStatus),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  // 1. HEADER & STEPPER (Tiến trình đơn hàng)
  Widget _buildOrderHeader(
    String bookingId,
    String status,
    String paymentStatus,
  ) {
    // Logic xác định bước hiện tại
    int currentStep = 1; // Mặc định: Đặt đơn
    if (paymentStatus == 'paid') currentStep = 2; // Đã thanh toán
    if (status == 'completed') currentStep = 3; // Hoàn thành tour

    // Nếu đơn bị hủy: Hiện thông báo đỏ
    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              "ĐƠN HÀNG ĐÃ BỊ HỦY",
              style: TextStyle(
                color: Colors.red[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Mã đơn: ${bookingId.substring(bookingId.length - 6).toUpperCase()}",
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
      );
    }

    // Nếu bình thường: Hiện Stepper
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mã đơn hàng", style: TextStyle(color: Colors.grey[600])),
              Text(
                bookingId.substring(bookingId.length - 6).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stepper UI
          Row(
            children: [
              _buildStepItem("Đặt đơn", true, true),
              _buildStepLine(currentStep >= 2),
              _buildStepItem("Thanh toán", currentStep >= 2, currentStep >= 2),
              _buildStepLine(currentStep >= 3),
              _buildStepItem("Hoàn thành", currentStep >= 3, currentStep >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00897B) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF00897B) : Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        transform: Matrix4.translationValues(
          0,
          -10,
          0,
        ), // Căn chỉnh line giữa icon
      ),
    );
  }

  // 2. CARD SẢN PHẨM
  Widget _buildProductCard(Map snapshot, Map item, String? rawDate) {
    String imageUrl = ImageHelper.resolveUrl(snapshot['image'] ?? item['image']);
    String title = snapshot['title'] ?? item['productTitle'] ?? "Tên tour";
    String dateStr = "Chưa cập nhật";
    
    // Logic Parse ngày mạnh mẽ hơn
    if (rawDate != null) {
      try {
        // Parse chuỗi ISO 8601 (VD: 2026-01-20T00:00:00.000Z)
        final DateTime parsedDate = DateTime.parse(rawDate).toLocal();
        dateStr = DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        print("Lỗi parse ngày: $e");
        dateStr = rawDate; // Nếu lỗi thì hiện nguyên chuỗi gốc
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl, 
              height: 80, 
              width: 80, 
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      "Khởi hành: $dateStr", 
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
                 const SizedBox(height: 6),
                 if (item['quantity'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "${item['quantity']} hành khách", 
                      style: TextStyle(fontSize: 12, color: Colors.teal[800], fontWeight: FontWeight.bold)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // 3. THÔNG TIN LIÊN HỆ & GHI CHÚ
  Widget _buildContactCard(Map contact, String? note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.person,
            "Họ tên",
            contact['fullName'] ?? contact['full_name'] ?? "---",
          ),
          _buildInfoRow(
            Icons.phone,
            "Điện thoại",
            contact['phone'] ?? contact['phone_number'] ?? "---",
          ),
          _buildInfoRow(Icons.email, "Email", contact['email'] ?? "---"),
          _buildInfoRow(
            Icons.location_on,
            "Địa chỉ",
            contact['address'] ?? "---",
          ),

          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ghi chú:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          note,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. DANH SÁCH HÀNH KHÁCH
  Widget _buildPassengersList(List passengers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: passengers.asMap().entries.map((entry) {
          final p = entry.value;
          final idx = entry.key;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  radius: 14,
                  child: Text(
                    "${idx + 1}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  p['fullName'] ?? "Khách ${idx + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "${_getTypeLabel(p['type'])} • ${p['gender'] ?? 'Chưa rõ'}",
                ),
              ),
              if (idx < passengers.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 5. LỊCH SỬ GIAO DỊCH (QUAN TRỌNG ĐỂ CHECK "UNPAID")
  Widget _buildTransactionHistory(List payments) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: payments.map((pay) {
          final isSuccess = pay['status'] == 'succeeded';
          final amount = pay['amount'] ?? 0;
          final date = pay['timestamp'] != null
              ? DateFormat(
                  'HH:mm dd/MM/yyyy',
                ).format(DateTime.parse(pay['timestamp']))
              : "---";

          return ListTile(
            leading: Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            title: Text(
              _formatPaymentGateway(pay['gateway']),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "+${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(amount)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  isSuccess ? "Thành công" : "Thất bại",
                  style: TextStyle(
                    fontSize: 10,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 6. TỔNG TIỀN
  Widget _buildPricingCard(
    num total,
    num discount,
    num finalPrice,
    String paymentStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow("Tạm tính", total),
          if (discount > 0)
            _buildPriceRow("Giảm giá", -discount, color: Colors.green),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tổng cộng",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'vi',
                  symbol: 'đ',
                ).format(finalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF00897B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: paymentStatus == 'paid'
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: paymentStatus == 'paid'
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                paymentStatus == 'paid' ? "ĐÃ THANH TOÁN" : "CHƯA THANH TOÁN",
                style: TextStyle(
                  color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. NÚT HÀNH ĐỘNG (THANH TOÁN / HỦY)
  Widget _buildActionButtons(String status, String paymentStatus) {
    return Column(
      children: [
        // Nút Thanh toán (Nếu chưa trả tiền và đơn chưa hủy)
        if (paymentStatus == 'unpaid' && status != 'cancelled')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(bookingId: widget.bookingId),
                  ),
                ).then((_) {
                  // Khi quay lại từ màn hình thanh toán, reload lại dữ liệu
                  _fetchBookingDetail();
                });
              },
              child: const Text(
                "THANH TOÁN NGAY",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Nút Hủy (Chỉ hiện khi đơn đang pending hoặc confirmed)
        if (status == 'pending' || status == 'confirmed')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCancelling
                  ? null
                  : _handleCancelBooking, // Disable khi đang gọi API
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Hủy đơn hàng",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    num amount, {
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            NumberFormat.currency(locale: 'vi', symbol: 'đ').format(amount),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'adult':
        return 'Người lớn';
      case 'child':
        return 'Trẻ em';
      case 'toddler':
        return 'Trẻ nhỏ';
      case 'infant':
        return 'Em bé';
      default:
        return 'Khách';
    }
  }

  String _formatPaymentGateway(String? gateway) {
    switch (gateway?.toLowerCase()) {
      case 'vnpay':
        return "VNPAY QR";
      case 'momo':
        return "Ví MoMo";
      case 'stripe':
        return "Thẻ Visa/Master";
      default:
        return gateway?.toUpperCase() ?? "Thanh toán";
    }
  }
}
