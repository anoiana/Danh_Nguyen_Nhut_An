import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  final String status;
  final DateTime timestamp;

  OrderStatus({required this.status, required this.timestamp});

  factory OrderStatus.fromMap(Map<String, dynamic> map) {
    return OrderStatus(
      status: map['status'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status, 'timestamp': Timestamp.fromDate(timestamp)};
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderStatus> statusHistory;
  final String orderStatus;
  final String paymentMethod;
  final List<Map<String, dynamic>> productIds;
  final String shippingAddress;
  final double shippingFee;
  final double totalAmount;
  final DateTime purchaseDate;
  final int numberOfProducts;
  final String? couponCode;

  Order({
    required this.id,
    required this.userId,
    required this.statusHistory,
    required this.orderStatus,
    required this.paymentMethod,
    required this.productIds,
    required this.shippingAddress,
    required this.shippingFee,
    required this.totalAmount,
    required this.purchaseDate,
    required this.numberOfProducts,
    this.couponCode,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    List<OrderStatus> statusHistory = [];
    if (map['statusHistory'] != null) {
      final historyMap = map['statusHistory'] as Map<String, dynamic>;
      statusHistory =
          historyMap.entries
              .map(
                (e) => OrderStatus(
                  status: e.key,
                  timestamp: (e.value as Timestamp).toDate(),
                ),
              )
              .toList();
      statusHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return Order(
      id: id,
      userId: map['userId'] as String,
      statusHistory: statusHistory,
      orderStatus: map['orderStatus'] as String,
      paymentMethod: map['paymentMethod'] as String,
      productIds: List<Map<String, dynamic>>.from(map['productIds'] ?? []),
      shippingAddress: map['shippingAddress'] as String,
      shippingFee: (map['shippingFee'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      numberOfProducts: map['numberOfProducts'] as int,
      couponCode: map['couponCode'] as String?,
    );
  }
}
