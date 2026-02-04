import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  // 🎨 Color Palette (same as login & admin)
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
          "User Dashboard",
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
                // 👋 GREETING
                const Text(
                  "Hello 👋",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here’s your attendance overview",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // 📊 SUMMARY CARDS
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isWeb ? 2 : 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isWeb ? 1.8 : 2.2,
                    children: const [
                      _UserCard(
                        icon: Icons.today_outlined,
                        title: "Today's Status",
                        value: "Present",
                        color: neonYellow,
                      ),
                      _UserCard(
                        icon: Icons.calendar_month_outlined,
                        title: "This Month",
                        value: "18 / 20 Days",
                        color: blue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🔘 ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("CHECK IN / CHECK OUT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violet,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // TODO: Navigate to Check-in Screen
                    },
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

// 🧩 USER SUMMARY CARD
class _UserCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _UserCard({
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
              fontSize: 26,
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
