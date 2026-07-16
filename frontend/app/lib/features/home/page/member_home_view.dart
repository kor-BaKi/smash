import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/activity_model.dart';
import '../provider/activity_provider.dart';
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
          padding: const EdgeInsets.all(20),
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
        padding: const EdgeInsets.all(20),
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
                                    );
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
                    child: Row(
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
                        Text(
                          "'${_buttonLabel(activity.myParticipation!.type)}'로 응답했어요",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primaryDeep,
                          ),
                        ),
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
