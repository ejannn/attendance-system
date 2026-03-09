// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class UserService {
  final String token;

  UserService(this.token);

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  // ── Get all users ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/users/all"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception("Failed to load users: ${response.statusCode}");
  }

  // ── Create user ────────────────────────────────────────────────────────────
  Future<void> createUser({
    required String username,
    required String password,
    String? fullName,
    required String roleName,
  }) async {
    final response = await http.post(
      Uri.parse(
        "${ApiConfig.baseUrl}/users/admin/create-user?role_name=$roleName",
      ),
      headers: _headers,
      body: jsonEncode({
        "username": username,
        "password": password,
        "full_name": fullName,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Failed to create user");
    }
  }

  // ── Change role ────────────────────────────────────────────────────────────
  Future<void> changeRole(int userId, String roleName) async {
    final response = await http.patch(
      Uri.parse(
        "${ApiConfig.baseUrl}/admin/promote/$userId?role_name=$roleName",
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Failed to change role");
    }
  }

  // ── Delete user ────────────────────────────────────────────────────────────
  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/admin/users/$userId"),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Failed to delete user");
    }
  }
}
