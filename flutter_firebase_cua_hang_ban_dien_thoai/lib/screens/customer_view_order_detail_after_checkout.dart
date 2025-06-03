import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class OrderDetailAfterDetail extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailAfterDetail({super.key, required this.order});
  Future<String> fetchFullName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['fullName'] ?? 'N/A';
      }
      return 'N/A';
    } catch (e) {
      print("Error fetching fullName for userId $userId: $e");
      return 'N/A';
    }
  }

  Future<String> fetchPhoneNumber(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['phoneNumber'] ?? 'N/A';
      }
      return 'N/A';
    } catch (e) {
      print("Error fetching phoneNumber for userId $userId: $e");
      return 'N/A';
    }
  }

  Future<Map<String, dynamic>?> fetchVariantDetails(String variantId) async {
    print(order);

    try {
      final variantDoc = await FirebaseFirestore.instance
          .collection('variants')
          .doc(variantId)
          .get();

      if (!variantDoc.exists) {
        print("Variant $variantId does not exist");
        return null;
      }

      final variantData = variantDoc.data();
      if (variantData == null) {
        print("No data for variant $variantId");
        return null;
      }

      final productId = variantData['productId'] as String?;
      if (productId == null) {
        print("No productId for variant $variantId");
        return null;
      }

      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        print("Product $productId does not exist");
        return null;
      }

      final productData = productDoc.data();
      if (productData == null) {
        print("No data for product $productId");
        return null;
      }

      return {
        'name': productData['name'] ?? 'N/A',
        'image': variantData['image'] ?? '',
        'performance': variantData['performance'] ?? 'N/A',
        'color': variantData['color'] ?? 'N/A',
      };
    } catch (e) {
      print("Error fetching variant details for variantId $variantId: $e");
      return null;
    }
  }

  // Hàm lấy thông tin coupon từ couponCode
  Future<Map<String, dynamic>?> fetchCouponDetails(String? couponCode) async {
    if (couponCode == null || couponCode.isEmpty) {
      return null;
    }
    try {
      final couponDoc = await FirebaseFirestore.instance
          .collection('couponCode')
          .where('couponCode', isEqualTo: couponCode)
          .limit(1)
          .get();

      if (couponDoc.docs.isNotEmpty) {
        final couponData = couponDoc.docs.first.data();
        return {
          'discountMoney': couponData['discountMoney'] ?? 0.0,
        };
      }
      print("No coupon found for code $couponCode");
      return null;
    } catch (e) {
      print("Error fetching coupon details for couponCode $couponCode: $e");
      return null;
    }
  }

  // Hàm tính subtotal với VAT 10%
  double calculateSubtotalWithVAT() {
    final productIds = order['productIds'] as List<dynamic>? ?? [];
    double subtotal = 0.0;
    for (var product in productIds) {
      final price = (product['price'] ?? 0.0) as double;
      final quantity = (product['quantity'] ?? 0) as int;
      subtotal += price * quantity;
    }
    return subtotal * 1.1; // 10% VAT
  }

  @override
  Widget build(BuildContext context) {
    final currentDateTime = DateTime.now();
    final purchaseDate = order['purchaseDate'] != null
        ? (order['purchaseDate'] as Timestamp).toDate()
        : currentDateTime;
    final shippingFee = order['shippingFee'] ?? 0.0;
    final couponCode = order['couponCode'] as String?;
    final subtotalWithVAT = calculateSubtotalWithVAT();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipping Address Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFEE4D2D), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Shipping Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<String>(
                      future: fetchFullName(order['userId'] ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                            'N/A',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          );
                        }
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String>(
                      future: fetchPhoneNumber(order['userId'] ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                            'N/A',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          );
                        }
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      order['shippingAddress'] ?? 'N/A',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Order Status and Date Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          order['orderStatus'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: order['orderStatus'] == 'Pending'
                                ? Colors.orange
                                : order['orderStatus'] == 'Completed'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildInfoRow(
                      Icons.calendar_today,
                      'Order Date',
                      DateFormat('dd/MM/yyyy – HH:mm').format(purchaseDate),
                    ),
                    buildInfoRow(
                      Icons.receipt_long,
                      'Order ID',
                      order['orderId'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Products Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(
                      (order['productIds'] as List<dynamic>?)?.length ?? 0,
                          (index) {
                        final product = (order['productIds'] as List<dynamic>)[index];
                        final variantId = product['variantId'] ?? '';
                        final quantity = product['quantity'] ?? 0;
                        final price = product['price'] ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<Map<String, dynamic>?>(
                                  future: fetchVariantDetails(variantId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    }
                                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                      return Image.network(
                                        "https://via.placeholder.com/80",
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    final variantData = snapshot.data!;
                                    final image = variantData['image'] ?? '';
                                    if (image.isEmpty) {
                                      return Image.network(
                                        "https://via.placeholder.com/80",
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    try {
                                      String base64String = image;
                                      if (image.startsWith('data:image')) {
                                        base64String = image.split(',')[1];
                                      }
                                      final imageBytes = base64Decode(base64String);
                                      return Image.memory(
                                        imageBytes,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            "https://via.placeholder.com/80",
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      );
                                    } catch (e) {
                                      print("Error decoding image for variant $variantId: $e");
                                      return Image.network(
                                        "https://via.placeholder.com/80",
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: fetchVariantDetails(variantId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text("Loading...", style: TextStyle(fontSize: 16));
                                        }
                                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                          return const Text("N/A", style: TextStyle(fontSize: 16));
                                        }
                                        final variantData = snapshot.data!;
                                        return Text(
                                          variantData['name'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: fetchVariantDetails(variantId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text("Loading...", style: TextStyle(fontSize: 14, color: Colors.grey));
                                        }
                                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                          return const Text(
                                            "Performance: N/A, Color: N/A",
                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                          );
                                        }
                                        final variantData = snapshot.data!;
                                        return Text(
                                          "${variantData['performance']} - ${variantData['color']}",
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "x$quantity",
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        Text(
                                          formatPrice(price),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEE4D2D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Order Summary Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: fetchCouponDetails(couponCode),
                  builder: (context, couponSnapshot) {
                    final discount = couponSnapshot.data?['discountMoney'] ?? 0.0;
                    final effectiveDiscount = (discount > 0 && discount <= subtotalWithVAT + shippingFee) ? discount : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildInfoRow(
                          Icons.payment,
                          'Payment Method',
                          order['paymentMethod'] ?? 'N/A',
                        ),
                        buildSummaryRow('Subtotal', formatPrice(subtotalWithVAT)),
                        buildSummaryRow('Shipping Fee', formatPrice(shippingFee)),
                        buildSummaryRow(
                          'Coupon Discount',
                          effectiveDiscount > 0 ? "-${formatPrice(effectiveDiscount)}" : '0.00đ',
                        ),
                        const Divider(height: 20, thickness: 1, color: Colors.grey),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              formatPrice((subtotalWithVAT + shippingFee - effectiveDiscount)),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEE4D2D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? Colors.grey[700], size: 20),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: statusColor ?? Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
