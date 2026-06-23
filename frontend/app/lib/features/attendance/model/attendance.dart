class AttendanceMember {
  AttendanceMember({
    required this.userId,
    required this.name,
    required this.fulfilled,
    required this.guaranteed,
    required this.shortfall,
    required this.isShortfall,
  });

  final int userId;
  final String name;
  final int fulfilled;
  final int guaranteed;
  final int shortfall;
  final bool isShortfall;

  factory AttendanceMember.fromJson(Map<String, dynamic> json) {
    return AttendanceMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      fulfilled: json['fulfilled'] as int,
      guaranteed: json['guaranteed'] as int,
      shortfall: json['shortfall'] as int,
      isShortfall: json['isShortfall'] as bool,
    );
  }
}

class GroupAttendance {
  GroupAttendance({
    required this.groupId,
    required this.groupLabel,
    required this.year,
    required this.month,
    required this.guaranteedCount,
    required this.members,
  });

  final int groupId;
  final String groupLabel;
  final int year;
  final int month;
  final int guaranteedCount;
  final List<AttendanceMember> members;

  factory GroupAttendance.fromJson(Map<String, dynamic> json) {
    return GroupAttendance(
      groupId: json['groupId'] as int,
      groupLabel: json['groupLabel'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      guaranteedCount: json['guaranteedCount'] as int,
      members: (json['members'] as List)
          .map((e) => AttendanceMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShortfallMember {
  ShortfallMember({
    required this.userId,
    required this.name,
    required this.groupLabel,
    required this.fulfilled,
    required this.guaranteed,
    required this.shortfall,
  });

  final int userId;
  final String name;
  final String groupLabel;
  final int fulfilled;
  final int guaranteed;
  final int shortfall;

  factory ShortfallMember.fromJson(Map<String, dynamic> json) {
    return ShortfallMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      groupLabel: json['groupLabel'] as String,
      fulfilled: json['fulfilled'] as int,
      guaranteed: json['guaranteed'] as int,
      shortfall: json['shortfall'] as int,
    );
  }
}

class OtherGroupActivity {
  OtherGroupActivity({required this.activityId, required this.date, required this.groupLabel});

  final int activityId;
  final String date;
  final String groupLabel;

  factory OtherGroupActivity.fromJson(Map<String, dynamic> json) {
    return OtherGroupActivity(
      activityId: json['activityId'] as int,
      date: json['date'] as String,
      groupLabel: json['groupLabel'] as String,
    );
  }
}

class OtherGroupSummary {
  OtherGroupSummary({required this.userId, required this.name, required this.count, required this.activities});

  final int userId;
  final String name;
  final int count;
  final List<OtherGroupActivity> activities;

  factory OtherGroupSummary.fromJson(Map<String, dynamic> json) {
    return OtherGroupSummary(
      userId: json['userId'] as int,
      name: json['name'] as String,
      count: json['count'] as int,
      activities: (json['activities'] as List)
          .map((e) => OtherGroupActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
