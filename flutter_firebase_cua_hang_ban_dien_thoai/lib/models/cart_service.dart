import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


Future<void> addToCart(String productId, String userId, int? indexVariant, BuildContext context) async {
  // Kiểm tra nếu indexVariant là null
  if (indexVariant == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng chọn một variant trước khi thêm vào giỏ hàng!')),
    );
    return;
  }

  // Kiểm tra productId và userId
  if (productId.isEmpty || userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thông tin sản phẩm hoặc người dùng không hợp lệ!')),
    );
    return;
  }

  try {
    DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(userId);
    DocumentSnapshot cartSnapshot = await cartRef.get();

    if (cartSnapshot.exists) {
      Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
      List<dynamic> productIds = cartData['productIds'] ?? [];

      // Kiểm tra xem cả productId và indexVariant có trùng với một mục trong productIds không
      int existingIndex = productIds.indexWhere((item) =>
      item['id'] == productId && item['indexVariant'] == indexVariant);

      if (existingIndex != -1) {
        // Nếu cả id và indexVariant đều trùng, tăng quantity của mục đó
        productIds[existingIndex]['quantity'] = (productIds[existingIndex]['quantity'] ?? 1) + 1;
        await cartRef.update({
          'productIds': productIds,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm đã có trong giỏ hàng, số lượng được tăng!')),
        );
      } else {
        // Nếu không trùng cả id và indexVariant, thêm mới vào productIds với quantity: 1
        productIds.add({
          'id': productId,
          'indexVariant': indexVariant,
          'quantity': 1,
        });
        await cartRef.update({
          'productIds': productIds,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm đã được thêm vào giỏ hàng!')),
        );
      }
    } else {
      // Nếu giỏ hàng chưa tồn tại, tạo mới
      await cartRef.set({
        'userId': userId,
        'productIds': [
          {
            'id': productId,
            'indexVariant': indexVariant,
            'quantity': 1,
          }
        ],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm đã được thêm vào giỏ hàng!')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi khi thêm sản phẩm: $e')),
    );
  }
}