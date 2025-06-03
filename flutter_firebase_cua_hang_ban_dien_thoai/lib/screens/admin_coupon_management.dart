import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coupon.dart';
import 'package:coupon_uikit_flutter/coupon_uikit.dart';
import 'admin_add_coupon.dart';
import 'admin_view_coupon_detail.dart';

class CouponManagement extends StatefulWidget {
  const CouponManagement({super.key});

  @override
  State<CouponManagement> createState() => _CouponManagementState();
}

class _CouponManagementState extends State<CouponManagement> {
  List<Coupon> coupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    final snapshot = await FirebaseFirestore.instance
      .collection('couponCode')
      .where('validity', isEqualTo: true)
      .get();

    final data = snapshot.docs.map((doc) {
      return Coupon.fromMap(doc.id, doc.data());
    }).toList();

    setState(() {
      coupons = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? Center(child: CircularProgressIndicator())
          : coupons.isEmpty ? Center(child: Text("No available coupons"))
          : ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return buildCouponCard(coupon, context);
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCoupon()),
          ).then((_) => fetchCoupons());
        },
        backgroundColor: Color(0xFFDB3022),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
        tooltip: "Add Coupon",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Widget buildCouponCard(Coupon coupon, BuildContext context) {
  const Color primaryColor = Color(0xffcbf3f0);
  const Color secondaryColor = Color(0xff368f8b);
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CouponDetail(coupon: coupon)),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CouponCard(
        height: 120,
        backgroundColor: primaryColor,
        curveAxis: Axis.vertical,
        firstChild: Container(
          decoration: const BoxDecoration(
            color: secondaryColor,
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
                        "${(coupon.discountMoney).toStringAsFixed(0)}VND",
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
              const Expanded(
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
                '${coupon.couponCode}',
                style: const TextStyle(
                  fontSize: 24,
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Created at: ${DateFormat('dd/MM/yyyy').format(coupon.createdAt)}',
                style: const TextStyle(
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}



