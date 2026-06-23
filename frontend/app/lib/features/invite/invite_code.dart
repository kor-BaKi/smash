class InviteCode {
  InviteCode({required this.id, required this.code, required this.isActive});

  final int id;
  final String code;
  final bool isActive;

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(id: json['id'] as int, code: json['code'] as String, isActive: json['isActive'] as bool);
  }
}
