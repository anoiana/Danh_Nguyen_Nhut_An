import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AddCoupon extends StatefulWidget {
  const AddCoupon({super.key});

  @override
  State<AddCoupon> createState() => _AddCouponState();
}

class _AddCouponState extends State<AddCoupon> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  int? _discountValue;
  final TextEditingController _descriptionController = TextEditingController();
  int _maxUses = 1;
  bool _validity = true;

  final List<int> _discountOptions = [10000, 20000, 50000, 100000];

  String generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(5, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _submitCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    final data = {
      'discountMoney': _discountValue,
      'quantity': _maxUses,
      'validity': true,
      'description': _descriptionController.text.trim(),
      'createdAt': Timestamp.now(),
      'usedCount': 0,
    };

    try {
      await FirebaseFirestore.instance
          .collection('couponCode')
          .add({
        'couponCode': code,
        'discountMoney': _discountValue,
        'quantity': 10,
        'validity': true,
        'description': _descriptionController.text.trim(),
        'createdAt': Timestamp.now(),
        'usedCount': 0,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon added successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _codeController.text = generateRandomCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Coupon')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          height: 330,
          child: Card(
            color: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(labelText: 'Coupon Code', border: OutlineInputBorder(),),
                      enabled: false,
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _discountValue,
                      decoration: InputDecoration(labelText: 'Discount Value', border: OutlineInputBorder(),),
                      items: _discountOptions
                          .map((val) => DropdownMenuItem(
                        value: val,
                        child: Text('$val VND'),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _discountValue = val!;
                        });
                      },
                      validator: (val) => val == null ? 'Please select discount' : null,
                    ),
                    // SizedBox(height: 20),
                    // // Validity
                    // SwitchListTile(
                    //   title: Text('Valid'),
                    //   value: _validity,
                    //   onChanged: (val) {
                    //     setState(() {
                    //       _validity = val;
                    //     });
                    //   },
                    // ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(),),
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter description' : null,
                    ),
                    SizedBox(height: 40),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 130,
                        height: 35,
                        child: ElevatedButton(
                          onPressed: _submitCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB3022),
                          ),
                          child: const Text(
                            "Add coupon",
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Times New Roman',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
