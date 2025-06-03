import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';
import 'admin_view_order_detail_in_coupon.dart';
import 'dart:convert';

class CouponDetail extends StatefulWidget {
  final Coupon coupon;

  const CouponDetail({super.key, required this.coupon});

  @override
  State<CouponDetail> createState() => _CouponDetailState();
}

class _CouponDetailState extends State<CouponDetail> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('couponCode', isEqualTo: widget.coupon.couponCode)
          .get();

      final orderList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        print("Raw productIds for order ${data['orderId']}: ${data['productIds']} (Type: ${data['productIds'].runtimeType})");
        if (data['productIds'] is String) {
          try {
            data['productIds'] = jsonDecode(data['productIds'] as String) as List<dynamic>;
          } catch (e) {
            print("Error parsing productIds JSON for order ${data['orderId']}: $e");
            data['productIds'] = [];
          }
        } else if (data['productIds'] is! List) {
          print("productIds is not a list for order ${data['orderId']}: ${data['productIds']}");
          data['productIds'] = [];
        }
        return data;
      }).toList();

      setState(() {
        orders = orderList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> fetchProduct(String variantId) async {
    try {
      final variantDoc = await FirebaseFirestore.instance
          .collection('variants')
          .doc(variantId)
          .get();

      if (!variantDoc.exists) {
        print("Variant $variantId not found");
        return null;
      }

      final variantData = variantDoc.data()!;
      final productId = variantData['productId'] as String?;

      if (productId == null) {
        print("Product ID not found in variant $variantId");
        return null;
      }

      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        print("Product $productId not found");
        return null;
      }

      final productData = productDoc.data()!;
      final images = productData['image'] is List<dynamic> ? productData['image'] as List<dynamic> : [];
      final firstImage = images.isNotEmpty ? images[0] as String : '';

      String base64String = firstImage;
      if (firstImage.startsWith('data:image/')) {
        base64String = firstImage.split(',').last;
      }

      return {
        'name': productData['name'] ?? 'N/A',
        'image': base64String,
        'color': variantData['color'] as String? ?? 'N/A',
        'performance': variantData['performance'] as String? ?? 'N/A',
        'variant': variantData,
      };
    } catch (e) {
      print("Error fetching product for variant $variantId: $e");
      return null;
    }
  }

  Future<String> fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print("User $userId not found");
        return 'Unknown User';
      }

      final userData = userDoc.data()!;
      return userData['fullName'] as String? ?? 'Unknown User';
    } catch (e) {
      print("Error fetching user name for $userId: $e");
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupon Detail'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 385,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDB3022).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.coupon.couponCode,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDB3022),
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.description, color: Color(0xFFDB3022)),
                            title: const Text(
                              "Description",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              widget.coupon.description,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.discount, color: Color(0xFFDB3022)),
                            title: const Text(
                              "Discount",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${widget.coupon.discountMoney.toStringAsFixed(0)} VND",
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.format_list_numbered, color: Color(0xFFDB3022)),
                            title: const Text(
                              "Quantity",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${widget.coupon.quantity}",
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.date_range, color: Color(0xFFDB3022)),
                            title: const Text(
                              "Created At",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy – HH:mm').format(widget.coupon.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.verified,
                              color: widget.coupon.validity ? Colors.green : Colors.red,
                            ),
                            title: const Text(
                              "Valid",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              widget.coupon.validity ? "Yes" : "No",
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.coupon.validity ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Order List",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                  ? const Center(child: Text("No orders use this coupon"))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final productIds = order['productIds'] as List<dynamic>? ?? [];
                  final firstProduct = productIds.isNotEmpty && productIds[0] is Map<String, dynamic>
                      ? productIds[0] as Map<String, dynamic>?
                      : null;
                  final otherProductCount = productIds.length > 1 ? productIds.length - 1 : 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetail(order: order),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Order ID: ${order['orderId'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDB3022),
                                  ),
                                ),
                                Text(
                                  order['orderStatus'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: order['orderStatus'] == 'Pending'
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            FutureBuilder<String>(
                              future: fetchUserName(order['userId'] ?? ''),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text("Buyer: Loading...");
                                }
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return const Text("Buyer: Unknown User");
                                }
                                return Text(
                                  "Customer: ${snapshot.data}",
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                );
                              },
                            ),
                            const Divider(height: 20),

                            // Phần sản phẩm
                            if (firstProduct != null && firstProduct['variantId'] is String)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ảnh sản phẩm
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: fetchProduct(firstProduct['variantId'] as String),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                        return Image.network(
                                          "https://via.placeholder.com/50",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      final product = snapshot.data!;
                                      final image = product['image'] ?? '';
                                      if (image.isEmpty) {
                                        return Image.network(
                                          "https://via.placeholder.com/50",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      try {
                                        final imageBytes = base64Decode(image);
                                        return Image.memory(
                                          imageBytes,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.network(
                                              "https://via.placeholder.com/50",
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        );
                                      } catch (e) {
                                        print("Error decoding base64: $e");
                                        return Image.network(
                                          "https://via.placeholder.com/50",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  // Thông tin sản phẩm
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<Map<String, dynamic>?>(
                                          future: fetchProduct(firstProduct['variantId'] as String),
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
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<Map<String, dynamic>?>(
                                          future: fetchProduct(firstProduct['variantId'] as String),
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
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "x${firstProduct['quantity'] ?? 'N/A'}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        Text(
                                          "${firstProduct['price']?.toStringAsFixed(2) ?? '0'} VND",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            if (otherProductCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Và $otherProductCount sản phẩm khác",
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ),

                            const Divider(height: 20),

                            // Tổng tiền
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total:",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "${order['totalAmount']?.toStringAsFixed(2) ?? '0'} VND",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDB3022),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}