import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/activity_model.dart';
import '../provider/activity_provider.dart';

class MemberHomeView extends ConsumerStatefulWidget {
  const MemberHomeView({super.key});

  @override
  ConsumerState<MemberHomeView> createState() => _MemberHomeViewState();
}

class _MemberHomeViewState extends ConsumerState<MemberHomeView> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 그려진 직후 데이터 로드
    Future.microtask(() {
      ref.read(activityProvider.notifier).loadTodayActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityProvider);

    if (activityState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activityState.errorMessage != null) {
      return Center(child: Text(activityState.errorMessage!));
    }

    if (activityState.activities.isEmpty) {
      return const Center(child: Text('오늘은 예정된 활동이 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(activityProvider.notifier).loadTodayActivities(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activityState.activities.length,
        itemBuilder: (context, index) {
          final activity = activityState.activities[index];
          return _ActivityCard(activity: activity);
        },
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final TodayActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  activity.groupLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (activity.isMyGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '내 조',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (activity.voteClosed)
              const Text(
                '투표가 마감되었습니다.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                children: activity.availableButtons.map((type) {
                  return ElevatedButton(
                    onPressed: () {
                      ref
                          .read(activityProvider.notifier)
                          .participate(
                            activityId: activity.activityId,
                            type: type,
                          );
                    },
                    child: Text(_buttonLabel(type)),
                  );
                }).toList(),
              ),
            if (activity.myParticipation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '내 응답: ${_buttonLabel(activity.myParticipation!.type)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buttonLabel(String type) {
    switch (type) {
      case 'ATTEND':
        return '참여';
      case 'ABSENT':
        return '불참';
      case 'CARRYOVER':
        return '이월';
      case 'OTHER_GROUP':
        return '타조참';
      case 'FREE_ATTEND':
        return '자유참여';
      default:
        return type;
    }
  }
}
