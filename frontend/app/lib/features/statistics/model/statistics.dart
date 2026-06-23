class MonthlyFulfillment {
  MonthlyFulfillment({
    required this.year,
    required this.month,
    required this.guaranteed,
    required this.fulfilled,
    required this.fulfillmentRate,
  });

  final int year;
  final int month;
  final int guaranteed;
  final int fulfilled;
  final double fulfillmentRate;

  factory MonthlyFulfillment.fromJson(Map<String, dynamic> json) {
    return MonthlyFulfillment(
      year: json['year'] as int,
      month: json['month'] as int,
      guaranteed: json['guaranteed'] as int,
      fulfilled: json['fulfilled'] as int,
      fulfillmentRate: (json['fulfillmentRate'] as num).toDouble(),
    );
  }
}

class GroupComparisonItem {
  GroupComparisonItem({
    required this.groupId,
    required this.groupLabel,
    required this.guaranteed,
    required this.fulfilled,
    required this.shortfallMemberCount,
    required this.fulfillmentRate,
  });

  final int groupId;
  final String groupLabel;
  final int guaranteed;
  final int fulfilled;
  final int shortfallMemberCount;
  final double fulfillmentRate;

  factory GroupComparisonItem.fromJson(Map<String, dynamic> json) {
    return GroupComparisonItem(
      groupId: json['groupId'] as int,
      groupLabel: json['groupLabel'] as String,
      guaranteed: json['guaranteed'] as int,
      fulfilled: json['fulfilled'] as int,
      shortfallMemberCount: json['shortfallMemberCount'] as int,
      fulfillmentRate: (json['fulfillmentRate'] as num).toDouble(),
    );
  }
}

class MonthlyCarryoverCount {
  MonthlyCarryoverCount({required this.year, required this.month, required this.count});

  final int year;
  final int month;
  final int count;

  factory MonthlyCarryoverCount.fromJson(Map<String, dynamic> json) {
    return MonthlyCarryoverCount(
      year: json['year'] as int,
      month: json['month'] as int,
      count: json['count'] as int,
    );
  }
}
