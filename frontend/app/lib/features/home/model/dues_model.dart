class DuesMember {
  final int userId;
  final String name;
  final String studentNo;
  final int? groupId;
  final bool isPaid;

  DuesMember({
    required this.userId,
    required this.name,
    required this.studentNo,
    this.groupId,
    required this.isPaid,
  });

  factory DuesMember.fromJson(Map<String, dynamic> json) {
    return DuesMember(
      userId: json['userId'],
      name: json['name'],
      studentNo: json['studentNo'],
      groupId: json['groupId'],
      isPaid: json['isPaid'],
    );
  }

  DuesMember copyWith({bool? isPaid}) {
    return DuesMember(
      userId: userId,
      name: name,
      studentNo: studentNo,
      groupId: groupId,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
