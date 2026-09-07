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
    Future.microtask(() {
      ref.read(activityProvider.notifier).loadTodayActivities();
      ref.read(pollProvider.notifier).loadPolls();
    });
  }

  String _formatTodayLabel() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}월 ${now.day}일 $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityProvider);
    final user = ref.watch(authProvider).user;

    if (activityState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }

    return RefreshIndicator(
      color: AppColors.lime,
      backgroundColor: AppColors.card,
      onRefresh: () =>
          ref.read(activityProvider.notifier).loadTodayActivities(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTodayLabel(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFamily: 'BMJUA',
                          ),
                          children: [
                            TextSpan(
                              text: user?.name ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                              ),
                            ),
                            const TextSpan(
                              text: ' •',
                              style: TextStyle(color: AppColors.lime),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user?.name.substring(0, 1) ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (activityState.activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    '오늘은 예정된 활동이 없습니다',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            ...activityState.activities.map(
              (activity) => _ActivityCard(activity: activity),
            ),

          // 투표 카드
          ...ref
              .watch(pollProvider)
              .polls
              .where((p) => !p.isExpired)
              .map((poll) => _PollCard(poll: poll)),
        ],
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final TodayActivity activity;
  const _ActivityCard({required this.activity});

  Color get _cardColor {
    if (activity.voteClosed) return AppColors.card;
    if (activity.activityType == 'FREE') return AppColors.green;
    if (!activity.isMyGroup) return AppColors.card;
    return AppColors.lime;
  }

  bool get _isColorCard =>
      !activity.voteClosed &&
      (activity.activityType == 'FREE' || activity.isMyGroup);

  Color get _textColor => AppColors.white;
  Color get _subColor => AppColors.white.withValues(alpha: 0.6);

  String get _subtitle {
    if (activity.voteClosed) return '${activity.groupLabel} · 마감됨';
    if (activity.activityType == 'FREE') {
      return '${activity.groupLabel} · 자유활동';
    }
    if (!activity.isMyGroup) return '${activity.groupLabel} · 타 조 활동';
    return '${activity.groupLabel} · 마감 전';
  }

  String _buttonLabel(String type) {
    switch (type) {
      case 'ATTEND':
      case 'REGULAR':
      case 'FREE_ATTEND':
        return '참여';
      case 'ABSENT':
        return '불참';
      case 'CARRYOVER':
        return '이월';
      case 'OTHER_GROUP':
        return '타조참';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타입 라벨
          Text(
            activity.voteClosed
                ? '마감'
                : activity.activityType == 'FREE'
                ? '자유활동'
                : activity.isMyGroup
                ? '오늘 활동'
                : '타 조 활동',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _subColor,
              letterSpacing: 0.07,
            ),
          ),
          const SizedBox(height: 6),

          // 제목
          Text(
            '${activity.groupLabel} ${activity.activityType == 'FREE' ? '자유활동' : '정규활동'}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: _textColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: TextStyle(fontSize: 13, color: _subColor),
          ),

          const SizedBox(height: 18),

          // 마감
          if (activity.voteClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.gray,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '투표가 마감되었습니다',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            )
          else
            // 액션 버튼
            Row(
              children: activity.availableButtons.map((type) {
                final isPrimary =
                    type == 'ATTEND' || type == 'FREE_ATTEND';
                Color btnBg;
                Color btnFg;

                if (_isColorCard) {
                  btnBg = isPrimary
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.1);
                  btnFg = AppColors.white;
                } else {
                  btnBg = isPrimary
                      ? AppColors.lime
                      : Colors.white.withValues(alpha: 0.1);
                  btnFg = AppColors.white;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (type == 'CARRYOVER') {
                          showDialog(
                            context: context,
                            builder: (_) => CarryoverDialog(
                              activityId: activity.activityId,
                              onCompleted: () => _showTravelTypeDialog(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: btnBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _buttonLabel(type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: btnFg,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          // 응답 결과
          if (activity.myParticipation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isColorCard
                    ? Colors.black.withValues(alpha: 0.08)
                    : AppColors.card2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _isColorCard
                              ? const Color(0xFF111111)
                              : AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 13,
                          color: _isColorCard
                              ? AppColors.lime
                              : const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "'${_buttonLabel(activity.myParticipation!.type)}'로 응답했어요",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                      ),
                      if (!activity.voteClosed)
                        GestureDetector(
                          onTap: () => ref
                              .read(activityProvider.notifier)
                              .cancelParticipation(activity.activityId),
                          child: Text(
                            '다시 선택',
                            style: TextStyle(
                              fontSize: 12,
                              color: _subColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // 이동 방법
                  if (activity.myParticipation!.type == 'REGULAR' ||
                      activity.myParticipation!.type == 'OTHER_GROUP' ||
                      activity.myParticipation!.type == 'CARRYOVER') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 14,
                          color: _subColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity.myParticipation!.travelType == null
                              ? '이동 방법을 선택해주세요'
                              : activity.myParticipation!.travelType ==
                                    'TOGETHER'
                              ? '같이 이동'
                              : '따로 이동',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                activity.myParticipation!.travelType ==
                                    null
                                ? AppColors.coral
                                : _subColor,
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
                              color: _isColorCard
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              activity.myParticipation!.travelType == null
                                  ? '선택하기'
                                  : '변경',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MyTransportGroup(activityId: activity.activityId),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) =>
                    ActivityDetailDialog(activityId: activity.activityId),
              ),
              child: Text(
                '투표 결과 보기 ›',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _subColor,
                ),
              ),
            ),
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.isAnonymous ? '익명 투표' : '기명 투표',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.6),
              letterSpacing: 0.07,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            poll.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.white,
              height: 1.15,
            ),
          ),
          if (poll.closedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '마감: ${poll.closedAt!.substring(0, 16).replaceAll('T', ' ')}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),

          if (!hasVoted)
            Column(
              children: rows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: row.asMap().entries.map((entry) {
                      final option = entry.value;
                      final isLast = entry.key == row.length - 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 8),
                          child: GestureDetector(
                            onTap: state.isSubmitting
                                ? null
                                : () => ref
                                      .read(pollProvider.notifier)
                                      .vote(poll.id, option.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                option.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
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
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: AppColors.lime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "'${votedOption!.content}'에 투표했어요",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: state.isSubmitting
                        ? null
                        : () => ref
                              .read(pollProvider.notifier)
                              .cancelVote(poll.id),
                    child: Text(
                      '다시 투표',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => PollResultDialog(pollId: poll.id),
              ),
              child: Text(
                '결과 보기 ›',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        '이동 방법을 선택해주세요',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
      content: const Text(
        '정문에서 함께 이동하시나요?',
        style: TextStyle(fontSize: 14, color: AppColors.gray),
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
              backgroundColor: AppColors.lime,
              foregroundColor: const Color(0xFF111111),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
              foregroundColor: AppColors.gray,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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

    ref.watch(transportByActivityProvider(widget.activityId));
    final myGroup = ref
        .read(transportByActivityProvider(widget.activityId).notifier)
        .findMyGroup(userId);

    if (myGroup == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 14,
              color: AppColors.gray,
            ),
            SizedBox(width: 8),
            Text(
              '택시 그룹 배정 대기 중',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car,
                size: 14,
                color: Color(0xFF111111),
              ),
              const SizedBox(width: 6),
              Text(
                '${myGroup.groupNumber}호차',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${myGroup.members.length}명',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0x88111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  color: isMe
                      ? const Color(0xFF111111)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  m.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.lime : const Color(0xFF111111),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '택시비 정산',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lime,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color pollOptionColor(String content, int index) {
  if (content.contains('불')) return AppColors.coral;
  if (content.contains('참')) return AppColors.green;
  const palette = [
    AppColors.lime,
    AppColors.coral,
    AppColors.green,
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
  ];
  return palette[index % palette.length];
}
