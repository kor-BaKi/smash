import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/carryover_candidate_model.dart';
import '../provider/activity_provider.dart';

class CarryoverDialog extends ConsumerStatefulWidget {
  final int activityId;
  final VoidCallback? onCompleted;
  const CarryoverDialog({
    super.key,
    required this.activityId,
    this.onCompleted,
  });

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
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        '이월할 날짜 선택',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: state.isLoadingCandidates
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.lime),
                ),
              )
            : state.carryoverCandidates.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '이월 가능한 날짜가 없습니다.',
                  style: TextStyle(color: AppColors.gray),
                ),
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
                          )
                          .then((_) {
                            Navigator.of(context).pop();
                            widget.onCompleted?.call();
                          });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: AppColors.gray)),
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
        color: candidate.isFuture ? AppColors.lime : AppColors.darkGray,
      ),
      title: Text(
        candidate.date,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        candidate.isFuture ? '다가오는 활동일' : '지난 미참여일',
        style: const TextStyle(color: AppColors.gray, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
