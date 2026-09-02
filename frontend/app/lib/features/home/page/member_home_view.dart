import 'package:app/features/home/page/poll_result_dialog.dart';
import 'package:app/features/home/page/taxi_settlement_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/activity_model.dart';
import '../model/poll_model.dart';
import '../provider/activity_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/poll_provider.dart';
import '../provider/transport_provider.dart';
import 'activity_detail_dialog.dart';
import 'carryover_dialog.dart';

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
      ref.read(pollProvider.notifier).loadPolls();
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

    final dateLabel = _formatTodayLabel();

    if (activityState.activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(activityProvider.notifier).loadTodayActivities(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              '오늘 활동 · $dateLabel',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 120),
            const Center(child: Text('오늘은 예정된 활동이 없습니다.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(activityProvider.notifier).loadTodayActivities(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            '오늘 활동 · $dateLabel',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ...activityState.activities.map(
            (activity) => _ActivityCard(activity: activity),
          ),
          ...ref
              .watch(pollProvider)
              .polls
              .where((p) => !p.isExpired)
              .map((poll) => _PollCard(poll: poll)),
        ],
      ),
    );
  }

  String _formatTodayLabel() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}월 ${now.day}일 $weekday';
  }
}

class _ActivityCard extends ConsumerWidget {
  final TodayActivity activity;

  const _ActivityCard({required this.activity});

  // 카드 상단 밴드 색상 결정
  Color get _bandColor {
    if (activity.voteClosed) return AppColors.textTertiary;
    if (activity.activityType == 'FREE') return AppColors.freeActivity;
    if (!activity.isMyGroup) return AppColors.amber;
    return AppColors.primary;
  }

  // 뱃지 (내 조 / 자유활동 / 타 조 / 마감)
  ({String text, Color bg, Color fg}) get _badge {
    if (activity.voteClosed) {
      return (
        text: '마감',
        bg: AppColors.neutralBg,
        fg: AppColors.textTertiary,
      );
    }
    if (activity.activityType == 'FREE') {
      return (
        text: '자유활동',
        bg: AppColors.freeActivityBg,
        fg: AppColors.freeActivityText,
      );
    }
    if (activity.isMyGroup) {
      return (
        text: '내 조',
        bg: AppColors.primaryBg,
        fg: AppColors.primaryDeep,
      );
    }
    return (text: '타 조', bg: AppColors.amberBg, fg: AppColors.amber);
  }

