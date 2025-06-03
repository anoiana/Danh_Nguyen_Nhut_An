import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cross_platform_mobile_app_development/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:cross_platform_mobile_app_development/widgets/filter_sheet.dart';
import 'package:cross_platform_mobile_app_development/screens/product_detail.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_product.dart';
import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class ProductCatalog extends StatefulWidget {
  final String title;
  final String category;
  final String filterType;
  const ProductCatalog({
    Key? key,
    required this.title,
    required this.category,
    required this.filterType,
  }) : super(key: key);

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  @override
  Widget build(BuildContext context) {
    return ProductCatalogPage(
      title: widget.title,
      category: widget.category,
      filterType: widget.filterType,
    );
  }
}

class ProductCatalogPage extends StatefulWidget {
  final String title;
  final String category;
  final String filterType;

  const ProductCatalogPage({
    Key? key,
    required this.title,
    required this.category,
    required this.filterType,
  }) : super(key: key);

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

enum SortCriteria { nameAZ, nameZA, priceLowToHigh, priceHighToLow }

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  String searchQuery = "";
  SortCriteria? sortCriteria;
  double selectedMinPrice = 0;
  double selectedMaxPrice = double.infinity;
  List<String> selectedColors = [];
  List<String> selectedBrands = [];
  bool isFilterApplied = false;
  String uid = "unknown";
  Map<String, List<Map<String, dynamic>>> productVariants = {};
  int cartItemCount = 0;

