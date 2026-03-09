// lib/navigation/login_navigation.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/admin_dashboard.dart';
import '../screens/user_dashboard.dart';

class LoginNavigator {
  static void navigate(BuildContext context, UserModel user) {
    Widget destination;

    // Route based on role — easy to add new roles here
    switch (user.role) {
      case "admin":
        destination = AdminDashboard(user: user);
        break;
      case "teacher":
        destination = AdminDashboard(
          user: user,
        ); // teachers see similar view as admin
        break;
      case "manager":
        destination = AdminDashboard(user: user);
        break;
      case "employee":
      case "student":
      default:
        destination = UserDashboard(user: user);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
