class OrderItem {
  final String variantId;
  final int quantity;
  final double price;

  OrderItem({
    required this.variantId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {'variantId': variantId, 'quantity': quantity, 'price': price};
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      variantId: map['variantId'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
