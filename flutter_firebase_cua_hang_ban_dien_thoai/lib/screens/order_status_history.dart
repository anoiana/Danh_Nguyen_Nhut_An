import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/models/order_item.dart';

class OrderStatusHistory {
  final String status;
  final DateTime timestamp;

  OrderStatusHistory({required this.status, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {status: Timestamp.fromDate(timestamp)};
  }

  factory OrderStatusHistory.fromMap(String status, Timestamp timestamp) {
    return OrderStatusHistory(status: status, timestamp: timestamp.toDate());
  }
}

class Order {
  final String id;
  final String userId;
  final String orderStatus;
  final List<OrderStatusHistory> statusHistory;
  final List<OrderItem> productIds;
  final double totalAmount;
  final double shippingFee;
  final String shippingAddress;
  final String paymentMethod;
  final String? couponCode;
  final DateTime purchaseDate;
  final int numberOfProducts;

  Order({
    required this.id,
    required this.userId,
    required this.orderStatus,
    required this.statusHistory,
    required this.totalAmount,
    required this.shippingFee,
    required this.shippingAddress,
    required this.paymentMethod,
    this.couponCode,
    required this.purchaseDate,
    required this.numberOfProducts,
    required this.productIds,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    List<OrderStatusHistory> statusHistoryList = [];
    List<OrderItem> productList = [];
    if (map['statusHistory'] != null) {
      final statusMap = map['statusHistory'] as Map<String, dynamic>;
      statusHistoryList =
          statusMap.entries.map((entry) {
            return OrderStatusHistory.fromMap(
              entry.key,
              entry.value as Timestamp,
            );
          }).toList();
      statusHistoryList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return Order(
      id: id,
      userId: map['userId'] ?? '',
      orderStatus: map['orderStatus'] ?? '',
      statusHistory: statusHistoryList,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0).toDouble(),
      shippingAddress: map['shippingAddress'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      couponCode: map['couponCode'],
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      numberOfProducts: map['numberOfProducts'] ?? 0,
      productIds: productList,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> statusHistoryMap = {};
    for (var status in statusHistory) {
      statusHistoryMap[status.status] = Timestamp.fromDate(status.timestamp);
    }

    return {
      'userId': userId,
      'orderStatus': orderStatus,
      'statusHistory': statusHistoryMap,
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'numberOfProducts': numberOfProducts,
    };
  }
}
