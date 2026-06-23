enum UserRole { admin, member }

class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.groupId,
  });

  final int id;
  final String name;
  final UserRole role;
  final int? groupId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      role: (json['role'] as String) == 'ADMIN'
          ? UserRole.admin
          : UserRole.member,
      groupId: json['groupId'] as int?,
    );
  }
}
