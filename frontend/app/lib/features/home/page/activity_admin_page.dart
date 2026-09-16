import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/activity_admin_model.dart';
import '../provider/activity_admin_provider.dart';
import 'activity_photo_page.dart';

class ActivityAdminPage extends ConsumerStatefulWidget {
  const ActivityAdminPage({super.key});

  @override
  ConsumerState<ActivityAdminPage> createState() =>
      _ActivityAdminPageState();
}

class _ActivityAdminPageState extends ConsumerState<ActivityAdminPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activityAdminProvider.notifier).loadActivities();
    });
  }

  Future<void> _pickDate() async {
    final state = ref.read(activityAdminProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref
          .read(activityAdminProvider.notifier)
          .loadActivities(date: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityAdminProvider);
    final dateLabel =
        '${state.selectedDate.year}.${state.selectedDate.month.toString().padLeft(2, '0')}.${state.selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('날짜별 활동 관리')),
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.lime,
              ),
              title: Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.gray,
              ),
              onTap: _pickDate,
            ),
          ),
          Container(height: 0.5, color: AppColors.border),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lime,
                    ),
                  )
                : state.activities.isEmpty
                ? const Center(
                    child: Text(
                      '이 날짜에 활동이 없습니다.',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.activities.length,
                    itemBuilder: (context, index) {
                      final activity = state.activities[index];
                      return _ActivityAdminTile(activity: activity);
                    },
                  ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.coral),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityAdminTile extends ConsumerWidget {
  final ActivitySummaryItem activity;

  const _ActivityAdminTile({required this.activity});

  bool get _isPast {
    final date = DateTime.parse(activity.activityDate);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayDateOnly);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = activity.summary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.groupLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (activity.isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coralTag,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '취소됨',
                    style: TextStyle(
                      color: AppColors.coralTagText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (activity.activityType == 'FREE')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenTag,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '자유활동',
                    style: TextStyle(
                      color: AppColors.greenTagText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '참여 ${summary.regular} · 이월 ${summary.carryover} · 타조참 ${summary.otherGroup} · 자유참여 ${summary.freeAttend} · 불참 ${summary.absent}',
            style: const TextStyle(fontSize: 13, color: AppColors.gray),
          ),
          if (_isPast) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.lime,
                    size: 20,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityPhotoPage(
                        activityId: activity.activityId,
                        activityLabel:
                            '${DateTime.parse(activity.activityDate).month}/${DateTime.parse(activity.activityDate).day} 활동',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => ref
                      .read(activityAdminProvider.notifier)
                      .toggleCancel(
                        activity.activityId,
                        activity.isCancelled,
                      ),
                  child: Text(
                    activity.isCancelled ? '취소 복구' : '활동 취소',
                    style: TextStyle(
                      color: activity.isCancelled
                          ? AppColors.lime
                          : AppColors.coral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: activity.isCancelled
                      ? null
                      : () => ref
                            .read(activityAdminProvider.notifier)
                            .toggleType(
                              activity.activityId,
                              activity.activityType,
                            ),
                  child: Text(
                    activity.activityType == 'REGULAR'
                        ? '자유활동 전환'
                        : '정규활동 전환',
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.lime,
                    size: 20,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityPhotoPage(
                        activityId: activity.activityId,
                        activityLabel:
                            '${DateTime.parse(activity.activityDate).month}/${DateTime.parse(activity.activityDate).day} 활동',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
