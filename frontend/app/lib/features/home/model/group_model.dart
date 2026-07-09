class GroupDetail {
  final int id;
  final String dayOfWeek;
  final String timeSlot;
  final String label;
  final int? leaderUserId;
  final int memberCount;

  GroupDetail({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.label,
    this.leaderUserId,
    required this.memberCount,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: json['id'],
      dayOfWeek: json['dayOfWeek'],
      timeSlot: json['timeSlot'],
      label: json['label'],
      leaderUserId: json['leaderUserId'],
      memberCount: json['memberCount'],
    );
  }
}
