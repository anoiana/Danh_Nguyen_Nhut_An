import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ViewModels
import '../../../auth/view_models/auth_view_model.dart';

// Screens
import '../../../auth/views/screens/login_screen.dart';
import 'order_history_screen.dart';

import 'edit_profile_screen.dart'; // Ensure this file exists from previous steps

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Get User Data from ViewModel
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    // 2. Safety Logic for Avatar
    ImageProvider? avatarImage;
    if (user != null && user.avatar != null && user.avatar!.isNotEmpty) {
      avatarImage = CachedNetworkImageProvider(user.avatar!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft modern grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================================
            // 1. MODERN HEADER SECTION (Gradient + Avatar + Stats)
            // ==========================================================
            Stack(
              clipBehavior:
                  Clip.none, // Allows the card to float outside the container
              children: [
                // A. Background Gradient
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                ),

                // B. User Info (Avatar + Name)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Avatar with border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(
                        user?.fullName ?? "Khách hàng",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Text(
                        user?.email ?? "Vui lòng đăng nhập",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Spacer to push content down below the floating card
            const SizedBox(height: 30),

            // ==========================================================
            // 2. MENU SECTIONS
            // ==========================================================

            // --- Section: ACCOUNT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle("Tài khoản"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: "Thông tin cá nhân",
                          subtitle: "Chỉnh sửa tên, số điện thoại",
                          onTap: () {
                            // Navigate to Edit Profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: "Đổi mật khẩu",
                          onTap: () {
                            // TODO: Navigate to Change Password
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Section: ACTIVITY ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle("Hoạt động"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: "Lịch sử đơn hàng",
                          onTap: () {
                            // ✅ Navigate to Order History
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderHistoryScreen(),
                              ),
                            );
                          },
                          trailingText: "Xem tất cả",
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.favorite_border,
                          title: "Đã lưu",
                          onTap: () {},
                          badgeCount: 2, // Hardcoded for demo
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Section: SUPPORT & SETTINGS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle("Hỗ trợ & Cài đặt"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.headset_mic_outlined,
                          title: "Trung tâm trợ giúp",
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: "Cài đặt ứng dụng",
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: "Đăng xuất",
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          iconBgColor: Colors.red.withOpacity(0.1),
                          onTap: () {
                            authViewModel.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Phiên bản 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELPER WIDGETS
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF00897B), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 60, // Align with text
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF00897B),
    Color? iconBgColor,
    Color textColor = Colors.black87,
    String? trailingText,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      // Add Ink response
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor ?? iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing Widgets (Text or Badge)
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

            if (badgeCount != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
