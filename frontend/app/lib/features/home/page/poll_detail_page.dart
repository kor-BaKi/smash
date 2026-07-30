import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/poll_model.dart';
import '../provider/auth_provider.dart';
import '../provider/poll_provider.dart';

class PollDetailPage extends ConsumerStatefulWidget {
  final int pollId;

  const PollDetailPage({super.key, required this.pollId});

  @override
  ConsumerState<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends ConsumerState<PollDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pollProvider.notifier).loadDetail(widget.pollId),
    );
  }

  Future<void> _confirmClose() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('투표 종료'),
        content: const Text('투표를 종료할까요?\n종료 후에는 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '종료',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(pollProvider.notifier).close(widget.pollId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pollProvider);
    final poll = state.selectedPoll;
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('투표'),
        actions: [
          if (isAdmin && poll != null && !poll.isExpired)
            TextButton(
              onPressed: _confirmClose,
              child: const Text(
                '종료',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading || poll == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 제목/설명
                  Text(
                    poll.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (poll.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      poll.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        poll.isAnonymous
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        poll.isAnonymous ? '익명 투표' : '기명 투표',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '총 ${poll.totalVotes}명 참여',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: poll.isExpired
                              ? AppColors.neutralBg
                              : AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          poll.isExpired ? '종료' : '진행 중',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: poll.isExpired
                                ? AppColors.textTertiary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.neutralBg),
                  const SizedBox(height: 16),

                  // 옵션 목록
                  ...poll.options.map(
                    (option) => _OptionTile(poll: poll, option: option),
                  ),

                  // 종료 안내
                  if (poll.isExpired) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '종료된 투표입니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _OptionTile extends ConsumerWidget {
  final PollInfo poll;
  final PollOptionResult option;

  const _OptionTile({required this.poll, required this.option});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pollProvider);
    final isMyVote = poll.myVotedOptionId == option.id;
    final hasVoted = poll.myVotedOptionId != null;
    final percent = poll.totalVotes == 0
        ? 0.0
        : option.voteCount / poll.totalVotes;

    return GestureDetector(
      onTap: (hasVoted || poll.isExpired || state.isSubmitting)
          ? null
          : () => ref.read(pollProvider.notifier).vote(poll.id, option.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isMyVote ? AppColors.primaryBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMyVote ? AppColors.primary : AppColors.divider,
            width: isMyVote ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              // 퍼센트 배경 바
              if (hasVoted || poll.isExpired)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent,
                    child: Container(
                      color: isMyVote
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.neutralBg,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isMyVote)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  option.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isMyVote
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isMyVote
                                        ? AppColors.primaryDeep
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!poll.isAnonymous &&
                              option.voters.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              option.voters.join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasVoted || poll.isExpired) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isMyVote
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${option.voteCount}명',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
