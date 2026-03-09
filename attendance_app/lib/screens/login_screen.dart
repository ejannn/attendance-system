import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../navigation/login_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? error;

  static const Color darkPurple = Color(0xFF362F4F);
  static const Color violet = Color(0xFF5B23FF);
  static const Color blue = Color(0xFF008BFF);
  static const Color neonYellow = Color(0xFFE4FF30);

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

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

    // ✅ Pass full UserModel — no more role string checks here
    LoginNavigator.navigate(context, user);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Column(
                        children: [
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

                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Username is required"
                            : null,
                        decoration: _inputDecoration(
                          label: "Username",
                          icon: Icons.person_outline,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Password is required"
                            : null,
                        decoration: _inputDecoration(
                          label: "Password",
                          icon: Icons.lock_outline,
                        ),
                      ),

                      const SizedBox(height: 22),

                      if (error != null)
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),

                      const SizedBox(height: 22),

                      ElevatedButton(
                        onPressed: isLoading ? null : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violet,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: blue),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonYellow, width: 1.2),
      ),
    );
  }
}
