import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity_model.dart';

class ActivityState {
  final List<TodayActivity> activities;
  final bool isLoading;
  final String? errorMessage;

  const ActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ActivityState copyWith({
    List<TodayActivity>? activities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(const ActivityState());

  // 오늘 활동 불러오기
  Future<void> loadTodayActivities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await ActivityApi.getTodayActivities();
      final activities = data
          .map((json) => TodayActivity.fromJson(json))
          .toList();

      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '활동을 불러오지 못했습니다.',
      );
    }
  }

  // 참여 응답
  Future<void> participate({
    required int activityId,
    required String type,
    int? targetActivityId,
  }) async {
    try {
      await ActivityApi.participate(
        activityId: activityId,
        type: type,
        targetActivityId: targetActivityId,
      );
      // 응답 후 최신 상태로 다시 불러오기
      await loadTodayActivities();
    } catch (e) {
      state = state.copyWith(errorMessage: '참여 응답에 실패했습니다.');
    }
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
      return ActivityNotifier();
    });
