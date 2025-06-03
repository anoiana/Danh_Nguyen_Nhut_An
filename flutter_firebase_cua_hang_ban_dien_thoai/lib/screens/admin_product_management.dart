import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/models/product.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_add_product.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_update_product.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_view_product_detail.dart';
import 'package:cross_platform_mobile_app_development/widgets/tab_item.dart';
import 'package:flutter/material.dart';
import '../widgets/base64_image.dart';
import 'admin_add_discount_for_product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final List<String> tabTitles = [
    "Laptops",
    "Monitors",
    "Keyboards",
    "Hard Drivers",
    "Mouse",
  ];
  final List<String> firebaseCategories = [
    "Laptop",
    "Monitor",
    "Keyboard",
    "Hard Drivers",
    "Mouse",
  ];
  String _selectedCategory = "Laptop";
  String searchQuery = "";
  final Map<String, Future<int>> _productDiscountCache = {};

  void _deleteProduct(String productId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: const Text(
                "Bạn có chắc chắn muốn xóa sản phẩm này không?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('product')
          .doc(productId)
          .delete();
      await FirebaseFirestore.instance
          .collection('variants')
          .where('productId', isEqualTo: productId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sản phẩm và variants đã bị xóa")));
      _productDiscountCache.remove(productId);
    }
  }

  void _editProduct(QueryDocumentSnapshot productSnapshot) {
    var data = productSnapshot.data() as Map<String, dynamic>;
    Product product = Product.fromFirestore(data, productSnapshot.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UpdateProduct(
              product: product,
              selectedCategory: _selectedCategory,
            ),
      ),
    ).then((result) {
      if (mounted && result != null &&
          result == "Product updated successfully") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Sản phẩm đã cập nhật thành công!")),
        );
        _productDiscountCache.remove(productSnapshot.id);
      }
    });
  }

  void _addDiscountForProduct(QueryDocumentSnapshot productSnapshot,
      bool isEditing) {
    var data = productSnapshot.data() as Map<String, dynamic>;
    Product product = Product.fromFirestore(data, productSnapshot.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddDiscountForProduct(product: product, isEditing: isEditing),
      ),
    ).then((result) {
      _productDiscountCache.remove(productSnapshot.id);
    });
  }

  Widget buildProductImage(String imageUrl) {
    if (imageUrl.startsWith("data:image")) {
      return Base64ImageWidget(base64String: imageUrl);
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    }
  }

  Future<void> _removeExpiredDiscounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('variants')
        .get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('discountExpiry')) {
        final expiry = DateTime.tryParse(data['discountExpiry']);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          Map<String, dynamic> updateData = {
            'discountPercentage': FieldValue.delete(),
            'discountedPrice': FieldValue.delete(),
            'discountDuration': FieldValue.delete(),
            'discountExpiry': FieldValue.delete(),
            'createdAt': FieldValue.delete(),
          };
          await FirebaseFirestore.instance
              .collection("variants")
              .doc(doc.id)
              .update(updateData);
          final productId = data['productId'];
          _productDiscountCache.remove(productId);
        }
      }
    }
  }

  Future<int> _getMaxVariantDiscount(String productId) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('variants')
          .where('productId', isEqualTo: productId)
          .get();

      print("Checking discount for product: $productId");
      print("Variants found: ${snapshot.docs.length}");

      int maxDiscount = 0;
      DateTime now = DateTime(
          2025, 5, 15, 21, 46); // 09:46 PM +07, May 15, 2025

      for (var doc in snapshot.docs) {
        var variantData = doc.data();
        print("Variant: ${doc.id}, Data: $variantData");

        if (variantData.containsKey("discountPercentage") &&
            variantData.containsKey("discountExpiry")) {
          String? expiryStr = variantData["discountExpiry"]?.toString();
          DateTime? expiry = expiryStr != null
              ? DateTime.tryParse(expiryStr)
              : null;
          print("Parsed expiry: $expiry, Current time: $now");

          if (expiry != null && expiry.isAfter(now)) {
            num? discountValue = variantData["discountPercentage"] as num?;
            int discount = discountValue != null ? discountValue.round() : 0;
            print("Discount: $discount, Max so far: $maxDiscount");
            if (discount > maxDiscount) {
              maxDiscount = discount;
            }
          } else {
            print("Discount expired or invalid expiry for variant: ${doc.id}");
          }
        } else {
          print("Missing discount fields in variant: ${doc.id}");
        }
      }

      print("Final max discount for product $productId: $maxDiscount");
      return maxDiscount;
    } catch (e) {
      print("Error fetching discount for product $productId: $e");
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _removeExpiredDiscounts();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabTitles.length,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: Colors.black12,
                  ),
                  child: TabBar(
                    onTap: (index) {
                      setState(() {
                        _selectedCategory = firebaseCategories[index];
                        _productDiscountCache.clear();
                      });
                    },
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: List.generate(tabTitles.length, (index) {
                      return TabItem(title: tabTitles[index], count: index + 1);
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 8),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: Icon(
                                  Icons.search, color: Color(0xFFDB3022)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Color(0xFFDB3022), width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 5.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddProduct(category: _selectedCategory),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Color(0xFFDB3022)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine maxCrossAxisExtent based on platform and available width
                    double maxCrossAxisExtent;
                    if (kIsWeb) {
                      if (constraints.maxWidth > 1200) {
                        maxCrossAxisExtent =
                            constraints.maxWidth / 4; // Approx 4 items
                      } else if (constraints.maxWidth > 800) {
                        maxCrossAxisExtent =
                            constraints.maxWidth / 3; // Approx 3 items
                      } else {
                        maxCrossAxisExtent =
                            constraints.maxWidth / 2; // Approx 2 items
                      }
                    } else {
                      maxCrossAxisExtent =
                          constraints.maxWidth / 2; // Mobile: 2 items
                    }

                    return StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('product')
                          .where('category', isEqualTo: _selectedCategory)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("Không có sản phẩm nào"));
                        }
                        var products = snapshot.data!.docs;
                        var filteredProducts = products.where((doc) {
                          var product = doc.data() as Map<String, dynamic>;
                          var productName = (product["name"] ?? "")
                              .toLowerCase();
                          return productName.contains(searchQuery);
                        }).toList();

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxCrossAxisExtent,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            var productDoc = filteredProducts[index];
                            var product = productDoc.data() as Map<
                                String,
                                dynamic>;
                            product['id'] = productDoc.id;

                            if (!_productDiscountCache.containsKey(
                                productDoc.id)) {
                              _productDiscountCache[productDoc.id] =
                                  _getMaxVariantDiscount(productDoc.id);
                            }
                            Future<
                                int> maxDiscount = _productDiscountCache[productDoc
                                .id]!;

                            List<dynamic>? images = product["image"];
                            String imageUrl = (images != null &&
                                images.isNotEmpty)
                                ? images[0]
                                : "https://via.placeholder.com/150";

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ViewProductDetail(
                                          product: product,
                                        ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius
                                                  .vertical(
                                                  top: Radius.circular(10)),
                                              child: buildProductImage(
                                                  imageUrl),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product["name"] ??
                                                        "Không có tên",
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight
                                                            .bold),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                                FutureBuilder<int>(
                                                  future: maxDiscount,
                                                  builder: (context, snapshot) {
                                                    bool hasDiscount = snapshot
                                                        .hasData &&
                                                        snapshot.data! > 0;
                                                    return PopupMenuButton<
                                                        String>(
                                                      onSelected: (value) {
                                                        if (value == "edit") {
                                                          _editProduct(
                                                              productDoc);
                                                        } else
                                                        if (value == "delete") {
                                                          _deleteProduct(
                                                              productDoc.id);
                                                        } else if (value ==
                                                            "add discount") {
                                                          _addDiscountForProduct(
                                                              productDoc,
                                                              hasDiscount);
                                                        }
                                                      },
                                                      itemBuilder: (context) {
                                                        return [
                                                          const PopupMenuItem(
                                                            value: "edit",
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.edit,
                                                                    color: Colors
                                                                        .blue),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                    "Edit product"),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: "add discount",
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons
                                                                    .local_offer,
                                                                    color: Colors
                                                                        .red),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(hasDiscount
                                                                    ? "Edit discount"
                                                                    : "Add discount"),
                                                              ],
                                                            ),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: "delete",
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons
                                                                    .delete,
                                                                    color: Colors
                                                                        .red),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                    "Delete product"),
                                                              ],
                                                            ),
                                                          ),
                                                        ];
                                                      },
                                                      icon: const Icon(
                                                          Icons.more_vert),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  FutureBuilder<int>(
                                    future: maxDiscount,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox();
                                      }
                                      if (snapshot.hasError) {
                                        print(
                                            "Error fetching discount for product ${product['id']}: ${snapshot
                                                .error}");
                                        return const SizedBox();
                                      }
                                      if (snapshot.hasData) {
                                        final discount = snapshot.data!;
                                        if (discount > 0) {
                                          return Positioned(
                                            top: 0,
                                            left: 0,
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: const BorderRadius
                                                    .only(
                                                  topLeft: Radius.circular(10),
                                                  bottomRight: Radius.circular(
                                                      10),
                                                ),
                                              ),
                                              child: Text(
                                                "-$discount%",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}