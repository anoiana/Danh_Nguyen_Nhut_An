import 'dart:convert';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_mobile_app_development/screens/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_view_order_detail_after_checkout.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class ThankYouScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const ThankYouScreen({Key? key, required this.order}) : super(key: key);

  Future<Map<String, dynamic>?> fetchVariantDetails(String variantId) async {
    try {
      final variantDoc = await FirebaseFirestore.instance
          .collection('variants')
          .doc(variantId)
          .get();

      if (!variantDoc.exists) return null;
      final variantData = variantDoc.data();
      final productId = variantData?['productId'] as String?;

      if (productId == null) return null;

      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get();

      if (!productDoc.exists) return null;
      final productData = productDoc.data();

      // Lấy ảnh: ưu tiên ảnh variant, nếu không có thì lấy từ product
      String image = '';
      if ((variantData?['image'] as String?)?.isNotEmpty == true) {
        image = variantData!['image'];
      } else if (productData?['image'] is List && productData!['image'].isNotEmpty) {
        image = productData['image'][0]; // base64 string
      }

      return {
        'name': productData?['name'] ?? 'N/A',
        'image': image,
        'performance': variantData?['performance'] ?? 'N/A',
        'color': variantData?['color'] ?? 'N/A',
      };
    } catch (e) {
      print("Error fetching variant details: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final purchaseDate = order['purchaseDate'] is Timestamp
        ? (order['purchaseDate'] as Timestamp).toDate()
        : DateTime(2025, 5, 15, 18, 18); // 06:18 PM +07, May 15, 2025
    final totalAmount = order['totalAmount'] as double? ?? 0.0;
    final productIds = order['productIds'] as List<dynamic>?;
    final firstProduct = productIds != null && productIds.isNotEmpty
        ? productIds[0] as Map<String, dynamic>?
        : null;
    final variantId = firstProduct != null && firstProduct['variantId'] is String
        ? firstProduct['variantId'] as String
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thank You",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Cảm ơn quý khách đã mua hàng!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Đơn hàng của bạn đã được đặt thành công. Chúng tôi sẽ xử lý và giao hàng sớm nhất có thể.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: ${DateFormat('dd/MM/yyyy – HH:mm').format(purchaseDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Total: ${totalAmount.toStringAsFixed(0)} VND',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (variantId != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: fetchVariantDetails(variantId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[200],
                                            child: const Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                        final image = snapshot.data!['image'] ?? '';
                                        String base64Str = image;

                                        if (image.startsWith('data:image')) {
                                          final splitData = image.split(',');
                                          if (splitData.length == 2) {
                                            base64Str = splitData[1];
                                          }
                                        }

                                        try {
                                          final imageBytes = base64Decode(base64Str);
                                          return Image.memory(
                                            imageBytes,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          );
                                        } catch (e) {
                                          print("Lỗi giải mã ảnh base64: $e");
                                          return Image.network(
                                            "https://picsum.photos/50/50",
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          );
                                        }

                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FutureBuilder<Map<String, dynamic>?>(
                                            future: fetchVariantDetails(variantId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Text("Product: Loading...");
                                              }
                                              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                                return const Text("Product: N/A");
                                              }
                                              final product = snapshot.data!;
                                              return Text(
                                                product['name'] ?? 'N/A',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<Map<String, dynamic>?>(
                                            future: fetchVariantDetails(variantId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Text("Color: Loading...");
                                              }
                                              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                                return const Text("Color: N/A");
                                              }
                                              final product = snapshot.data!;
                                              return Text(
                                                "${product['color']} - ${product['performance']}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "x${firstProduct!['quantity'] as int? ?? 'N/A'}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            formatPrice(num.tryParse(firstProduct!['price']?.toString() ?? '0') ?? 0.0),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              print(order);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailAfterDetail(order: order),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.shopping_bag, color: Colors.white),
                    label: const Text(
                      "Tiếp tục mua hàng",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}