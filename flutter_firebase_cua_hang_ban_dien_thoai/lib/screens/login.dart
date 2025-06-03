import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/screens/admin_home_screen.dart';
import 'package:cross_platform_mobile_app_development/screens/reset_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'signup.dart';
import 'dart:convert';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  // okkk
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Lưu thông tin đăng nhập nếu người dùng chọn "Remember me"
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
    }

    try {
      // Đăng nhập với Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Đồng bộ giỏ hàng từ SharedPreferences sang Firestore
      await syncGuestCartToFirestore(uid);

      // Kiểm tra thông tin người dùng trong Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String status = userData['status'] ?? 'Active'; // Mặc định là Active nếu không có status
        if (status == 'Banned') {
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Banned'),
              content: const Text(
                'Your account has been banned. Please contact support.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        if (userData.containsKey('role')) {
          String role = userData['role'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', role);

          if (role == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else if (role == 'Customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = "User role is not defined.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "User document does not exist.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = "Tài khoản không tồn tại.";
        } else if (e.code == 'wrong-password') {
          _errorMessage = "Mật khẩu không chính xác.";
        } else {
          _errorMessage = "Đăng nhập thất bại. Vui lòng thử lại.";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Đăng nhập thất bại: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> syncGuestCartToFirestore(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];
    if (guestCart.isEmpty) return;

    DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(uid);
    DocumentSnapshot cartSnapshot = await cartRef.get();

    List<Map<String, dynamic>> cartItems = guestCart.map((item) {
      try {
        return jsonDecode(item) as Map<String, dynamic>;
      } catch (e) {
        print("Error decoding cart item: $e, item: $item");
        return <String, dynamic>{}; // Trả về map rỗng nếu lỗi
      }
    }).where((item) => item.isNotEmpty).toList();

    if (cartItems.isEmpty) {
      print("No valid cart items to sync.");
      return;
    }

    try {
      if (!cartSnapshot.exists) {
        await cartRef.set({'productIds': cartItems});
      } else {
        Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> productIds = cartData['productIds'] ?? [];
        for (var item in cartItems) {
          int existingIndex = productIds.indexWhere(
                (existing) => existing['productId'] == item['productId'] && existing['variantId'] == item['variantId'],
          );
          if (existingIndex != -1) {
            productIds[existingIndex]['quantity'] = (productIds[existingIndex]['quantity'] as int? ?? 0) + (item['quantity'] as int? ?? 1);
          } else {
            productIds.add(item);
          }
        }
        await cartRef.update({'productIds': productIds});
      }

      // Xóa giỏ hàng tạm sau khi đồng bộ
      await prefs.remove('guestCart');
      print("Cart synced successfully for user $uid");
    } catch (e) {
      print("Error syncing cart to Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error syncing cart: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = const Color(0xFFDB3022); // Màu đỏ thay cho xanh dương
    final Color lightBackgroundColor = Colors.red[50]!; // Nền nhạt đỏ

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.login, // Icon đăng nhập
                      size: 60,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Sign In",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your credentials to login",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 35),

                    _buildTextField(
                      controller: _emailController,
                      hintText: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    const SizedBox(height: 18),
                    _buildPasswordField(
                      controller: _passwordController,
                      hintText: "Password",
                      obscureText: _obscureText,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? newValue) async {
                            setState(() {
                              _rememberMe = newValue ?? false;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                        Text(
                          "Remember me",
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const ResetPasswordScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Forgot your password?",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      height: 50,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp()),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required Color primaryColor,
    required Color lightBackgroundColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required Color primaryColor,
    required Color lightBackgroundColor,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
      ),
    );
  }
}