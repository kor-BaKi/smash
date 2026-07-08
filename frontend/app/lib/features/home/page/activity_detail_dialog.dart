import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/activity_detail_model.dart';
import '../provider/activity_provider.dart';

class ActivityDetailDialog extends ConsumerStatefulWidget {
  final int activityId;

  const ActivityDetailDialog({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailDialog> createState() =>
      _ActivityDetailDialogState();
}

class _ActivityDetailDialogState
    extends ConsumerState<ActivityDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(activityProvider.notifier)
          .loadActivityDetail(widget.activityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityProvider);
    final detail = state.selectedDetail;

    return AlertDialog(
      title: const Text('투표 결과'),
      content: SizedBox(
        width: double.maxFinite,
        child: state.isLoadingDetail
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : state.errorMessage != null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(state.errorMessage!),
              )
            : detail == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('데이터가 없습니다.'),
              )
            : _DetailBody(detail: detail),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ActivityDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${detail.groupLabel} · ${detail.activityDate}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _CountRow(label: '참여', count: detail.summary.regular),
          _CountRow(label: '이월', count: detail.summary.carryover),
          _CountRow(label: '타조참', count: detail.summary.otherGroup),
          _CountRow(label: '자유참여', count: detail.summary.freeAttend),
          _CountRow(label: '불참', count: detail.summary.absent),
          const Divider(height: 24),
          _ParticipantGroup(
            title: '참여',
            people: detail.participants.regular,
          ),
          _ParticipantGroup(
            title: '이월',
            people: detail.participants.carryover,
          ),
          _ParticipantGroup(
            title: '타조참',
            people: detail.participants.otherGroup,
          ),
          _ParticipantGroup(
            title: '자유참여',
            people: detail.participants.freeAttend,
          ),
          _ParticipantGroup(
            title: '불참',
            people: detail.participants.absent,
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;

  const _CountRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count명',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ParticipantGroup extends StatelessWidget {
  final String title;
  final List<ParticipantInfo> people;

  const _ParticipantGroup({required this.title, required this.people});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: people
                .map(
                  (p) => Chip(
                    label: Text(p.name),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
