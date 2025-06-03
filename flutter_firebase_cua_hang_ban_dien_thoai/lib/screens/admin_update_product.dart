import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/models/product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class UpdateProduct extends StatefulWidget {
  final Product product;
  final String selectedCategory;
  const UpdateProduct({
    super.key,
    required this.product,
    required this.selectedCategory,
  });

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, List<String>> categoryBrands = {
    "Laptop": ["MacBook", "Asus", "MSI", "HP", "Dell", "Acer", "LG", "Lenovo"],
    "Monitor": ["LG UltraGear", "Dell UltraSharp", "Samsung Odyssey", "Alienware", "Asus Rog Swift"],
    "Hard Drivers": ["Seagate", "Western Digital", "Samsung SSD", "WD", "Toshiba"],
    "Keyboard": ["Logitech", "Razer", "Corsair", "Darue", "Fillco", "Newmen"],
    "Mouse": ["Logitech", "Razer", "SteelSeries", "Corsair", "Darue"],
  };

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  bool isLoading = false;
  String? _selectedBrand;
  String? _selectedColor;
  Uint8List? _selectedImageBytes;
  File? _selectedImageFile;
  int selectedVariantIndex = 0;
  List<Map<String, dynamic>> variants = [];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _indicatorScrollController = ScrollController();

  List<String> _brands = [];
  final List<String> colors = ["Silver", "White", "Grey", "Black", "Blue", "Pink", "Red"];

  @override
  void initState() {
    super.initState();
    print("Product brand: ${widget.product.brand}");
    print("Selected category: ${widget.selectedCategory}");
    print("Available brands: $categoryBrands");

    _fetchVariants();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);

    _brands = List.from(categoryBrands[widget.selectedCategory] ?? ['Unknown']);
    if (widget.product.brand != null && widget.product.brand!.isNotEmpty && !_brands.contains(widget.product.brand)) {
      _brands.add(widget.product.brand!);
    }
    _selectedBrand = widget.product.brand != null && widget.product.brand!.isNotEmpty
        ? widget.product.brand
        : (_brands.isNotEmpty ? _brands.first : null);
    print("Selected brand: $_selectedBrand");
    print("Brands list: $_brands");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _indicatorScrollController.dispose();
    super.dispose();
  }

  Future<void> updateMissingBrands() async {
    final snapshot = await FirebaseFirestore.instance.collection('product').get();
    for (var doc in snapshot.docs) {
      if (!doc.data().containsKey('brand')) {
        await doc.reference.update({
          'brand': 'Unknown', // Hoặc giá trị mặc định phù hợp
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = kIsWeb ? null : File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _fetchVariants() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot variantSnapshot = await FirebaseFirestore.instance
          .collection('variants')
          .where('productId', isEqualTo: widget.product.id)
          .get();

      List<Map<String, dynamic>> fetchedVariants = variantSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'performance': data['performance'] ?? '',
          'importPrice': data['importPrice']?.toDouble() ?? 0.0,
          'sellingPrice': data['sellingPrice']?.toDouble() ?? 0.0,
          'stock': data['stock'] ?? 0,
          'image': data['image'] ?? '',
          'color': data['color'] ?? 'N/A',
        };
      }).toList();

      setState(() {
        variants = fetchedVariants;
        isLoading = false;
      });
    } catch (e) {
      print("🔥 Error fetching variants: $e");
      setState(() {
        variants = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error fetching variants: $e")));
    }
  }

  Future<String?> _pickImageVariant() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        return "data:image/png;base64,${base64Encode(bytes)}";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking variant image: $e')));
    }
    return null;
  }

  void _saveProduct() async {
    setState(() {
      isLoading = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    String? imageBase64;
    if (_selectedImageBytes != null) {
      imageBase64 = "data:image/png;base64,${base64Encode(_selectedImageBytes!)}";
    }

    List<String> updatedImages = List.from(widget.product.images);
    if (imageBase64 != null) {
      if (updatedImages.isNotEmpty) {
        updatedImages.removeLast();
      }
      updatedImages.add(imageBase64);
    }

    final Map<String, dynamic> updatedProduct = {
      'name': _nameController.text.trim(),
      'category': widget.selectedCategory,
      'brand': _selectedBrand ?? "Unknown",
      'color': _selectedColor ?? "Unknown",
      'description': _descriptionController.text.trim(),
      'image': updatedImages,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.product.id)
          .update(updatedProduct);

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, "Product updated successfully");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sản phẩm đã cập nhật thành công!")),
      );
    } catch (e) {
      print("🔥 Error updating product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi: Không thể cập nhật sản phẩm!")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildImageWidget() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _selectedImageBytes != null
                ? Image.memory(_selectedImageBytes!, height: 200, width: 200, fit: BoxFit.cover)
                : (widget.product.images.isNotEmpty
                ? _loadNetworkImage(widget.product.images.last)
                : const Center(child: Text("No Image Selected"))),
          ),
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              tooltip: "Upload Image",
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadNetworkImage(String base64String) {
    try {
      if (base64String.contains(",")) {
        base64String = base64String.split(",").last;
      }
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(imageBytes, height: 200, width: 200, fit: BoxFit.cover);
    } catch (e) {
      print("🔥 Lỗi giải mã Base64: $e");
      return const Center(child: Text("Không thể hiển thị ảnh"));
    }
  }

  Future<List<Map<String, dynamic>>?> _showEditVariantDialog(BuildContext context, int index) async {
    var variant = variants[index];
    TextEditingController nameController = TextEditingController(text: variant["performance"]);
    TextEditingController stockController = TextEditingController(text: variant["stock"].toString());
    TextEditingController importPriceController = TextEditingController(text: variant["importPrice"].toString());
    TextEditingController priceController = TextEditingController(text: variant["sellingPrice"].toString());
    String? selectedColor = colors.contains(variant["color"]) ? variant["color"] : colors.first;
    print("Variant Color: ${variant["color"]}, Selected Color: $selectedColor");
    String? newImage = variant["image"];

    return await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Update Variant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        newImage?.startsWith("data:image") == true
                            ? Image.memory(base64Decode(newImage!.split(",").last), height: 120)
                            : Image.network(
                          newImage ?? "",
                          height: 120,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.red),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
                            child: SizedBox(
                              height: 25,
                              width: 25,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.camera_alt, color: Colors.black54, size: 18),
                                onPressed: () async {
                                  String? selectedImage = await _pickImageVariant();
                                  if (selectedImage != null) {
                                    setState(() {
                                      newImage = selectedImage;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Performance", border: OutlineInputBorder()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Stock", border: OutlineInputBorder()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: importPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Import Price", border: OutlineInputBorder()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Selling Price", border: OutlineInputBorder()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      items: colors.map<DropdownMenuItem<String>>((color) => DropdownMenuItem<String>(
                        value: color,
                        child: Text(color, style: TextStyle(color: Colors.black),),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedColor = value;
                          print("New selected color: $selectedColor");
                        });
                      },
                      decoration: const InputDecoration(labelText: "Color", border: OutlineInputBorder()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      validator: (value) => value == null ? "Please select a color" : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('variants').doc(variant['id']).update({
                            'performance': nameController.text,
                            'stock': int.tryParse(stockController.text) ?? 0,
                            'importPrice': double.tryParse(importPriceController.text) ?? 0.0,
                            'sellingPrice': double.tryParse(priceController.text) ?? 0.0,
                            'image': newImage,
                            'color': selectedColor,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          setState(() {
                            variants[index] = {
                              'id': variant['id'],
                              'performance': nameController.text,
                              'stock': int.tryParse(stockController.text) ?? 0,
                              'importPrice': double.tryParse(importPriceController.text) ?? 0.0,
                              'sellingPrice': double.tryParse(priceController.text) ?? 0.0,
                              'image': newImage,
                              'color': selectedColor,
                            };
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Variant đã cập nhật thành công!")),
                          );
                          Navigator.pop(context, variants);
                        } catch (e) {
                          print("🔥 Error updating variant: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("❌ Lỗi: Không thể cập nhật variant!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB3022),
                        minimumSize: const Size(100, 40),
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Product")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildImageWidget(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
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
                            double indicatorPosition = (index - 2).clamp(0, variants.length - 5) * 16.0;
                            _indicatorScrollController.animateTo(
                              indicatorPosition,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          itemBuilder: (context, index) {
                            final variant = variants[index];
                            return Center(
                              child: SizedBox(
                                width: 400,
                                child: AnimatedContainer(
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
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          variant["image"] != null &&
                                              variant["image"].startsWith("data:image")
                                              ? Image.memory(
                                            base64Decode(variant["image"].split(",").last),
                                            height: 120,
                                          )
                                              : Image.network(
                                            variant["image"] ?? "",
                                            height: 120,
                                            errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 100, color: Colors.red),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            variant["performance"],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text("Color: ${variant["color"]}"),
                                          Text("Stock: ${variant["stock"]}"),
                                          Text(
                                            "Import Price: ${formatPrice(variant["importPrice"])}",
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                          Text(
                                            "Selling Price: ${formatPrice(variant["sellingPrice"])}",
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                                            onPressed: () async {
                                              List<Map<String, dynamic>>? updatedVariants =
                                              await _showEditVariantDialog(context, index);
                                              if (updatedVariants != null) {
                                                setState(() {
                                                  variants = updatedVariants;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                    double indicatorPosition = (index - 2).clamp(0, variants.length - 5) * 16.0;
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
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Product Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDB3022)),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          validator: (value) =>
                          value == null || value.isEmpty ? "Please enter product name" : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedBrand,
                          items: _brands.map((brand) => DropdownMenuItem(value: brand, child: Text(brand, style: TextStyle(color: Colors.black),))).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBrand = value;
                            });
                          },
                          decoration: const InputDecoration(labelText: "Brand", border: OutlineInputBorder()),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          validator: (value) => value == null || value.isEmpty ? "Please select a brand" : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          validator: (value) =>
                          value == null || value.isEmpty ? "Please enter a description" : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB3022),
                    minimumSize: const Size(150, 50),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}