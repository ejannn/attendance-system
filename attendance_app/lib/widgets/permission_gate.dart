// lib/widgets/permission_gate.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class PermissionGate extends StatelessWidget {
  final UserModel user;
  final String permission;
  final Widget child;
  final Widget fallback;

  const PermissionGate({
    super.key,
    required this.user,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return user.can(permission) ? child : fallback;
  }
}
