class InviteCode {
  final int id;
  final String code;
  final bool isActive;

  InviteCode({
    required this.id,
    required this.code,
    required this.isActive,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      id: json['id'],
      code: json['code'],
      isActive: json['isActive'],
    );
  }
}
