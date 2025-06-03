import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:coupon_uikit_flutter/coupon_uikit.dart';

class CouponListScreen extends StatefulWidget {
  final TextEditingController couponController;
  final VoidCallback applyCoupon;
  final double totalOrderValue;

  const CouponListScreen({
    Key? key,
    required this.couponController,
    required this.applyCoupon,
    required this.totalOrderValue,
  }) : super(key: key);

  @override
  _CouponListScreenState createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  List<Map<String, dynamic>> availableCoupons = [];
  bool isLoadingCoupons = true;

  @override
  void initState() {
    super.initState();
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    setState(() => isLoadingCoupons = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('couponCode')
          .where('validity', isEqualTo: true)
          .get();

      setState(() {
        availableCoupons = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        isLoadingCoupons = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading coupons: $e')),
      );
      setState(() => isLoadingCoupons = false);
    }
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    const Color primaryColor = Color(0xffcbf3f0);
    const Color secondaryColor = Color(0xff368f8b);

    DateTime createdAt;
    if (coupon['createdAt'] is Timestamp) {
      createdAt = (coupon['createdAt'] as Timestamp).toDate();
    } else if (coupon['createdAt'] is String) {
      createdAt = DateTime.tryParse(coupon['createdAt'] as String) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    // Lấy giá trị discountMoney từ coupon
    double discountMoney = (coupon['discountMoney'] is num
        ? (coupon['discountMoney'] as num).toDouble()
        : double.tryParse(coupon['discountMoney']?.toString() ?? "0.0")) ?? 0.0;

    // Kiểm tra nếu discountMoney lớn hơn totalOrderValue
    bool isCouponValid = discountMoney <= widget.totalOrderValue;

    return GestureDetector(
      onTap: () {
        if (!isCouponValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This coupon cannot be used. Please choose a coupon with a value less than or equal to your total order value (₫${widget.totalOrderValue.toStringAsFixed(0)}).',
              ),
            ),
          );
          return;
        }

        setState(() {
          widget.couponController.text = coupon['couponCode'] as String;
        });
        widget.applyCoupon();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: CouponCard(
          height: 120,
          backgroundColor: primaryColor,
          curveAxis: Axis.vertical,
          firstChild: Container(
            decoration: BoxDecoration(
              color: isCouponValid ? secondaryColor : Colors.grey,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${discountMoney.toStringAsFixed(0)}VND",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white54, height: 0),
                Expanded(
                  child: Center(
                    child: Text(
                      'SPECIAL\nOFFER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coupon Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${coupon['couponCode']}',
                  style: TextStyle(
                    fontSize: 24,
                    color: isCouponValid ? secondaryColor : Colors.grey, // Đổi màu nếu không hợp lệ
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Available Coupons",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppColor.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: isLoadingCoupons
            ? const Center(child: CircularProgressIndicator())
            : availableCoupons.isEmpty
            ? const Center(child: Text("No available coupons"))
            : ListView.builder(
          itemCount: availableCoupons.length,
          itemBuilder: (context, index) {
            final coupon = availableCoupons[index];
            return _buildCouponCard(coupon);
          },
        ),
      ),
    );
  }
}