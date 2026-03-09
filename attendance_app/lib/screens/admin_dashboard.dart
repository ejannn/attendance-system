import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../screens/login_screen.dart';
import '../config/permissions.dart';
import '../widgets/permission_gate.dart';
import '../screens/user_management_screen.dart';
import '../screens/admin_attendance_screen.dart';
import '../screens/admin_mark_attendance_screen.dart';
import 'dart:ui';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ── Premium Color Palette ──────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F0B1A);
  static const Color bgLight = Color(0xFF1F1836);
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color vividViolet = Color(0xFF8A2BE2);
  static const Color neonYellow = Color(0xFFE4FF30);

  bool _isLoading = true;
  String? _error;
  int _totalUsers = 0;
  int _presentToday = 0;
  double _attendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }

      final service = AttendanceService(token);
      final stats = await service.getDashboardStats();

      if (mounted) {
        setState(() {
          _totalUsers = stats["total_users"] ?? 0;
          _presentToday = stats["present_today"] ?? 0;
          _attendanceRate = (stats["attendance_rate"] ?? 0.0).toDouble();
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

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: bgDark.withOpacity(0.5)),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF0F0B1A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "D B T C - C E B U",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: "Refresh Stats",
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: "Logout",
            onPressed: () => _logout(context),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 700;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ──────────────────────────────────────────────
                    Text(
                      "Hello, ${widget.user.fullName ?? widget.user.username}.",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vividViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: vividViolet.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.user.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: vividViolet,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Main Content Area ─────────────────────────────────────
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: neonYellow,
                              ),
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
                                ],
                              ),
                            )
                          : GridView.count(
                              crossAxisCount: isWeb ? 3 : 1,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: isWeb ? 1.6 : 1.8,
                              children: [
                                _GlassStatCard(
                                  icon: Icons.groups_rounded,
                                  title: "Total Users",
                                  value: "$_totalUsers",
                                  glowColor: electricBlue,
                                ),
                                _GlassStatCard(
                                  icon: Icons.how_to_reg_rounded,
                                  title: "Present Today",
                                  value: "$_presentToday",
                                  glowColor: neonYellow,
                                ),
                                _GlassStatCard(
                                  icon: Icons.insights_rounded,
                                  title: "Attendance Rate",
                                  value:
                                      "${_attendanceRate.toStringAsFixed(1)}%",
                                  glowColor: vividViolet,
                                ),

                                // ── Action Cards ─────────────────────────────────
                                PermissionGate(
                                  user: widget.user,
                                  permission: Permissions.manageUsers,
                                  child: _AnimatedActionCard(
                                    icon: Icons.manage_accounts_rounded,
                                    label: "Manage Users",
                                    accentColor: vividViolet,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserManagementScreen(
                                          currentUser: widget.user,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                PermissionGate(
                                  user: widget.user,
                                  permission: Permissions.viewAllAttendance,
                                  child: _AnimatedActionCard(
                                    icon: Icons.list_alt_rounded,
                                    label: "View All Attendance",
                                    accentColor: electricBlue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminAttendanceScreen(
                                            currentUser: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                PermissionGate(
                                  user: widget.user,
                                  permission: Permissions.markAnyAttendance,
                                  child: _AnimatedActionCard(
                                    icon: Icons.assignment_ind_rounded,
                                    label: "Mark Attendance",
                                    accentColor: neonYellow,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminMarkAttendanceScreen(
                                                currentUser: widget.user,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Glassmorphic Stat Card ───────────────────────────────────────────────────

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color glowColor;

  const _GlassStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: glowColor),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Action Card ───────────────────────────────────────────────────

class _AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        widget.onTap();
        _controller.reverse(); // Ensure it bounces back on tap
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.15),
                      widget.accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, size: 36, color: widget.accentColor),
                    const Spacer(),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
