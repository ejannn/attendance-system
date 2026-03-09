import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  final UserModel currentUser;

  const UserManagementScreen({super.key, required this.currentUser});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // ── Premium Color Palette ──────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F0B1A);
  static const Color bgLight = Color(0xFF1F1836);
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color vividViolet = Color(0xFF8A2BE2);
  static const Color neonYellow = Color(0xFFE4FF30);

  static const List<String> availableRoles = [
    "admin",
    "teacher",
    "manager",
    "employee",
    "student",
  ];

  late UserService _userService;
  List<Map<String, dynamic>> _users = [];
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
        _error = "Not authenticated";
        _isLoading = false;
      });
      return;
    }
    _userService = UserService(token);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _userService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
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

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    String selectedRole = "student";
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgDark.withOpacity(0.8),
                  border: Border.all(color: vividViolet.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "NEW USER",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 24),
                        _dialogTextField(
                          controller: fullNameController,
                          label: "Full Name (optional)",
                        ),
                        const SizedBox(height: 16),
                        _dialogTextField(
                          controller: usernameController,
                          label: "Username",
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        _dialogTextField(
                          controller: passwordController,
                          label: "Password",
                          obscure: true,
                          validator: (v) =>
                              v == null || v.length < 6 ? "Min 6 chars" : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration("Role"),
                          items: availableRoles
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedRole = v ?? "student"),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vividViolet,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDialogState(() => isLoading = true);
                                      try {
                                        await _userService.createUser(
                                          username: usernameController.text.trim(),
                                          password: passwordController.text.trim(),
                                          fullName: fullNameController.text.trim().isEmpty
                                              ? null
                                              : fullNameController.text.trim(),
                                          roleName: selectedRole,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        _loadUsers();
                                        _showSnack("User created 🚀", isSuccess: true);
                                      } catch (e) {
                                        setDialogState(() => isLoading = false);
                                        _showSnack(e.toString(), isError: true);
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text("Create",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user["role"];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgDark.withOpacity(0.8),
                  border: Border.all(color: electricBlue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "CHANGE ROLE",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "@${user['username']}",
                      style: const TextStyle(color: electricBlue),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: bgDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration("New Role"),
                      items: availableRoles
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedRole = v ?? user["role"]),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: electricBlue,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setDialogState(() => isLoading = true);
                                  try {
                                    await _userService.changeRole(user["id"], selectedRole);
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _loadUsers();
                                    _showSnack("Role updated 🔄", isSuccess: true);
                                  } catch (e) {
                                    setDialogState(() => isLoading = false);
                                    _showSnack(e.toString(), isError: true);
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : const Text("Save",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  void _showDeleteDialog(Map<String, dynamic> user) {
    bool isLoading = false;

    if (user["id"] == widget.currentUser.id) {
      _showSnack("You cannot delete yourself", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgDark.withOpacity(0.8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      "DELETE USER?",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Are you sure you want to delete @${user["username"]}? This action is permanent.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setDialogState(() => isLoading = true);
                                  try {
                                    await _userService.deleteUser(user["id"]);
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _loadUsers();
                                    _showSnack("User deleted 🗑️", isSuccess: true);
                                  } catch (e) {
                                    setDialogState(() => isLoading = false);
                                    _showSnack(e.toString(), isError: true);
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Delete",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;

    Color bgColor = const Color(0xFF2A2440);
    if (isError) bgColor = Colors.redAccent.withOpacity(0.9);
    if (isSuccess) bgColor = neonYellow.withOpacity(0.9);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.black87 : Colors.white),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case "admin":
        return neonYellow;
      case "teacher":
        return electricBlue;
      case "manager":
        return Colors.orangeAccent;
      case "employee":
        return Colors.greenAccent;
      default:
        return Colors.white54; // student
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          "U S E R S",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: vividViolet,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("New User", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreateUserDialog,
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
              ? const Center(child: CircularProgressIndicator(color: vividViolet))
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
                          Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vividViolet,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Retry", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header count ───────────────────────────────────
                          Text(
                            "Total: ${_users.length} registered user${_users.length != 1 ? 's' : ''}",
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),

                          // ── Table ──────────────────────────────────────────
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
                                                  color: vividViolet,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                                dataTextStyle: const TextStyle(
                                                    color: Colors.white, fontSize: 14),
                                                columns: const [
                                                  DataColumn(label: Text("ID")),
                                                  DataColumn(label: Text("USERNAME")),
                                                  DataColumn(label: Text("FULL NAME")),
                                                  DataColumn(label: Text("ROLE")),
                                                  DataColumn(label: Text("ACTIONS")),
                                                ],
                                                rows: _users.map((user) {
                                                  final isSelf =
                                                      user["id"] == widget.currentUser.id;
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(Text("${user["id"]}", style: const TextStyle(color: Colors.white54))),
                                                      DataCell(Text(user["username"] ?? "—", style: const TextStyle(fontWeight: FontWeight.bold))),
                                                      DataCell(Text(user["full_name"] ?? "—")),
                                                      DataCell(
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: _roleColor(
                                                              user["role"],
                                                            ).withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(
                                                              color: _roleColor(
                                                                user["role"],
                                                              ).withOpacity(0.4),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            (user["role"] ?? "—").toUpperCase(),
                                                            style: TextStyle(
                                                              color: _roleColor(user["role"]),
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w800,
                                                              letterSpacing: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        isSelf
                                                            ? Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white.withOpacity(0.05),
                                                                  borderRadius: BorderRadius.circular(20),
                                                                ),
                                                                child: const Text(
                                                                  "(CURRENT USER)",
                                                                  style: TextStyle(
                                                                    color: Colors.white38,
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.w900,
                                                                    letterSpacing: 1.0,
                                                                  ),
                                                                ),
                                                              )
                                                            : Row(
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                      Icons.edit_rounded,
                                                                      color: electricBlue,
                                                                      size: 20,
                                                                    ),
                                                                    tooltip: "Change Role",
                                                                    onPressed: () =>
                                                                        _showChangeRoleDialog(user),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                      Icons.delete_rounded,
                                                                      color: Colors.redAccent,
                                                                      size: 20,
                                                                    ),
                                                                    tooltip: "Delete User",
                                                                    onPressed: () =>
                                                                        _showDeleteDialog(user),
                                                                  ),
                                                                ],
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

 
  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      validator: validator,
      decoration: _dialogInputDecoration(label),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: vividViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}