  String get _subtitle {
    if (activity.activityType == 'FREE') return '자유롭게 참여하세요';
    if (activity.voteClosed) return '${activity.groupLabel} · 마감됨';
    if (!activity.isMyGroup) return '${activity.groupLabel} · 타 조 활동';
    return '${activity.groupLabel} · 마감 전';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = _badge;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 컬러 밴드
          Container(height: 5, color: _bandColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${activity.groupLabel} ${activity.activityType == 'FREE' ? '자유활동' : '정규활동'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.text,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badge.fg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 14),

                // 마감 여부에 따른 액션 영역
                if (activity.voteClosed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.neutralBg,
                      borderRadius: BorderRadius.circular(10),
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
                          '투표가 마감되었습니다',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: activity.availableButtons.map((type) {
                      final isPrimaryAction =
                          type == 'ATTEND' || type == 'FREE_ATTEND';
                      return Expanded(
                        flex: isPrimaryAction ? 13 : 10,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ActionButton(
                            label: _buttonLabel(type),
                            color: _buttonColor(type),
                            onPressed: () {
                              if (type == 'CARRYOVER') {
                                showDialog(
                                  context: context,
                                  builder: (context) => CarryoverDialog(
                                    activityId: activity.activityId,
                                    onCompleted: () =>
                                        _showTravelTypeDialog(
                                          context,
                                          ref,
                                          activity.activityId,
                                        ),
                                  ),
                                );
                              } else {
                                final serverType = type == 'ATTEND'
                                    ? 'REGULAR'
                                    : type;
                                ref
                                    .read(activityProvider.notifier)
                                    .participate(
                                      activityId: activity.activityId,
                                      type: serverType,
                                    )
                                    .then((_) {
                                      // 참여/이월/타조참 모두 이동 방법 팝업
                                      if (type == 'ATTEND' ||
                                          type == 'CARRYOVER' ||
                                          type == 'OTHER_GROUP') {
                                        _showTravelTypeDialog(
                                          context,
                                          ref,
                                          activity.activityId,
                                        );
                                      }
                                    });
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (activity.myParticipation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "'${_buttonLabel(activity.myParticipation!.type)}'로 응답했어요",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                            if (!activity.voteClosed)
                              GestureDetector(
                                onTap: () => ref
                                    .read(activityProvider.notifier)
                                    .cancelParticipation(
                                      activity.activityId,
                                    ),
                                child: const Text(
                                  '다시 선택',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // 이동 방법 선택/변경
                        if (activity.myParticipation!.type == 'REGULAR' ||
                            activity.myParticipation!.type ==
                                'OTHER_GROUP' ||
                            activity.myParticipation!.type ==
                                'CARRYOVER') ...[
                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activity.myParticipation!.travelType ==
                                        null
                                    ? '이동 방법을 선택해주세요'
                                    : activity
                                              .myParticipation!
                                              .travelType ==
                                          'TOGETHER'
                                    ? '같이 이동'
                                    : '따로 이동',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      activity
                                              .myParticipation!
                                              .travelType ==
                                          null
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showTravelTypeDialog(
                                  context,
                                  ref,
                                  activity.activityId,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutralBg,
                                    borderRadius: BorderRadius.circular(
                                      999,
                                    ),
                                  ),
                                  child: Text(
                                    activity.myParticipation!.travelType ==
                                            null
                                        ? '선택하기'
                                        : '변경',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (activity.myParticipation != null &&
                              (activity.myParticipation!.type ==
                                      'REGULAR' ||
                                  activity.myParticipation!.type ==
                                      'OTHER_GROUP' ||
                                  activity.myParticipation!.type ==
                                      'CARRYOVER')) ...[
                            const SizedBox(height: 8),
                            _MyTransportGroup(
                              activityId: activity.activityId,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ActivityDetailDialog(
                          activityId: activity.activityId,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '투표 결과 보기 ›',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _buttonColor(String type) {
    switch (type) {
      case 'ATTEND':
        return AppColors.primary;
      case 'FREE_ATTEND':
        return AppColors.freeActivity;
      case 'ABSENT':
        return AppColors.neutralBg;
      case 'CARRYOVER':
        return AppColors.amberBg;
      case 'OTHER_GROUP':
        return AppColors.cardBg;
      default:
        return AppColors.neutralBg;
    }
  }

  String _buttonLabel(String type) {
    switch (type) {
      case 'ATTEND':
      case 'REGULAR':
        return '참여';
      case 'ABSENT':
        return '불참';
      case 'CARRYOVER':
        return '이월';
      case 'OTHER_GROUP':
        return '타조참';
      case 'FREE_ATTEND':
        return '참여';
      default:
        return type;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  bool get _isFilled =>
      color == AppColors.primary || color == AppColors.freeActivity;

  bool get _isOutline => color == AppColors.cardBg;

  @override
  Widget build(BuildContext context) {
    final textColor = _isFilled
        ? Colors.white
        : color == AppColors.amberBg
        ? AppColors.amber
        : _isOutline
        ? AppColors.amber
        : AppColors.textSecondary;

    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          side: _isOutline
              ? const BorderSide(color: AppColors.amber, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final PollInfo poll;

  const _PollCard({required this.poll});

  List<List<PollOptionResult>> _groupOptions() {
    final options = poll.options;
    final count = options.length;
    if (count <= 4) return [options];
    final topCount = count <= 6 ? (count / 2).ceil() : 4;
    return [options.sublist(0, topCount), options.sublist(topCount)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pollProvider);
    final hasVoted = poll.myVotedOptionId != null;
    final rows = _groupOptions();

    final votedOption = hasVoted
        ? poll.options.firstWhere((o) => o.id == poll.myVotedOptionId)
        : null;
    final votedColor = votedOption != null
        ? pollOptionColor(
            votedOption.content,
            poll.options.indexOf(votedOption),
          )
        : AppColors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, color: AppColors.amber),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        poll.isAnonymous ? '익명' : '기명',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
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
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // 날짜 정보 추가
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      poll.closedAt != null
                          ? '${poll.createdAt.substring(0, 10)} ~ ${poll.closedAt!.substring(0, 16).replaceAll('T', ' ')}'
                          : poll.createdAt.substring(0, 10),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 투표 전: 선택지 버튼
                if (!hasVoted)
                  Column(
                    children: rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: row.asMap().entries.map((entry) {
                            final option = entry.value;
                            final isLast = entry.key == row.length - 1;
                            final color = pollOptionColor(
                              option.content,
                              poll.options.indexOf(option),
                            );
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: isLast ? 0 : 8,
                                ),
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () => ref
                                              .read(pollProvider.notifier)
                                              .vote(poll.id, option.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color.withOpacity(
                                        0.12,
                                      ),
                                      foregroundColor: color,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      option.content,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),

                // 투표 후: 내가 선택한 옵션 + 다시 투표
                if (hasVoted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: votedColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: votedColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "'${votedOption!.content}'에 투표했어요",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: votedColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: state.isSubmitting
                              ? null
                              : () => ref
                                    .read(pollProvider.notifier)
                                    .cancelVote(poll.id),
                          child: const Text(
                            '다시 투표',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => PollResultDialog(pollId: poll.id),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: votedColor,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '투표 결과 보기 ›',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color pollOptionColor(String content, int index) {
  if (content.contains('불')) return AppColors.danger;
  if (content.contains('참')) return AppColors.freeActivity;

  const palette = [
    AppColors.primary,
    AppColors.amber,
    Color(0xFF7C3AED), // 보라
    Color(0xFF0891B2), // 청록
    Color(0xFFDB2777), // 핑크
    Color(0xFF65A30D), // 연두
  ];
  return palette[index % palette.length];
}

Future<void> _showTravelTypeDialog(
  BuildContext context,
  WidgetRef ref,
  int activityId,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        '이동 방법을 선택해주세요',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        '정문에서 함께 이동하시나요?',
        style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ActivityApi.updateTravelType(activityId, 'TOGETHER');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '같이 가겠습니다',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ActivityApi.updateTravelType(activityId, 'ALONE');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '따로 가겠습니다',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MyTransportGroup extends ConsumerStatefulWidget {
  final int activityId;

  const _MyTransportGroup({required this.activityId});

  @override
  ConsumerState<_MyTransportGroup> createState() =>
      _MyTransportGroupState();
}

class _MyTransportGroupState extends ConsumerState<_MyTransportGroup> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(transportByActivityProvider(widget.activityId).notifier)
          .loadGroups(widget.activityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) return const SizedBox();

    final transportState = ref.watch(
      transportByActivityProvider(widget.activityId),
    );
    final myGroup = ref
        .read(transportByActivityProvider(widget.activityId).notifier)
        .findMyGroup(userId);

    if (myGroup == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.neutralBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 14,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 8),
            Text(
              '택시 그룹 배정 대기 중',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${myGroup.groupNumber}호차',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${myGroup.members.length}명',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: myGroup.members.map((m) {
              final isMe = m.userId == userId;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  m.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaxiSettlementPage(
                    activityId: widget.activityId,
                    groupId: myGroup.groupId,
                    groupNumber: myGroup.groupNumber,
                    myUserId: userId,
                  ),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 14),
              label: const Text('택시비 정산'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
