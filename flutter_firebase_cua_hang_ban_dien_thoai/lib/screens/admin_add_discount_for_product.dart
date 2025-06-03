import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class AddDiscountForProduct extends StatefulWidget {
  final Product product;
  final bool isEditing;

  const AddDiscountForProduct({super.key, required this.product, this.isEditing = false});

  @override
  State<AddDiscountForProduct> createState() => _AddDiscountForProductState();
}

class _AddDiscountForProductState extends State<AddDiscountForProduct> {
  List<Map<String, dynamic>> _variants = [];
  bool _isLoading = true;
  Timer? _discountCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadVariants();
    _cleanExpiredDiscounts();
    _checkAndCleanExpiredDiscounts();

    _discountCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndCleanExpiredDiscounts();
    });
  }

  @override
  void dispose() {
    _discountCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndCleanExpiredDiscounts() async {
    final now = DateTime.now().toIso8601String();
    final firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot snapshot = await firestore
          .collection('variants')
          .where('discountExpiry', isLessThanOrEqualTo: now)
          .get();

      for (var doc in snapshot.docs) {
        await firestore.collection('variants').doc(doc.id).update({
          "discountPercentage": FieldValue.delete(),
          "discountedPrice": FieldValue.delete(),
          "discountDuration": FieldValue.delete(),
          "discountExpiry": FieldValue.delete(),
          "createdAt": FieldValue.delete(),
        });
      }

      print("Timer cleaned expired discounts at $now");
    } catch (e) {
      print("Error in Timer cleanup: $e");
    }
  }

  Future<void> _loadVariants() async {
    try {
      QuerySnapshot variantSnapshot = await FirebaseFirestore.instance
          .collection('variants')
          .where('productId', isEqualTo: widget.product.id)
          .get();

      setState(() {
        _variants = variantSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'data': data,
            'discountPercentage': (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
            'discountDuration': (data['discountDuration'] as num?)?.toInt() ?? 1,
            'oldDiscountPercentage': (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
            'oldDiscountDuration': (data['discountDuration'] as num?)?.toInt() ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading variants: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyDiscount() async {
    bool hasValidDiscount = _variants.any((variant) =>
    variant['discountPercentage'] > 0 && variant['discountDuration'] > 0);

    if (!hasValidDiscount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set valid discount for at least one variant")),
      );
      return;
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DateTime now = DateTime.now();

      for (var variant in _variants) {
        if (variant['discountPercentage'] <= 0 || variant['discountDuration'] <= 0) continue;

        double originalPrice = (variant['data']['sellingPrice'] as num?)?.toDouble() ?? 0.0;
        double discountedPrice = originalPrice * (1 - variant['discountPercentage'] / 100);
        DateTime expiryTime = now.add(Duration(hours: variant['discountDuration']));

        await firestore.collection('variants').doc(variant['id']).update({
          "discountPercentage": variant['discountPercentage'],
          "discountedPrice": discountedPrice.toStringAsFixed(2),
          "discountDuration": variant['discountDuration'],
          "discountExpiry": expiryTime.toIso8601String(),
          "createdAt": now.toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discounts applied successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error applying discounts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to apply discounts")),
      );
    }
  }

  Future<void> _cleanExpiredDiscounts() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String productId = widget.product.id;
      DateTime now = DateTime.now();

      QuerySnapshot variantSnapshot = await firestore
          .collection('variants')
          .where('productId', isEqualTo: productId)
          .where('discountExpiry', isLessThanOrEqualTo: now.toIso8601String())
          .get();

      for (var doc in variantSnapshot.docs) {
        await firestore.collection('variants').doc(doc.id).update({
          "discountPercentage": FieldValue.delete(),
          "discountedPrice": FieldValue.delete(),
          "discountDuration": FieldValue.delete(),
          "discountExpiry": FieldValue.delete(),
          "createdAt": FieldValue.delete(),
        });
      }
    } catch (e) {
      print("Error cleaning expired discounts: $e");
    }
  }

  Widget _buildVariantCard(Map<String, dynamic> variant) {
    String? newImage = variant['data']["image"];
    bool hasOldDiscount = variant['oldDiscountPercentage'] > 0 && variant['oldDiscountDuration'] > 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
              child: newImage?.startsWith("data:image") == true
                  ? Image.memory(base64Decode(newImage!.split(",").last), height: 120)
                  : Image.network(
                newImage ?? "",
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 100, color: Colors.red),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  variant['data']['color'] ?? 'Variant',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (hasOldDiscount)
                  Text(
                    "Old Discount: ${variant['oldDiscountPercentage'].toStringAsFixed(0)}% for ${variant['oldDiscountDuration']} hour${variant['oldDiscountDuration'] > 1 ? 's' : ''}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                const SizedBox(height: 10),
                Text(
                  "New Discount: ${variant['discountPercentage'].toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: variant['discountPercentage'],
                  min: 0,
                  max: 50,
                  label: "${variant['discountPercentage'].toStringAsFixed(0)}%",
                  onChanged: (value) {
                    setState(() {
                      variant['discountPercentage'] = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (variant['discountDuration'] > 1) {
                          setState(() {
                            variant['discountDuration']--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove, color: Colors.red),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${variant['discountDuration']} hour${variant['discountDuration'] > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          variant['discountDuration']++;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Variant Discounts" : "Add Variant Discounts"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Set discounts for individual variants",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_variants.isEmpty)
                const Text(
                  "No variants found for this product",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                )
              else
                ..._variants.map((variant) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildVariantCard(variant),
                )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _applyDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB3022),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Apply Discounts",
                  style: TextStyle(fontSize: 16, color: Colors.white),
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