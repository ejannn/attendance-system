// lib/screens/user_dashboard.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../screens/login_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../config/permissions.dart';
import '../widgets/permission_gate.dart';

class UserDashboard extends StatefulWidget {
  final UserModel user;

  const UserDashboard({super.key, required this.user});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  static const Color darkPurple = Color(0xFF362F4F);

  static const Color blue = Color(0xFF008BFF);
  static const Color neonYellow = Color(0xFFE4FF30);

  late AttendanceService _attendanceService;
  Map<String, dynamic>? _todayRecord;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final token = await AuthService().getToken();
    if (token == null) return;
    _attendanceService = AttendanceService(token);
    await _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _isLoading = true);
    try {
      final record = await _attendanceService.getTodayRecord();
      setState(() {
        _todayRecord = record;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTimeIn() async {
    setState(() => _isActionLoading = true);
    try {
      await _attendanceService.timeIn();
      await _loadToday();
      _showSnack("Time-in recorded ✅");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleTimeOut() async {
    setState(() => _isActionLoading = true);
    try {
      await _attendanceService.timeOut();
      await _loadToday();
      _showSnack("Time-out recorded ✅");
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ── Today status helpers ───────────────────────────────────────────────────

  bool get _hasTimedIn => _todayRecord != null;
  bool get _hasTimedOut =>
      _todayRecord != null && _todayRecord!["time_out"] != null;

  String get _todayStatus {
    if (!_hasTimedIn) return "Not checked in";
    if (!_hasTimedOut) return _todayRecord!["status"] ?? "Present";
    return "Completed";
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return "—";
    final dt = DateTime.parse(isoString).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  Color get _statusColor {
    if (!_hasTimedIn) return Colors.white38;
    if (_todayRecord!["status"] == "late") return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: const Text(
          "My Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadToday,
            tooltip: "Refresh",
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 700;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──────────────────────────────────────────────
                Text(
                  "Welcome, ${widget.user.fullName ?? widget.user.username} 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Role: ${widget.user.role}",
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 24),

                // ── Today's status cards ───────────────────────────────────
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: neonYellow),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: isWeb ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWeb ? 2.2 : 2.8,
                        children: [
                          _StatusCard(
                            icon: Icons.today_outlined,
                            title: "Today's Status",
                            value: _todayStatus,
                            color: _statusColor,
                          ),
                          _StatusCard(
                            icon: Icons.login_outlined,
                            title: "Time In",
                            value: _formatTime(_todayRecord?["time_in"]),
                            color: neonYellow,
                          ),
                          _StatusCard(
                            icon: Icons.logout_outlined,
                            title: "Time Out",
                            value: _formatTime(_todayRecord?["time_out"]),
                            color: blue,
                          ),
                        ],
                      ),

                const SizedBox(height: 24),

                // ── Action buttons ────────────────────────────────────────
                PermissionGate(
                  user: widget.user,
                  permission: Permissions.markOwnAttendance,
                  child: Column(
                    children: [
                      // Time In button — hidden after timing in
                      if (!_hasTimedIn)
                        _ActionButton(
                          label: "TIME IN",
                          icon: Icons.login_outlined,
                          color: Colors.greenAccent,
                          isLoading: _isActionLoading,
                          onPressed: _handleTimeIn,
                        ),

                      // Time Out button — shown only after timing in
                      if (_hasTimedIn && !_hasTimedOut) ...[
                        const SizedBox(height: 12),
                        _ActionButton(
                          label: "TIME OUT",
                          icon: Icons.logout_outlined,
                          color: Colors.orangeAccent,
                          isLoading: _isActionLoading,
                          onPressed: _handleTimeOut,
                        ),
                      ],

                      // Completed state
                      if (_hasTimedIn && _hasTimedOut)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Attendance complete for today",
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── View history ──────────────────────────────────────────
                PermissionGate(
                  user: widget.user,
                  permission: Permissions.viewOwnAttendance,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history, color: Colors.white70),
                      label: const Text(
                        "VIEW MY ATTENDANCE HISTORY",
                        style: TextStyle(color: Colors.white70),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AttendanceHistoryScreen(user: widget.user),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Status card ────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
