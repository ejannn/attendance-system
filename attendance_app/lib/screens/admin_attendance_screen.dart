import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminAttendanceScreen({super.key, required this.currentUser});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  // ── Premium Color Palette ──────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F0B1A);
  static const Color bgLight = Color(0xFF1F1836);
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color vividViolet = Color(0xFF8A2BE2);
  static const Color neonYellow = Color(0xFFE4FF30);

  late AttendanceService _attendanceService;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final token = await AuthService().getToken();
    if (token == null) {
      setState(() {
        _error = "Authentication token not found.";
        _isLoading = false;
      });
      return;
    }
    _attendanceService = AttendanceService(token);
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await _attendanceService.getAllAttendance();
      if (mounted) {
        setState(() {
          _records = records;
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

  String _formatTime(String? isoString) {
    if (isoString == null) return "—";
    final dt = DateTime.parse(isoString).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "late":
        return Colors.orangeAccent;
      case "absent":
        return Colors.redAccent;
      case "half_day":
        return vividViolet;
      default:
        return electricBlue; // present
    }
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
          "A T T E N D A N C E",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
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
              ? const Center(child: CircularProgressIndicator(color: electricBlue))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 64),
                          const SizedBox(height: 16),
                          Text("Error: ${_error!}",
                              style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: electricBlue,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Retry", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _loadRecords,
                          ),
                        ],
                      ),
                    )
                  : _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, color: Colors.white.withOpacity(0.2), size: 80),
                              const SizedBox(height: 16),
                              const Text(
                                "No attendance records found.",
                                style: TextStyle(color: Colors.white54, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Total: ${_records.length} record${_records.length != 1 ? 's' : ''}",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                              child: Center(
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.vertical,
                                                  child: DataTable(
                                                    headingRowHeight: 64,
                                                    dataRowMinHeight: 60,
                                                    dataRowMaxHeight: 60,
                                                    headingTextStyle: const TextStyle(
                                                      color: electricBlue,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 1.0,
                                                    ),
                                                    dataTextStyle: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    columns: const [
                                                      DataColumn(label: Text("NAME")),
                                                      DataColumn(label: Text("USERNAME")),
                                                      DataColumn(label: Text("DATE")),
                                                      DataColumn(label: Text("TIME IN")),
                                                      DataColumn(label: Text("TIME OUT")),
                                                      DataColumn(label: Text("STATUS")),
                                                    ],
                                                    rows: _records.map((r) {
                                                      return DataRow(
                                                        cells: [
                                                          DataCell(Text(r["full_name"] ?? "—", style: const TextStyle(fontWeight: FontWeight.bold))),
                                                          DataCell(Text(r["username"] ?? "—", style: const TextStyle(color: Colors.white54))),
                                                          DataCell(Text(r["date"] ?? "—")),
                                                          DataCell(Text(_formatTime(r["time_in"]))),
                                                          DataCell(Text(_formatTime(r["time_out"]))),
                                                          DataCell(
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: _statusColor(r["status"]).withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(20),
                                                                border: Border.all(color: _statusColor(r["status"]).withOpacity(0.4)),
                                                              ),
                                                              child: Text(
                                                                (r["status"] ?? "—").toUpperCase(),
                                                                style: TextStyle(
                                                                  color: _statusColor(r["status"]),
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w800,
                                                                  letterSpacing: 1.0,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
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