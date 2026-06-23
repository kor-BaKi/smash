import '../../../core/domain/day_of_week.dart';
import '../../../core/domain/time_slot.dart';

class Group {
  Group({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.label,
    required this.leaderUserId,
    required this.memberCount,
  });

  final int id;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final String label;
  final int? leaderUserId;
  final int memberCount;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      dayOfWeek: DayOfWeek.fromApi(json['dayOfWeek'] as String),
      timeSlot: TimeSlot.fromApi(json['timeSlot'] as String),
      label: json['label'] as String,
      leaderUserId: json['leaderUserId'] as int?,
      memberCount: json['memberCount'] as int,
    );
  }
}
