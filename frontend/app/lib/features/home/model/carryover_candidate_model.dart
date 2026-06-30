class CarryoverCandidate {
  final int targetActivityId;
  final String date;
  final String status;

  CarryoverCandidate({
    required this.targetActivityId,
    required this.date,
    required this.status,
  });

  factory CarryoverCandidate.fromJson(Map<String, dynamic> json) {
    return CarryoverCandidate(
      targetActivityId: json['targetActivityId'],
      date: json['date'],
      status: json['status'],
    );
  }

  bool get isFuture => status == 'FUTURE';
}
