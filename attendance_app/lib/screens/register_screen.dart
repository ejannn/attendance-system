import 'package:flutter/material.dart';
import 'AttendanceTableScreen.dart';

class AttendanceRegistrationScreen extends StatefulWidget {
  const AttendanceRegistrationScreen({super.key});

  @override
  State<AttendanceRegistrationScreen> createState() =>
      _AttendanceRegistrationScreenState();
}

class _AttendanceRegistrationScreenState
    extends State<AttendanceRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  // 🎨 Theme Colors
  static const Color darkPurple = Color(0xFF362F4F);
  static const Color violet = Color(0xFF5B23FF);
  static const Color blue = Color(0xFF008BFF);
  static const Color neonYellow = Color(0xFFE4FF30);

  String get formattedDate =>
      "${selectedDate.month}/${selectedDate.day}/${selectedDate.year}";

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  void submitAttendance() {
    if (_nameController.text.isEmpty ||
        _courseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final record = AttendanceRecord(
      name: _nameController.text,
      course: _courseController.text,
      date: formattedDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceTableScreen(
          selectedDate: formattedDate,
          newRecord: record,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: const Text("Attendance Registration"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: isWeb ? 420 : double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.edit_calendar,
                        size: 56, color: neonYellow),
                    const SizedBox(height: 16),
                    const Text(
                      "Register Attendance",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _inputField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 14),

                    _inputField(
                      controller: _courseController,
                      label: "Course & Year Level",
                      icon: Icons.school_outlined,
                    ),

                    const SizedBox(height: 14),

                    // 📅 DATE PICKER
                    GestureDetector(
                      onTap: pickDate,
                      child: AbsorbPointer(
                        child: _inputField(
                          label: "Date",
                          icon: Icons.calendar_today_outlined,
                          hint: formattedDate,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violet,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputField({
    TextEditingController? controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: blue, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
