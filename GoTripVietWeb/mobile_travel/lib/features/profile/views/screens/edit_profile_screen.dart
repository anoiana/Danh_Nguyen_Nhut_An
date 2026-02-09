import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/view_models/auth_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // Pre-fill data from the current logged-in user
    final user = Provider.of<AuthViewModel>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.fullName ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _emailController = TextEditingController(text: user?.email ?? ""); // Read-only
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ViewModel for loading state
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Chỉnh sửa thông tin",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Email (Read-Only)
              _buildLabel("ĐỊA CHỈ EMAIL"),
              TextField(
                controller: _emailController,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  "Email không thể thay đổi vì lý do bảo mật.",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Full Name
              _buildLabel("HỌ VÀ TÊN"),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(Icons.person_outline, "Nhập họ và tên"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Vui lòng nhập họ tên";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 3. Phone Number
              _buildLabel("SỐ ĐIỆN THOẠI"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(Icons.phone_outlined, "Nhập số điện thoại"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Vui lòng nhập số điện thoại";
                  }
                  if (val.length < 9) {
                    return "Số điện thoại không hợp lệ";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // 4. Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B), // Teal Color
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: authViewModel.isLoading
                      ? null
                      : () async {
                          // Dismiss keyboard
                          FocusScope.of(context).unfocus();

                          if (_formKey.currentState!.validate()) {
                            // Call API via ViewModel
                            final success = await authViewModel.updateUserInfo(
                              _nameController.text.trim(),
                              _phoneController.text.trim(),
                            );

                            if (!mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cập nhật hồ sơ thành công! 🎉"),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context); // Go back to Profile
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cập nhật thất bại. Vui lòng thử lại."),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: authViewModel.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Lưu thay đổi",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Label Builder
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Helper: Input Decoration
  InputDecoration _buildInputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF5F7FA), // Very light grey background
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}