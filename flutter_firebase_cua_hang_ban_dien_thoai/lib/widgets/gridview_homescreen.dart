import 'package:cross_platform_mobile_app_development/models/gridview_product_model.dart';
import 'package:cross_platform_mobile_app_development/widgets/gridview_item.dart';
import 'package:flutter/material.dart';

class GridviewHomescreen extends StatelessWidget {
  final List<GridviewProductModel> listProductInfoInHomescreen;
  final String? selectedCategory;
  final int crossAxisCount; // Thêm tham số crossAxisCount

  const GridviewHomescreen({
    super.key,
    required this.listProductInfoInHomescreen,
    this.selectedCategory,
    this.crossAxisCount = 2, // Giá trị mặc định là 2
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3 / 4, // Tỷ lệ khung hình (rộng/cao), điều chỉnh nếu cần
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: listProductInfoInHomescreen.length,
      itemBuilder: (context, index) {
        return GridviewItem(
          gridviewProductModel: listProductInfoInHomescreen[index],
          category: listProductInfoInHomescreen[index].category,
        );
      },
    );
  }
}