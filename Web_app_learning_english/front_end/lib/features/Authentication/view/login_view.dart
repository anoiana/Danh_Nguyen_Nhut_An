import 'dart:ui';
import 'package:flutter/material.dart';
import '../view_model/login_view_model.dart';
import '../../Library/view/library_view.dart';

// --- Theme Colors (Ported from LoginScreen) ---
const Color primaryPink = Color(0xFFE91E63);
const Color accentPink = Color(0xFFFF80AB);
const Color backgroundPink = Color(0xFFFCE4EC);
const Color darkTextColor = Color(0xFF333333);

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = LoginViewModel();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoginMode = true; // Toggle state

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _viewModel.setError("Vui lòng nhập tên đăng nhập và mật khẩu.");
      return;
    }

    if (_isLoginMode) {
      // Login Logic
      final success = await _viewModel.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LibraryView()),
        );
      }
    } else {
      // Register Logic
      final success = await _viewModel.register(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công! Vui lòng đăng nhập."),
          ),
        );
        setState(() {
          _isLoginMode = true; // Switch back to login
          _passwordController.clear();
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _viewModel.setError(''); // Clear errors
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          _isLoginMode
                              ? Icons.school_outlined
                              : Icons.person_add_alt_1_outlined,
                          size: 80,
                          color: primaryPink,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoginMode ? 'Chào mừng bạn!' : 'Tạo tài khoản mới',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _isLoginMode
                              ? 'Đăng nhập để bắt đầu học tập'
                              : 'Đăng ký để tham gia cùng chúng tôi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Tên đăng nhập',
                            prefixIcon: const Icon(
                              Icons.account_circle,
                              color: primaryPink,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: primaryPink,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: primaryPink,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryPink,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: primaryPink,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscureText,
                        ),
                        const SizedBox(height: 24),
                        // Error Message
                        if (_viewModel.errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _viewModel.errorMessage.replaceAll(
                                "Exception: ",
                                "",
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _viewModel.isBusy
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryPink,
                              ),
                            )
                            : ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  primaryPink,
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  Colors.white,
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 12),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              child: Text(
                                _isLoginMode ? 'Đăng nhập' : 'Đăng ký',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLoginMode
                                  ? 'Chưa có tài khoản?'
                                  : 'Đã có tài khoản?',
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLoginMode
                                    ? 'Đăng ký ngay'
                                    : 'Đăng nhập ngay',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryPink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
