class UserInfo {
  final int id;
  final String name;
  final String role;
  final int? groupId;

  UserInfo({
    required this.id,
    required this.name,
    required this.role,
    this.groupId,
  });

  // factory 생성자 -> JSON을 객체로 변환할 때 사용
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      groupId: json['groupId'],
    );
  }
  bool get isAdmin => role == 'ADMIN';
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['data']['accessToken'],
      refreshToken: json['data']['refreshToken'],
      user: UserInfo.fromJson(json['data']['user']),
    );
  }
}
