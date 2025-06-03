import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'admin_view_order_detail_in_coupon.dart';
import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  int currentPage = 1;
  final int itemsPerPage = 20;
  DocumentSnapshot? lastDocument;
  DocumentSnapshot? firstDocument;
  String selectedFilter = 'All';
  DateTime? customStartDate;
  DateTime? customEndDate;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders({bool nextPage = false, bool previousPage = false}) async {
    setState(() {
      isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('purchaseDate', descending: true);

      if (selectedFilter != 'All') {
        DateTime now = DateTime.now();
        DateTime startDate;
        DateTime endDate = now;

        if (selectedFilter == 'Today') {
          startDate = DateTime(now.year, now.month, now.day);
        } else if (selectedFilter == 'Yesterday') {
          startDate = DateTime(now.year, now.month, now.day - 1);
          endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        } else if (selectedFilter == 'This Week') {
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
        } else if (selectedFilter == 'This Month') {
          startDate = DateTime(now.year, now.month, 1);
        } else if (selectedFilter == 'Custom' && customStartDate != null && customEndDate != null) {
          startDate = customStartDate!;
          endDate = customEndDate!;
        } else {
          startDate = DateTime(1970);
        }

        query = query
            .where('purchaseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('purchaseDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .where('purchaseDate', isNotEqualTo: null);
      }

      if (nextPage && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!).limit(itemsPerPage);
      } else if (previousPage && firstDocument != null) {
        query = query.endBeforeDocument(firstDocument!).limitToLast(itemsPerPage);
      } else {
        query = query.limit(itemsPerPage);
      }

      final snapshot = await query.get().timeout(Duration(seconds: 30), onTimeout: () {
        throw Exception("Timeout while fetching orders");
      });

      print("Fetched ${snapshot.docs.length} orders at ${DateTime.now()}");
      final orderList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
        if (snapshot.docs.isNotEmpty) {
          lastDocument = snapshot.docs.last;
          firstDocument = snapshot.docs.first;
        } else {
          lastDocument = null;
          firstDocument = null;
        }
      });
    } catch (e, stackTrace) {
      print("Error fetching orders: $e at ${DateTime.now()}");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load orders: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'orderStatus': newStatus,
        'statusHistory.$newStatus': FieldValue.serverTimestamp(),
      });

      setState(() {
        final orderIndex = orders.indexWhere((order) => order['orderId'] == orderId);
        if (orderIndex != -1) {
          orders[orderIndex]['orderStatus'] = newStatus;
        }
      });

      print("Updated order $orderId to status $newStatus at ${DateTime.now()}");
    } catch (e) {
      print("Error updating order status for $orderId: $e at ${DateTime.now()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update order status: $e")),
      );
    }
  }

  Future<Map<String, dynamic>?> fetchProduct(String variantId) async {
    try {
      final variantDoc = await FirebaseFirestore.instance
          .collection('variants')
          .doc(variantId)
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception("Timeout while fetching variant $variantId");
      });

      if (!variantDoc.exists) {
        print("Variant $variantId not found at ${DateTime.now()}");
        return null;
      }

      final variantData = variantDoc.data()!;
      final productId = variantData['productId'] as String?;

      if (productId == null) {
        print("Product ID not found in variant $variantId at ${DateTime.now()}");
        return null;
      }

      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception("Timeout while fetching product $productId");
      });

      if (!productDoc.exists) {
        print("Product $productId not found at ${DateTime.now()}");
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
      print("Error fetching product for variant $variantId: $e at ${DateTime.now()}");
      return null;
    }
  }

  Future<String> fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception("Timeout while fetching user $userId");
      });

      if (!userDoc.exists) {
        print("User $userId not found at ${DateTime.now()}");
        return 'Unknown User';
      }

      final userData = userDoc.data()!;
      return userData['fullName'] as String? ?? 'Unknown User';
    } catch (e) {
      print("Error fetching user name for $userId: $e at ${DateTime.now()}");
      return 'Unknown User';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (customStartDate ?? DateTime.now()) : (customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          customStartDate = picked;
        } else {
          customEndDate = picked;
        }
      });
      fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 10,),
                  DropdownButton<String>(
                    value: selectedFilter,
                    items: <String>['All', 'Today', 'Yesterday', 'This Week', 'This Month', 'Custom']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        customStartDate = null;
                        customEndDate = null;
                        currentPage = 1;
                        lastDocument = null;
                        firstDocument = null;
                      });
                      fetchOrders();
                    },
                  ),
                ],
              ),
              if (selectedFilter == 'Custom') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            customStartDate != null
                                ? DateFormat('yyyy-MM-dd').format(customStartDate!)
                                : 'Select start date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            customEndDate != null
                                ? DateFormat('yyyy-MM-dd').format(customEndDate!)
                                : 'Select end date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                  ? const Center(child: Text("No orders found for the select filter"))
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
                                FutureBuilder<String>(
                                  future: fetchUserName(order['userId'] ?? ''),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Text("Customer: Loading...");
                                    }
                                    if (snapshot.hasError || !snapshot.hasData) {
                                      return const Text("Customer: Unknown User");
                                    }
                                    return Text(
                                      "Customer: ${snapshot.data}",
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    );
                                  },
                                ),
                                DropdownButton<String>(
                                  value: order['orderStatus'] ?? 'Pending',
                                  items: <String>['Pending', 'Confirmed', 'Shipping', 'Delivered']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: value == 'Pending' ? Colors.orange : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null && newValue != order['orderStatus']) {
                                      updateOrderStatus(order['orderId'], newValue);
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (firstProduct != null && firstProduct['variantId'] is String)
                              FutureBuilder<Map<String, dynamic>?>(
                                future: fetchProduct(firstProduct['variantId'] as String),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.network(
                                          "https://via.placeholder.com/50",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Product: N/A",
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "Color: N/A - Performance: N/A",
                                                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                                    );
                                  }
                                  final product = snapshot.data!;
                                  final image = product['image'] ?? '';
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      image.isEmpty
                                          ? Image.network(
                                        "https://via.placeholder.com/50",
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                          : FutureBuilder<Widget>(
                                        future: Future.microtask(() {
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
                                            print("Error decoding base64: $e at ${DateTime(2025, 5, 15, 22, 58)}");
                                            return Image.network(
                                              "https://via.placeholder.com/50",
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                        }),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          return snapshot.data!;
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'N/A',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${product['color']} - ${product['performance']}",
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                                  );
                                },
                              ),
                            if (otherProductCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "And $otherProductCount other products",
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total:",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  formatPrice(num.tryParse(order['totalAmount']?.toStringAsFixed(2) ?? '0') ?? 0.0),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      onPressed: currentPage > 1
                          ? () {
                        setState(() {
                          currentPage--;
                        });
                        fetchOrders(previousPage: true);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text("Previous Page", style: TextStyle(fontSize: 12),),
                    ),
                  ),
                  Text("Page $currentPage"),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: orders.length == itemsPerPage
                          ? () {
                        setState(() {
                          currentPage++;
                        });
                        fetchOrders(nextPage: true);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text("Next Page", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}