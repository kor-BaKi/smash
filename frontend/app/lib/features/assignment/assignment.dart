class UnassignedMember {
  UnassignedMember({required this.userId, required this.name, required this.availableGroupIds});

  final int userId;
  final String name;
  final List<int> availableGroupIds;

  factory UnassignedMember.fromJson(Map<String, dynamic> json) {
    return UnassignedMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      availableGroupIds: (json['availableGroupIds'] as List).cast<int>(),
    );
  }
}

class MemberAssignment {
  MemberAssignment({required this.userId, required this.name, required this.assignedGroupId, required this.availableGroupIds});

  final int userId;
  final String name;
  final int? assignedGroupId;
  final List<int> availableGroupIds;

  factory MemberAssignment.fromJson(Map<String, dynamic> json) {
    return MemberAssignment(
      userId: json['userId'] as int,
      name: json['name'] as String,
      assignedGroupId: json['assignedGroupId'] as int?,
      availableGroupIds: (json['availableGroupIds'] as List).cast<int>(),
    );
  }
}

class MemberUnassignedReason {
  MemberUnassignedReason({required this.userId, required this.name, required this.reason});

  final int userId;
  final String name;
  final String reason;

  factory MemberUnassignedReason.fromJson(Map<String, dynamic> json) {
    return MemberUnassignedReason(
      userId: json['userId'] as int,
      name: json['name'] as String,
      reason: json['reason'] as String,
    );
  }
}

class GroupDistribution {
  GroupDistribution({required this.groupId, required this.label, required this.count});

  final int groupId;
  final String label;
  final int count;

  factory GroupDistribution.fromJson(Map<String, dynamic> json) {
    return GroupDistribution(
      groupId: json['groupId'] as int,
      label: json['label'] as String,
      count: json['count'] as int,
    );
  }
}

class AssignmentPreview {
  AssignmentPreview({
    required this.previewToken,
    required this.basedOnMemberIds,
    required this.assignments,
    required this.unassigned,
    required this.groupDistribution,
  });

  final String previewToken;
  final List<int> basedOnMemberIds;
  final List<MemberAssignment> assignments;
  final List<MemberUnassignedReason> unassigned;
  final List<GroupDistribution> groupDistribution;

  factory AssignmentPreview.fromJson(Map<String, dynamic> json) {
    return AssignmentPreview(
      previewToken: json['previewToken'] as String,
      basedOnMemberIds: (json['basedOnMemberIds'] as List).cast<int>(),
      assignments: (json['assignments'] as List)
          .map((e) => MemberAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      unassigned: (json['unassigned'] as List)
          .map((e) => MemberUnassignedReason.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupDistribution: (json['groupDistribution'] as List)
          .map((e) => GroupDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SkippedMember {
  SkippedMember({required this.userId, required this.reason});

  final int userId;
  final String reason;

  factory SkippedMember.fromJson(Map<String, dynamic> json) {
    return SkippedMember(userId: json['userId'] as int, reason: json['reason'] as String);
  }
}

class ConfirmResult {
  ConfirmResult({required this.assignedCount, required this.skipped});

  final int assignedCount;
  final List<SkippedMember> skipped;

  factory ConfirmResult.fromJson(Map<String, dynamic> json) {
    return ConfirmResult(
      assignedCount: json['assignedCount'] as int,
      skipped: (json['skipped'] as List).map((e) => SkippedMember.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
