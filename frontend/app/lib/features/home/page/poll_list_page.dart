import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';
import '../provider/poll_provider.dart';
import 'poll_create_page.dart';
import 'poll_detail_page.dart';

class PollListPage extends ConsumerStatefulWidget {
  const PollListPage({super.key});

  @override
  ConsumerState<PollListPage> createState() => _PollListPageState();
}

class _PollListPageState extends ConsumerState<PollListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pollProvider.notifier).loadPolls());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pollProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('투표'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PollCreatePage()),
              ).then((_) => ref.read(pollProvider.notifier).loadPolls()),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.polls.isEmpty
          ? const Center(child: Text('진행 중인 투표가 없습니다.'))
          : RefreshIndicator(
              onRefresh: () => ref.read(pollProvider.notifier).loadPolls(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.polls.length,
                itemBuilder: (context, index) {
                  final poll = state.polls[index];
                  return GestureDetector(
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PollDetailPage(pollId: poll.id),
                          ),
                        ).then(
                          (_) =>
                              ref.read(pollProvider.notifier).loadPolls(),
                        ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 5,
                            color: poll.isExpired
                                ? AppColors.textTertiary
                                : AppColors.primary,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        poll.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: poll.isExpired
                                            ? AppColors.neutralBg
                                            : AppColors.primaryBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
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
                                if (poll.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    poll.description!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 10),
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
                                      poll.isAnonymous ? '익명' : '기명',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.people,
                                      size: 14,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${poll.totalVotes}명 참여',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    if (poll.myVotedOptionId != null) ...[
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.freeActivity,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '투표 완료',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.freeActivity,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
