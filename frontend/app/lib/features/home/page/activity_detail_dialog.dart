import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.maxFinite,
          child: state.isLoadingDetail
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : state.errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(state.errorMessage!),
                )
              : detail == null
              ? const SizedBox()
              : _DetailBody(detail: detail),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ActivityDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final total =
        detail.summary.regular +
        detail.summary.carryover +
        detail.summary.otherGroup +
        detail.summary.freeAttend;
    final participants = [
      ...detail.participants.regular,
      ...detail.participants.carryover,
      ...detail.participants.otherGroup,
      ...detail.participants.freeAttend,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '투표 결과',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail.groupLabel,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                count: total,
                label: '참여',
                bg: AppColors.primaryBg,
                fg: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                count: detail.summary.absent,
                label: '불참',
                bg: AppColors.neutralBg,
                fg: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '참여자',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        if (participants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '참여자가 없습니다.',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                children: participants
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.neutralBg,
                              child: Text(
                                p.name.characters.first,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neutralBg,
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color fg;

  const _StatBox({
    required this.count,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
