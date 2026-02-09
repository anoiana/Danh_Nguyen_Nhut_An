import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../core/utils/image_helper.dart';

class TourCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const TourCard({Key? key, required this.product, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? resolvedUrl;
    try {
      resolvedUrl = ImageHelper.resolveUrl(product.imageUrl);
    } catch (e) {
      resolvedUrl = product.imageUrl;
    }
    final validImageUrl = resolvedUrl ?? "https://placehold.co/600x400";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: validImageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
            ),

            // 2. CONTENT
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- ROW 1: CODE & LOCATION ---
                  Row(
                    children: [
                      // LEFT (Flex 4): Code
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_activity_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Mã: ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                product.productCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold, // Bold Black
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // RIGHT (Flex 5): Location (GPS)
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey,
                            ), // GPS Icon
                            const SizedBox(width: 4),
                            const Text(
                              "Từ: ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                product.startPoint,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold, // Bold Blue
                                  color: Color(0xFF1565C0),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // --- ROW 2: DURATION & TRANSPORT ---
                  // ✅ ALIGNMENT FIX: Used same Flex (4 and 5) as above
                  Row(
                    children: [
                      // LEFT (Flex 4): Duration
                      Expanded(
                        flex: 4,
                        child: _buildSimpleInfo(
                          Icons.access_time,
                          product.duration,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // RIGHT (Flex 5): Transport (Car)
                      // Now this starts at exactly the same pixel as the Location row above
                      Expanded(
                        flex: 5,
                        child: _buildSimpleInfo(
                          Icons.directions_bus_outlined,
                          product.transport,
                        ), // Car Icon
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. DEPARTURE DATES
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Khởi hành:",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(width: 6),

                      if (product.departureDates != null &&
                          product.departureDates!.isNotEmpty)
                        Expanded(
                          child: SizedBox(
                            height: 22,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: product.departureDates!.length,
                              itemBuilder: (context, index) {
                                final date = product.departureDates![index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    DateFormat('dd-MM').format(date),
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        const Text(
                          "Liên hệ",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
