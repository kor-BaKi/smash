import '../../core/domain/day_of_week.dart';
import '../../core/domain/time_slot.dart';

class Availability {
  Availability({required this.groupId, required this.dayOfWeek, required this.timeSlot, required this.label});

  final int groupId;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final String label;

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      groupId: json['groupId'] as int,
      dayOfWeek: DayOfWeek.fromApi(json['dayOfWeek'] as String),
      timeSlot: TimeSlot.fromApi(json['timeSlot'] as String),
      label: json['label'] as String,
    );
  }
}

class AvailabilityStatus {
  AvailabilityStatus({required this.availabilities, required this.assigned, required this.assignedGroupId});

  final List<Availability> availabilities;
  final bool assigned;
  final int? assignedGroupId;

  factory AvailabilityStatus.fromJson(Map<String, dynamic> json) {
    return AvailabilityStatus(
      availabilities: (json['availabilities'] as List)
          .map((e) => Availability.fromJson(e as Map<String, dynamic>))
          .toList(),
      assigned: json['assigned'] as bool,
      assignedGroupId: json['assignedGroupId'] as int?,
    );
  }
}
