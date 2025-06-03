import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddProduct extends StatefulWidget {
  final String category;
  const AddProduct({super.key, required this.category});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _importPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  String? _selectedBrand;
  String? _selectedColor;
  final List<String> _colors = ["Silver", "White", "Grey", "Black", "Blue", "Pink", "Red"];
  final Map<String, List<String>> categoryBrands = {
    "Laptop": ["MacBook", "Asus", "MSI", "HP", "Dell", "Acer", "LG", "Lenovo"],
    "Monitor": ["LG UltraGear", "Dell UltraSharp", "Samsung Odyssey", "Alienware", "Asus Rog Swift"],
    "Hard Drivers": ["Seagate", "Western Digital", "Samsung SSD", "WD", "Toshiba"],
    "Keyboard": ["Logitech", "Razer", "Corsair", "Darue", "Fillco", "Newmen"],
    "Mouse": ["Logitech", "Razer", "SteelSeries", "Corsair", "Darue"]
  };

  List<String> _brands = [];
  List<Map<String, dynamic>> _variants = [];

  void _addVariant() {
    setState(() {
      _variants.add({
        'image': null,
        'importPrice': '',
        'performance': '',
        'sellingPrice': '',
        'stock': '',
        'color': null, // Initialize color as null
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _brands = categoryBrands[widget.category] ?? [];
    _variants = [
      {
        'image': null,
        'importPrice': '',
        'performance': '',
        'sellingPrice': '',
        'stock': '',
        'color': null,
      },
      {
        'image': null,
        'importPrice': '',
        'performance': '',
        'sellingPrice': '',
        'stock': '',
        'color': null,
      }
    ];
  }

  List<Uint8List> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      List<Uint8List> imageBytesList = [];
      for (var image in images.take(4)) {
        Uint8List bytes = await image.readAsBytes();
        imageBytesList.add(bytes);
      }
      setState(() {
        _selectedImages = imageBytesList;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _variants[index]['image'] = base64Encode(bytes);
      });
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];
    for (var image in _selectedImages) {
      String base64String = base64Encode(image);
      base64Images.add("data:image/png;base64,$base64String");
    }
    return base64Images;
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _variants.length >= 2) {
      setState(() {
        isLoading = true;
      });

      try {
        // Convert product images to base64
        List<String> imagesBase64 = await _convertImagesToBase64();

        // Save product to 'product' collection
        DocumentReference productRef = await FirebaseFirestore.instance.collection('product').add({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'importPrice': double.tryParse(_importPriceController.text.trim()) ?? 0,
          'sellingPrice': double.tryParse(_sellingPriceController.text.trim()) ?? 0,
          'category': widget.category,
          'brand': _selectedBrand ?? '',
          'color': _selectedColor ?? '',
          'image': imagesBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });

        String productId = productRef.id;
        print("Product saved with ID: $productId");

        // Save variants to 'variants' collection
        for (var variant in _variants) {
          String base64Image = variant['image'] != null
              ? "data:image/png;base64,${variant['image']}"
              : "";

          // Validate variant fields
          if (variant['performance'].isEmpty ||
              variant['importPrice'].isEmpty ||
              variant['sellingPrice'].isEmpty ||
              variant['stock'].isEmpty ||
              variant['color'] == null) {
            throw Exception("All variant fields, including color, must be filled");
          }

          await FirebaseFirestore.instance.collection('variants').add({
            'productId': productId,
            'performance': variant['performance'],
            'importPrice': double.tryParse(variant['importPrice']) ?? 0,
            'sellingPrice': double.tryParse(variant['sellingPrice']) ?? 0,
            'stock': int.tryParse(variant['stock']) ?? 0,
            'image': base64Image,
            'color': variant['color'], // Save color
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product and variants added successfully!")),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error adding product/variants: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding product: $e")),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and add at least 2 variants")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _importPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: const Color(0xFFDB3022),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImages.isEmpty
                        ? const Center(child: Text("Tap to upload images"))
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImages.first,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: List.generate(_variants.length, (index) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    child: Card(
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "Variant ${index + 1}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDB3022),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _pickImage(index),
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                                child: _variants[index]['image'] == null
                                    ? const Center(child: Text("Tap to upload"))
                                    : Image.memory(
                                  base64Decode(_variants[index]['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Performance",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter performance";
                                }
                                return null;
                              },
                              onChanged: (val) => _variants[index]['performance'] = val,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Color",
                                border: OutlineInputBorder(),
                              ),
                              value: _variants[index]['color'],
                              items: _colors.map((color) {
                                return DropdownMenuItem(value: color, child: Text(color));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _variants[index]['color'] = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please select a color";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Import Price",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter import price";
                                }
                                if (double.tryParse(value.trim()) == null) {
                                  return "Enter a valid number";
                                }
                                return null;
                              },
                              onChanged: (val) => _variants[index]['importPrice'] = val,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Selling Price",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter selling price";
                                }
                                if (double.tryParse(value.trim()) == null) {
                                  return "Enter a valid number";
                                }
                                return null;
                              },
                              onChanged: (val) => _variants[index]['sellingPrice'] = val,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Stock",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter stock";
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return "Enter a valid number";
                                }
                                return null;
                              },
                              onChanged: (val) => _variants[index]['stock'] = val,
                            ),
                            const SizedBox(height: 10),
                            if (_variants.length > 2)
                              TextButton(
                                onPressed: () => setState(() => _variants.removeAt(index)),
                                child: const Text("Remove Variant", style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _addVariant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB3022),
                  minimumSize: const Size(150, 40),
                ),
                child: const Text(
                  "Add variant",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB3022),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Product Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter product name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: widget.category,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Brand",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedBrand,
                        items: _brands.map((brand) {
                          return DropdownMenuItem(value: brand, child: Text(brand));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBrand = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please select a brand";
                          }
                          return null;
                        },
                      ),
                      // const SizedBox(height: 16),
                      // DropdownButtonFormField<String>(
                      //   decoration: const InputDecoration(
                      //     labelText: "Color",
                      //     border: OutlineInputBorder(),
                      //   ),
                      //   value: _selectedColor,
                      //   items: _colors.map((color) {
                      //     return DropdownMenuItem(value: color, child: Text(color));
                      //   }).toList(),
                      //   onChanged: (value) {
                      //     setState(() {
                      //       _selectedColor = value;
                      //     });
                      //   },
                      //   validator: (value) {
                      //     if (value == null || value.trim().isEmpty) {
                      //       return "Please select a color";
                      //     }
                      //     return null;
                      //   },
                      // ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter description";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 16),
              // Card(
              //   color: Colors.white,
              //   elevation: 5,
              //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       children: [
              //         const Text(
              //           "Pricing Details",
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //             color: Color(0xFFDB3022),
              //           ),
              //         ),
              //         const SizedBox(height: 10),
              //         TextFormField(
              //           controller: _importPriceController,
              //           decoration: const InputDecoration(
              //             labelText: "Import Price",
              //             border: OutlineInputBorder(),
              //           ),
              //           keyboardType: TextInputType.number,
              //           validator: (value) {
              //             if (value == null || value.trim().isEmpty) {
              //               return "Please enter import price";
              //             }
              //             if (double.tryParse(value.trim()) == null) {
              //               return "Please enter a valid number";
              //             }
              //             return null;
              //           },
              //         ),
              //         const SizedBox(height: 16),
              //         TextFormField(
              //           controller: _sellingPriceController,
              //           decoration: const InputDecoration(
              //             labelText: "Selling Price",
              //             border: OutlineInputBorder(),
              //           ),
              //           keyboardType: TextInputType.number,
              //           validator: (value) {
              //             if (value == null || value.trim().isEmpty) {
              //               return "Please enter selling price";
              //             }
              //             if (double.tryParse(value.trim()) == null) {
              //               return "Please enter a valid number";
              //             }
              //             return null;
              //           },
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB3022),
                  minimumSize: const Size(250, 50),
                ),
                child: const Text(
                  "Add product",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Times New Roman',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
