// lib/controllers/login_controller.dart
import '../models/user.dart';
import '../services/auth_service.dart';

class LoginResult {
  final bool success;
  final UserModel? user;
  final String? error;

  LoginResult({required this.success, this.user, this.error});
}

class LoginController {
  final AuthService authService;

  LoginController(this.authService);

  Future<LoginResult> login(String username, String password) async {
    final loggedIn = await authService.login(username, password);

    if (!loggedIn) {
      return LoginResult(success: false, error: "Invalid username or password");
    }

    final user = await authService.getCurrentUser();

    if (user == null) {
      return LoginResult(success: false, error: "Failed to load user data");
    }

    return LoginResult(success: true, user: user);
  }
}
