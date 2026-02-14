import 'package:shared_preferences/shared_preferences.dart';
import 'package:hellen_app/features/Authentication/service/auth_service.dart';
import '../../../core/base_view_model.dart';
import '../model/login_response.dart';

class LoginViewModel extends BaseViewModel {
  Future<bool> login(String username, String password) async {
    setBusy(true);
    try {
      final LoginResponse response = await AuthService.login(
        username,
        password,
      );

      // Persist user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', response.userId);
      await prefs.setString('username', response.username);

      setBusy(false);
      return true;
    } catch (e, stackTrace) {
      print('Login Error Details: $e');
      print('Stack Trace: $stackTrace');
      setError(e.toString());
      setBusy(false);
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    setBusy(true);
    try {
      await AuthService.register(username, password);
      setBusy(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setBusy(false);
      return false;
    }
  }
}
