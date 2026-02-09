import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/login_response.dart';

/// Service for authentication-related API calls
class AuthService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Login with username and password
  static Future<LoginResponse> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Lỗi kết nối (${response.statusCode}): ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
      );
    }
  }

  /// Register a new user
  static Future<String> register(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return "Đăng ký thành công! Vui lòng đăng nhập.";
    } else {
      throw Exception(response.body);
    }
  }
}
