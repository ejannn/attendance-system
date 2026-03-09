import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/attendance_service.dart';

class AdminMarkAttendanceScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminMarkAttendanceScreen({super.key, required this.currentUser});

  @override
  State<AdminMarkAttendanceScreen> createState() =>
      _AdminMarkAttendanceScreenState();
}

class _AdminMarkAttendanceScreenState extends State<AdminMarkAttendanceScreen> {
  // ── Premium Color Palette ──────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F0B1A);
  static const Color bgLight = Color(0xFF1F1836);
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color vividViolet = Color(0xFF8A2BE2);
  static const Color neonYellow = Color(0xFFE4FF30);

  late UserService _userService;
  late AttendanceService _attendanceService;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final token = await AuthService().getToken();
    if (token == null) {
      setState(() {
        _error = "Not authenticated";
        _isLoading = false;
      });
      return;
    }
    _userService = UserService(token);
    _attendanceService = AttendanceService(token);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _userService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markTimeIn(int userId, String username) async {
    try {
      await _attendanceService.adminTimeIn(userId);
      _showSnack("TIME IN marked for $username ☀️", isSuccess: true);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _markTimeOut(int userId, String username) async {
    try {
      await _attendanceService.adminTimeOut(userId);
      _showSnack("TIME OUT marked for $username 🌙", isSuccess: true);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;

    Color bgColor = const Color(0xFF2A2440);
    if (isError) bgColor = Colors.redAccent.withOpacity(0.9);
    if (isSuccess) bgColor = electricBlue.withOpacity(0.9);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: bgDark.withOpacity(0.5)),
          ),
        ),
        title: const Text(
          "M A R K   A T T E N D A N C E",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
            tooltip: "Refresh List",
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgDark, bgLight],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: neonYellow),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonYellow,
                          foregroundColor: Colors.black87,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          "Retry",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loadUsers,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Select a user to mark their attendance",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final userId = user["id"] as int;
                            final username = user["username"] ?? "Unknown";
                            final fullName = user["full_name"] ?? "";
                            final role = user["role"] ?? "—";

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: vividViolet
                                            .withOpacity(0.2),
                                        child: Text(
                                          (fullName.isNotEmpty
                                                  ? fullName[0]
                                                  : username[0])
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: vividViolet,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName.isNotEmpty
                                                  ? fullName
                                                  : username,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "$role  •  @$username",
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // ── ACTION BUTTONS ──────────────────────────────
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildGlowButton(
                                            icon: Icons.wb_sunny_rounded,
                                            label: "IN",
                                            color: neonYellow,
                                            onPressed: () =>
                                                _markTimeIn(userId, username),
                                          ),
                                          const SizedBox(width: 12),
                                          _buildGlowButton(
                                            icon: Icons.nightlight_round,
                                            label: "OUT",
                                            color: electricBlue,
                                            onPressed: () =>
                                                _markTimeOut(userId, username),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
