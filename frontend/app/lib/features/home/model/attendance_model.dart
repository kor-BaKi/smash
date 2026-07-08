class MemberAttendance {
  final int userId;
  final String name;
  final int fulfilled;
  final int guaranteed;
  final int shortfall;
  final bool isShortfall;

  MemberAttendance({
    required this.userId,
    required this.name,
    required this.fulfilled,
    required this.guaranteed,
    required this.shortfall,
    required this.isShortfall,
  });

  factory MemberAttendance.fromJson(Map<String, dynamic> json) {
    return MemberAttendance(
      userId: json['userId'],
      name: json['name'],
      fulfilled: json['fulfilled'],
      guaranteed: json['guaranteed'],
      shortfall: json['shortfall'],
      isShortfall: json['isShortfall'],
    );
  }
}

class GroupAttendance {
  final int groupId;
  final String groupLabel;
  final int year;
  final int month;
  final int guaranteedCount;
  final List<MemberAttendance> members;

  GroupAttendance({
    required this.groupId,
    required this.groupLabel,
    required this.year,
    required this.month,
    required this.guaranteedCount,
    required this.members,
  });

  factory GroupAttendance.fromJson(Map<String, dynamic> json) {
    return GroupAttendance(
      groupId: json['groupId'],
      groupLabel: json['groupLabel'],
      year: json['year'],
      month: json['month'],
      guaranteedCount: json['guaranteedCount'],
      members: (json['members'] as List)
          .map((m) => MemberAttendance.fromJson(m))
          .toList(),
    );
  }
}

class ShortfallMember {
  final int userId;
  final String name;
  final String groupLabel;
  final int fulfilled;
  final int guaranteed;
  final int shortfall;

  ShortfallMember({
    required this.userId,
    required this.name,
    required this.groupLabel,
    required this.fulfilled,
    required this.guaranteed,
    required this.shortfall,
  });

  factory ShortfallMember.fromJson(Map<String, dynamic> json) {
    return ShortfallMember(
      userId: json['userId'],
      name: json['name'],
      groupLabel: json['groupLabel'],
      fulfilled: json['fulfilled'],
      guaranteed: json['guaranteed'],
      shortfall: json['shortfall'],
    );
  }
}

class OtherGroupMember {
  final int userId;
  final String name;
  final int count;
  final List<OtherGroupActivity> activities;

  OtherGroupMember({
    required this.userId,
    required this.name,
    required this.count,
    required this.activities,
  });

  factory OtherGroupMember.fromJson(Map<String, dynamic> json) {
    return OtherGroupMember(
      userId: json['userId'],
      name: json['name'],
      count: json['count'],
      activities: (json['activities'] as List)
          .map((a) => OtherGroupActivity.fromJson(a))
          .toList(),
    );
  }
}

class OtherGroupActivity {
  final int activityId;
  final String date;
  final String groupLabel;

  OtherGroupActivity({
    required this.activityId,
    required this.date,
    required this.groupLabel,
  });

  factory OtherGroupActivity.fromJson(Map<String, dynamic> json) {
    return OtherGroupActivity(
      activityId: json['activityId'],
      date: json['date'],
      groupLabel: json['groupLabel'],
    );
  }
}
