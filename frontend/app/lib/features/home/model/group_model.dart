class GroupDetail {
  final int id;
  final String dayOfWeek;
  final String timeSlot;
  final String label;
  final int? leaderUserId;
  final int? viceLeaderUserId;
  final int memberCount;

  GroupDetail({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.label,
    this.leaderUserId,
    this.viceLeaderUserId,
    required this.memberCount,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: json['id'],
      dayOfWeek: json['dayOfWeek'],
      timeSlot: json['timeSlot'],
      label: json['label'],
      leaderUserId: json['leaderUserId'],
      viceLeaderUserId: json['viceLeaderUserId'],
      memberCount: json['memberCount'],
    );
  }
}
