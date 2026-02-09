import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_helper.dart';

class AllCategoriesScreen extends StatelessWidget {
  final List<dynamic> categories;

  const AllCategoriesScreen({Key? key, required this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tất cả danh mục", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 cột
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8, // Tỷ lệ chiều cao/rộng
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          String rawImage = "";
          if (cat['image'] != null && cat['image'] is Map) {
            rawImage = cat['image']['url'] ?? "";
          }
          final imageUrl = ImageHelper.resolveUrl(rawImage);

          return GestureDetector(
            onTap: () {
              // TODO: Navigate to TourListScreen with category_id filter
              print("Selected Category: ${cat['name']}");
            },
            child: Column(
              children: [
                Container(
                  height: 80, width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl, fit: BoxFit.cover,
                      errorWidget: (_,__,___) => const Icon(Icons.category, color: Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] ?? "",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}