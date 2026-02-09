import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/event_model.dart';
import '../../../../core/utils/image_helper.dart';

class BannerSlider extends StatefulWidget {
  final List<EventModel> events;

  const BannerSlider({Key? key, required this.events}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  // Page Controller với viewportFraction < 1 để lộ ra 1 chút của slide tiếp theo (Tạo cảm giác muốn lướt)
  final PageController _pageController = PageController(viewportFraction: 0.92);

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tự động chạy slide sau mỗi 4 giây
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentIndex < widget.events.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // Khi người dùng vuốt tay, reset lại timer để tránh bị giật
  void _onUserSwipe(int index) {
    setState(() {
      _currentIndex = index;
    });
    _timer?.cancel();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // 1. SLIDER AREA
        SizedBox(
          height: 190, // Chiều cao vừa phải cho banner
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.events.length,
            onPageChanged: _onUserSwipe,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return _buildBannerItem(event);
            },
          ),
        ),

        const SizedBox(height: 12),

        // 2. DOT INDICATORS (Dấu chấm)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.events.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentIndex == index
                  ? 24
                  : 6, // Chấm dài nếu đang active
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFF00897B) // Màu Active (Teal)
                    : Colors.grey.shade300, // Màu Inactive
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- WIDGET: MỘT BANNER ĐƠN LẺ ---
  Widget _buildBannerItem(EventModel event) {
    return GestureDetector(
      onTap: () {
        // TODO: Xử lý khi bấm vào Banner (Điều hướng đến chi tiết sự kiện hoặc danh sách tour)
        print("Bấm vào sự kiện: ${event.title}");
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 6,
        ), // Khoảng cách giữa các slide
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // A. ẢNH NỀN
              CachedNetworkImage(
                imageUrl: ImageHelper.resolveUrl(event.imageUrl),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.fill,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),

              // B. LỚP PHỦ GRADIENT (Để chữ dễ đọc hơn)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7), // Đen mờ ở dưới đáy
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // C. NỘI DUNG CHỮ
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "Sự kiện"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "HOT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tiêu đề sự kiện
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
