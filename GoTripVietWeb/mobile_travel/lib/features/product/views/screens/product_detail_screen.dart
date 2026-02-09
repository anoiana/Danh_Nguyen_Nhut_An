import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// ViewModels & Models
import '../../view_models/product_view_model.dart';
import '../../../../core/utils/image_helper.dart';

// Screens
import '../../../booking/views/screens/booking_screen.dart';

// Widgets
import '../../../home/views/widgets/tour_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  int _currentImageIndex = 0;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductViewModel>(
        context,
        listen: false,
      ).loadProductDetails(widget.productId);
    });

    // Listen scroll for AppBar effect
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 200 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductViewModel>(
        builder: (context, viewModel, child) {
          // 1. Loading State
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B)),
            );
          }

          // 2. Error/Empty State
          if (viewModel.product == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: const BackButton(color: Colors.black),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Không tìm thấy thông tin tour",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = viewModel.product!;
          final List<String> images = product.images.isNotEmpty
              ? product.images
              : [""];

          // Calculate Price (Based on selected date or default)
          final num currentPrice = viewModel.selectedInventory != null
              ? viewModel.selectedInventory['price']
              : product.price;

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- A. HEADER IMAGE SLIDER ---
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    systemOverlayStyle: _isScrolled
                        ? SystemUiOverlayStyle.dark
                        : SystemUiOverlayStyle.light,

                    // Back Button
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isScrolled
                            ? Colors.transparent
                            : Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: BackButton(
                        color: _isScrolled ? Colors.black : Colors.white,
                      ),
                    ),

                    // Title (Show when scrolled)
                    title: _isScrolled
                        ? Text(
                            product.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    centerTitle: true,

                    // Share Button
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isScrolled
                              ? Colors.transparent
                              : Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.share,
                            color: _isScrolled ? Colors.black : Colors.white,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],

                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) =>
                                setState(() => _currentImageIndex = index),
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: ImageHelper.resolveUrl(images[index]),
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              );
                            },
                          ),
                          // Gradient Overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Page Indicator
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${_currentImageIndex + 1} / ${images.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- B. CONTENT BODY ---
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      transform: Matrix4.translationValues(0, -20, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. THUMBNAILS (Small Images)
                          if (images.length > 1)
                            Container(
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final isSelected =
                                      _currentImageIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: isSelected
                                            ? Border.all(
                                                color: const Color(0xFF00897B),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: ImageHelper.resolveUrl(
                                            images[index],
                                          ),
                                          fit: BoxFit.cover,
                                          // Dim unselected images
                                          color: isSelected
                                              ? null
                                              : Colors.white.withOpacity(0.4),
                                          colorBlendMode: isSelected
                                              ? null
                                              : BlendMode.modulate,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // 2. Title & Rating
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Tour trọn gói",
                                  style: TextStyle(
                                    color: Colors.teal[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "4.8",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " (128 đánh giá)",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.startPoint,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 24),

                          // 3. Quick Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickInfo(
                                Icons.access_time_filled,
                                "Thời gian",
                                product.duration,
                                Colors.blue,
                              ),
                              _buildQuickInfo(
                                Icons.directions_bus,
                                "Phương tiện",
                                product.transport,
                                Colors.orange,
                              ),
                              _buildQuickInfo(
                                Icons.group,
                                "Quy mô",
                                "20-30 khách",
                                Colors.purple,
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // 4. DATE SELECTOR (Improved UI)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader("Lịch khởi hành"),
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF00897B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (viewModel.inventoryItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Đang cập nhật lịch khởi hành...",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: viewModel.inventoryItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = viewModel.inventoryItems[index];
                                  final date = DateTime.parse(
                                    item['tour_details']['date'],
                                  );
                                  final isSelected =
                                      viewModel.selectedInventory == item;
                                  final total =
                                      item['tour_details']['total_slots'];
                                  final booked =
                                      item['tour_details']['booked_slots'];
                                  final available = total - booked;
                                  final isFull = available <= 0;

                                  return GestureDetector(
                                    onTap: isFull
                                        ? null
                                        : () => viewModel.selectDate(item),
                                    child: Container(
                                      width: 100,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF00897B)
                                            : (isFull
                                                  ? Colors.grey[100]
                                                  : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF00897B)
                                              : (isFull
                                                    ? Colors.grey[300]!
                                                    : Colors.grey[300]!),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF00897B,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Date
                                          Text(
                                            DateFormat('dd/MM').format(date),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isFull
                                                        ? Colors.grey
                                                        : Colors.black87),
                                            ),
                                          ),

                                          // Price
                                          if (!isFull)
                                            Text(
                                              NumberFormat.compact(
                                                locale: 'vi',
                                              ).format(
                                                item['price'],
                                              ), // e.g., 1.5tr
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFFD32F2F),
                                              ),
                                            ),

                                          // Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.2,
                                                    )
                                                  : (isFull
                                                        ? Colors.grey[300]
                                                        : Colors.green[50]),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isFull
                                                  ? "Hết chỗ"
                                                  : "Còn $available vé",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isFull
                                                          ? Colors.grey
                                                          : Colors.green[700]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 32),

                          // 5. Itinerary Timeline
                          _buildSectionHeader("Lịch trình chi tiết"),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: product.itinerary.length,
                            itemBuilder: (context, index) {
                              final item = product.itinerary[index];
                              final isLast =
                                  index == product.itinerary.length - 1;
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Timeline Line
                                    Column(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE0F2F1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "${index + 1}",
                                              style: const TextStyle(
                                                color: Color(0xFF00897B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: Colors.grey[200],
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Content
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ngày ${item.day}: ${item.title}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.details,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            if (item.meals.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.restaurant,
                                                      size: 14,
                                                      color: Colors.orange,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Ăn uống: ${item.meals.join(', ')}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.orange[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // 6. Highlights (Grid)
                          _buildSectionHeader("Điểm nổi bật"),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildHighlightCard(
                                Icons.camera_alt,
                                "Tham quan",
                                "Đa dạng",
                              ),
                              _buildHighlightCard(
                                Icons.restaurant_menu,
                                "Ẩm thực",
                                "Đặc sản vùng",
                              ),
                              _buildHighlightCard(
                                Icons.hotel,
                                "Lưu trú",
                                "Tiêu chuẩn 4*",
                              ),
                              _buildHighlightCard(
                                Icons.verified_user,
                                "Bảo hiểm",
                                "Trọn gói",
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // 7. Policies
                          _buildSectionHeader("Lưu ý quan trọng"),
                          const SizedBox(height: 12),
                          _buildPolicyTile(
                            "Giá bao gồm",
                            "Xe đưa đón, Khách sạn, Vé tham quan...",
                          ),
                          _buildPolicyTile(
                            "Giá không bao gồm",
                            "Thuế VAT, Chi phí cá nhân...",
                          ),
                          _buildPolicyTile(
                            "Hoàn hủy",
                            "Hủy trước 7 ngày miễn phí...",
                          ),

                          const SizedBox(height: 32),

                          // 8. Related Tours
                          if (viewModel.relatedTours.isNotEmpty) ...[
                            _buildSectionHeader("Gợi ý cho bạn"),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: viewModel.relatedTours.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  return SizedBox(
                                    width: 200,
                                    child: TourCard(
                                      product: viewModel.relatedTours[index],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            productId: viewModel
                                                .relatedTours[index]
                                                .id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 100), // Padding for Bottom Bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- C. BOTTOM BAR (Fixed) ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(top: BorderSide(color: Colors.grey[100]!)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Tổng giá trị",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(
                              locale: 'vi',
                              symbol: '₫',
                            ).format(currentPrice),
                            style: const TextStyle(
                              color: Color(0xFF00897B),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: viewModel.selectedInventory == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingScreen(
                                      product: product,
                                      selectedInventory:
                                          viewModel.selectedInventory,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Đặt Ngay",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickInfo(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00897B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTile(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
