import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_coupon_management.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_dashboard.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_order_management.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_product_management.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_support_customer.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_user_management.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:cross_platform_mobile_app_development/widgets/bottom_nav_model.dart';
import 'package:cross_platform_mobile_app_development/widgets/bottom_navbar.dart';
import 'package:cross_platform_mobile_app_development/widgets/nav_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final productNavKey = GlobalKey<NavigatorState>();
  final userNavKey = GlobalKey<NavigatorState>();
  final orderNavKey = GlobalKey<NavigatorState>();
  final couponNavKey = GlobalKey<NavigatorState>();
  final adminDashboardKey = GlobalKey<NavigatorState>();
  final supportCustomerKey = GlobalKey<NavigatorState>();

  int selectedTab = 0;
  List<BottomNavModel> items = [];

  @override
  void initState() {
    super.initState();
    items = [
      BottomNavModel(page: ProductManagement(), navKey: productNavKey),
      BottomNavModel(page: UserManagement(), navKey: userNavKey),
      BottomNavModel(page: OrderManagement(), navKey: orderNavKey),
      BottomNavModel(page: CouponManagement(), navKey: couponNavKey),
      BottomNavModel(page: AdminDashboard(), navKey: adminDashboardKey),
      BottomNavModel(page: AdminSupportCustomer(), navKey: supportCustomerKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? 'unknow';

    return Scaffold(
      appBar: AppBar(
        title: Text('E-Commerce App', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColor.primaryColor,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: <Widget>[
          StreamBuilder<int>(
            stream: _getTotalUnreadMessageCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasData && snapshot.data! > 0) {
                int unreadCount = snapshot.data!;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedTab = 5;
                        });
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.message_outlined, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedTab = 5;
                  });
                },
              );
            },
          ),
        ],
      ),
      drawer: NavDrawer(uid: uid),
      body: PopScope(
        canPop: items[selectedTab].navKey.currentState?.canPop() ?? true,
        onPopInvoked: (didPop) {
          if (!didPop) {
            if (items[selectedTab].navKey.currentState?.canPop() ?? false) {
              items[selectedTab].navKey.currentState?.pop();
            }
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: selectedTab,
            children:
                items
                    .map(
                      (page) => Navigator(
                        key: page.navKey,
                        onGenerateInitialRoutes: (navigator, initialRoute) {
                          return [
                            MaterialPageRoute(builder: (context) => page.page),
                          ];
                        },
                      ),
                    )
                    .toList(),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton:
              selectedTab != 5
                  ? Transform.translate(
                    offset: const Offset(
                      0,
                      4,
                    ), // Dịch chuyển lên trên 32px (nửa chiều cao FAB)
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      height: 64,
                      width: 64,
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        onPressed: () {
                          setState(() {
                            selectedTab = 4;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 3,
                            color: AppColor.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: AppColor.primaryColor,
                        ),
                      ),
                    ),
                  )
                  : null,
          bottomNavigationBar:
              selectedTab != 5
                  ? BottomNavBar(
                    pageIndex: selectedTab,
                    onTap: (index) {
                      if (index == selectedTab) {
                        items[index].navKey.currentState?.popUntil(
                          (route) => route.isFirst,
                        );
                      } else {
                        setState(() {
                          selectedTab = index;
                        });
                      }
                    },
                  )
                  : null, // Hide BottomNavigationBar when on chat screen
        ),
      ),
    );
  }

  Stream<int> _getTotalUnreadMessageCount() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('receiverId', isEqualTo: 'BnVj2FLLvLN8DQJ7ewL2pEUA8Nw2')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }
}
