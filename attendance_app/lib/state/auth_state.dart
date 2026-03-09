// lib/state/auth_state.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // Permission check — use this everywhere instead of checking role
  bool can(String permission) {
    return _user?.can(permission) ?? false;
  }
}
