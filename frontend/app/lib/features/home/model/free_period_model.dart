class FreePeriodInfo {
  final int id;
  final String startDate;
  final String endDate;

  FreePeriodInfo({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  factory FreePeriodInfo.fromJson(Map<String, dynamic> json) {
    return FreePeriodInfo(
      id: json['id'],
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}
