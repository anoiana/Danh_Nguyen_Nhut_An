import 'package:flutter/material.dart';
import '../../../../core/utils/image_helper.dart';
import '../widgets/small_card.dart'; // Tận dụng SmallCard cũ
import 'tour_list_screen.dart'; // Để navigate sang danh sách tour

class AllLocationsScreen extends StatelessWidget {
  final List<dynamic> locations;

  const AllLocationsScreen({Key? key, required this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Tất cả điểm đến", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cột
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Tỷ lệ khung hình
        ),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final loc = locations[index];
          
          // Xử lý ảnh
          String rawImage = "";
          if (loc['images'] != null && (loc['images'] as List).isNotEmpty) {
            var firstImg = loc['images'][0];
            rawImage = (firstImg is Map) ? (firstImg['url'] ?? "") : firstImg.toString();
          }
          final imageUrl = ImageHelper.resolveUrl(rawImage);

          return SmallCard(
            name: loc['name'] ?? "Địa điểm",
            imageUrl: imageUrl,
            // LOGIC: Bấm vào địa điểm -> Ra danh sách tour của địa điểm đó
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourListScreen(
                    title: "Tour tại ${loc['name']}",
                    queryParams: {'location_id': loc['_id']}, // Lọc theo ID địa điểm
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}