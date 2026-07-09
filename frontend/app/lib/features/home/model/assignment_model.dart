class AssignmentItem {
  final int userId;
  final String name;
  int assignedGroupId; // 수동 조정 가능하도록 final 아님
  final List<int> availableGroupIds;

  AssignmentItem({
    required this.userId,
    required this.name,
    required this.assignedGroupId,
    required this.availableGroupIds,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      userId: json['userId'],
      name: json['name'],
      assignedGroupId: json['assignedGroupId'],
      availableGroupIds: List<int>.from(json['availableGroupIds']),
    );
  }
}

class UnassignedItem {
  final int userId;
  final String name;
  final String reason;

  UnassignedItem({
    required this.userId,
    required this.name,
    required this.reason,
  });

  factory UnassignedItem.fromJson(Map<String, dynamic> json) {
    return UnassignedItem(
      userId: json['userId'],
      name: json['name'],
      reason: json['reason'],
    );
  }
}

class GroupDistribution {
  final int groupId;
  final String label;
  final int count;

  GroupDistribution({
    required this.groupId,
    required this.label,
    required this.count,
  });

  factory GroupDistribution.fromJson(Map<String, dynamic> json) {
    return GroupDistribution(
      groupId: json['groupId'],
      label: json['label'],
      count: json['count'],
    );
  }
}

class AssignmentPreview {
  final String previewToken;
  final List<int> basedOnMemberIds;
  final List<AssignmentItem> assignments;
  final List<UnassignedItem> unassigned;
  final List<GroupDistribution> groupDistribution;

  AssignmentPreview({
    required this.previewToken,
    required this.basedOnMemberIds,
    required this.assignments,
    required this.unassigned,
    required this.groupDistribution,
  });

  factory AssignmentPreview.fromJson(Map<String, dynamic> json) {
    return AssignmentPreview(
      previewToken: json['previewToken'],
      basedOnMemberIds: List<int>.from(json['basedOnMemberIds']),
      assignments: (json['assignments'] as List)
          .map((e) => AssignmentItem.fromJson(e))
          .toList(),
      unassigned: (json['unassigned'] as List)
          .map((e) => UnassignedItem.fromJson(e))
          .toList(),
      groupDistribution: (json['groupDistribution'] as List)
          .map((e) => GroupDistribution.fromJson(e))
          .toList(),
    );
  }
}
