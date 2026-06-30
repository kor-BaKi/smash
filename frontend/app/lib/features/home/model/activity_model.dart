// 서버 응답 데이터 모델
class ParticipationInfo {
  final int participationId;
  final String type;
  final int? targetActivityId;

  ParticipationInfo({
    required this.participationId,
    required this.type,
    this.targetActivityId,
  });

  factory ParticipationInfo.fromJson(Map<String, dynamic> json) {
    return ParticipationInfo(
      participationId: json['participationId'],
      type: json['type'],
      targetActivityId: json['targetActivityId'],
    );
  }
}

class TodayActivity {
  final int activityId;
  final String activityDate;
  final int groupId;
  final String groupLabel;
  final String activityType;
  final bool isMyGroup;
  final List<String> availableButtons;
  final ParticipationInfo? myParticipation;
  final bool voteClosed;

  TodayActivity({
    required this.activityId,
    required this.activityDate,
    required this.groupId,
    required this.groupLabel,
    required this.activityType,
    required this.isMyGroup,
    required this.availableButtons,
    this.myParticipation,
    required this.voteClosed,
  });

  factory TodayActivity.fromJson(Map<String, dynamic> json) {
    return TodayActivity(
      activityId: json['activityId'],
      activityDate: json['activityDate'],
      groupId: json['groupId'],
      groupLabel: json['groupLabel'],
      activityType: json['activityType'],
      isMyGroup: json['isMyGroup'],
      availableButtons: List<String>.from(json['availableButtons']),
      myParticipation: json['myParticipation'] == null
          ? null
          : ParticipationInfo.fromJson(json['myParticipation']),
      voteClosed: json['voteClosed'],
    );
  }
}
