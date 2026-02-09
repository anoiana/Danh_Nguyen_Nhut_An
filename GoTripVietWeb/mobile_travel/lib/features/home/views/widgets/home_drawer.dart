import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/view_models/auth_view_model.dart';
import '../../../auth/views/screens/login_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access AuthViewModel to get user data
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    return Drawer(
      child: Column(
        children: [
          // 1. HEADER (User Info)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.teal,
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  "https://img.freepik.com/free-photo/travel-concept-with-baggage_23-2149153260.jpg",
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.isNotEmpty == true 
                    ? user!.fullName[0].toUpperCase() 
                    : "U",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            accountName: Text(
              user?.fullName ?? "Khách",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? "Vui lòng đăng nhập"),
          ),

          // 2. MENU ITEMS
          ListTile(
            leading: const Icon(Icons.home, color: Colors.teal),
            title: const Text("Trang chủ"),
            onTap: () => Navigator.pop(context), // Close drawer
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: const Text("Hồ sơ cá nhân"),
            onTap: () {
              // Navigation logic here
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.teal),
            title: const Text("Đơn hàng của tôi"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text("Cài đặt"),
            onTap: () {},
          ),

          const Spacer(), // Pushes Logout to the bottom

          // 3. LOGOUT BUTTON
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Đăng xuất?"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                // Perform Logout
                await authViewModel.logout();
                
                // Redirect to Login Screen
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}