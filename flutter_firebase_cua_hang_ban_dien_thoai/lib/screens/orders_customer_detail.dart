import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart'
hide Order;
import 'package:cross_platform_mobile_app_development/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class OrdersCustomerDetail extends StatelessWidget {
  final Order order;

  const OrdersCustomerDetail({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${order.id.substring(0, 8)}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderStatusCard(),
            _buildOrderStatusHistory(),
            SizedBox(height: 10,),
            _buildOrderItems(),
            _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(order.orderStatus),
                  color: _getStatusColor(order.orderStatus),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(order.orderStatus),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.orderStatus),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật lúc: ${order.statusHistory.isNotEmpty ? _formatDateTime(order.statusHistory.last.timestamp) : 'Đang chờ người bán xác nhận'}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchProduct(String variantId) async {
    try {
      final variantDoc = await FirebaseFirestore.instance
          .collection('variants')
          .doc(variantId)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Timeout while fetching variant $variantId");
            },
          );

      if (!variantDoc.exists) {
        print(
          "Variant $variantId not found at ${DateTime(2025, 5, 15, 22, 58)}",
        );
        return null;
      }

      final variantData = variantDoc.data()!;
      final productId = variantData['productId'] as String?;

      if (productId == null) {
        print(
          "Product ID not found in variant $variantId at ${DateTime(2025, 5, 15, 22, 58)}",
        );
        return null;
      }

      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Timeout while fetching product $productId");
            },
          );

      if (!productDoc.exists) {
        print(
          "Product $productId not found at ${DateTime(2025, 5, 15, 22, 58)}",
        );
        return null;
      }

      final productData = productDoc.data()!;
      final images =
          productData['image'] is List<dynamic>
              ? productData['image'] as List<dynamic>
              : [];
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
      print(
        "Error fetching product for variant $variantId: $e at ${DateTime(2025, 5, 15, 22, 58)}",
      );
      return null;
    }
  }

  Widget _buildOrderItems() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm đã đặt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.productIds.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> item = order.productIds[index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: fetchProduct(item['variantId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const SizedBox();
                    }
                    final product = snapshot.data!;
                    final image = product['image'] ?? '';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
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
                                          final imageBytes = base64Decode(
                                            image,
                                          );
                                          return Image.memory(
                                            imageBytes,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Image.network(
                                                "https://via.placeholder.com/50",
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          );
                                        } catch (e) {
                                          print(
                                            "Error decoding base64: $e at ${DateTime(2025, 5, 15, 22, 58)}",
                                          );
                                          return Image.network(
                                            "https://via.placeholder.com/50",
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                      }),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        return snapshot.data!;
                                      },
                                    ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${product['name']} - ${product['color']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Số lượng: ${item['quantity']}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatPrice(num.tryParse(item['price']?.toStringAsFixed(2) ?? '0') ?? 0.0),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusHistory() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Lịch sử trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.statusHistory.length,
            itemBuilder: (context, index) {
              final status = order.statusHistory[index];
              final isLast = index == order.statusHistory.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('d MMM').format(status.timestamp),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(status.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(status.status),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Mã đơn hàng:', '#${order.id.substring(0, 8)}'),
            _buildDetailRow('Ngày đặt:', _formatDateTime(order.purchaseDate)),
            _buildDetailRow('Số lượng sản phẩm:', '${order.numberOfProducts}'),
            _buildDetailRow('Phương thức thanh toán:', order.paymentMethod),
            _buildDetailRow(
              'Địa chỉ giao hàng:',
              order.shippingAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              'Tổng tiền hàng:',
              '${_formatPrice(order.totalAmount - order.shippingFee)} ₫',
            ),
            _buildDetailRow(
              'Phí vận chuyển:',
              '${_formatPrice(order.shippingFee)} ₫',
            ),
            if (order.couponCode != null)
              _buildDetailRow('Mã giảm giá:', order.couponCode!),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Tổng thanh toán:',
              '${_formatPrice(order.totalAmount)} ₫',
              valueStyle: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(),
              maxLines: maxLines,
              overflow: overflow,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'shipping':
        return Colors.green;
      case 'delivered':
        return Colors.deepOrange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return "Đang chờ xác nhận";
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _formatPrice(double price) {
    return NumberFormat('#,###').format(price);
  }
}
