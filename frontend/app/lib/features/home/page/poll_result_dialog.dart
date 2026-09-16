import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';
import '../provider/poll_provider.dart';

Color pollOptionColor(String content, int index) {
  if (content.contains('불')) return AppColors.coral;
  if (content.contains('참')) return AppColors.green;

  const palette = [
    AppColors.lime,
    AppColors.coral,
    AppColors.green,
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
  ];
  return palette[index % palette.length];
}

class PollResultDialog extends ConsumerStatefulWidget {
  final int pollId;
  const PollResultDialog({super.key, required this.pollId});

  @override
  ConsumerState<PollResultDialog> createState() =>
      _PollResultDialogState();
}

class _PollResultDialogState extends ConsumerState<PollResultDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pollProvider.notifier).loadDetail(widget.pollId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pollProvider);
    final poll = state.selectedPoll;
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.maxFinite,
          child: state.isLoading || poll == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lime,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            poll.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        if (isAdmin && !poll.isExpired)
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      24,
                                    ),
                                  ),
                                  title: const Text(
                                    '투표 종료',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  content: const Text(
                                    '투표를 종료할까요?\n종료 후에는 되돌릴 수 없습니다.',
                                    style: TextStyle(
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: AppColors.gray,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        '종료',
                                        style: TextStyle(
                                          color: AppColors.coral,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await ref
                                    .read(pollProvider.notifier)
                                    .close(widget.pollId);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text(
                              '종료',
                              style: TextStyle(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (poll.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        poll.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '총 ${poll.totalVotes}명 참여',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: poll.isExpired
                                ? AppColors.grayTag
                                : AppColors.greenTag,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            poll.isExpired ? '종료' : '진행 중',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: poll.isExpired
                                  ? AppColors.grayTagText
                                  : AppColors.greenTagText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: AppColors.border),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...poll.options.asMap().entries.map((entry) {
                              final index = entry.key;
                              final option = entry.value;
                              final isMyVote =
                                  poll.myVotedOptionId == option.id;
                              final color = pollOptionColor(
                                option.content,
                                index,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMyVote
                                      ? color.withValues(alpha: 0.12)
                                      : AppColors.card2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMyVote
                                      ? Border.all(
                                          color: color,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    if (isMyVote)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: color,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        option.content,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isMyVote
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isMyVote
                                              ? color
                                              : AppColors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${option.voteCount}명',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isMyVote
                                            ? color
                                            : AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            if (!poll.isAnonymous &&
                                poll.options.any(
                                  (o) => o.voters.isNotEmpty,
                                )) ...[
                              const SizedBox(height: 16),
                              const Text(
                                '참여자',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...poll.options
                                  .asMap()
                                  .entries
                                  .where((e) => e.value.voters.isNotEmpty)
                                  .map((entry) {
                                    final index = entry.key;
                                    final option = entry.value;
                                    final color = pollOptionColor(
                                      option.content,
                                      index,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              option.content,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option.voters.join(', '),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.gray,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.card2,
                          foregroundColor: AppColors.gray,
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('닫기'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
