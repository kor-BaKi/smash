import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity.dart';
import '../provider/today_activity_controller.dart';
import 'activity_detail_page.dart';

class TodayActivityPage extends ConsumerWidget {
  const TodayActivityPage({super.key});

  Future<void> _handleButtonTap(BuildContext context, WidgetRef ref, TodayActivity activity, ClientParticipationType type) async {
    if (type != ClientParticipationType.carryover) {
      await ref.read(todayActivitiesProvider.notifier).submit(activity.activityId, type);
      return;
    }

    final candidates = await ref.read(activityApiProvider).getCarryoverCandidates(activity.activityId);
    if (!context.mounted) return;

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이월이 불가능합니다.')));
      return;
    }

    final selected = await showDialog<CarryoverCandidate>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('이월할 날짜 선택'),
        children: candidates
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, c),
                  child: Text('${c.date} (${c.status})'),
                ))
            .toList(),
      ),
    );

    if (selected != null) {
      await ref
          .read(todayActivitiesProvider.notifier)
          .submit(activity.activityId, ClientParticipationType.carryover, targetActivityId: selected.targetActivityId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesState = ref.watch(todayActivitiesProvider);
    final scope = ref.watch(todayScopeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 투표')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MY', label: Text('본인 조')),
                ButtonSegment(value: 'ALL', label: Text('전체 조')),
              ],
              selected: {scope},
              onSelectionChanged: (selection) => ref.read(todayScopeProvider.notifier).state = selection.first,
            ),
          ),
          Expanded(
            child: activitiesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(child: Text('오늘 활동이 없습니다.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(todayActivitiesProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(activity.groupLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ActivityDetailPage(activityId: activity.activityId),
                                      ),
                                    ),
                                    child: const Text('상세보기'),
                                  ),
                                ],
                              ),
                              Text(
                                activity.myParticipation == null
                                    ? '응답 없음'
                                    : '내 응답: ${activity.myParticipation!.type.koreanLabel}',
                              ),
                              if (activity.voteClosed)
                                const Text('투표 마감', style: TextStyle(color: Colors.grey))
                              else
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ...activity.availableButtons.map(
                                      (type) => OutlinedButton(
                                        onPressed: () => _handleButtonTap(context, ref, activity, type),
                                        child: Text(type.koreanLabel),
                                      ),
                                    ),
                                    if (activity.myParticipation != null)
                                      TextButton(
                                        onPressed: () =>
                                            ref.read(todayActivitiesProvider.notifier).cancel(activity.activityId),
                                        child: const Text('응답 취소'),
                                      ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}
