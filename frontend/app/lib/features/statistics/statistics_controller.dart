import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'statistics.dart';
import 'statistics_repository.dart';

DateTime _monthsAgo(int months) {
  final now = DateTime.now();
  final totalMonths = now.year * 12 + (now.month - 1) - months;
  return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1);
}

// 추이 탭(충족률/이월빈도) 공용 기간 — 기본 최근 6개월.
final statisticsFromYearProvider = StateProvider<int>((ref) => _monthsAgo(5).year);
final statisticsFromMonthProvider = StateProvider<int>((ref) => _monthsAgo(5).month);
final statisticsToYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final statisticsToMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

// null = 전체(클럽 전체 합산).
final statisticsGroupIdProvider = StateProvider<int?>((ref) => null);

final statisticsComparisonYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final statisticsComparisonMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

final fulfillmentTrendProvider = FutureProvider<List<MonthlyFulfillment>>((ref) {
  final groupId = ref.watch(statisticsGroupIdProvider);
  final fromYear = ref.watch(statisticsFromYearProvider);
  final fromMonth = ref.watch(statisticsFromMonthProvider);
  final toYear = ref.watch(statisticsToYearProvider);
  final toMonth = ref.watch(statisticsToMonthProvider);
  return ref.read(statisticsRepositoryProvider).getFulfillmentTrend(
        groupId: groupId,
        fromYear: fromYear,
        fromMonth: fromMonth,
        toYear: toYear,
        toMonth: toMonth,
      );
});

final groupComparisonProvider = FutureProvider<List<GroupComparisonItem>>((ref) {
  final year = ref.watch(statisticsComparisonYearProvider);
  final month = ref.watch(statisticsComparisonMonthProvider);
  return ref.read(statisticsRepositoryProvider).getGroupComparison(year, month);
});

final carryoverTrendProvider = FutureProvider<List<MonthlyCarryoverCount>>((ref) {
  final fromYear = ref.watch(statisticsFromYearProvider);
  final fromMonth = ref.watch(statisticsFromMonthProvider);
  final toYear = ref.watch(statisticsToYearProvider);
  final toMonth = ref.watch(statisticsToMonthProvider);
  return ref.read(statisticsRepositoryProvider).getCarryoverTrend(
        fromYear: fromYear,
        fromMonth: fromMonth,
        toYear: toYear,
        toMonth: toMonth,
      );
});
