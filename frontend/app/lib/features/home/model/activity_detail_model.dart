class ParticipantInfo {
  final int userId;
  final String name;

  ParticipantInfo({required this.userId, required this.name});

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(userId: json['userId'], name: json['name']);
  }
}

class ActivitySummary {
  final int regular;
  final int carryover;
  final int otherGroup;
  final int freeAttend;
  final int absent;

  ActivitySummary({
    required this.regular,
    required this.carryover,
    required this.otherGroup,
    required this.freeAttend,
    required this.absent,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      regular: json['regular'],
      carryover: json['carryover'],
      otherGroup: json['otherGroup'],
      freeAttend: json['freeAttend'],
      absent: json['absent'],
    );
  }
}

class ActivityParticipants {
  final List<ParticipantInfo> regular;
  final List<ParticipantInfo> carryover;
  final List<ParticipantInfo> otherGroup;
  final List<ParticipantInfo> freeAttend;
  final List<ParticipantInfo> absent;

  ActivityParticipants({
    required this.regular,
    required this.carryover,
    required this.otherGroup,
    required this.freeAttend,
    required this.absent,
  });

  static List<ParticipantInfo> _parseList(dynamic list) {
    return (list as List).map((e) => ParticipantInfo.fromJson(e)).toList();
  }

  factory ActivityParticipants.fromJson(Map<String, dynamic> json) {
    return ActivityParticipants(
      regular: _parseList(json['regular']),
      carryover: _parseList(json['carryover']),
      otherGroup: _parseList(json['otherGroup']),
      freeAttend: _parseList(json['freeAttend']),
      absent: _parseList(json['absent']),
    );
  }
}

class ActivityDetail {
  final int activityId;
  final String activityDate;
  final String groupLabel;
  final String activityType;
  final bool isCancelled;
  final ActivitySummary summary;
  final ActivityParticipants participants;

  ActivityDetail({
    required this.activityId,
    required this.activityDate,
    required this.groupLabel,
    required this.activityType,
    required this.isCancelled,
    required this.summary,
    required this.participants,
  });

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    return ActivityDetail(
      activityId: json['activityId'],
      activityDate: json['activityDate'],
      groupLabel: json['groupLabel'],
      activityType: json['activityType'],
      isCancelled: json['isCancelled'],
      summary: ActivitySummary.fromJson(json['summary']),
      participants: ActivityParticipants.fromJson(json['participants']),
    );
  }
}