  // Phân trang
  final int _limit = 10; // Số sản phẩm mỗi trang
  List<QueryDocumentSnapshot> products = [];
  DocumentSnapshot? lastDocument; // Để theo dõi tài liệu cuối cùng của trang trước
  bool isLoading = false;
  bool hasMore = true; // Kiểm tra xem còn dữ liệu để tải không
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrentUser();
      loadCartItemCount();
      _loadProducts(); // Tải trang đầu tiên
    });

    // Lắng nghe sự kiện cuộn để tải thêm
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        _loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadCartItemCount() async {
    if (uid == 'unknown') {
      final prefs = await SharedPreferences.getInstance();
      List<String> guestCartString = prefs.getStringList('guestCart') ?? [];
      if (mounted) setState(() {
        cartItemCount = guestCartString.map((item) => jsonDecode(item)['quantity'] as int? ?? 0).fold(0, (a, b) => a + b);
      });
    } else {
      final cartDoc = await FirebaseFirestore.instance.collection('cart').doc(uid).get();
      if (cartDoc.exists) {
        List<dynamic> productIds = cartDoc.data()?['productIds'] ?? [];
        if (mounted) setState(() {
          cartItemCount = productIds.map((item) => item['quantity'] as int? ?? 0).fold(0, (a, b) => a + b);
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    if (isLoading || !hasMore) return;

    if (mounted) setState(() {
      isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('product')
          .where('category', isEqualTo: widget.category)
          .limit(_limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      // Sắp xếp trên server nếu có tiêu chí
      if (sortCriteria != null) {
        switch (sortCriteria) {
          case SortCriteria.nameAZ:
            query = query.orderBy('name', descending: false);
            break;
          case SortCriteria.nameZA:
            query = query.orderBy('name', descending: true);
            break;
          case SortCriteria.priceLowToHigh:
            query = query.orderBy('sellingPrice', descending: false);
            break;
          case SortCriteria.priceHighToLow:
            query = query.orderBy('sellingPrice', descending: true);
            break;
          default:
            break;
        }
      }

      final snapshot = await query.get();
      final newProducts = snapshot.docs;

      if (newProducts.isEmpty) {
        if (mounted) setState(() {
          hasMore = false;
          isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      Map<String, Map<String, dynamic>> variantData = {};

      for (var product in newProducts) {
        final productId = product.id;
        final productData = product.data() as Map<String, dynamic>;
        final variants = await fetchVariants(productId);
        variantData[productId] = processVariants(variants, now, productData);
      }

      if (mounted) setState(() {
        products.addAll(newProducts);
        lastDocument = newProducts.last;
        hasMore = newProducts.length == _limit;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading products: $e");
      if (mounted) setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> getProductIdsWithActiveDiscount() async {
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('variants')
          .where('discountPercentage', isGreaterThan: 0)
          .get();

      final productIds = snapshot.docs
          .map((doc) => doc.data()['productId']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      print('Active discount product IDs: $productIds');
      return productIds;
    } catch (e) {
      print('Error fetching active discount product IDs: $e');
      return [];
    }
  }

  List<QueryDocumentSnapshot> sortProducts(List<QueryDocumentSnapshot> products, Map<String, Map<String, dynamic>> variantData) {
    if (sortCriteria == null) return products;

    return List<QueryDocumentSnapshot>.from(products)
      ..sort((a, b) {
        var dataA = a.data() as Map<String, dynamic>;
        var dataB = b.data() as Map<String, dynamic>;
        final variantDataA = variantData[a.id] ?? {'lowestPrice': dataA['sellingPrice'] ?? 0};
        final variantDataB = variantData[b.id] ?? {'lowestPrice': dataB['sellingPrice'] ?? 0};

        switch (sortCriteria) {
          case SortCriteria.nameAZ:
            return dataA['name'].toString().toLowerCase().compareTo(dataB['name'].toString().toLowerCase());
          case SortCriteria.nameZA:
            return dataB['name'].toString().toLowerCase().compareTo(dataA['name'].toString().toLowerCase());
          case SortCriteria.priceLowToHigh:
            return (variantDataA['lowestPrice'] as num).compareTo(variantDataB['lowestPrice']);
          case SortCriteria.priceHighToLow:
            return (variantDataB['lowestPrice'] as num).compareTo(variantDataA['lowestPrice']);
          default:
            return 0;
        }
      });
  }

  Future<List<String>> getTopBestSellerProductIds(String category) async {
    try {
      // Step 1: Fetch all product IDs in the category
      final productSnapshot = await FirebaseFirestore.instance
          .collection('product')
          .where('category', isEqualTo: category)
          .get();
      final productIds = productSnapshot.docs.map((doc) => doc.id).toList();
      print('Products in category $category: $productIds');

      // Step 2: Fetch all variants and map variantId to productId
      final allVariants = await FirebaseFirestore.instance
          .collection('variants')
          .get();
      final variantMap = {for (var doc in allVariants.docs) doc.id: doc.data()['productId'] as String};

      // Step 3: Fetch all orders and calculate total sales
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      Map<String, int> variantSales = {}; // variantId -> total quantity sold
      for (var doc in orderSnapshot.docs) {
        final productIdsData = doc.data()['productIds'] as List<dynamic>? ?? [];
        for (var product in productIdsData) {
          if (product is Map<String, dynamic>) {
            final variantId = product['variantId'] as String?;
            final quantity = (product['quantity'] as num?)?.toInt() ?? 0;
            if (variantId != null) {
              variantSales[variantId] = (variantSales[variantId] ?? 0) + quantity;
              print('Variant $variantId sold $quantity units');
            }
          }
        }
      }

      // Step 4: Map variant sales to product sales
      Map<String, int> productSales = {}; // productId -> total quantity sold
      for (var entry in variantSales.entries) {
        final variantId = entry.key;
        final quantity = entry.value;
        final productId = variantMap[variantId];
        if (productId != null) {
          productSales[productId] = (productSales[productId] ?? 0) + quantity;
          print('Product $productId total sales: ${productSales[productId]}');
        }
      }

      // Step 5: Sort by sales and get top 5 unique products
      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<String> topProductIds = [];
      Set<String> uniqueProducts = {};

      for (var entry in sortedProducts) {
        if (topProductIds.length >= 5) break;
        if (!uniqueProducts.contains(entry.key)) {
          topProductIds.add(entry.key);
          uniqueProducts.add(entry.key);
        }
      }

      print('Top best seller product IDs for category $category: $topProductIds');
      return topProductIds;
    } catch (e) {
      print('Error fetching best seller product IDs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchVariants(String productId) async {
    if (productVariants.containsKey(productId)) {
      return productVariants[productId]!;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('variants')
        .where('productId', isEqualTo: productId)
        .get();

    final variants = snapshot.docs.map((doc) => doc.data()).toList();
    if (mounted) setState(() {
      productVariants[productId] = variants;
    });
    return variants;
  }

  Map<String, dynamic> processVariants(List<Map<String, dynamic>> variants, DateTime now, Map<String, dynamic> productData) {
    double lowestPrice = double.infinity;
    double originalPrice = double.infinity;
    int highestDiscount = 0;
    DateTime? latestExpiry;

    if (variants.isEmpty) {
      final productPrice = (productData['sellingPrice'] as num?)?.toDouble() ?? 0;
      return {
        'lowestPrice': productPrice,
        'originalPrice': productPrice,
        'highestDiscount': 0,
        'discountExpiry': null,
        'isDiscountActive': false,
      };
    }

    for (var variant in variants) {
      final sellingPrice = (variant['sellingPrice'] as num?)?.toDouble() ?? 0;
      final discount = (variant['discountPercentage'] as num?)?.toInt() ?? 0;
      final discountDuration = (variant['discountDuration'] as num?)?.toInt() ?? 0;
      final expiryStr = variant['discountExpiry']?.toString();
      DateTime? expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

      double effectivePrice = sellingPrice;
      if (discount > 0 && discountDuration > 0 && expiry != null && now.isBefore(expiry)) {
        effectivePrice = sellingPrice * (1 - discount / 100);
      }

      lowestPrice = lowestPrice < effectivePrice ? lowestPrice : effectivePrice;
      originalPrice = originalPrice < sellingPrice ? originalPrice : sellingPrice;

      if (discount > highestDiscount) {
        highestDiscount = discount;
      }

      if (expiry != null && (latestExpiry == null || expiry.isAfter(latestExpiry))) {
        latestExpiry = expiry;
      }
    }

    final isDiscountActive = highestDiscount > 0 && latestExpiry != null && now.isBefore(latestExpiry);

    if (lowestPrice == double.infinity) {
      lowestPrice = originalPrice == double.infinity ? (productData['sellingPrice'] as num?)?.toDouble() ?? 0 : originalPrice;
    }
    if (originalPrice == double.infinity) {
      originalPrice = (productData['sellingPrice'] as num?)?.toDouble() ?? 0;
    }

    return {
      'lowestPrice': lowestPrice,
      'originalPrice': originalPrice,
      'highestDiscount': highestDiscount,
      'discountExpiry': latestExpiry,
      'isDiscountActive': isDiscountActive,
    };
  }

  List<QueryDocumentSnapshot> filterAndSortProducts(List<QueryDocumentSnapshot> products, Map<String, Map<String, dynamic>> variantData) {
    final now = DateTime.now();
    List<QueryDocumentSnapshot> filteredProducts = List.from(products);

    // Lọc theo filterType
    if (widget.filterType == 'promotion') {
      filteredProducts = filteredProducts.where((product) {
        final data = variantData[product.id];
        return data?['isDiscountActive'] ?? false;
      }).toList();
    } else if (widget.filterType == 'new') {
      filteredProducts = filteredProducts.where((product) {
        final data = product.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'];
        if (createdAt == null) return false;

        DateTime? createdDate;
        if (createdAt is Timestamp) {
          createdDate = createdAt.toDate();
        } else {
          createdDate = DateTime.tryParse(createdAt.toString());
        }

        return createdDate != null && now.difference(createdDate).inDays <= 7;
      }).toList();
    }

    // Lọc theo searchQuery
    filteredProducts = filteredProducts.where((product) {
      var data = product.data() as Map<String, dynamic>;
      var name = (data['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery);
    }).toList();

    // Lọc theo bộ lọc giá, màu sắc, thương hiệu
    if (isFilterApplied) {
      filteredProducts = filteredProducts.where((product) {
        final data = variantData[product.id];
        final price = data?['lowestPrice'] as num? ?? 0;
        return price >= selectedMinPrice && price <= selectedMaxPrice;
      }).toList();

      if (selectedColors.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          final variants = productVariants[product.id] ?? [];
          if (variants.isEmpty) {
            final productData = product.data() as Map<String, dynamic>;
            var productColor = (productData['color'] ?? '').toString().toLowerCase();
            return selectedColors.any((color) => color.toLowerCase() == productColor);
          }
          return variants.any((variant) {
            var productColor = (variant['color'] ?? '').toString().toLowerCase();
            return selectedColors.any((color) => color.toLowerCase() == productColor);
          });
        }).toList();
      }

      if (selectedBrands.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          final variants = productVariants[product.id] ?? [];
          if (variants.isEmpty) {
            final productData = product.data() as Map<String, dynamic>;
            var productBrand = (productData['brand'] ?? '').toString().toLowerCase();
            return selectedBrands.any((brand) => brand.toLowerCase() == productBrand);
          }
          return variants.any((variant) {
            var productBrand = (variant['brand'] ?? '').toString().toLowerCase();
            return selectedBrands.any((brand) => brand.toLowerCase() == productBrand);
          });
        }).toList();
      }
    }

    // Nếu đã sắp xếp trên server, không cần sắp xếp lại ở client
    if (sortCriteria == null || sortCriteria == SortCriteria.nameAZ || sortCriteria == SortCriteria.nameZA || sortCriteria == SortCriteria.priceLowToHigh || sortCriteria == SortCriteria.priceHighToLow) {
      return filteredProducts;
    }

    return filteredProducts;
  }

  void getCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) setState(() {
      uid = currentUser?.uid ?? 'unknown';
    });
  }

  Widget _buildProductImage(dynamic imageData) {
    const placeholderUrl = 'https://via.placeholder.com/150';

    if (imageData == null || (imageData is List && imageData.isEmpty)) {
      return Image.network(
        placeholderUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }

    final image = imageData is List ? imageData[0] : imageData;

    if (image is String && image.startsWith('data:image')) {
      try {
        final base64String = image.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error);
          },
        );
      } catch (e) {
        return Image.network(
          placeholderUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        );
      }
    }

    if (image is String && Uri.tryParse(image)?.hasScheme == true) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error);
        },
      );
    }

    if (!kIsWeb && image is String && File(image).existsSync()) {
      return Image.file(
        File(image),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error);
        },
      );
    }

    return Image.network(
      placeholderUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );
  }

  Future<void> _resetAndLoadProducts() async {
    if (mounted) setState(() {
      products.clear();
      lastDocument = null;
      hasMore = true;
      isLoading = false;
    });
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final filterType = widget.filterType;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColor.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  getCurrentUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(userId: uid),
                    ),
                  ).then((_) {
                    loadCartItemCount();
                  });
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          if (constraints.maxWidth >= 1500) {
            crossAxisCount = 5;
          } else if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 900) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 2;
          }

          double childAspectRatio = 0.7;
          if (kIsWeb) {
            if (crossAxisCount >= 4) {
              childAspectRatio = 0.8;
            } else if (crossAxisCount == 3) {
              childAspectRatio = 0.75;
            } else {
              childAspectRatio = 0.7;
            }
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kIsWeb && constraints.maxWidth > 800 ? 24.0 : 10.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                          _resetAndLoadProducts(); // Reset và tải lại khi tìm kiếm
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFDB3022),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
                            borderSide: const BorderSide(color: Color(0xFFDB3022), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.black),
                      tooltip: "Filter products",
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          constraints: kIsWeb && constraints.maxWidth > 600
                              ? BoxConstraints(maxWidth: constraints.maxWidth * 0.5, maxHeight: constraints.maxHeight * 0.8)
                              : BoxConstraints(maxHeight: constraints.maxHeight * 0.8),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => FilterSheet(
                            initialCategory: widget.category,
                            onApplyFilter: (min, max, colors, brands) {
                              setState(() {
                                selectedMinPrice = min;
                                selectedMaxPrice = max == 1000000000 ? double.infinity : max;
                                selectedColors = colors;
                                selectedBrands = brands;
                                isFilterApplied = true;
                              });
                              _resetAndLoadProducts(); // Reset và tải lại khi áp dụng bộ lọc
                            },
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<SortCriteria>(
                      icon: const Icon(Icons.swap_vert, color: Colors.black),
                      tooltip: "Sort products",
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
                      ),
                      onSelected: (SortCriteria selected) {
                        setState(() {
                          sortCriteria = selected;
                        });
                        _resetAndLoadProducts(); // Reset và tải lại khi thay đổi sắp xếp
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: SortCriteria.nameAZ, child: Text("📖 Name (A-Z)")),
                        const PopupMenuItem(value: SortCriteria.nameZA, child: Text("📖 Name (Z-A)")),
                        const PopupMenuItem(value: SortCriteria.priceLowToHigh, child: Text("💰 Ascending price")),
                        const PopupMenuItem(value: SortCriteria.priceHighToLow, child: Text("💰 Descending price")),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: filterType == 'promotion_active_discount' || filterType == 'promotion'
                      ? getProductIdsWithActiveDiscount()
                      : filterType == 'bestseller'
                      ? getTopBestSellerProductIds(widget.category)
                      : Future.value([]),
                  builder: (context, futureSnapshot) {
                    if ((filterType == 'promotion_active_discount' || filterType == 'promotion' || filterType == 'bestseller') &&
                        futureSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<String> filterProductIds = futureSnapshot.data ?? [];
                    print('Filter product IDs for $filterType: $filterProductIds');

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('product')
                          .where('category', isEqualTo: widget.category)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          print('No products found for category: ${widget.category}');
                          return const Center(child: Text('No products available'));
                        }

                        var products = snapshot.data!.docs;
                        print('Total products before filtering: ${products.length}');

                        final now = DateTime.now();

                        return FutureBuilder<Map<String, Map<String, dynamic>>>(
                          future: () async {
                            Map<String, Map<String, dynamic>> variantData = {};
                            for (var product in products) {
                              final productId = product.id;
                              final productData = product.data() as Map<String, dynamic>;
                              final variants = await fetchVariants(productId);
                              variantData[productId] = processVariants(variants, now, productData);
                            }
                            return variantData;
                          }(),
                          builder: (context, variantSnapshot) {
                            if (variantSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!variantSnapshot.hasData) {
                              print('Error loading variants');
                              return const Center(child: Text('Error loading variants'));
                            }

                            final variantData = variantSnapshot.data!;
                            print('Variant data loaded for products: ${variantData.keys.length}');

                            // Apply filters
                            if (filterType == 'promotion' || filterType == 'promotion_active_discount' || filterType == 'bestseller') {
                              products = products.where((product) {
                                final isInFilter = filterProductIds.contains(product.id);
                                print('Product ${product.id} in bestseller filter: $isInFilter');
                                return isInFilter;
                              }).toList();
                              print('Products after $filterType filter: ${products.length}');
                            } else if (filterType == 'new') {
                              products = products.where((product) {
                                final data = product.data() as Map<String, dynamic>;
                                final createdAt = data['createdAt'];
                                if (createdAt == null) return false;

                                DateTime? createdDate;
                                if (createdAt is Timestamp) {
                                  createdDate = createdAt.toDate();
                                } else {
                                  createdDate = DateTime.tryParse(createdAt.toString());
                                }

                                return createdDate != null && now.difference(createdDate).inDays <= 7;
                              }).toList();
                              print('Products after new filter: ${products.length}');
                            }

                            products = products.where((product) {
                              var data = product.data() as Map<String, dynamic>;
                              var name = (data['name'] ?? '').toString().toLowerCase();
                              return name.contains(searchQuery);
                            }).toList();
                            print('Products after search filter: ${products.length}');

                            if (isFilterApplied) {
                              products = products.where((product) {
                                final data = variantData[product.id];
                                final price = data?['lowestPrice'] as num? ?? 0;
                                return price >= selectedMinPrice && price <= selectedMaxPrice;
                              }).toList();
                              print('Products after price filter: ${products.length}');

                              if (selectedColors.isNotEmpty) {
                                products = products.where((product) {
                                  final variants = productVariants[product.id] ?? [];
                                  if (variants.isEmpty) {
                                    final productData = product.data() as Map<String, dynamic>;
                                    var productColor = (productData['color'] ?? '').toString().toLowerCase();
                                    return selectedColors.any((color) => color.toLowerCase() == productColor);
                                  }
                                  return variants.any((variant) {
                                    var productColor = (variant['color'] ?? '').toString().toLowerCase();
                                    return selectedColors.any((color) => color.toLowerCase() == productColor);
                                  });
                                }).toList();
                                print('Products after color filter: ${products.length}');
                              }

                              if (selectedBrands.isNotEmpty) {
                                products = products.where((product) {
                                  final variants = productVariants[product.id] ?? [];
                                  if (variants.isEmpty) {
                                    final productData = product.data() as Map<String, dynamic>;
                                    var productBrand = (productData['brand'] ?? '').toString().toLowerCase();
                                    return selectedBrands.any((brand) => brand.toLowerCase() == productBrand);
                                  }
                                  return variants.any((variant) {
                                    var productBrand = (variant['brand'] ?? '').toString().toLowerCase();
                                    return selectedBrands.any((brand) => brand.toLowerCase() == productBrand);
                                  });
                                }).toList();
                                print('Products after brand filter: ${products.length}');
                              }
                            }

                            products = sortProducts(products, variantData);
                            print('Final products after sorting: ${products.length}');

                            if (products.isEmpty && (filterType == 'promotion' || filterType == 'promotion_active_discount' || filterType == 'bestseller')) {
                              return Center(child: Text('No $filterType products available'));
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(8.0),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final productData = product.data() as Map<String, dynamic>;
                                final Map<String, dynamic> productWithId = {
                                  ...productData,
                                  'id': product.id,
                                };
                                final variantInfo = variantData[product.id] ?? {
                                  'lowestPrice': productData['sellingPrice'] ?? 0,
                                  'originalPrice': productData['sellingPrice'] ?? 0,
                                  'highestDiscount': 0,
                                  'discountExpiry': null,
                                  'isDiscountActive': false,
                                };

                                final lowestPrice = variantInfo['lowestPrice'] as double;
                                final originalPrice = variantInfo['originalPrice'] as double;
                                final highestDiscount = variantInfo['highestDiscount'] as int;
                                final discountExpiry = variantInfo['discountExpiry'] as DateTime?;
                                final isDiscountActive = variantInfo['isDiscountActive'] as bool;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsScreen(product: productWithId),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Card(
                                        color: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                                child: _buildProductImage(productData['image']),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                productData['name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(
                                                productData['description'] ?? '',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                              child: isDiscountActive
                                                  ? Row(
                                                children: [
                                                  Text(
                                                    formatPrice(lowestPrice),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    formatPrice(originalPrice),
                                                    style: const TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              )
                                                  : Text(
                                                lowestPrice > 0
                                                    ? formatPrice(lowestPrice)
                                                    : 'Price unavailable',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isDiscountActive)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.deepOrange, Colors.orangeAccent],
                                              ),
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '-$highestDiscount%',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                                                    const SizedBox(width: 2),
                                                    const Text(
                                                      "Flash sale",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                CountdownTimer(
                                                  endTime: discountExpiry!.millisecondsSinceEpoch,
                                                  widgetBuilder: (_, time) {
                                                    if (time == null) {
                                                      return const Text(
                                                        "Đã kết thúc",
                                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                                      );
                                                    }
                                                    return Text(
                                                      '${time.hours?.toString().padLeft(2, '0') ?? "00"}:'
                                                          '${time.min?.toString().padLeft(2, '0') ?? "00"}:'
                                                          '${time.sec?.toString().padLeft(2, '0') ?? "00"}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}