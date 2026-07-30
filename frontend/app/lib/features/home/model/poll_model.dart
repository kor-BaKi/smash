class PollOptionResult {
  final int id;
  final String content;
  final int orderIndex;
  final int voteCount;
  final List<String> voters;

  PollOptionResult({
    required this.id,
    required this.content,
    required this.orderIndex,
    required this.voteCount,
    required this.voters,
  });

  factory PollOptionResult.fromJson(Map<String, dynamic> json) {
    return PollOptionResult(
      id: json['id'],
      content: json['content'],
      orderIndex: json['orderIndex'],
      voteCount: json['voteCount'],
      voters: List<String>.from(json['voters'] ?? []),
    );
  }
}

class PollInfo {
  final int id;
  final String title;
  final String? description;
  final bool isAnonymous;
  final bool isClosed;
  final bool isExpired;
  final String? closedAt;
  final String createdAt;
  final List<PollOptionResult> options;
  final int? myVotedOptionId;

  PollInfo({
    required this.id,
    required this.title,
    this.description,
    required this.isAnonymous,
    required this.isClosed,
    required this.isExpired,
    this.closedAt,
    required this.createdAt,
    required this.options,
    this.myVotedOptionId,
  });

  factory PollInfo.fromJson(Map<String, dynamic> json) {
    return PollInfo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isAnonymous: json['isAnonymous'],
      isClosed: json['isClosed'],
      isExpired: json['isExpired'],
      closedAt: json['closedAt'],
      createdAt: json['createdAt'],
      options: (json['options'] as List)
          .map((e) => PollOptionResult.fromJson(e))
          .toList(),
      myVotedOptionId: json['myVotedOptionId'],
    );
  }

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);
}
