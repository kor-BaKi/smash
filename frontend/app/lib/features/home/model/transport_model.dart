class TransportMemberInfo {
  // Spring의 TransportGroupResponse과 연결
  final int userId;
  final String name;
  final String? travelType;

  TransportMemberInfo({
    required this.userId,
    required this.name,
    this.travelType,
  });

  // JSON을 객체로 변환
  factory TransportMemberInfo.fromJson(Map<String, dynamic> json) {
    return TransportMemberInfo(
      userId: json['userId'],
      name: json['name'],
      travelType: json['travelType'],
    );
  }
}

class TransportGroupInfo {
  final int groupId;
  final int groupNumber;
  final List<TransportMemberInfo> members;

  TransportGroupInfo({
    required this.groupId,
    required this.groupNumber,
    required this.members,
  });

  factory TransportGroupInfo.fromJson(Map<String, dynamic> json) {
    return TransportGroupInfo(
      groupId: json['groupId'],
      groupNumber: json['groupNumber'],
      members: (json['members'] as List)
          .map((e) => TransportMemberInfo.fromJson(e))
          .toList(),
    );
  }
}
