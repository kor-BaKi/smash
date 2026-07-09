class RegisteredMember {
  final int id;
  final String name;
  final String studentNo;
  final String status;
  final String? role;

  RegisteredMember({
    required this.id,
    required this.name,
    required this.studentNo,
    required this.status,
    this.role,
  });

  factory RegisteredMember.fromJson(Map<String, dynamic> json) {
    return RegisteredMember(
      id: json['id'],
      name: json['name'],
      studentNo: json['studentNo'],
      status: json['status'],
      role: json['role'],
    );
  }
}

class FailedMember {
  final String studentNo;
  final String reason;

  FailedMember({required this.studentNo, required this.reason});

  factory FailedMember.fromJson(Map<String, dynamic> json) {
    return FailedMember(
      studentNo: json['studentNo'],
      reason: json['reason'],
    );
  }
}

class BulkRegisterResult {
  final List<RegisteredMember> succeeded;
  final List<FailedMember> failed;
  final int totalRequested;
  final int successCount;

  BulkRegisterResult({
    required this.succeeded,
    required this.failed,
    required this.totalRequested,
    required this.successCount,
  });

  factory BulkRegisterResult.fromJson(Map<String, dynamic> json) {
    return BulkRegisterResult(
      succeeded: (json['succeeded'] as List)
          .map((e) => RegisteredMember.fromJson(e))
          .toList(),
      failed: (json['failed'] as List)
          .map((e) => FailedMember.fromJson(e))
          .toList(),
      totalRequested: json['totalRequested'],
      successCount: json['successCount'],
    );
  }
}
