class Item {
  final String productId; // Add id
  final int indexVariant;
  final String name;
  final String image;
  final String? variantId;
  final double price;
  int quantity;
  bool selected;
  final String color;
  final String performance;
  final double? discountedPrice;

  Item({
    required this.productId,
    required this.indexVariant,
    required this.name,
    required this.variantId,
    required this.image,
    required this.price,
    required this.color,
    this.quantity = 1,
    this.selected = false,
    this.discountedPrice,
    required this.performance,
  });
}