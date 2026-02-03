import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    } else {
      return "http://localhost:8000";
    }
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": username, "password": password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: "token", value: data["access_token"]);
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _storage.read(key: "token");
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
