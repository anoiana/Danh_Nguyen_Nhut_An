import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter/material.dart';
import '../models/Item.dart';
import '../models/address.dart';
import './checkout_process.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coupon_list_screen.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}
class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  late TextEditingController couponController;
  final double taxRate = 0.1;
  double discountAmount = 0;
  String? appliedCouponCode;
  late TextEditingController addressDetailController;

  String? selectedLocation;
  double shippingFee = 0;
  bool hasAddress = false;

  List<Province> provinces = [];
  List<District> districts = [];
  List<Ward> wards = [];

  List<TextEditingController> quantityControllers = [];

  Province? selectedProvince;
  District? selectedDistrict;
  Ward? selectedWard;

  final Map<String, double> shippingFees = {
    'Hà Nội City': 20000,
    'Hồ Chí Minh City': 25000,
    'Đà Nẵng City': 30000,
    'Cần Thơ City': 35000,
    'An Giang Province': 35000,
  };

  final List<Province> defaultProvinces = [
    Province(
      name: 'Hà Nội',
      fullName: 'Hà Nội City',
      nameEn: 'Hanoi',
      code: '1',
      type: 'C',
    ),
    Province(
      name: 'Hồ Chí Minh',
      fullName: 'Hồ Chí Minh City',
      nameEn: 'Ho Chi Minh City',
      code: '2',
      type: 'C',
    ),
    Province(
      name: 'Đà Nẵng',
      fullName: 'Đà Nẵng City',
      nameEn: 'Da Nang',
      code: '3',
      type: 'C',
    ),
    Province(
      name: 'Cần Thơ',
      fullName: 'Cần Thơ City',
      nameEn: 'Can Tho',
      code: '4',
      type: 'C',
    ),
  ];

  @override
  void initState() {
    super.initState();
    couponController = TextEditingController();
    addressDetailController = TextEditingController();
    fetchCartItems();
    fetchProvincesData();
    _loadUserAddress();
  }

  Future<void> fetchProvincesData() async {
    try {
      List<Province> fetchedProvinces = await fetchProvinces();
      setState(() {
        provinces = fetchedProvinces;
      });
    } catch (e) {
      setState(() {
        provinces = defaultProvinces;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading provinces: $e. Using default list.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: fetchProvincesData,
          ),
        ),
      );
    }
  }

  Future<void> fetchDistrictsData(String provinceCode) async {
    try {
      List<District> fetchedDistricts = await fetchDistricts(provinceCode);
      setState(() {
        districts = fetchedDistricts;
        selectedDistrict = null;
        selectedWard = null;
        wards = [];
      });
    } catch (e) {
      setState(() {
        districts = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading districts: $e')),
      );
    }
  }

  Future<void> fetchWardsData(String districtCode) async {
    try {
      List<Ward> fetchedWards = await fetchWards(districtCode);
      setState(() {
        wards = fetchedWards;
        selectedWard = null;
      });
    } catch (e) {
      setState(() {
        wards = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading wards: $e')),
      );
    }
  }

  Future<void> _showShippingLocationDialog() async {
    if (provinces.isEmpty) {
      await fetchProvincesData();
    }

    bool isLoadingDistricts = false;
    bool isLoadingWards = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Select Shipping Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              bool isAddressComplete = provinces == defaultProvinces
                  ? selectedProvince != null
                  : (selectedProvince != null && selectedDistrict != null && selectedWard != null);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provinces == defaultProvinces)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Unable to load provinces from server. Using default list.',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          softWrap: true,
                        ),
                      ),
                    const Text(
                      'Province/City',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    provinces.isEmpty
                        ? const Text('No province data available', style: TextStyle(color: Colors.grey))
                        : DropdownButtonFormField<Province>(
                      value: selectedProvince,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.map, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Select province/city'),
                      items: provinces.map((Province province) {
                        return DropdownMenuItem<Province>(
                          value: province,
                          child: Text(province.name, style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis,),
                        );
                      }).toList(),
                      onChanged: (Province? selection) async {
                        if (selection != null) {
                          setDialogState(() {
                            selectedProvince = selection;
                            selectedDistrict = null;
                            selectedWard = null;
                            districts.clear();
                            wards.clear();
                            isLoadingDistricts = true;
                          });

                          if (selection != defaultProvinces) {
                            await fetchDistrictsData(selection.code);
                            setDialogState(() {
                              isLoadingDistricts = false;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (provinces != defaultProvinces) ...[
                      const Text(
                        'District',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      isLoadingDistricts
                          ? const Center(child: CircularProgressIndicator())
                          : districts.isEmpty
                          ? const Text('Select province/city first', style: TextStyle(color: Colors.grey))
                          : DropdownButtonFormField<District>(
                        value: selectedDistrict,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_city, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Select district'),
                        items: districts.map((District district) {
                          return DropdownMenuItem<District>(
                            value: district,
                            child: Text(district.name, style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis,),
                          );
                        }).toList(),
                        onChanged: (District? selection) async {
                          if (selection != null) {
                            setDialogState(() {
                              selectedDistrict = selection;
                              selectedWard = null;
                              wards.clear();
                              isLoadingWards = true;
                            });

                            await fetchWardsData(selection.code);
                            setDialogState(() {
                              isLoadingWards = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (provinces != defaultProvinces) ...[
                      const Text(
                        'Ward',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      isLoadingWards
                          ? const Center(child: CircularProgressIndicator())
                          : wards.isEmpty
                          ? const Text('Select district first', style: TextStyle(color: Colors.grey))
                          : DropdownButtonFormField<Ward>(
                        value: selectedWard,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.home, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Select ward'),
                        items: wards.map((Ward ward) {
                          return DropdownMenuItem<Ward>(
                            value: ward,
                            child: Text(ward.name, style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis,),
                          );
                        }).toList(),
                        onChanged: (Ward? selection) {
                          setDialogState(() {
                            selectedWard = selection;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    AnimatedOpacity(
                      opacity: isAddressComplete ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: isAddressComplete
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Address Details (house number, street name, etc.)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: addressDetailController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.location_history, color: Colors.blue),
                                hintText: 'E.g., 123 Le Loi Street',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                // addressDetailController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear Selection', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                setState(() {
                  selectedProvince = null;
                  selectedDistrict = null;
                  selectedWard = null;
                  districts.clear();
                  wards.clear();
                  selectedLocation = null;
                  shippingFee = 0;
                });
                // addressDetailController.dispose();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (selectedProvince == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a province/city!')),
                  );
                  return;
                }
                if (provinces != defaultProvinces && (selectedDistrict == null || selectedWard == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select district and ward!')),
                  );
                  return;
                }

                String addressDetail = addressDetailController.text.trim();
                setState(() {
                  selectedLocation = provinces == defaultProvinces
                      ? (addressDetail.isNotEmpty
                      ? '$addressDetail, ${selectedProvince!.name}'
                      : selectedProvince!.name)
                      : (addressDetail.isNotEmpty
                      ? '$addressDetail, ${selectedWard!.name}, ${selectedDistrict!.name}, ${selectedProvince!.name}'
                      : '${selectedWard!.name}, ${selectedDistrict!.name}, ${selectedProvince!.name}');
                  shippingFee = shippingFees[selectedProvince!.name] ?? 40000;
                });

                // addressDetailController.dispose();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    couponController.dispose();
    addressDetailController.dispose();
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchCartItems() async {
    setState(() => isLoading = true);
    try {
      if (widget.userId == 'unknown') {
        await _fetchCartFromSharedPreferences();
      } else {
        await _fetchCartFromFirestore();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart: $e')),
      );
      setState(() {
        cartItems = [];
        quantityControllers = [];
      });
      print("General error loading cart: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCartFromFirestore() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      DocumentSnapshot cartDoc = await db.collection("cart").doc(widget.userId).get();

      if (!cartDoc.exists) {
        setState(() {
          cartItems = [];
          quantityControllers = [];
          isLoading = false; // Đặt isLoading ở đây
        });
        print("Cart document does not exist. Number of items: ${cartItems.length}");
        return;
      }

      var productIdsRaw = cartDoc["productIds"] ?? [];
      print("Raw productIds data from Firestore: $productIdsRaw");
      print("Type of productIdsRaw: ${productIdsRaw.runtimeType}");

      List<Map<String, dynamic>> productEntries = (productIdsRaw as List<dynamic>)
          .where((item) => item != null)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      print("productEntries after processing: $productEntries");
      print("Type of productEntries after processing: ${productEntries.runtimeType}");

      if (productEntries.isEmpty) {
        setState(() {
          cartItems = [];
          quantityControllers = [];
          isLoading = false; // Đặt isLoading ở đây
        });
        print("No items in cart. Number of items: ${cartItems.length}");
        return;
      }

      List<String> productIds = productEntries
          .map((entry) => entry['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      List<String> variantIds = productEntries
          .map((entry) => entry['variantId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> productDataMap = {};
      List<List<String>> productChunks = _splitList(productIds, 10);
      for (var chunk in productChunks) {
        try {
          QuerySnapshot productSnapshot = await db
              .collection("product")
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (var doc in productSnapshot.docs) {
            productDataMap[doc.id] = doc.data() as Map<String, dynamic>;
          }
        } catch (chunkError) {
          print("Error processing product chunk $chunk: $chunkError");
          continue;
        }
      }

      Map<String, List<Map<String, dynamic>>> productVariantsMap = {};
      await Future.wait(productIds.map((productId) async {
        try {
          QuerySnapshot variantSnapshot = await db
              .collection("variants")
              .where("productId", isEqualTo: productId)
              .get();
          List<Map<String, dynamic>> variants = [];
          for (var doc in variantSnapshot.docs) {
            var variantData = doc.data() as Map<String, dynamic>;
            variantData['variantId'] = doc.id;
            DateTime now = DateTime.now();
            if (variantData.containsKey('discountPercentage') && variantData.containsKey('discountExpiry')) {
              num discountPercentage = num.tryParse(variantData['discountPercentage']?.toString() ?? '0') ?? 0;
              String? expiryStr = variantData['discountExpiry']?.toString();
              DateTime? expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
              if (discountPercentage > 0 && expiry != null && now.isBefore(expiry)) {
                num sellingPrice = num.tryParse(variantData['sellingPrice']?.toString() ?? '0') ?? 0;
                num discountedPrice = sellingPrice * (1 - discountPercentage / 100);
                variantData['discountedPrice'] = discountedPrice;
              }
            }
            variants.add(variantData);
          }
          productVariantsMap[productId] = variants;
        } catch (e) {
          print("Error fetching variants for product $productId: $e");
          productVariantsMap[productId] = [];
        }
      }));

      List<Map<String, dynamic>> allItems = [];
      for (var entry in productEntries) {
        String? productId = entry['id'] as String?;
        String? variantId = entry['variantId'] as String?;
        int quantity = entry['quantity'] as int? ?? 1;

        if (productId == null || productId.isEmpty) {
          print("Skipping item with invalid productId: $entry");
          continue;
        }

        var productData = productDataMap[productId] ?? {};
        Map<String, dynamic>? variantData;
        var variants = productVariantsMap[productId] ?? [];
        if (variantId != null) {
          variantData = variants.firstWhere(
                  (v) => v['variantId'] == variantId,
              orElse: () => {});
        }

        allItems.add({
          'productId': productId,
          'variantId': variantId,
          'name': productData["name"]?.toString() ?? "Unknown Item",
          'image': variantData != null
              ? (variantData["image"]?.toString() ?? "")
              : (productData["image"] is List && (productData["image"] as List).isNotEmpty
              ? (productData["image"] as List).first?.toString() ?? ""
              : ""),
          'price': variantData != null
              ? (variantData["discountedPrice"] != null
              ? (variantData["discountedPrice"] is num
              ? (variantData["discountedPrice"] as num).toDouble()
              : double.tryParse(variantData["discountedPrice"]?.toString() ?? "0.0") ?? 0.0)
              : (variantData["sellingPrice"] is num
              ? (variantData["sellingPrice"] as num).toDouble()
              : double.tryParse(variantData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0))
              : (productData["sellingPrice"] is num
              ? (productData["sellingPrice"] as num).toDouble()
              : double.tryParse(productData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0),
          'originalPrice': variantData != null
              ? (variantData["sellingPrice"] is num
              ? (variantData["sellingPrice"] as num).toDouble()
              : double.tryParse(variantData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0)
              : null,
          'performance': variantData != null
              ? (variantData["performance"]?.toString() ?? "Unknown Performance")
              : (productData["brand"]?.toString() ?? "Unknown Brand"),
          'color': variantData != null
              ? (variantData["color"]?.toString() ?? "Unknown Color")
              : "Not specified",
          'quantity': quantity,
          'selected': false,
          'variants': variants,
        });
      }

      setState(() {
        cartItems = allItems;
        quantityControllers = cartItems.map((item) => TextEditingController(text: item['quantity'].toString())).toList();
        isLoading = false; // Đặt isLoading ở đây
      });
      print("Successfully loaded cart from Firestore. Number of items: ${cartItems.length}");
    } catch (e) {
      print("Error in _fetchCartFromFirestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart from Firestore: $e')),
      );
      setState(() {
        cartItems = [];
        quantityControllers = [];
        isLoading = false; // Đặt isLoading ở đây
      });
    }
  }

  Future<void> _fetchCartFromSharedPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> guestCart = prefs.getStringList('guestCart') ?? [];

      if (guestCart.isEmpty) {
        setState(() {
          cartItems = [];
          quantityControllers = [];
          isLoading = false;
        });
        print("Guest cart is empty. Number of items: ${cartItems.length}");
        return;
      }

      List<Map<String, dynamic>> productEntries = [];
      for (var item in guestCart) {
        try {
          productEntries.add(jsonDecode(item) as Map<String, dynamic>);
        } catch (e) {
          print("Error decoding cart item: $e, item: $item");
          continue;
        }
      }

      if (productEntries.isEmpty) {
        setState(() {
          cartItems = [];
          quantityControllers = [];
          isLoading = false;
        });
        print("No valid items in guest cart. Number of items: ${cartItems.length}");
        return;
      }

      // Sử dụng 'id' thay vì 'productId'
      List<String> productIds = productEntries
          .map((entry) => entry['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      List<String> variantIds = productEntries
          .map((entry) => entry['variantId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      FirebaseFirestore db = FirebaseFirestore.instance;
      Map<String, Map<String, dynamic>> productDataMap = {};
      List<List<String>> productChunks = _splitList(productIds, 10);
      for (var chunk in productChunks) {
        try {
          QuerySnapshot productSnapshot = await db
              .collection("product")
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (var doc in productSnapshot.docs) {
            productDataMap[doc.id] = doc.data() as Map<String, dynamic>;
          }
        } catch (chunkError) {
          print("Error processing product chunk $chunk: $chunkError");
          continue;
        }
      }

      Map<String, List<Map<String, dynamic>>> productVariantsMap = {};
      await Future.wait(productIds.map((productId) async {
        try {
          QuerySnapshot variantSnapshot = await db
              .collection("variants")
              .where("productId", isEqualTo: productId)
              .get();
          List<Map<String, dynamic>> variants = [];
          for (var doc in variantSnapshot.docs) {
            var variantData = doc.data() as Map<String, dynamic>;
            variantData['variantId'] = doc.id;
            DateTime now = DateTime.now();
            if (variantData.containsKey('discountPercentage') &&
                variantData.containsKey('discountExpiry')) {
              num discountPercentage = num.tryParse(
                  variantData['discountPercentage']?.toString() ?? '0') ?? 0;
              String? expiryStr = variantData['discountExpiry']?.toString();
              DateTime? expiry = expiryStr != null
                  ? DateTime.tryParse(expiryStr)
                  : null;
              if (discountPercentage > 0 && expiry != null &&
                  now.isBefore(expiry)) {
                num sellingPrice = num.tryParse(
                    variantData['sellingPrice']?.toString() ?? '0') ?? 0;
                num discountedPrice = sellingPrice *
                    (1 - discountPercentage / 100);
                variantData['discountedPrice'] = discountedPrice;
              }
            }
            variants.add(variantData);
          }
          productVariantsMap[productId] = variants;
        } catch (e) {
          print("Error fetching variants for product $productId: $e");
          productVariantsMap[productId] = [];
        }
      }));

      List<Map<String, dynamic>> allItems = [];
      for (var entry in productEntries) {
        String? productId = entry['id'] as String?; // Sử dụng 'id' thay vì 'productId'
        String? variantId = entry['variantId'] as String?;
        int quantity = entry['quantity'] as int? ?? 1;

        if (productId == null || productId.isEmpty) {
          print("Skipping item with invalid productId: $entry");
          continue;
        }

        var productData = productDataMap[productId] ?? {};
        Map<String, dynamic>? variantData;
        var variants = productVariantsMap[productId] ?? [];
        if (variantId != null) {
          variantData = variants.firstWhere(
                  (v) => v['variantId'] == variantId,
              orElse: () => {});
        }

        allItems.add({
          'productId': productId,
          'variantId': variantId,
          'name': productData["name"]?.toString() ?? "Unknown Item",
          'image': variantData != null
              ? (variantData["image"]?.toString() ?? "")
              : (productData["image"] is List &&
              (productData["image"] as List).isNotEmpty
              ? (productData["image"] as List).first?.toString() ?? ""
              : ""),
          'price': variantData != null
              ? (variantData["discountedPrice"] != null
              ? (variantData["discountedPrice"] is num
              ? (variantData["discountedPrice"] as num).toDouble()
              : double.tryParse(
              variantData["discountedPrice"]?.toString() ?? "0.0") ?? 0.0)
              : (variantData["sellingPrice"] is num
              ? (variantData["sellingPrice"] as num).toDouble()
              : double.tryParse(
              variantData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0))
              : (productData["sellingPrice"] is num
              ? (productData["sellingPrice"] as num).toDouble()
              : double.tryParse(
              productData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0),
          'originalPrice': variantData != null
              ? (variantData["sellingPrice"] is num
              ? (variantData["sellingPrice"] as num).toDouble()
              : double.tryParse(
              variantData["sellingPrice"]?.toString() ?? "0.0") ?? 0.0)
              : null,
          'performance': variantData != null
              ? (variantData["performance"]?.toString() ?? "Unknown Performance")
              : (productData["brand"]?.toString() ?? "Unknown Brand"),
          'color': variantData != null
              ? (variantData["color"]?.toString() ?? "Unknown Color")
              : "Not specified",
          'quantity': quantity,
          'selected': false,
          'variants': variants,
        });
      }

      setState(() {
        cartItems = allItems;
        quantityControllers = cartItems.map((item) =>
            TextEditingController(text: item['quantity'].toString())).toList();
        isLoading = false;
      });
      print(
          "Successfully loaded cart from SharedPreferences. Number of items: ${cartItems.length}");
    } catch (e) {
      print("Error in _fetchCartFromSharedPreferences: $e");
      setState(() {
        cartItems = [];
        quantityControllers = [];
        isLoading = false;
      });
    }
  }

  // Future<void> _updateVariant(int index, Map<String, dynamic> newVariant) async {
  //   Map<String, dynamic> item = cartItems[index];
  //   String productId = item['productId'] as String;
  //   String? oldVariantId = item['variantId'] as String?;
  //   String newVariantId = newVariant['variantId'] as String;
  //
  //   try {
  //     DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(widget.userId);
  //     DocumentSnapshot cartSnapshot = await cartRef.get();
  //
  //     if (!cartSnapshot.exists) {
  //       print("Cart does not exist!");
  //       return;
  //     }
  //
  //     Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
  //     List<dynamic> productIds = List.from(cartData['productIds'] ?? []);
  //
  //     int productIndex = productIds.indexWhere(
  //           (entry) => entry['id'] == productId && entry['variantId'] == oldVariantId,
  //     );
  //
  //     if (productIndex == -1) {
  //       print("Item not found in productIds!");
  //       return;
  //     }
  //
  //     productIds[productIndex]['variantId'] = newVariantId;
  //
  //     await cartRef.update({
  //       'productIds': productIds,
  //     });
  //
  //     setState(() {
  //       cartItems[index]['variantId'] = newVariantId;
  //       cartItems[index]['performance'] = newVariant['performance']?.toString() ?? "Unknown Performance";
  //       cartItems[index]['color'] = newVariant['color']?.toString() ?? "Unknown Color";
  //       cartItems[index]['price'] = newVariant['discountedPrice'] != null
  //           ? (newVariant['discountedPrice'] is num
  //           ? (newVariant['discountedPrice'] as num).toDouble()
  //           : double.tryParse(newVariant['discountedPrice']?.toString() ?? "0.0") ?? 0.0)
  //           : (newVariant['sellingPrice'] is num
  //           ? (newVariant['sellingPrice'] as num).toDouble()
  //           : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0);
  //       cartItems[index]['originalPrice'] = newVariant['sellingPrice'] is num
  //           ? (newVariant['sellingPrice'] as num).toDouble()
  //           : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0;
  //       cartItems[index]['image'] = newVariant['image']?.toString() ?? "";
  //     });
  //
  //     print("Variant updated successfully!");
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error updating variant: $e')),
  //     );
  //     print("Error updating variant: $e");
  //   }
  // }

  Future<void> _updateVariant(int index, Map<String, dynamic> newVariant) async {
    if (widget.userId == 'unknown') {
      // Cập nhật trong SharedPreferences
      await _updateVariantInSharedPreferences(index, newVariant);
    } else {
      // Cập nhật trong Firestore
      await _updateVariantInFirestore(index, newVariant);
    }
  }

  Future<void> _updateVariantInFirestore(int index, Map<String, dynamic> newVariant) async {
    Map<String, dynamic> item = cartItems[index];
    String productId = item['productId'] as String;
    String? oldVariantId = item['variantId'] as String?;
    String newVariantId = newVariant['variantId'] as String;

    try {
      DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(widget.userId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (!cartSnapshot.exists) {
        print("Cart does not exist!");
        return;
      }

      Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
      List<dynamic> productIds = List.from(cartData['productIds'] ?? []);

      int productIndex = productIds.indexWhere(
            (entry) => entry['id'] == productId && entry['variantId'] == oldVariantId,
      );

      if (productIndex == -1) {
        print("Item not found in productIds!");
        return;
      }

      productIds[productIndex]['variantId'] = newVariantId;

      await cartRef.update({
        'productIds': productIds,
      });

      setState(() {
        cartItems[index]['variantId'] = newVariantId;
        cartItems[index]['performance'] = newVariant['performance']?.toString() ?? "Unknown Performance";
        cartItems[index]['color'] = newVariant['color']?.toString() ?? "Unknown Color";
        cartItems[index]['price'] = newVariant['discountedPrice'] != null
            ? (newVariant['discountedPrice'] is num
            ? (newVariant['discountedPrice'] as num).toDouble()
            : double.tryParse(newVariant['discountedPrice']?.toString() ?? "0.0") ?? 0.0)
            : (newVariant['sellingPrice'] is num
            ? (newVariant['sellingPrice'] as num).toDouble()
            : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0);
        cartItems[index]['originalPrice'] = newVariant['sellingPrice'] is num
            ? (newVariant['sellingPrice'] as num).toDouble()
            : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0;
        cartItems[index]['image'] = newVariant['image']?.toString() ?? "";
      });

      print("Variant updated successfully in Firestore!");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating variant in Firestore: $e')),
      );
      print("Error updating variant in Firestore: $e");
    }
  }

  Future<void> _updateVariantInSharedPreferences(int index, Map<String, dynamic> newVariant) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];

    if (index >= 0 && index < guestCart.length) {
      Map<String, dynamic> item = jsonDecode(guestCart[index]) as Map<String, dynamic>;
      item['variantId'] = newVariant['variantId'];

      guestCart[index] = jsonEncode(item);
      await prefs.setStringList('guestCart', guestCart);

      setState(() {
        cartItems[index]['variantId'] = newVariant['variantId'];
        cartItems[index]['performance'] = newVariant['performance']?.toString() ?? "Unknown Performance";
        cartItems[index]['color'] = newVariant['color']?.toString() ?? "Unknown Color";
        cartItems[index]['price'] = newVariant['discountedPrice'] != null
            ? (newVariant['discountedPrice'] is num
            ? (newVariant['discountedPrice'] as num).toDouble()
            : double.tryParse(newVariant['discountedPrice']?.toString() ?? "0.0") ?? 0.0)
            : (newVariant['sellingPrice'] is num
            ? (newVariant['sellingPrice'] as num).toDouble()
            : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0);
        cartItems[index]['originalPrice'] = newVariant['sellingPrice'] is num
            ? (newVariant['sellingPrice'] as num).toDouble()
            : double.tryParse(newVariant['sellingPrice']?.toString() ?? "0.0") ?? 0.0;
        cartItems[index]['image'] = newVariant['image']?.toString() ?? "";
      });

      print("Variant updated successfully in SharedPreferences!");
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (widget.userId == 'unknown') {
      await _updateQuantityInSharedPreferences(index, newQuantity);
    } else {
      await _updateQuantityInFirestore(index, newQuantity);
    }
  }

  Future<void> _updateQuantityInSharedPreferences(int index, int newQuantity) async {
    if (newQuantity < 0) {
      quantityControllers[index].text = cartItems[index]['quantity'].toString();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];

    if (index >= 0 && index < guestCart.length) {
      Map<String, dynamic> item = jsonDecode(guestCart[index]) as Map<String, dynamic>;
      int stock = await _getStockFromVariant(item['variantId'] as String?);
      if (newQuantity > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity exceeds stock! Current stock: $stock')),
        );
        quantityControllers[index].text = cartItems[index]['quantity'].toString();
        return;
      }

      if (newQuantity == 0) {
        guestCart.removeAt(index);
      } else {
        item['quantity'] = newQuantity;
        guestCart[index] = jsonEncode(item);
      }

      await prefs.setStringList('guestCart', guestCart);

      setState(() {
        if (newQuantity == 0) {
          cartItems.removeAt(index);
          quantityControllers.removeAt(index);
        } else {
          cartItems[index]['quantity'] = newQuantity;
          quantityControllers[index].text = newQuantity.toString();
        }
      });

      print("Quantity updated successfully in SharedPreferences!");
    }
  }

  Future<void> _updateQuantityInFirestore(int index, int newQuantity) async {
    // Giữ nguyên logic cũ của _updateQuantity
    if (newQuantity < 0) {
      quantityControllers[index].text = cartItems[index]['quantity'].toString();
      return;
    }

    Map<String, dynamic> item = cartItems[index];
    int oldQuantity = item['quantity'] as int;

    try {
      DocumentSnapshot variantDoc = await FirebaseFirestore.instance.collection('variants').doc(item['variantId']).get();

      if (!variantDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variant not found in Firestore!')),
        );
        quantityControllers[index].text = oldQuantity.toString();
        return;
      }

      Map<String, dynamic> variantData = variantDoc.data() as Map<String, dynamic>;
      int stock = int.tryParse(variantData['stock']?.toString() ?? '0') ?? 0;

      if (newQuantity > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity exceeds stock! Current stock: $stock')),
        );
        quantityControllers[index].text = oldQuantity.toString();
        return;
      }

      DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(widget.userId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (!cartSnapshot.exists) {
        print("Cart does not exist!");
        quantityControllers[index].text = oldQuantity.toString();
        return;
      }

      Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
      List<dynamic> productIds = List.from(cartData['productIds'] ?? []);

      int productIndex = productIds.indexWhere(
            (entry) => entry['id'] == item['productId'] && entry['variantId'] == item['variantId'],
      );

      if (productIndex == -1) {
        print("Item not found in productIds!");
        quantityControllers[index].text = oldQuantity.toString();
        return;
      }

      if (newQuantity == 0) {
        productIds.removeAt(productIndex);
      } else {
        productIds[productIndex]['quantity'] = newQuantity;
      }

      await cartRef.update({
        'productIds': productIds,
      });

      setState(() {
        if (newQuantity == 0) {
          cartItems.removeAt(index);
          quantityControllers.removeAt(index);
        } else {
          cartItems[index]['quantity'] = newQuantity;
          quantityControllers[index].text = newQuantity.toString();
        }
      });

      print("Quantity updated successfully in Firestore!");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity in Firestore: $e')),
      );
      quantityControllers[index].text = oldQuantity.toString();
      print("Error updating quantity in Firestore: $e");
    }
  }

  Future<int> _getStockFromVariant(String? variantId) async {
    if (variantId == null) return 0;
    try {
      DocumentSnapshot variantDoc = await FirebaseFirestore.instance.collection('variants').doc(variantId).get();
      if (variantDoc.exists) {
        return int.tryParse(variantDoc['stock']?.toString() ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      print("Error fetching stock for variant $variantId: $e");
      return 0;
    }
  }

  Future<void> _deleteItem(int index) async {
    if (widget.userId == 'unknown') {
      await _deleteItemFromSharedPreferences(index);
    } else {
      await _deleteItemFromFirestore(index);
    }
  }

  Future<void> _deleteItemFromFirestore(int index) async {
    // Giữ nguyên logic cũ của _deleteItem
    Map<String, dynamic> item = cartItems[index];

    try {
      DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(widget.userId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (!cartSnapshot.exists) {
        print("Cart does not exist!");
        return;
      }

      Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
      List<dynamic> productIds = cartData['productIds'] ?? [];

      int productIndex = productIds.indexWhere(
            (entry) => entry['id'] == item['productId'] && entry['variantId'] == item['variantId'],
      );

      if (productIndex == -1) {
        print("Item not found in productIds!");
        return;
      }

      productIds.removeAt(productIndex);

      await cartRef.update({
        'productIds': productIds,
      });

      setState(() {
        cartItems.removeAt(index);
        quantityControllers.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart!')),
      );
      print("Item deleted successfully from Firestore!");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item from Firestore: $e')),
      );
      print("Error removing item from Firestore: $e");
    }
  }

  Future<void> _deleteItemFromSharedPreferences(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];

    if (index >= 0 && index < guestCart.length) {
      guestCart.removeAt(index);
      await prefs.setStringList('guestCart', guestCart);

      setState(() {
        cartItems.removeAt(index);
        quantityControllers.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart!')),
      );
      print("Item deleted successfully from SharedPreferences!");
    }
  }

  List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  void clearCoupon() {
    setState(() {
      discountAmount = 0;
      appliedCouponCode = null;
      couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon code removed!')),
    );
  }

  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in cartItems) {
      if (item['selected'] == true) {
        subtotal += (item['price'] as double) * (item['quantity'] as int);
      }
    }
    return subtotal;
  }

  double calculateTax() {
    return calculateSubtotal() * taxRate;
  }

  double calculateTotal() {
    double subtotal = calculateSubtotal();
    double total = subtotal + calculateTax() + shippingFee - discountAmount;
    return total < 0 ? 0 : total;
  }

  Future<void> applyCoupon() async {
    String couponCode = couponController.text.trim();

    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code!')),
      );
      return;
    }

    try {
      QuerySnapshot couponSnapshot = await FirebaseFirestore.instance.collection('couponCode').get();
      bool couponFound = false;
      DocumentSnapshot? matchingDoc;

      for (var doc in couponSnapshot.docs) {
        Map<String, dynamic> couponData = doc.data() as Map<String, dynamic>;
        if (couponData['couponCode'] == couponCode) {
          couponFound = true;
          matchingDoc = doc;
          break;
        }
      }

      if (!couponFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon code does not exist!')),
        );
        return;
      }

      Map<String, dynamic> couponData = matchingDoc!.data() as Map<String, dynamic>;
      bool isValid = couponData['validity'] ?? false;
      int quantity = couponData['quantity'] ?? 0;

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon code is not valid!')),
        );
        return;
      }

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon code has no remaining uses!')),
        );
        return;
      }

      double discountMoney = (couponData['discountMoney'] is num
          ? (couponData['discountMoney'] as num).toDouble()
          : double.tryParse(couponData['discountMoney']?.toString() ?? "0.0")) ?? 0.0;

      setState(() {
        discountAmount = discountMoney;
        appliedCouponCode = couponCode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon applied successfully! Discount: ₫${discountAmount.toStringAsFixed(0)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying coupon code: $e')),
      );
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      cartItems[index]['selected'] = !cartItems[index]['selected'];
    });
  }

  Future<void> _loadUserAddress() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (userDoc.exists && userDoc['address'] != null && userDoc['address'].toString().isNotEmpty) {
        setState(() {
          selectedLocation = userDoc['address'] as String;
          hasAddress = true;
          shippingFee = shippingFees.values.firstWhere(
                (fee) => shippingFees.keys.any((key) => selectedLocation!.contains(key)),
            orElse: () => 40000,
          );
        });
        print("Loaded address from Firestore: $selectedLocation");
      } else {
        setState(() {
          hasAddress = false;
        });
        print("No address found in Firestore");
      }
    } catch (e) {
      print("Error loading address: $e");
      setState(() {
        hasAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Cart",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppColor.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(10),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                _buildCouponInput(),
                const SizedBox(height: 15),
                Expanded(
                  child: cartItems.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Your cart is empty",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(index, cartItems[index]),
                  ),
                ),
                const SizedBox(height: 15),
                _buildSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, Map<String, dynamic> item) {
    final double price = item['price'] as double;
    final double? originalPrice = item['originalPrice'] as double?;
    final bool hasDiscount = originalPrice != null && price < originalPrice;
    final String? variantId = item['variantId'] as String?;
    final List<Map<String, dynamic>> variants = (item['variants'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    Map<String, dynamic>? currentVariant = variants.firstWhere(
          (v) => v['variantId'] == variantId,
      orElse: () => {},
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      color: Colors.white,
      child: SizedBox(
        height: 150,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Checkbox(
                  value: item['selected'] as bool,
                  onChanged: (value) => _toggleSelection(index),
                  activeColor: Colors.orange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              FutureBuilder<String?>(
                future: variantId != null
                    ? FirebaseFirestore.instance
                    .collection('variants')
                    .doc(variantId)
                    .get()
                    .then((doc){
                  if (doc.exists) {
                    return doc.data()?['image'] as String?;
                  } else {
                    return null;
                  }
                })
                    : Future.value(null),
                builder: (context, snapshot) {
                  Widget imageWidget;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    imageWidget = const CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.contains(',')) {
                    imageWidget = item['image'].toString().isNotEmpty
                        ? Image.network(
                      item['image'].toString(),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80),
                    )
                        : const Icon(Icons.image_not_supported, size: 80);
                  } else {
                    if (!snapshot.data!.contains(',')) {
                      imageWidget = const Icon(Icons.image_not_supported, size: 80);
                      print("Invalid base64 format: ${snapshot.data}");
                    } else {
                      try {
                        final base64Data = snapshot.data!.split(',').last;
                        imageWidget = Image.memory(
                          base64Decode(base64Data),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 80),
                        );
                      } catch (e) {
                        imageWidget =
                        const Icon(Icons.image_not_supported, size: 80);
                        print("Error decoding base64 image: $e");
                      }
                    }
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: imageWidget,
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'].toString(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      DropdownButton<Map<String, dynamic>>(
                        value: currentVariant.isNotEmpty ? currentVariant : null,
                        isExpanded: true,
                        items: variants.map((variant) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: variant,
                            child: Text(
                              "${variant['performance']?.toString() ?? 'Unknown'} - ${variant['color']?.toString() ?? 'Unknown'}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          );
                        }).toList(),
                        onChanged: (Map<String, dynamic>? newVariant) async {
                          if (newVariant != null && newVariant['variantId'] != variantId) {
                            await _updateVariant(index, newVariant);
                          }
                        },
                      ),
                      // const Spacer(),
                      Column(
                        children: [
                          Text(
                            formatPrice(price),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasDiscount) ...[
                            Text(
                              formatPrice(originalPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _deleteItem(index),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: (item['quantity'] as int) > 1
                                ? () {
                              _updateQuantity(index, (item['quantity'] as int) - 1);
                              quantityControllers[index].text = item['quantity'].toString();
                            }
                                : null,
                            icon: const Icon(Icons.remove, size: 12, color: Colors.grey),
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(
                            width: 10,
                            child: TextField(
                              controller: quantityControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (value) {
                                int? newQuantity = int.tryParse(value);
                                if (newQuantity != null && newQuantity >= 0) {
                                  _updateQuantity(index, newQuantity);
                                } else {
                                  quantityControllers[index].text = item['quantity'].toString();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid quantity!')),
                                  );
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _updateQuantity(index, (item['quantity'] as int) + 1);
                              quantityControllers[index].text = item['quantity'].toString();
                            },
                            icon: const Icon(Icons.add, size: 12, color: Colors.grey),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                label.contains("Subtotal")
                    ? Icons.receipt
                    : label.contains("Tax")
                    ? Icons.account_balance
                    : label.contains("Shipping Fee")
                    ? Icons.local_shipping
                    : label.contains("Discount")
                    ? Icons.discount
                    : Icons.payment,
                size: 20,
                color: color ?? Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            formatPrice(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    double subtotal = calculateSubtotal();
    double discount = discountAmount;

    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            formatPrice(calculateTotal()),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPriceRow("Subtotal", calculateSubtotal(), color: Colors.black54),
              _buildPriceRow("Tax (10% VAT)", calculateTax(), color: Colors.black54),
              GestureDetector(
                onTap: _showShippingLocationDialog,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Shipping Fee",
                                    style: TextStyle(fontSize: 16, color: Colors.blue),
                                  ),
                                  if (selectedLocation != null)
                                    Text(
                                      "($selectedLocation)",
                                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    )
                                  else
                                    const Text(
                                      "Select location",
                                      style: TextStyle(fontSize: 14, color: Colors.blue),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPrice(shippingFee),
                        style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (discount > 0) _buildPriceRow("Discount", -discount, color: Colors.green),
              Divider(thickness: 1, color: Colors.grey.shade300),
              _buildPriceRow("Total Payment", calculateTotal(), color: Colors.red, isBold: true),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  List<Map<String, dynamic>> selectedItems = cartItems.where((item) => item['selected'] == true).toList();
                  if (selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one item to checkout!')),
                    );
                    return;
                  }
                  if (selectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a shipping location!')),
                    );
                    return;
                  }

                  List<Item> convertedItems = [];
                  for (int i = 0; i < cartItems.length; i++) {
                    if (cartItems[i]['selected'] == true) {
                      convertedItems.add(Item(
                        productId: cartItems[i]['productId'] as String,
                        indexVariant: i, // Sử dụng chỉ số từ cartItems
                        name: cartItems[i]['name'] as String,
                        image: cartItems[i]['image'] as String,
                        variantId: cartItems[i]['variantId'] as String?,
                        price: cartItems[i]['price'] as double,
                        performance: cartItems[i]['performance'] as String,
                        color: cartItems[i]['color'] as String,
                        quantity: cartItems[i]['quantity'] as int,
                      ));
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        userId: widget.userId,
                        selectedItems: convertedItems,
                        shippingAddress: selectedLocation!,
                        shippingFee: shippingFee,
                        discountAmount: discountAmount,
                        appliedCouponCode: appliedCouponCode,
                        hasAddress: hasAddress,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text(
                  "Checkout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildCouponInput() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.2),
  //           blurRadius: 8,
  //           spreadRadius: 2,
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.local_offer, color: Colors.grey),
  //         SizedBox(width: 10,),
  //         Expanded(
  //           child: TextField(
  //             controller: couponController,
  //             decoration: const InputDecoration(
  //               hintText: "Enter coupon code",
  //               border: InputBorder.none,
  //               hintStyle: TextStyle(color: Colors.grey),
  //             ),
  //           ),
  //         ),
  //         ElevatedButton.icon(
  //           onPressed: applyCoupon,
  //           icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
  //           label: const Text("Apply", style: TextStyle(color: Colors.white)),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColor.primaryColor,
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           ),
  //         ),
  //         IconButton(
  //           onPressed: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => CouponListScreen(
  //                   couponController: couponController,
  //                   applyCoupon: applyCoupon,
  //                 ),
  //               ),
  //             );
  //           },
  //           icon: const Icon(Icons.list_alt, color: Colors.blue, size: 24),
  //           tooltip: "View Coupons",
  //           splashRadius: 20,
  //         ),
  //         if (discountAmount > 0)
  //           IconButton(
  //             onPressed: clearCoupon,
  //             icon: const Icon(Icons.cancel, color: Colors.redAccent),
  //             splashRadius: 20,
  //           ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildCouponInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: couponController,
              decoration: const InputDecoration(
                hintText: "Enter coupon code",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: applyCoupon,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
            label: const Text("Apply", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Tính tổng giá trị đơn hàng (chỉ tính subtotal của các mặt hàng đã chọn)
              double totalOrderValue = calculateSubtotal();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CouponListScreen(
                    couponController: couponController,
                    applyCoupon: applyCoupon,
                    totalOrderValue: totalOrderValue, // Truyền totalOrderValue
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, color: Colors.blue, size: 24),
            tooltip: "View Coupons",
            splashRadius: 20,
          ),
          if (discountAmount > 0)
            IconButton(
              onPressed: clearCoupon,
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
