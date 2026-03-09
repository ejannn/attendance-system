import 'package:flutter/material.dart';

class AttendanceRecord {
  final String name;
  final String course;
  final String date;

  AttendanceRecord({
    required this.name,
    required this.course,
    required this.date,
  });
}

class AttendanceTableScreen extends StatefulWidget {
  final String selectedDate;
  final AttendanceRecord newRecord;

  const AttendanceTableScreen({
    super.key,
    required this.selectedDate,
    required this.newRecord,
  });

  @override
  State<AttendanceTableScreen> createState() => _AttendanceTableScreenState();
}

class _AttendanceTableScreenState extends State<AttendanceTableScreen> {
  final List<AttendanceRecord> records = [];

  // 🎨 Theme
  static const Color darkPurple = Color(0xFF362F4F);
  static const Color neonYellow = Color(0xFFE4FF30);

  @override
  void initState() {
    super.initState();
    records.add(widget.newRecord);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: Text("Attendance – ${widget.selectedDate}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: neonYellow,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Course & Year")),
                DataColumn(label: Text("Date")),
              ],
              rows: records
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text(r.name)),
                        DataCell(Text(r.course)),
                        DataCell(Text(r.date)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
