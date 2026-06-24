class FreePeriod {
  FreePeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final String? name;
  final String startDate;
  final String endDate;

  factory FreePeriod.fromJson(Map<String, dynamic> json) {
    return FreePeriod(
      id: json['id'] as int,
      name: json['name'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    );
  }
}
