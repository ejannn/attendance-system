import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // 🎨 Color Palette
  static const Color darkPurple = Color(0xFF362F4F);
  static const Color violet = Color(0xFF5B23FF);
  static const Color blue = Color(0xFF008BFF);
  static const Color neonYellow = Color(0xFFE4FF30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          )
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
                // 👋 HEADER
                const Text(
                  "Welcome back, Admin 👑",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Overview of today’s attendance activity",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // 📊 DASHBOARD CARDS
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isWeb ? 3 : 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isWeb ? 1.6 : 1.8,
                    children: const [
                      _DashboardCard(
                        icon: Icons.people_alt_outlined,
                        title: "Total Students",
                        value: "1,240",
                        color: blue,
                      ),
                      _DashboardCard(
                        icon: Icons.fact_check_outlined,
                        title: "Present Today",
                        value: "1,103",
                        color: neonYellow,
                      ),
                      _DashboardCard(
                        icon: Icons.bar_chart_outlined,
                        title: "Attendance Rate",
                        value: "89%",
                        color: violet,
                      ),
                    ],
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

// 🧩 REUSABLE CARD WIDGET
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
