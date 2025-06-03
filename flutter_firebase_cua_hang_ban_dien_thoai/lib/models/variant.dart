class Variant {
  final String id;
  final String productId;
  final String color;
  final String performance;
  final int importPrice;
  final int sellingPrice;
  final double discountPercentage;
  final DateTime discountExpiry;
  final DateTime createdAt;
  final int stock;
  final String image;

  Variant({
    required this.id,
    required this.productId,
    required this.color,
    required this.performance,
    required this.importPrice,
    required this.sellingPrice,
    required this.discountPercentage,
    required this.discountExpiry,
    required this.createdAt,
    required this.stock,
    required this.image,
  });

  factory Variant.fromFirestore(Map<String, dynamic> data, String id) {
    return Variant(
      id: id,
      productId: data["productId"] ?? "",
      color: data["color"] ?? "Không có màu",
      performance: data["performance"] ?? "Không có thông số",
      importPrice: data["importPrice"] ?? 0,
      sellingPrice: data["sellingPrice"] ?? 0,
      discountPercentage: (data["discountPercentage"] ?? 0).toDouble(),
      discountExpiry: DateTime.parse(data["discountExpiry"]),
      createdAt: DateTime.parse(data["createdAt"]),
      stock: data["stock"] ?? 0,
      image: data["image"] ?? "",
    );
  }

  double get discountedPrice {
    return sellingPrice * (1 - discountPercentage / 100);
  }
}
