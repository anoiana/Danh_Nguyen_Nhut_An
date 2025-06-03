import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_status.dart' as models;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy tất cả đơn hàng của một user
  // Stream<List<models.Order>> getUserOrders(String userId) {
  //   return _firestore
  //       .collection('orders')
  //       .where('userId', isEqualTo: userId)
  //       .orderBy('purchaseDate', descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs
  //             .map((doc) => models.Order.fromMap(doc.data(), doc.id))
  //             .toList();
  //       });
  // }

  Stream<List<models.Order>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => models.Order.fromMap(doc.data(), doc.id))
              .toList()
            ..sort(
              (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
            ); // Sắp xếp trong ứng dụng
        });
  }

  // Lấy chi tiết một đơn hàng
  Future<models.Order?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return models.Order.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw Exception('Đơn hàng không tồn tại');
      }

      final currentData = orderDoc.data()!;
      final statusHistory = Map<String, dynamic>.from(
        currentData['statusHistory'] as Map<String, dynamic>? ?? {},
      );

      // Thêm trạng thái mới vào lịch sử
      statusHistory[newStatus] = Timestamp.now();

      transaction.update(orderRef, {
        'orderStatus': newStatus,
        'statusHistory': statusHistory,
      });
    });
  }

  // Hủy đơn hàng
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await updateOrderStatus(orderId, 'cancelled');
  }
}
