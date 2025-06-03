import 'package:cross_platform_mobile_app_development/models/gridview_product_model.dart';
import 'package:flutter/material.dart';

class GridviewItem extends StatelessWidget {
  final GridviewProductModel gridviewProductModel;
  final String category;

  const GridviewItem({
    super.key,
    required this.gridviewProductModel,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    List<String> words = gridviewProductModel.title.split(" ");

    return GestureDetector(
      onTap: gridviewProductModel.onTap,
      child: Card(
        color: Colors.transparent,
        shape: BeveledRectangleBorder(
          side: const BorderSide(color: Colors.blue, width: 1.0),
        ),
        elevation: 0.0,
        child: Stack(
          fit: StackFit.expand, // Đảm bảo Stack lấp đầy không gian của Card
          children: [
            // Hình ảnh với kích thước cố định
            SizedBox.expand(
              child: Image(
                image: AssetImage(gridviewProductModel.imageUrl),
                fit: BoxFit.contain, // Hiển thị toàn bộ ảnh, tránh méo mó
                alignment: Alignment.center,
              ),
            ),
            // Nền đỏ nghiêng
            Positioned.fill(
              child: ClipRect(
                child: Container(
                  transform: Matrix4.skew(-0.7, 0), // Hiệu ứng nghiêng
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            // Văn bản tiêu đề
            Positioned(
              top: 20,
              left: 10,
              right: 10, // Giới hạn chiều rộng văn bản
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: words
                    .map(
                      (word) => Text(
                    word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // Giới hạn 1 dòng mỗi từ
                    overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
                  ),
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}