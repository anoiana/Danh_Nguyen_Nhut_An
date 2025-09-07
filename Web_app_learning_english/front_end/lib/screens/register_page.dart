import 'package:flutter/material.dart';
import '../api/auth_service.dart';

// Màu sắc chủ đạo
const Color primaryPink = Color(0xFFE91E63);
const Color accentPink = Color(0xFFFF80AB);
const Color backgroundPink = Color(0xFFFCE4EC);
const Color darkTextColor = Color(0xFF333333);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final result = await AuthService.register(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted && result.startsWith("Đăng ký thành công")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result, style: const TextStyle(color: Colors.white)),
            backgroundColor: primaryPink,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _message = result;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Đã có lỗi xảy ra: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.white)), // Đặt màu trắng cho tiêu đề
        backgroundColor: primaryPink,
        elevation: 0,
        foregroundColor: Colors.white, // Đặt màu trắng cho icon và văn bản khác (như nút back)
      ),
      body: Container(
        color: backgroundPink,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add, size: 60, color: primaryPink),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Tên đăng nhập',
                        prefixIcon: const Icon(Icons.account_circle, color: primaryPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryPink, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock, color: primaryPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryPink, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility_off, color: primaryPink),
                          onPressed: () {},
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                        ),
                      ),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryPink))
                        : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(primaryPink),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      child: const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}