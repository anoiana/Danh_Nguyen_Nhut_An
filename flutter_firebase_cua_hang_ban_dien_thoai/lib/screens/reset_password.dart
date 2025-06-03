import 'package:cross_platform_mobile_app_development/screens/login.dart'; // Keep your actual path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  String errorMessage = "";
  bool isLoading = false;
  bool _emailSent = false;

  // --- Logic remains unchanged ---
  Future<void> resetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = "Vui lòng nhập địa chỉ email hợp lệ.";
        _emailSent = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
      _emailSent = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        isLoading = false;
        _emailSent = true;
        errorMessage = "";
      });

      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã gửi liên kết đặt lại mật khẩu tới $email"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        _emailSent = false;
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          errorMessage = 'Không tìm thấy người dùng với email này.';
        } else {
          errorMessage = 'Lỗi: ${e.message ?? "Không thể gửi email."}';
        }
      });
    }
    catch (error) {
      setState(() {
        isLoading = false;
        _emailSent = false;
        errorMessage = "Đã xảy ra lỗi không mong muốn: ${error.toString()}";
      });
    } finally {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // --- End of unchanged Logic ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = Colors.blue[700]!;
    // --- REVERTED HERE: Use light blue for TextField background ---
    final Color textFieldBackgroundColor = Colors.blue[50]!; // Reverted to blue[50]

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Forgot Your Password?",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Enter your email address below and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Email Input Field using reverted background color ---
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    // Removed explicit text/hint styling as it might not be needed
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      prefixIcon: Icon(Icons.email_outlined, color: primaryColor, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: textFieldBackgroundColor, // Use the reverted light blue color
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- Error Message Display ---
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // --- Success Message Display ---
                  if (_emailSent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        "Password reset link sent to ${emailController.text.trim()}. Please check your inbox (and spam folder).",
                        style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // --- Loading Indicator or Reset Button ---
                  SizedBox(
                    height: 50,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : ElevatedButton(
                      onPressed: (_emailSent || isLoading) ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "SEND RESET LINK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}