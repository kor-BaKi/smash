import '../../core/domain/day_of_week.dart';
import '../../core/domain/time_slot.dart';

class ActivitySchedule {
  ActivitySchedule({required this.dayOfWeek, required this.timeSlot, required this.isActive});

  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final bool isActive;

  factory ActivitySchedule.fromJson(Map<String, dynamic> json) {
    return ActivitySchedule(
      dayOfWeek: DayOfWeek.fromApi(json['dayOfWeek'] as String),
      timeSlot: TimeSlot.fromApi(json['timeSlot'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  ActivitySchedule copyWith({bool? isActive}) {
    return ActivitySchedule(dayOfWeek: dayOfWeek, timeSlot: timeSlot, isActive: isActive ?? this.isActive);
  }
}
