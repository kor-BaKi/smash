import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity.dart';
import 'activity_detail_controller.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final int activityId;

  Widget _participantSection(String title, List<Participant> participants) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${participants.length}명)', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (participants.isEmpty)
            const Padding(padding: EdgeInsets.only(left: 8), child: Text('-'))
          else
            ...participants.map((p) => Padding(padding: const EdgeInsets.only(left: 8), child: Text(p.name))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(activityDetailProvider(activityId));

    return Scaffold(
      appBar: AppBar(title: const Text('활동 상세')),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (detail) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(detail.groupLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${detail.activityDate} · ${detail.activityType.koreanLabel}${detail.isCancelled ? ' · 취소됨' : ''}'),
              const Divider(),
              _participantSection('정규', detail.participants.regular),
              _participantSection('이월', detail.participants.carryover),
              _participantSection('타조참여', detail.participants.otherGroup),
              _participantSection('자유참여', detail.participants.freeAttend),
              _participantSection('불참', detail.participants.absent),
            ],
          );
        },
      ),
    );
  }
}
