import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? error;

  // 🎨 Color Palette
  static const Color darkPurple = Color(0xFF362F4F);
  static const Color violet = Color(0xFF5B23FF);
  static const Color blue = Color(0xFF008BFF);
  static const Color neonYellow = Color(0xFFE4FF30);

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final success = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success) {
      setState(() {
        isLoading = false;
        error = "Invalid credentials";
      });
      return;
    }

    final user = await _authService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      setState(() {
        isLoading = false;
        error = "Failed to load user";
      });
      return;
    }

    if (user["role"] == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurple,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 600;
          final double containerWidth = isWeb ? 420 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 0 : 28,
                vertical: 32,
              ),
              child: Container(
                width: containerWidth,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isWeb
                      ? Colors.white.withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🧠 HEADER
                    Column(
                      children: const [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 64,
                          color: neonYellow,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Attendance System",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Smart & Secure Attendance Tracking",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 42),

                    // 👤 USERNAME
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: blue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: neonYellow,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 🔒 PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: blue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: neonYellow,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ❌ ERROR MESSAGE
                    if (error != null)
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),

                    const SizedBox(height: 22),

                    // 🔐 LOGIN BUTTON
                    ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violet,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // 🟢 FOOTER
                    Text(
                      "Secure • Fast • Reliable",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: neonYellow.withOpacity(0.85),
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
}
