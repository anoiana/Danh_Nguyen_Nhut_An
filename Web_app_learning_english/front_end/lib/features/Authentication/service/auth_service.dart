import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/login_response.dart';

class AuthService {
  final http.Client _client = http.Client();

  Future<LoginResponse> login(String username, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/login');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<String> register(String username, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/register');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return "Registration successful";
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
