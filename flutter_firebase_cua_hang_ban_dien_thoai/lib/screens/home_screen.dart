import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/models/gridview_product_model.dart';
import 'package:cross_platform_mobile_app_development/screens/chat_screen.dart';
import 'package:cross_platform_mobile_app_development/screens/product_catalog.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:cross_platform_mobile_app_development/widgets/gridview_homescreen.dart';
import 'package:cross_platform_mobile_app_development/widgets/nav_drawer.dart';
import 'package:cross_platform_mobile_app_development/widgets/tab_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = "";

  final List<GridviewProductModel> laptopInfo = [
    GridviewProductModel(
      imageUrl: "assets/laptop1.jpg",
      title: 'Promotion Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Promotion Products',
              category: 'Laptop',
              filterType: 'promotion',
            ),
          ),
        );
      },
      category: "Laptop",
    ),
    GridviewProductModel(
      imageUrl: "assets/laptop2.png",
      title: 'New Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'New Products',
              category: 'Laptop',
              filterType: 'new',
            ),
          ),
        );
      },
      category: "Laptop",
    ),
    GridviewProductModel(
      imageUrl: "assets/laptop3.jpg",
      title: 'Best Seller',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Best Seller',
              category: 'Laptop',
              filterType: 'bestseller',
            ),
          ),
        );
      },
      category: "Laptop",
    ),
    GridviewProductModel(
      imageUrl: "assets/laptop3.jpg",
      title: 'All Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'All Products',
              category: 'Laptop',
              filterType: 'all',
            ),
          ),
        );
      },
      category: "Laptop",
    ),
  ];

  final List<GridviewProductModel> monitorInfo = [
    GridviewProductModel(
      imageUrl: "assets/monitor6.jpg",
      title: 'Promotion Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Promotion Products',
              category: "Monitor",
              filterType: 'promotion',
            ),
          ),
        );
      },
      category: "Monitor",
    ),
    GridviewProductModel(
      imageUrl: "assets/monitor5.jpg",
      title: 'New Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'New Products',
              category: "Monitor",
              filterType: 'new',
            ),
          ),
        );
      },
      category: "Monitor",
    ),
    GridviewProductModel(
      imageUrl: "assets/monitor3.jpg",
      title: 'Best Seller',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Best Seller',
              category: "Monitor",
              filterType: 'bestseller',
            ),
          ),
        );
      },
      category: "Monitor",
    ),
    GridviewProductModel(
      imageUrl: "assets/monitor3.jpg",
      title: 'All Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'All Products',
              category: "Monitor",
              filterType: 'all',
            ),
          ),
        );
      },
      category: "Monitor",
    ),
  ];

  final List<GridviewProductModel> hardDriverInfo = [
    GridviewProductModel(
      imageUrl: "assets/harddriver5.jpg",
      title: 'Promotion Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Promotion Products',
              category: "Hard Drivers",
              filterType: 'promotion',
            ),
          ),
        );
      },
      category: "Hard Drivers",
    ),
    GridviewProductModel(
      imageUrl: "assets/harddriver2.jpg",
      title: 'New Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'New Products',
              category: "Hard Drivers",
              filterType: 'new',
            ),
          ),
        );
      },
      category: "Hard Drivers",
    ),
    GridviewProductModel(
      imageUrl: "assets/harddriver3.jpg",
      title: 'Best Seller',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Best Seller',
              category: "Hard Drivers",
              filterType: 'bestseller',
            ),
          ),
        );
      },
      category: "Hard Drivers",
    ),
    GridviewProductModel(
      imageUrl: "assets/harddriver3.jpg",
      title: 'All Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'All Products',
              category: "Hard Drivers",
              filterType: 'all',
            ),
          ),
        );
      },
      category: "Hard Drivers",
    ),
  ];

  final List<GridviewProductModel> mouseInfo = [
    GridviewProductModel(
      imageUrl: "assets/mouse1.jpg",
      title: 'Promotion Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Promotion Products',
              category: "Mouse",
              filterType: 'promotion',
            ),
          ),
        );
      },
      category: "Mouse",
    ),
    GridviewProductModel(
      imageUrl: "assets/mouse2.jpg",
      title: 'New Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'New Products',
              category: "Mouse",
              filterType: 'new',
            ),
          ),
        );
      },
      category: "Mouse",
    ),
    GridviewProductModel(
      imageUrl: "assets/mouse4.png",
      title: 'Best Seller',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Best Seller',
              category: "Mouse",
              filterType: 'bestseller',
            ),
          ),
        );
      },
      category: "Mouse",
    ),
    GridviewProductModel(
      imageUrl: "assets/mouse4.png",
      title: 'All Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'All Products',
              category: "Mouse",
              filterType: 'all',
            ),
          ),
        );
      },
      category: "Mouse",
    ),
  ];

  final List<GridviewProductModel> keyboardInfo = [
    GridviewProductModel(
      imageUrl: "assets/keyboard1.jpg",
      title: 'Promotion Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Promotion Products',
              category: "Keyboard",
              filterType: 'promotion',
            ),
          ),
        );
      },
      category: "Keyboard",
    ),
    GridviewProductModel(
      imageUrl: "assets/keyboard4.jpg",
      title: 'New Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'New Products',
              category: "Keyboard",
              filterType: 'new',
            ),
          ),
        );
      },
      category: "Keyboard",
    ),
    GridviewProductModel(
      imageUrl: "assets/keyboard5.jpg",
      title: 'Best Seller',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'Best Seller',
              category: "Keyboard",
              filterType: 'bestseller',
            ),
          ),
        );
      },
      category: "Keyboard",
    ),
    GridviewProductModel(
      imageUrl: "assets/keyboard5.jpg",
      title: 'All Products',
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductCatalog(
              title: 'All Products',
              category: "Keyboard",
              filterType: 'all',
            ),
          ),
        );
      },
      category: "Keyboard",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? 'unknown'; // Truyền uid vào NavDrawer

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'E-Commerce App',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColor.primaryColor,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          actions: <Widget>[
            StreamBuilder<int>(
              stream: _getUnreadMessageCountStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasData && snapshot.data! > 0) {
                  int unreadCount = snapshot.data!;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.white),
                        onPressed: () {
                          _updateMessageReadStatus(uid);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                customerId: uid,
                                role: 'Customer',
                              ),
                            ),
                          );
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
                  icon: const Icon(Icons.message, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(customerId: uid, role: 'Customer'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        drawer: NavDrawer(uid: uid),
        body: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth >= 1200 ? 4 : 2;

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.black12,
                      ),
                      child: TabBar(
                        onTap: (index) {
                          setState(() {
                            _selectedCategory = [
                              "Laptops",
                              "Monitors",
                              "Hard Drivers",
                              "Keyboards",
                              "Mouse",
                            ][index];
                          });
                        },
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: const BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black54,
                        tabs: const [
                          TabItem(title: 'Laptops', count: 1),
                          TabItem(title: 'Monitors', count: 2),
                          TabItem(title: 'Hard Drivers', count: 3),
                          TabItem(title: 'Keyboards', count: 4),
                          TabItem(title: 'Mouse', count: 5),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridviewHomescreen(
                          listProductInfoInHomescreen: laptopInfo,
                          selectedCategory: _selectedCategory,
                          crossAxisCount: crossAxisCount,
                        ),
                        GridviewHomescreen(
                          listProductInfoInHomescreen: monitorInfo,
                          selectedCategory: _selectedCategory,
                          crossAxisCount: crossAxisCount,
                        ),
                        GridviewHomescreen(
                          listProductInfoInHomescreen: hardDriverInfo,
                          selectedCategory: _selectedCategory,
                          crossAxisCount: crossAxisCount,
                        ),
                        GridviewHomescreen(
                          listProductInfoInHomescreen: keyboardInfo,
                          selectedCategory: _selectedCategory,
                          crossAxisCount: crossAxisCount,
                        ),
                        GridviewHomescreen(
                          listProductInfoInHomescreen: mouseInfo,
                          selectedCategory: _selectedCategory,
                          crossAxisCount: crossAxisCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Stream<int> _getUnreadMessageCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  void _updateMessageReadStatus(String uid) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}