import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/carryover_candidate_model.dart';
import '../provider/activity_provider.dart';

class CarryoverDialog extends ConsumerStatefulWidget {
  final int activityId;

  const CarryoverDialog({super.key, required this.activityId});

  @override
  ConsumerState<CarryoverDialog> createState() => _CarryoverDialogState();
}

class _CarryoverDialogState extends ConsumerState<CarryoverDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(activityProvider.notifier)
          .loadCarryoverCandidates(widget.activityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityProvider);

    return AlertDialog(
      title: const Text('이월할 날짜 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: state.isLoadingCandidates
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : state.carryoverCandidates.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('이월 가능한 날짜가 없습니다.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: state.carryoverCandidates.length,
                itemBuilder: (context, index) {
                  final candidate = state.carryoverCandidates[index];
                  return _CandidateTile(
                    candidate: candidate,
                    onTap: () {
                      ref
                          .read(activityProvider.notifier)
                          .participate(
                            activityId: widget.activityId,
                            type: 'CARRYOVER',
                            targetActivityId: candidate.targetActivityId,
                          );
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final CarryoverCandidate candidate;
  final VoidCallback onTap;

  const _CandidateTile({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        candidate.isFuture ? Icons.event : Icons.history,
        color: candidate.isFuture ? Colors.blue : Colors.grey,
      ),
      title: Text(candidate.date),
      subtitle: Text(candidate.isFuture ? '다가오는 활동일' : '지난 미참여일'),
      onTap: onTap,
    );
  }
}
