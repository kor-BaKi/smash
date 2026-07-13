class ScheduleItem {
  final int id;
  final String dayOfWeek;
  final String timeSlot;
  bool isActive;

  ScheduleItem({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.isActive,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      dayOfWeek: json['dayOfWeek'],
      timeSlot: json['timeSlot'],
      isActive: json['isActive'],
    );
  }
}
