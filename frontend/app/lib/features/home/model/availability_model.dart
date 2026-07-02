class GroupItem {
  final int id;
  final String label;
  final String dayOfWeek;
  final String timeSlot;

  GroupItem({
    required this.id,
    required this.label,
    required this.dayOfWeek,
    required this.timeSlot,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      id: json['id'],
      label: json['label'],
      dayOfWeek: json['dayOfWeek'],
      timeSlot: json['timeSlot'],
    );
  }
}
