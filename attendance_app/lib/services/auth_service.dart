// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    } else {
      return "http://10.0.2.2:8000"; // Android emulator
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": username, "password": password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token, role, and permissions — not just the token
      await _storage.write(key: "token", value: data["access_token"]);
      await _storage.write(key: "role", value: data["role"]);
      await _storage.write(
        key: "permissions",
        value: jsonEncode(data["permissions"]), // store as JSON string
      );

      return true;
    }
    return false;
  }

  // ── Get current user from /users/me ───────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: "token");
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ── Load user from storage (no API call) ──────────────────────────────────
  Future<UserModel?> getUserFromStorage() async {
    final token = await _storage.read(key: "token");
    final role = await _storage.read(key: "role");
    final permissionsJson = await _storage.read(key: "permissions");

    if (token == null || role == null || permissionsJson == null) return null;

    final permissions = Set<String>.from(jsonDecode(permissionsJson));
    return UserModel(
      id: 0, // not stored locally, call getCurrentUser() if you need it
      username: "",
      role: role,
      permissions: permissions,
    );
  }

  // ── Token getter ──────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ── Check if logged in ────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: "token");
    return token != null;
  }
}
