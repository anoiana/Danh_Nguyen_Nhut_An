// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../service/AppwriteService.dart';
//
// class ResetPasswordScreen extends StatefulWidget {
//   final String userId;
//   final String secret;
//
//   ResetPasswordScreen({required this.userId, required this.secret});
//
//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }
//
// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   final AppwriteService _appwriteService = AppwriteService();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//
//   Future<void> _handleResetPassword() async {
//     if (_newPasswordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please enter a new password'),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//       return;
//     }
//
//     if (_newPasswordController.text != _confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Passwords do not match'),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       await _appwriteService.updatePassword(
//         userId: widget.userId,
//         secret: widget.secret,
//         newPassword: _newPasswordController.text,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Password reset successfully'),
//           backgroundColor: Colors.green[700],
//         ),
//       );
//       Navigator.pushReplacementNamed(context, '/login');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to reset password: $e'),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isLargeScreen = MediaQuery.of(context).size.width > 600;
//     final double maxWidth = isLargeScreen ? 500 : double.infinity;
//     final double fontSizeTitle = isLargeScreen ? 32 : 28;
//     final double fontSizeButton = isLargeScreen ? 20 : 18;
//     final double paddingValue = isLargeScreen ? 32.0 : 24.0;
//     final double fieldHeight = isLargeScreen ? 60.0 : 56.0;
//     final double iconSize = isLargeScreen ? 28 : 24;
//
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Center(
//         child: SingleChildScrollView(
//           child: Container(
//             constraints: BoxConstraints(maxWidth: maxWidth),
//             padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 40.0),
//             margin: isLargeScreen ? EdgeInsets.all(20.0) : null,
//             decoration: isLargeScreen
//                 ? BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 10,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             )
//                 : null,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text(
//                   'Reset Password',
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     color: Colors.blue[600],
//                     fontSize: fontSizeTitle,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: isLargeScreen ? 60 : 40),
//                 SizedBox(
//                   height: fieldHeight,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: TextField(
//                       controller: _newPasswordController,
//                       obscureText: _obscurePassword,
//                       style: GoogleFonts.poppins(
//                         color: Colors.black87,
//                         fontSize: isLargeScreen ? 18 : 16,
//                       ),
//                       decoration: InputDecoration(
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 0,
//                           horizontal: 16,
//                         ),
//                         labelText: 'New Password',
//                         labelStyle: GoogleFonts.poppins(
//                           color: Colors.blue[600],
//                           fontSize: isLargeScreen ? 18 : 16,
//                         ),
//                         prefixIcon: Icon(
//                           Icons.lock,
//                           color: Colors.blue[600],
//                           size: iconSize,
//                         ),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                             color: Colors.blue[600],
//                             size: iconSize,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                         filled: true,
//                         fillColor: Colors.transparent,
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: isLargeScreen ? 30 : 20),
//                 SizedBox(
//                   height: fieldHeight,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: TextField(
//                       controller: _confirmPasswordController,
//                       obscureText: _obscurePassword,
//                       style: GoogleFonts.poppins(
//                         color: Colors.black87,
//                         fontSize: isLargeScreen ? 18 : 16,
//                       ),
//                       decoration: InputDecoration(
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 0,
//                           horizontal: 16,
//                         ),
//                         labelText: 'Confirm Password',
//                         labelStyle: GoogleFonts.poppins(
//                           color: Colors.blue[600],
//                           fontSize: isLargeScreen ? 18 : 16,
//                         ),
//                         prefixIcon: Icon(
//                           Icons.lock,
//                           color: Colors.blue[600],
//                           size: iconSize,
//                         ),
//                         filled: true,
//                         fillColor: Colors.transparent,
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: isLargeScreen ? 30 : 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     padding: EdgeInsets.symmetric(
//                       vertical: isLargeScreen ? 20 : 16,
//                       horizontal: isLargeScreen ? 120 : 100,
//                     ),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     elevation: 5,
//                   ).copyWith(
//                     overlayColor: WidgetStateProperty.all(Colors.blue[800]),
//                   ),
//                   onPressed: _isLoading ? null : _handleResetPassword,
//                   child: _isLoading
//                       ? SizedBox(
//                     width: isLargeScreen ? 28 : 24,
//                     height: isLargeScreen ? 28 : 24,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 3,
//                     ),
//                   )
//                       : Text(
//                     'Reset Password',
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: fontSizeButton,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
// }