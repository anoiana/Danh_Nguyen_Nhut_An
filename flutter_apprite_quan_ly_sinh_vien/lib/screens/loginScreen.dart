import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/AppwriteService.dart';
import 'package:midterm/screens/teacherScreen.dart';
import 'package:midterm/screens/studentScreen.dart';
import 'package:midterm/screens/adminScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _roles = ['Student', 'Teacher', 'Admin'];
  String? _selectedRole;
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn vai trò'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập tài khoản'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedRole == "Admin" ? 'Vui lòng nhập Admin ID' : 'Vui lòng nhập mã bí mật'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appwriteService = AppwriteService();

      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a role'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      if (_accountController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      final userInfo = await appwriteService.getLoggedInUser(
        role: _selectedRole!,
        account: _accountController.text,
        secretCode: _passwordController.text,
      );

      if (userInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid credentials. Please try again.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      if (_selectedRole == "Admin") {
        final adminId = "680dc2e800198007feb6";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(adminId: adminId,),
          ),
        );
      } else if (_selectedRole == "Teacher") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherScreen(
              teacherId: userInfo['teacherId'] ?? 'Unknown ID',
            ),
          ),
        );
      } else if (_selectedRole == "Student") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentScreen(
              studentId: userInfo['studentId'] ?? 'Unknown ID',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid role selected'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    final double maxWidth = isLargeScreen ? 500 : double.infinity;
    final double fontSizeTitle = isLargeScreen ? 32 : 28;
    final double fontSizeButton = isLargeScreen ? 20 : 18;
    final double paddingValue = isLargeScreen ? 32.0 : 24.0;
    final double fieldHeight = isLargeScreen ? 60.0 : 56.0;
    final double iconSize = isLargeScreen ? 28 : 24;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 40.0),
            margin: isLargeScreen ? EdgeInsets.all(20.0) : null,
            decoration: isLargeScreen
                ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ĐĂNG NHẬP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.blue[600],
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 60 : 40),
                SizedBox(
                  height: fieldHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      hint: Text(
                        'Chọn vai trò',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: isLargeScreen ? 18 : 16,
                        ),
                      ),
                      items: _roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: isLargeScreen ? 18 : 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                          _accountController.clear();
                          _passwordController.clear();
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        labelText: 'Vai trò',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                          fontSize: isLargeScreen ? 18 : 16,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.blue[600],
                          size: iconSize,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue[600],
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isLargeScreen ? 30 : 20),
                SizedBox(
                  height: fieldHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _accountController,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: isLargeScreen ? 18 : 16,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        labelText: _selectedRole == "Admin" ? 'Email' : 'Id Code',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                          fontSize: isLargeScreen ? 18 : 16,
                        ),
                        prefixIcon: Icon(
                          _selectedRole == "Admin" ? Icons.email : Icons.badge,
                          color: Colors.blue[600],
                          size: iconSize,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                      ),
                      keyboardType: _selectedRole == "Admin"
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                    ),
                  ),
                ),
                SizedBox(height: isLargeScreen ? 30 : 20),
                SizedBox(
                  height: fieldHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: isLargeScreen ? 18 : 16,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        labelText: _selectedRole == "Admin" ? 'Admin ID' : 'Password',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                          fontSize: isLargeScreen ? 18 : 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.blue[600],
                          size: iconSize,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blue[600],
                            size: iconSize,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isLargeScreen ? 30 : 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(
                      vertical: isLargeScreen ? 20 : 16,
                      horizontal: isLargeScreen ? 120 : 100,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(Colors.blue[800]),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? SizedBox(
                    width: isLargeScreen ? 28 : 24,
                    height: isLargeScreen ? 28 : 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Text(
                    'Đăng nhập',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: fontSizeButton,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}