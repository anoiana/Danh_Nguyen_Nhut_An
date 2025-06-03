class Product {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String description;
  final List<String> images;
  // final List<dynamic> variants;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.images,
    required this.brand,
    required this.description,
    // required this.variants
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data["name"] ?? "Không có tên",
      category: data["category"] ?? "Không có danh mục",
      images: List<String>.from(data["image"] ?? []),
      brand: data["brand"] ?? "Chưa có brand",
      description: data["description"] ?? "Chưa có mo ta",
      // variants: List<dynamic>.from(data["variants"] ?? []),
    );
  }
}
