import 'activity_detail_model.dart';

class ActivitySummaryItem {
  final int activityId;
  final String activityDate;
  final String groupLabel;
  final String activityType;
  final bool isCancelled;
  final ActivitySummary summary;

  ActivitySummaryItem({
    required this.activityId,
    required this.activityDate,
    required this.groupLabel,
    required this.activityType,
    required this.isCancelled,
    required this.summary,
  });

  factory ActivitySummaryItem.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryItem(
      activityId: json['activityId'],
      activityDate: json['activityDate'],
      groupLabel: json['groupLabel'],
      activityType: json['activityType'],
      isCancelled: json['isCancelled'],
      summary: ActivitySummary.fromJson(json['summary']),
    );
  }
}
