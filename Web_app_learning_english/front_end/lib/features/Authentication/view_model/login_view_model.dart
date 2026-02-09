import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/base_view_model.dart';
import '../service/auth_service.dart';
import '../model/login_response.dart';

class LoginViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();

  Future<bool> login(String username, String password) async {
    setBusy(true);
    try {
      final LoginResponse response = await _authService.login(
        username,
        password,
      );

      // Persist user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', response.userId);
      await prefs.setString('username', response.username);

      setBusy(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setBusy(false);
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    setBusy(true);
    try {
      await _authService.register(username, password);
      // Registration successful, usually we don't login automatically here or we can
      // For now just return true
      setBusy(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setBusy(false);
      return false;
    }
  }
}
