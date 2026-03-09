// lib/models/user.dart

class UserModel {
  final int id;
  final String username;
  final String? fullName;
  final String role;
  final Set<String> permissions;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    required this.role,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      username: json["username"],
      fullName: json["full_name"],
      role: json["role"],
      permissions: Set<String>.from(json["permissions"] ?? []),
    );
  }

  bool can(String permission) => permissions.contains(permission);
}
