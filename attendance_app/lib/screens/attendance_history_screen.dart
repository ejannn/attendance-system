// lib/screens/attendance_history_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final UserModel user;

  const AttendanceHistoryScreen({super.key, required this.user});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color darkPurple = Color(0xFF362F4F);
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
    if (token == null) return;
    _attendanceService = AttendanceService(token);
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await _attendanceService.getMyAttendance();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        return Colors.purpleAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: const Text(
          "My Attendance History",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonYellow))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRecords,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _records.isEmpty
          ? const Center(
              child: Text(
                "No attendance records yet",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_records.length} record${_records.length != 1 ? 's' : ''} found",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingTextStyle: const TextStyle(
                              color: neonYellow,
                              fontWeight: FontWeight.bold,
                            ),
                            dataTextStyle: const TextStyle(color: Colors.white),
                            columns: const [
                              DataColumn(label: Text("Date")),
                              DataColumn(label: Text("Time In")),
                              DataColumn(label: Text("Time Out")),
                              DataColumn(label: Text("Status")),
                            ],
                            rows: _records.map((r) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(r["date"] ?? "—")),
                                  DataCell(Text(_formatTime(r["time_in"]))),
                                  DataCell(Text(_formatTime(r["time_out"]))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          r["status"],
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _statusColor(
                                            r["status"],
                                          ).withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        r["status"] ?? "—",
                                        style: TextStyle(
                                          color: _statusColor(r["status"]),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                  ),
                ],
              ),
            ),
    );
  }
}
