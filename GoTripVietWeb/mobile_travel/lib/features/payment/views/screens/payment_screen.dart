import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../view_models/payment_view_model.dart';
import 'payment_webview.dart';
import '../../../home/views/screens/home_screen.dart';
import '../../../../core/utils/image_helper.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Payment Method Selection (Default: VNPAY)
  String _paymentMethod = 'vnpay';

  @override
  void initState() {
    super.initState();
    // Fetch fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentViewModel>(
        context,
        listen: false,
      ).loadBookingDetails(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PaymentViewModel>(context);
    final booking = viewModel.bookingDetails;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      backgroundColor: Colors.grey[100],

      // Handle Loading State
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
          ? Center(child: Text(viewModel.errorMessage))
          : _buildMainContent(context, viewModel, booking),

      // Bottom Payment Bar
      bottomNavigationBar: !viewModel.isLoading && booking != null
          ? _buildBottomBar(context, viewModel, booking)
          : null,
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    PaymentViewModel viewModel,
    Map<String, dynamic> booking,
  ) {
    // Helper Data Extraction
    final pricing = booking['pricing'] ?? {};
    final customer = booking['customer_details'] ?? {};
    final passengers = booking['passengers'] as List? ?? [];

    // Tour Snapshot Logic (Matches React)
    final mainItem = (booking['items'] as List).isNotEmpty
        ? booking['items'][0]
        : {};
    final tourTitle =
        mainItem['snapshot']?['title'] ?? mainItem['productTitle'] ?? "Tour";
    final tourImage = mainItem['snapshot']?['image'] ?? mainItem['image'];
    final createdDate = DateTime.parse(booking['createdAt']);
    final deadlineDate = createdDate.add(
      const Duration(hours: 24),
    ); // Example Deadline

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOUR SUMMARY CARD
          _buildTourSummary(tourTitle, tourImage, createdDate),
          const SizedBox(height: 16),

     
          // 3. CONTACT INFO
          _sectionHeader("Thông tin liên hệ"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Họ tên:", customer['fullName']),
                _infoRow("Email:", customer['email']),
                _infoRow("Điện thoại:", customer['phone']),
                if (customer['address'] != null)
                  _infoRow("Địa chỉ:", customer['address']),
                if (customer['note'] != null &&
                    customer['note'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Ghi chú: ${customer['note']}",
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. PASSENGER LIST (Accordion style)
          if (passengers.isNotEmpty) ...[
            _sectionHeader("Danh sách hành khách (${passengers.length})"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Xem chi tiết",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                children: passengers.map<Widget>((p) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(
                      p['fullName'] ?? "Khách",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${_getTypeLabel(p['type'])} • ${p['gender']} • ${p['dateOfBirth'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(p['dateOfBirth'])) : ''}",
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. PRICING BREAKDOWN
          _sectionHeader("Chi tiết thanh toán"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _priceRow(
                  "Trị giá booking",
                  pricing['total_price_before_discount'],
                ),
                if (pricing['discount_amount'] > 0)
                  _priceRow(
                    "Giảm giá",
                    -pricing['discount_amount'],
                    isDiscount: true,
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Thanh toán",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'vi',
                        symbol: '₫',
                      ).format(pricing['final_price']),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. PAYMENT METHOD
          _sectionHeader("Phương thức thanh toán"),
          GestureDetector(
            onTap: () => setState(() => _paymentMethod = 'vnpay'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paymentMethod == 'vnpay'
                    ? Colors.teal.withOpacity(0.05)
                    : Colors.white,
                border: Border.all(
                  color: _paymentMethod == 'vnpay'
                      ? Colors.teal
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Radio(
                    value: 'vnpay',
                    groupValue: _paymentMethod,
                    onChanged: (val) =>
                        setState(() => _paymentMethod = val.toString()),
                    activeColor: Colors.teal,
                  ),
                  Image.network(
                    "https://vnpay.vn/s1/statics.vnpay.vn/2023/6/0oxhzjmxbksr1686814746087.png",
                    width: 30,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "VNPAY-QR / Ví VNPAY / ATM",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    PaymentViewModel viewModel,
    Map<String, dynamic> booking,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: viewModel.isProcessing
              ? null
              : () async {
                  if (_paymentMethod != 'vnpay') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn VNPAY")),
                    );
                    return;
                  }

                  final url = await viewModel.getPaymentUrl();
                  if (url != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentWebView(
                          paymentUrl: url,
                          bookingId: widget.bookingId, // ✅ Pass ID here
                        ),
                      ),
                    );
                  }
                },
          child: viewModel.isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text(
                  "THANH TOÁN NGAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTourSummary(String title, String? imageUrl, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: ImageHelper.resolveUrl(imageUrl),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "---",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, num amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            NumberFormat.currency(locale: 'vi', symbol: '₫').format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDiscount ? Colors.green : Colors.black,
            ),
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

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hủy thanh toán?"),
        content: const Text(
          "Đơn hàng của bạn sẽ được giữ trong 24h. Bạn có chắc muốn quay lại trang chủ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ở lại"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text("Về trang chủ"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Thanh toán thành công!"),
          ],
        ),
        content: const Text(
          "Vé điện tử sẽ được gửi đến email của bạn. Cảm ơn bạn đã lựa chọn GoTripViet.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
            child: const Text("Hoàn tất"),
          ),
        ],
      ),
    );
  }
}
