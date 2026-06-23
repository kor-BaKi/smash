import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../group/group_controller.dart';
import 'statistics_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('통계'),
          bottom: const TabBar(
            tabs: [Tab(text: '충족률 추이'), Tab(text: '조별 비교'), Tab(text: '이월 빈도')],
          ),
        ),
        body: const TabBarView(
          children: [_FulfillmentTrendTab(), _GroupComparisonTab(), _CarryoverTrendTab()],
        ),
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromYear = ref.watch(statisticsFromYearProvider);
    final fromMonth = ref.watch(statisticsFromMonthProvider);
    final toYear = ref.watch(statisticsToYearProvider);
    final toMonth = ref.watch(statisticsToMonthProvider);
    final now = DateTime.now();
    final years = [for (var y = now.year - 2; y <= now.year; y++) y];
    final months = [for (var m = 1; m <= 12; m++) m];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<int>(
            value: fromYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y년'))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(statisticsFromYearProvider.notifier).state = value;
            },
          ),
          DropdownButton<int>(
            value: fromMonth,
            items: months.map((m) => DropdownMenuItem(value: m, child: Text('$m월'))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(statisticsFromMonthProvider.notifier).state = value;
            },
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
          DropdownButton<int>(
            value: toYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y년'))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(statisticsToYearProvider.notifier).state = value;
            },
          ),
          DropdownButton<int>(
            value: toMonth,
            items: months.map((m) => DropdownMenuItem(value: m, child: Text('$m월'))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(statisticsToMonthProvider.notifier).state = value;
            },
          ),
        ],
      ),
    );
  }
}

class _FulfillmentTrendTab extends ConsumerWidget {
  const _FulfillmentTrendTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupControllerProvider);
    final selectedGroupId = ref.watch(statisticsGroupIdProvider);
    final trendState = ref.watch(fulfillmentTrendProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: groupsState.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(error.toString()),
            data: (groups) => DropdownButton<int?>(
              value: selectedGroupId,
              items: [
                const DropdownMenuItem(value: null, child: Text('전체')),
                ...groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.label))),
              ],
              onChanged: (value) => ref.read(statisticsGroupIdProvider.notifier).state = value,
            ),
          ),
        ),
        const _PeriodSelector(),
        Expanded(
          child: trendState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (trend) {
              if (trend.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 1,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text('${(value * 100).round()}%'),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('${trend[index].month}월', style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        color: Theme.of(context).colorScheme.primary,
                        spots: [
                          for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].fulfillmentRate),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupComparisonTab extends ConsumerWidget {
  const _GroupComparisonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(statisticsComparisonYearProvider);
    final month = ref.watch(statisticsComparisonMonthProvider);
    final comparisonState = ref.watch(groupComparisonProvider);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              DropdownButton<int>(
                value: year,
                items: [
                  for (var y = now.year - 1; y <= now.year + 1; y++) DropdownMenuItem(value: y, child: Text('$y년')),
                ],
                onChanged: (value) {
                  if (value != null) ref.read(statisticsComparisonYearProvider.notifier).state = value;
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: month,
                items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('$m월'))],
                onChanged: (value) {
                  if (value != null) ref.read(statisticsComparisonMonthProvider.notifier).state = value;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: comparisonState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('조가 없습니다.'));
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 1,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text('${(value * 100).round()}%'),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= items.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(items[index].groupLabel, style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    barGroups: [
                      for (var i = 0; i < items.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: items[i].fulfillmentRate,
                              color: items[i].shortfallMemberCount > 0
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.primary,
                              width: 18,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CarryoverTrendTab extends ConsumerWidget {
  const _CarryoverTrendTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendState = ref.watch(carryoverTrendProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PeriodSelector(),
        Expanded(
          child: trendState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (trend) {
              if (trend.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }
              final maxCount = trend.map((m) => m.count).fold<int>(0, (a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maxCount == 0 ? 1 : (maxCount + 1).toDouble(),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('${trend[index].month}월', style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    barGroups: [
                      for (var i = 0; i < trend.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: trend[i].count.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 18,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
