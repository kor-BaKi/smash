import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_admin_api.dart';
import '../model/activity_admin_model.dart';

class ActivityAdminState {
  final DateTime selectedDate;
  final List<ActivitySummaryItem> activities;
  final bool isLoading;
  final String? errorMessage;

  ActivityAdminState({
    DateTime? selectedDate,
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now();

  ActivityAdminState copyWith({
    DateTime? selectedDate,
    List<ActivitySummaryItem>? activities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActivityAdminState(
      selectedDate: selectedDate ?? this.selectedDate,
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ActivityAdminNotifier extends StateNotifier<ActivityAdminState> {
  ActivityAdminNotifier() : super(ActivityAdminState());

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // 선택한 날짜의 활동 목록 조회
  Future<void> loadActivities({DateTime? date}) async {
    final targetDate = date ?? state.selectedDate;
    state = state.copyWith(
      selectedDate: targetDate,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final data = await ActivityAdminApi.getActivitiesByDate(
        _formatDate(targetDate),
      );
      final activities = data
          .map((json) => ActivitySummaryItem.fromJson(json))
          .toList();
      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '활동 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 활동 취소/복구 토글
  Future<void> toggleCancel(
    int activityId,
    bool currentIsCancelled,
  ) async {
    try {
      await ActivityAdminApi.updateActivity(
        activityId,
        isCancelled: !currentIsCancelled,
      );
      await loadActivities();
    } catch (e) {
      state = state.copyWith(errorMessage: '처리에 실패했습니다.');
    }
  }

  // REGULAR <-> FREE 전환
  Future<void> toggleType(int activityId, String currentType) async {
    final newType = currentType == 'REGULAR' ? 'FREE' : 'REGULAR';
    try {
      await ActivityAdminApi.updateActivity(
        activityId,
        activityType: newType,
      );
      await loadActivities();
    } catch (e) {
      state = state.copyWith(errorMessage: '처리에 실패했습니다.');
    }
  }
}

final activityAdminProvider =
    StateNotifierProvider<ActivityAdminNotifier, ActivityAdminState>((
      ref,
    ) {
      return ActivityAdminNotifier();
    });
