import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../view_models/booking_view_model.dart';
import '../../../auth/view_models/auth_view_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../payment/views/screens/payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final ProductModel product;
  final dynamic selectedInventory;

  const BookingScreen({
    Key? key,
    required this.product,
    required this.selectedInventory,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho Liên hệ
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthViewModel>(context, listen: false).user;
    if (user != null) {
      _nameController.text =
          user.fullName ?? ""; // Nên thêm ?? "" cho cả tên để an toàn
      _emailController.text = user.email ?? ""; // Nên thêm ?? "" cho cả email
      _phoneController.text = user.phone ?? ""; // ✅ Đã sửa lỗi
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // --- HELPERS ---
  String formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi', symbol: '₫').format(amount);
  }

  Future<void> _selectDate(
    BuildContext context,
    int index,
    BookingViewModel vm,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 20),
      ), // Mặc định 20 tuổi
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00897B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      vm.updatePassengerInfo(index, dob: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<BookingViewModel>(context);
    final user = Provider.of<AuthViewModel>(context).user;

    // Tính giá
    final double basePrice =
        (widget.selectedInventory['price'] ?? widget.product.price).toDouble();
    final priceData = viewModel.calculatePrice(basePrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Đặt Tour",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TÓM TẮT TOUR
              _buildSummaryCard(),
              const SizedBox(height: 20),

              // 2. THÔNG TIN LIÊN HỆ
              _buildSectionHeader("Thông tin liên hệ"),
              _buildContactForm(user == null),
              const SizedBox(height: 20),

              // 3. SỐ LƯỢNG KHÁCH
              _buildSectionHeader("Số lượng hành khách"),
              _buildPassengerCounts(viewModel, basePrice),
              const SizedBox(height: 20),

              // 4. THÔNG TIN HÀNH KHÁCH CHI TIẾT
              _buildSectionHeader("Thông tin hành khách"),
              _buildPassengerDetailsForm(viewModel),
              const SizedBox(height: 20),

              // 5. MÃ GIẢM GIÁ
              _buildSectionHeader("Ưu đãi"),
              _buildPromoSection(viewModel, priceData['subTotal']!),

              const SizedBox(height: 100), // Padding cho Bottom Bar
            ],
          ),
        ),
      ),

      // BOTTOM BAR THANH TOÁN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tổng thanh toán",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  formatCurrency(priceData['final']!),
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (priceData['discount']! > 0)
                  Text(
                    "Đã giảm: ${formatCurrency(priceData['discount']!)}",
                    style: const TextStyle(color: Colors.green, fontSize: 11),
                  ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => _handleSubmit(
                      viewModel,
                      user?.id ?? '',
                      basePrice,
                      priceData,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "THANH TOÁN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBMIT LOGIC ---
  // --- SUBMIT LOGIC (Đã cập nhật đầy đủ field giống Web) ---
  Future<void> _handleSubmit(
    BookingViewModel vm,
    String userId,
    double basePrice,
    Map<String, double> priceData,
  ) async {
    // 1. Validate các ô nhập liệu cơ bản (Tên, Email, SĐT...)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ thông tin bắt buộc"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validate Ngày sinh hành khách (Bắt buộc giống Web)
    for (var p in vm.passengers) {
      if (p.dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng chọn ngày sinh cho tất cả hành khách"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // 3. Lấy ảnh đầu tiên của Tour để gửi đi (An toàn, tránh lỗi index)
    final String imgUrl = widget.product.images.isNotEmpty
        ? widget.product.images.first
        : "";

    // 4. Gọi hàm submit trong ViewModel
    final result = await vm.submitBooking(
      productId: widget.product.id,
      productTitle: widget.product.title,
      productImage:
          imgUrl, // <--- [MỚI] Gửi ảnh tour để hiện trong lịch sử đơn hàng
      inventoryItem: widget.selectedInventory,
      userId: userId,
      contactInfo: {
        'fullName': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text, // <--- [MỚI] Gửi địa chỉ người đặt
        'note': _noteController.text,
      },
      basePrice: basePrice,
      priceData: priceData,
    );

    // 5. Xử lý kết quả trả về
    if (result != null && mounted) {
      // Logic tìm Booking ID an toàn (Cover mọi trường hợp API trả về: _id, id, bookingId...)
      String? bookingId = result['bookingId'];

      if (bookingId == null) {
        bookingId = result['_id'] ?? result['id'];
      }

      if (bookingId == null && result['data'] != null) {
        bookingId =
            result['data']['bookingId'] ??
            result['data']['_id'] ??
            result['data']['id'];
      }

      if (bookingId != null) {
        // Thành công: Chuyển sang màn hình Thanh toán
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(bookingId: bookingId!),
          ),
        );
      } else {
        // Thất bại: Không tìm thấy ID trong response
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi hệ thống: Không lấy được Booking ID"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // --- WIDGET COMPONENTS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final dateStr = widget.selectedInventory['tour_details']['date'];
    final date = DateTime.parse(dateStr);

    // Fix: Lấy ảnh đầu tiên an toàn
    final imageUrl = widget.product.images.isNotEmpty
        ? widget.product.images.first
        : "";

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
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Khởi hành: ${DateFormat('dd/MM/yyyy').format(date)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.transport,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(bool showLoginHint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (showLoginHint)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Đăng nhập để tích điểm và điền thông tin nhanh hơn!",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          _buildTextField(_nameController, "Họ và tên *", Icons.person),
          const SizedBox(height: 12),
          _buildTextField(
            _phoneController,
            "Số điện thoại *",
            Icons.phone,
            type: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _emailController,
            "Email *",
            Icons.email,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(_addressController, "Địa chỉ", Icons.location_on),
          const SizedBox(height: 12),
          _buildTextField(_noteController, "Ghi chú", Icons.note, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildPassengerCounts(BookingViewModel vm, double basePrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCounterRow(
            "Người lớn",
            ">12 tuổi",
            vm.adults,
            (v) => vm.updateCount('adult', v),
            basePrice,
          ),
          const Divider(),
          _buildCounterRow(
            "Trẻ em",
            "5-11 tuổi",
            vm.children,
            (v) => vm.updateCount('child', v),
            basePrice * 0.8,
          ),
          const Divider(),
          _buildCounterRow(
            "Trẻ nhỏ",
            "2-4 tuổi",
            vm.toddlers,
            (v) => vm.updateCount('toddler', v),
            basePrice * 0.5,
          ),
          const Divider(),
          _buildCounterRow(
            "Em bé",
            "<2 tuổi",
            vm.infants,
            (v) => vm.updateCount('infant', v),
            basePrice * 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetailsForm(BookingViewModel vm) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.passengers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = vm.passengers[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hành khách ${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeLabel(p.type),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: p.fullName,
                decoration: _inputDecor("Họ tên", Icons.person_outline),
                onChanged: (val) => vm.updatePassengerInfo(index, name: val),
                validator: (v) => v!.isEmpty ? "Nhập tên" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: p.gender,
                      decoration: _inputDecor("Giới tính", null),
                      items: ["Nam", "Nữ", "Khác"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          vm.updatePassengerInfo(index, gender: val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, index, vm),
                      child: InputDecorator(
                        decoration: _inputDecor(
                          "Ngày sinh",
                          Icons.calendar_month,
                        ),
                        child: Text(
                          p.dob == null
                              ? "Chọn ngày"
                              : DateFormat('dd/MM/yyyy').format(p.dob!),
                          style: TextStyle(
                            color: p.dob == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Common UI Helpers
  InputDecoration _inputDecor(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: Colors.grey)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: (v) =>
          label.contains("*") && v!.isEmpty ? "Vui lòng nhập thông tin" : null,
      decoration: _inputDecor(label, icon),
    );
  }

  Widget _buildCounterRow(
    String label,
    String sub,
    int value,
    Function(int) onChange,
    double price,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  formatCurrency(price),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00897B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => onChange(-1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove_circle_outline, color: Colors.grey),
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                "$value",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => onChange(1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add_circle, color: Color(0xFF00897B)),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
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

  // --- 1. HÀM HIỂN THỊ DANH SÁCH MÃ GIẢM GIÁ (BOTTOM SHEET) ---
  void _showPromoListSheet(
    BuildContext context,
    BookingViewModel vm,
    double subTotal,
  ) {
    // Gọi API lấy danh sách mới nhất mỗi khi mở
    vm.fetchPromotions();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Để thấy bo góc
      isScrollControlled: true, // Cho phép full chiều cao nếu cần
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Thanh kéo (Handle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Mã giảm giá",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách mã
                  Expanded(
                    child: Consumer<BookingViewModel>(
                      builder: (context, viewModel, child) {
                        if (viewModel.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00897B),
                            ),
                          );
                        }

                        if (viewModel.availablePromos.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 50,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Chưa có mã giảm giá nào.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: viewModel.availablePromos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final promo = viewModel.availablePromos[index];
                            // Kiểm tra điều kiện đơn tối thiểu
                            final canUse = subTotal >= promo.minSpend;
                            final isSelected =
                                viewModel.appliedPromo != null &&
                                viewModel.appliedPromo!['code'] == promo.code;

                            return InkWell(
                              onTap: canUse
                                  ? () {
                                      // 1. Chọn mã trong ViewModel
                                      viewModel.selectPromoFromList(
                                        promo,
                                        subTotal,
                                      );
                                      // 2. Cập nhật Text Controller để hiện mã lên ô nhập
                                      _promoController.text = promo.code;
                                      // 3. Đóng Bottom Sheet
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: canUse
                                      ? Colors.white
                                      : Colors.grey[50],
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.orange
                                        : (canUse
                                              ? Colors.grey[300]!
                                              : Colors.grey[200]!),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    // Icon Ticket bên trái
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: canUse
                                            ? Colors.orange[50]
                                            : Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.confirmation_number,
                                        color: canUse
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Thông tin mã
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                promo.code,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: canUse
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  promo.type == 'percentage'
                                                      ? "-${promo.value}%"
                                                      : "-${NumberFormat.compact(locale: 'vi').format(promo.value)}", // VD: -100K
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            promo.description,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Đơn tối thiểu: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(promo.minSpend)}",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (!canUse)
                                            const Text(
                                              "Chưa đủ điều kiện đơn hàng",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Nút chọn (Radio)
                                    if (canUse)
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. HÀM DỰNG GIAO DIỆN PHẦN ƯU ĐÃI (WIDGET) ---
  Widget _buildPromoSection(BookingViewModel vm, double subTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Mã giảm giá",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Nút mở danh sách BottomSheet
              InkWell(
                onTap: () => _showPromoListSheet(context, vm, subTotal),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    "Chọn mã >",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  // Tái sử dụng hàm _inputDecor đã có trong file của bạn
                  decoration: _inputDecor("Nhập mã khuyến mãi", null),
                  onChanged: (val) {
                    // Có thể clear lỗi khi user gõ lại
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () =>
                    vm.applyPromoCode(_promoController.text, subTotal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Áp dụng",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Hiển thị lỗi nếu có
          if (vm.promoError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    vm.promoError,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Hiển thị mã đã áp dụng thành công
          if (vm.appliedPromo != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Đã áp dụng mã: ${vm.appliedPromo!['code']}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      vm.removePromo();
                      _promoController.clear();
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
