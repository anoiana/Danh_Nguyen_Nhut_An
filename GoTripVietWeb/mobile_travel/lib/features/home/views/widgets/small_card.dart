import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/image_helper.dart';

class SmallCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String? type; // e.g., "Khách sạn", "Căn hộ"
  final double? rating; // e.g., 9.5
  final int? reviewCount;
  final double? price; // e.g., 500000
  final VoidCallback onTap;

  const SmallCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.type,
    this.rating,
    this.reviewCount,
    this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Helper format tiền tệ
    final currencyFormat = NumberFormat.currency(locale: 'vi', symbol: 'VND');
    final validImageUrl = ImageHelper.resolveUrl(imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Điều chỉnh độ rộng cho vừa vặn hơn
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. IMAGE (Đã xóa nút Heart) ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: validImageUrl,
                height: 100, // Chiều cao ảnh vừa phải
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200], 
                  child: const Icon(Icons.image, color: Colors.grey)
                ),
              ),
            ),

            // --- 2. CONTENT ---
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên địa điểm
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Hiển thị loại (nếu có)
                  if (type != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      type!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Hiển thị đánh giá (nếu có)
                  if (rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003B95), // Booking.com Blue
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 10
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (reviewCount != null)
                          Text(
                            "($reviewCount)",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}