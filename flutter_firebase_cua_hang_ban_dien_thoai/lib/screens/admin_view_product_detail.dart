import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import '../widgets/base64_image.dart';
import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class ViewProductDetail extends StatefulWidget {
  final Map<String, dynamic> product;

  const ViewProductDetail({super.key, required this.product});

  @override
  _ViewProductDetailState createState() => _ViewProductDetailState();
}

class _ViewProductDetailState extends State<ViewProductDetail> {
  int selectedVariantIndex = 0;
  late List<String> imageUrls;
  List<Map<String, dynamic>> variants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    imageUrls = List<String>.from(widget.product['image'] ?? []);
    fetchVariants();
  }

  Future<void> fetchVariants() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? productId = widget.product['id'];
      if (productId == null) {
        QuerySnapshot productSnapshot = await FirebaseFirestore.instance
            .collection('product')
            .where('name', isEqualTo: widget.product['name'])
            .limit(1)
            .get();
        if (productSnapshot.docs.isNotEmpty) {
          productId = productSnapshot.docs.first.id;
        }
      }

      if (productId == null) {
        print("❌ No product ID found for product: ${widget.product['name']}");
        setState(() {
          variants = [];
          isLoading = false;
        });
        return;
      }

      QuerySnapshot variantSnapshot = await FirebaseFirestore.instance
          .collection('variants')
          .where('productId', isEqualTo: productId)
          .get();

      List<Map<String, dynamic>> fetchedVariants = variantSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'performance': data['performance'] ?? '',
          'importPrice': data['importPrice']?.toString() ?? '0',
          'sellingPrice': data['sellingPrice']?.toString() ?? '0',
          'stock': data['stock']?.toString() ?? '0',
          'image': data['image'] ?? '',
          'color': data['color'] ?? 'N/A',
          'discountPercentage': (data['discountPercentage'] as num?)?.toDouble() ?? 0.0, // Đảm bảo là double
          'discountedPrice': data['discountedPrice']?.toString(),
        };
      }).toList();

      setState(() {
        variants = fetchedVariants;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching variants: $e");
      setState(() {
        variants = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching variants: $e")),
      );
    }
  }

  bool showAllVariants = false;
  TextEditingController _commentController = TextEditingController();
  bool isExpanded = false;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _indicatorScrollController = ScrollController();

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

  Widget buildProductImageVariant(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
    }
    if (imageUrl.startsWith("data:image")) {
      return Base64ImageWidget(base64String: imageUrl);
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 100, color: Colors.red);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double discount = (widget.product["discountPercentage"] ?? 0).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Detail"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 400,
                    child: Swiper(
                      itemCount: widget.product['image']?.length ?? 0,
                      pagination: const SwiperPagination(),
                      control: const SwiperControl(),
                      autoplay: true,
                      itemBuilder: (context, index) {
                        return buildProductImage(widget.product['image'][index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${widget.product["name"]}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "Brand: ${widget.product["brand"]}",
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  Text(
                    "${widget.product["description"]}",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Text(
                      isExpanded ? "Hide" : "Read more",
                      style: const TextStyle(color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 320,
                    child: Column(
                      children: [
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : variants.isEmpty
                              ? const Center(child: Text("No variants available"))
                              : PageView.builder(
                            itemCount: variants.length,
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                selectedVariantIndex = index;
                              });
                              double indicatorPosition =
                                  (index - 2).clamp(0, variants.length - 5) * 16.0;
                              _indicatorScrollController.animateTo(
                                indicatorPosition,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            itemBuilder: (context, index) {
                              final variant = variants[index];
                              double discountPercentage = (variant['discountPercentage'] as num?)?.toDouble() ?? 0.0; // Đảm bảo là double
                              return Center(
                                child: SizedBox(
                                  width: 400,
                                  child: Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 5),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: selectedVariantIndex == index
                                              ? Colors.white70.withOpacity(0.3)
                                              : Colors.white,
                                          border: Border.all(
                                            color: selectedVariantIndex == index ? Colors.black : Colors.grey,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 140,
                                              child: buildProductImageVariant(variant["image"]),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              variant["performance"],
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text("Color: ${variant["color"]}"),
                                            Text("Stock: ${variant["stock"]}"),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (discountPercentage > 0 && variant["discountedPrice"] != null)
                                                  Text(
                                                    formatPrice(num.tryParse(variant["sellingPrice"]?.toString() ?? '0') ?? 0.0),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                Text(
                                                  (discountPercentage > 0 && variant["discountedPrice"] != null)
                                                      ? formatPrice(num.tryParse(variant["discountedPrice"]?.toString() ?? '0') ?? 0.0)
                                                      : formatPrice(num.tryParse(variant["sellingPrice"]?.toString() ?? '0') ?? 0.0),
                                                  style: TextStyle(
                                                    color: (discountPercentage > 0 && variant["discountedPrice"] != null)
                                                        ? Colors.red
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (discountPercentage > 0)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(20),
                                                bottomLeft: Radius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              "-${discountPercentage.round()}%",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            height: 20,
                            width: 100,
                            child: variants.length < 5
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(variants.length, (index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: selectedVariantIndex == index ? Colors.blue : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            )
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              controller: _indicatorScrollController,
                              itemCount: variants.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                      double indicatorPosition =
                                          (index - 2).clamp(0, variants.length - 5) * 16.0;
                                      _indicatorScrollController.animateTo(
                                        indicatorPosition,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: selectedVariantIndex == index ? Colors.blue : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}