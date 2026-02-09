import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Check if user is already logged in (Check token on app start)
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      // We have a token, let's fetch the full profile
      try {
        _user = await _authService.getProfile();
      } catch (e) {
        // Token might be expired
        await _authService.logout();
        _user = null;
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true; // Login success
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false; // Login failed
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String phone,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _authService.register(fullName, email, password, phone);
      _isLoading = false;
      notifyListeners();
      return true; // Register success
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateUserInfo(String fullName, String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Call API to update server
      final updatedUser = await _authService.updateProfile(
        fullName: fullName,
        phone: phone,
      );

      // DEBUG: Print to Console to verify data
      print("📱 APP: Updating User Info...");
      print("Old Name: ${_user?.fullName}");
      print("New Name from Server: ${updatedUser.fullName}");

      // 2. Update the User in Memory (Immediate UI Update)
      _user = updatedUser;

      // 3. ✅ SAVE TO LOCAL STORAGE (Crucial Step!)
      // This ensures if you restart the app, the new name is still there.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));

      return true; // Success
    } catch (e) {
      print("❌ Update Profile Error: $e");
      return false; // Failed
    } finally {
      _isLoading = false;
      // 4. Trigger UI Rebuild
      notifyListeners();
    }
  }
}
