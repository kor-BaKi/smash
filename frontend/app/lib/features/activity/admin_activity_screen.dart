import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/activity_type.dart';
import 'activity_detail_screen.dart';
import 'admin_activity_controller.dart';

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(adminActivityDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(current),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(adminActivityDateProvider.notifier).state = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(adminActivityDateProvider);
    final activitiesState = ref.watch(adminActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 관리'),
        actions: [
          TextButton(
            onPressed: () => _pickDate(context, ref),
            child: Text(date, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: activitiesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('해당 날짜의 활동이 없습니다.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(adminActivitiesProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('${activity.groupLabel}${activity.isCancelled ? ' (취소됨)' : ''}'),
                    subtitle: Text(
                      '${activity.activityType.koreanLabel} · 정규 ${activity.summary.regular} / 이월 ${activity.summary.carryover} / '
                      '타조 ${activity.summary.otherGroup} / 자유 ${activity.summary.freeAttend} / 불참 ${activity.summary.absent}',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ActivityDetailScreen(activityId: activity.activityId)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: '정규/자유 전환',
                          onPressed: () => ref.read(adminActivitiesProvider.notifier).updateActivity(
                                activity.activityId,
                                activityType: activity.activityType == ActivityType.regular
                                    ? ActivityType.free
                                    : ActivityType.regular,
                              ),
                        ),
                        Switch(
                          value: !activity.isCancelled,
                          onChanged: (enabled) => ref
                              .read(adminActivitiesProvider.notifier)
                              .updateActivity(activity.activityId, isCancelled: !enabled),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
