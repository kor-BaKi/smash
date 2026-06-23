import '../../core/domain/activity_type.dart';

enum ClientParticipationType {
  attend,
  otherGroup,
  freeAttend,
  absent,
  carryover;

  String get apiValue {
    switch (this) {
      case ClientParticipationType.attend:
        return 'ATTEND';
      case ClientParticipationType.otherGroup:
        return 'OTHER_GROUP';
      case ClientParticipationType.freeAttend:
        return 'FREE_ATTEND';
      case ClientParticipationType.absent:
        return 'ABSENT';
      case ClientParticipationType.carryover:
        return 'CARRYOVER';
    }
  }

  static ClientParticipationType fromApi(String value) {
    return ClientParticipationType.values.firstWhere(
      (t) => t.apiValue == value,
    );
  }

  String get koreanLabel {
    switch (this) {
      case ClientParticipationType.attend:
        return '참석';
      case ClientParticipationType.otherGroup:
        return '타조참여';
      case ClientParticipationType.freeAttend:
        return '자유참여';
      case ClientParticipationType.absent:
        return '불참';
      case ClientParticipationType.carryover:
        return '이월';
    }
  }
}

class MyParticipation {
  MyParticipation({
    required this.type,
    required this.targetActivityId,
  });

  final ClientParticipationType type;
  final int? targetActivityId;

  factory MyParticipation.fromJson(Map<String, dynamic> json) {
    return MyParticipation(
      type: ClientParticipationType.fromApi(
        json['type'] as String,
      ),
      targetActivityId: json['targetActivityId'] as int?,
    );
  }
}

class TodayActivity {
  TodayActivity({
    required this.activityId,
    required this.activityDate,
    required this.groupId,
    required this.groupLabel,
    required this.activityType,
    required this.isMyGroup,
    required this.availableButtons,
    required this.myParticipation,
    required this.voteClosed,
  });

  final int activityId;
  final String activityDate;
  final int groupId;
  final String groupLabel;
  final ActivityType activityType;
  final bool isMyGroup;
  final List<ClientParticipationType> availableButtons;
  final MyParticipation? myParticipation;
  final bool voteClosed;

  factory TodayActivity.fromJson(Map<String, dynamic> json) {
    return TodayActivity(
      activityId: json['activityId'] as int,
      activityDate: json['activityDate'] as String,
      groupId: json['groupId'] as int,
      groupLabel: json['groupLabel'] as String,
      activityType: ActivityType.fromApi(
        json['activityType'] as String,
      ),
      isMyGroup: json['isMyGroup'] as bool,
      availableButtons: (json['availableButtons'] as List)
          .map(
            (e) => ClientParticipationType.fromApi(e as String),
          )
          .toList(),
      myParticipation: json['myParticipation'] == null
          ? null
          : MyParticipation.fromJson(
              json['myParticipation'] as Map<String, dynamic>,
            ),
      voteClosed: json['voteClosed'] as bool,
    );
  }
}

class CarryoverCandidate {
  CarryoverCandidate({
    required this.targetActivityId,
    required this.date,
    required this.status,
  });

  final int targetActivityId;
  final String date;
  final String status; // FUTURE | PAST_ABSENT

  factory CarryoverCandidate.fromJson(
    Map<String, dynamic> json,
  ) {
    return CarryoverCandidate(
      targetActivityId: json['targetActivityId'] as int,
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }
}

class ParticipationSummary {
  ParticipationSummary({
    required this.regular,
    required this.carryover,
    required this.otherGroup,
    required this.freeAttend,
    required this.absent,
  });

  final int regular;
  final int carryover;
  final int otherGroup;
  final int freeAttend;
  final int absent;

  factory ParticipationSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ParticipationSummary(
      regular: json['regular'] as int,
      carryover: json['carryover'] as int,
      otherGroup: json['otherGroup'] as int,
      freeAttend: json['freeAttend'] as int,
      absent: json['absent'] as int,
    );
  }
}

class Participant {
  Participant({required this.userId, required this.name});

  final int userId;
  final String name;

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] as int,
      name: json['name'] as String,
    );
  }
}

class ActivityParticipants {
  ActivityParticipants({
    required this.regular,
    required this.carryover,
    required this.otherGroup,
    required this.freeAttend,
    required this.absent,
  });

  final List<Participant> regular;
  final List<Participant> carryover;
  final List<Participant> otherGroup;
  final List<Participant> freeAttend;
  final List<Participant> absent;

  factory ActivityParticipants.fromJson(
    Map<String, dynamic> json,
  ) {
    List<Participant> parse(String key) => (json[key] as List)
        .map(
          (e) => Participant.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return ActivityParticipants(
      regular: parse('regular'),
      carryover: parse('carryover'),
      otherGroup: parse('otherGroup'),
      freeAttend: parse('freeAttend'),
      absent: parse('absent'),
    );
  }
}

class ActivityDetail {
  ActivityDetail({
    required this.activityId,
    required this.activityDate,
    required this.groupLabel,
    required this.activityType,
    required this.isCancelled,
    required this.summary,
    required this.participants,
  });

  final int activityId;
  final String activityDate;
  final String groupLabel;
  final ActivityType activityType;
  final bool isCancelled;
  final ParticipationSummary summary;
  final ActivityParticipants participants;

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    return ActivityDetail(
      activityId: json['activityId'] as int,
      activityDate: json['activityDate'] as String,
      groupLabel: json['groupLabel'] as String,
      activityType: ActivityType.fromApi(
        json['activityType'] as String,
      ),
      isCancelled: json['isCancelled'] as bool,
      summary: ParticipationSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      participants: ActivityParticipants.fromJson(
        json['participants'] as Map<String, dynamic>,
      ),
    );
  }
}

class ActivitySummary {
  ActivitySummary({
    required this.activityId,
    required this.groupLabel,
    required this.activityType,
    required this.isCancelled,
    required this.summary,
  });

  final int activityId;
  final String groupLabel;
  final ActivityType activityType;
  final bool isCancelled;
  final ParticipationSummary summary;

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      activityId: json['activityId'] as int,
      groupLabel: json['groupLabel'] as String,
      activityType: ActivityType.fromApi(
        json['activityType'] as String,
      ),
      isCancelled: json['isCancelled'] as bool,
      summary: ParticipationSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );
  }
}
