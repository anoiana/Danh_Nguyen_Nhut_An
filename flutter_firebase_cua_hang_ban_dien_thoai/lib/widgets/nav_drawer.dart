import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_home_screen.dart';
import 'package:cross_platform_mobile_app_development/screens/change_password.dart';
import 'package:cross_platform_mobile_app_development/screens/change_profile.dart';
import 'package:cross_platform_mobile_app_development/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/screens/login.dart';
import 'package:cross_platform_mobile_app_development/screens/orders_admin.dart';
import 'package:cross_platform_mobile_app_development/screens/orders_customer.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/signup.dart';

class NavDrawer extends StatelessWidget {
  final String uid;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NavDrawer({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLoggedIn = currentUser != null;

    if (!isLoggedIn) {
      return Drawer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildGuestHeader(context),
              buildGuestMenuItems(context),
            ],
          ),
        ),
      );
    }

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy dữ liệu người dùng'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final fullName = userData['fullName'] ?? 'No Name';
          final email = userData['email'] ?? 'No Email';
          final imageLink = userData['image'] ?? null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildHeader(context, fullName, email, imageLink, currentUser.uid),
                buildUserMenuItems(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildGuestHeader(BuildContext context) => Material(
    color: AppColor.primaryColor,
    child: Container(
      padding: EdgeInsets.only(
        top: 24 + MediaQuery.of(context).padding.top,
        bottom: 24,
      ),
      child: const Column(
        children: [
          CircleAvatar(radius: 52, backgroundImage: AssetImage('assets/laptop2.png')),
          SizedBox(height: 12),
          Text("Khách", style: TextStyle(fontSize: 28, color: Colors.white)),
          SizedBox(height: 4),
          Text("Chưa có email", style: TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    ),
  );

  Widget buildGuestMenuItems(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    child: Wrap(
      runSpacing: 16,
      children: [
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('Login'),
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.app_registration),
          title: const Text('Sign Up'),
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUp()));
          },
        ),
      ],
    ),
  );

  Widget buildHeader(BuildContext context, String fullName, String email, String? imageLink, String uid) => Material(
    color: AppColor.primaryColor,
    child: Container(
      padding: EdgeInsets.only(
        top: 24 + MediaQuery.of(context).padding.top,
        bottom: 24,
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 52, backgroundImage: getUserImage(imageLink)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(fullName, style: const TextStyle(fontSize: 28, color: Colors.white)),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ChangeProfile(uid: uid)),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          Text(email, style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    ),
  );

  Widget buildUserMenuItems(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    child: Wrap(
      runSpacing: 16,
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('Home'),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? role = prefs.getString('userRole');
            if (role == 'Admin') {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AdminHomeScreen()));
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.password_rounded),
          title: const Text('Change Password'),
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ChangePassword()),
          ),
        ),
        FutureBuilder<String?>(
          future: SharedPreferences.getInstance().then(
                (prefs) => prefs.getString('userRole'),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink(); // Show nothing while loading
            }
            bool isAdmin = snapshot.data == 'Admin';
            return isAdmin
                ? SizedBox.shrink() // Hide the ListTile for Admin
                : ListTile(
              leading: const Icon(Icons.format_align_justify),
              title: const Text('Orders'),
              onTap: () async {
                SharedPreferences prefs =
                await SharedPreferences.getInstance();
                String? role = prefs.getString('userRole');
                if (role == 'Admin') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => OrdersAdmin()),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => OrdersCustomer(userId: uid),
                    ),
                  );
                }
              },
            );
          },
        ),
        const Divider(color: Colors.black87),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      logout(context);
                      Navigator.of(context).pop();
                    },
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );

  void logout(BuildContext context) async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
          (route) => false, // Xóa tất cả màn hình trước đó
    );
  }

  ImageProvider? getUserImage(String? imageLink) {
    if (imageLink == null || imageLink.isEmpty) {
      return const AssetImage('assets/laptop2.png');
    }
    if (imageLink.startsWith('http') || imageLink.startsWith('https://')) {
      return NetworkImage(imageLink);
    }
    const base64Prefix = "base64,";
    final base64Index = imageLink.indexOf(base64Prefix);
    if (base64Index != -1) {
      final actualBase64 = imageLink.substring(
        base64Index + base64Prefix.length,
      );
      try {
        final bytes = base64Decode(actualBase64);
        return MemoryImage(bytes);
      } catch (e) {
        return const AssetImage('assets/laptop2.png');
      }
    }
    try {
      final bytes = base64Decode(imageLink);
      return MemoryImage(bytes);
    } catch (e) {
      return const AssetImage('assets/laptop2.png');
    }
  }
}
