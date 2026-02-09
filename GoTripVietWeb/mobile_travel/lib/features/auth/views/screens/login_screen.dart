import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Ensure you have this package
import '../../view_models/auth_view_model.dart';
import '../../../home/views/screens/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isObscure = true;
  @override
  void initState() {
    super.initState();
    // Simple fade-in animation for "Lively" feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. LIVELY HEADER (Image + Welcome Text)
            Stack(
              children: [
                // Background Image
                Container(
                  height: size.height * 0.35,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        "https://img.freepik.com/free-vector/travel-concept-with-landmarks_1057-4873.jpg",
                      ),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                // Gradient Overlay for text readability
                Container(
                  height: size.height * 0.35,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.teal.withOpacity(0.3),
                        Colors.teal.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Welcome Text
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Xin chào,",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Sẵn sàng cho chuyến đi mới?",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. FORM SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Input
                      _buildFriendlyInput(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_rounded,
                        validator: (v) =>
                            v!.isEmpty ? "Vui lòng nhập email" : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      _buildFriendlyInput(
                        controller: _passwordController,
                        label: "Mật khẩu",
                        icon: Icons.lock_rounded,
                        isPassword: true, // This marks it as a password field
                        obscureText: _isObscure, // Pass the dynamic state
                        validator: (v) =>
                            v!.length < 6 ? "Mật khẩu quá ngắn" : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            // Change icon based on state
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // Toggle state
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {}, // TODO: Implement Forgot Password
                          child: const Text(
                            "Quên mật khẩu?",
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Error Message
                      if (authViewModel.errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authViewModel.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 3. BIG GRADIENT BUTTON
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Colors.tealAccent, Colors.teal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: authViewModel.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    bool success = await authViewModel.login(
                                      _emailController.text,
                                      _passwordController.text,
                                      
                                    );
                                    if (success && mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                          child: authViewModel.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 4. SOCIAL LOGIN & REGISTER
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Hoặc đăng nhập với",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            "assets/icons/google.png",
                            Colors.red,
                          ), // Placeholder color if no icon
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            "assets/icons/facebook.png",
                            Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Chưa có tài khoản? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text(
                              "Đăng ký ngay",
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Friendly Inputs
  Widget _buildFriendlyInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false, // Add this param
    Widget? suffixIcon, // Add this param
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        // If it is a password field, use the obscureText state passed in.
        // If not (e.g. Email), it is always false.
        obscureText: isPassword ? obscureText : false,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          suffixIcon: suffixIcon, // Place the eye icon here
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Helper for Social Buttons
  Widget _buildSocialButton(String assetPath, Color placeholderColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      // In a real app, use Image.asset(assetPath)
      child: Icon(Icons.public, color: placeholderColor, size: 30),
    );
  }
}
