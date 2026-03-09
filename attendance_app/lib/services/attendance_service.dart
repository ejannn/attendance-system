// lib/services/attendance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class AttendanceService {
  final String token;

  AttendanceService(this.token);

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  // ── Time In ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> timeIn() async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/attendance/time-in"),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) return data;
    throw Exception(data["detail"] ?? "Failed to time in");
  }

  // ── Time Out ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> timeOut() async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/attendance/time-out"),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) return data;
    throw Exception(data["detail"] ?? "Failed to time out");
  }

  // ── Get my attendance ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMyAttendance() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/attendance/me"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception("Failed to load attendance");
  }

  // ── Get today's record ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getTodayRecord() async {
    final records = await getMyAttendance();
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    for (final r in records) {
      if (r["date"] == todayStr) return r;
    }
    return null;
  }

  // ── Admin: Get all attendance ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/admin/attendance"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data["attendance"] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(
      jsonDecode(response.body)["detail"] ?? "Failed to load all attendance",
    );
  }

  // ── Admin: Dashboard Stats ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/admin/dashboard-stats"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load dashboard stats");
  }

  // ── Admin: Time In for User ────────────────────────────────────────────────
  Future<Map<String, dynamic>> adminTimeIn(int userId) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/attendance/time-in/$userId"),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data["detail"] ?? "Failed to time in user");
  }

  // ── Admin: Time Out for User ───────────────────────────────────────────────
  Future<Map<String, dynamic>> adminTimeOut(int userId) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/attendance/time-out/$userId"),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data["detail"] ?? "Failed to time out user");
  }
}
