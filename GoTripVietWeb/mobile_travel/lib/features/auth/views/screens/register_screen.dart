import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State for password visibility
  bool _isObscure = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Animation setup
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
            // 1. HEADER (Different image for variety)
            Stack(
              children: [
                Container(
                  height: size.height * 0.30,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      // Using a different travel image (Map/Planning)
                      image: CachedNetworkImageProvider("https://img.freepik.com/free-photo/travel-concept-with-baggage_23-2149153260.jpg"), 
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                ),
                Container(
                  height: size.height * 0.30,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.teal.withOpacity(0.3), Colors.teal.withOpacity(0.9)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Tạo tài khoản", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text("Bắt đầu hành trình của bạn!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
                      // Full Name
                      _buildFriendlyInput(
                        controller: _nameController,
                        label: "Họ và tên",
                        icon: Icons.person_rounded,
                        validator: (v) => v!.isEmpty ? "Vui lòng nhập họ tên" : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildFriendlyInput(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_rounded,
                        validator: (v) => !v!.contains("@") ? "Email không hợp lệ" : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildFriendlyInput(
                        controller: _phoneController,
                        label: "Số điện thoại",
                        icon: Icons.phone_android_rounded,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Password with Eye Icon
                      _buildFriendlyInput(
                        controller: _passwordController,
                        label: "Mật khẩu",
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        obscureText: _isObscure,
                        validator: (v) => v!.length < 6 ? "Tối thiểu 6 ký tự" : null,
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),

                      // Error Message
                      if (authViewModel.errorMessage.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(authViewModel.errorMessage, style: const TextStyle(color: Colors.red)),
                        ),

                      const SizedBox(height: 30),

                      // 3. REGISTER BUTTON
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: authViewModel.isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              bool success = await authViewModel.register(
                                _nameController.text,
                                _emailController.text,
                                _passwordController.text,
                                _phoneController.text,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập.")),
                                );
                                Navigator.pop(context); // Go back to login
                              }
                            }
                          },
                          child: authViewModel.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Đăng ký", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. LOGIN LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Đã có tài khoản? ", style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text("Đăng nhập", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                          )
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

  // Helper Method (Reused)
  Widget _buildFriendlyInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, offset: const Offset(0, 4), blurRadius: 10)]
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: inputType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
          ),
        ),
      ),
    );
  }
}