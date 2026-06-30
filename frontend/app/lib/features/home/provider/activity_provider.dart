import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity_model.dart';
import '../model/carryover_candidate_model.dart';

class ActivityState {
  final List<TodayActivity> activities;
  final bool isLoading;
  final String? errorMessage;
  final List<CarryoverCandidate> carryoverCandidates;
  final bool isLoadingCandidates;

  const ActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
    this.carryoverCandidates = const [],
    this.isLoadingCandidates = false,
  });

  ActivityState copyWith({
    List<TodayActivity>? activities,
    bool? isLoading,
    String? errorMessage,
    List<CarryoverCandidate>? carryoverCandidates,
    bool? isLoadingCandidates,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      carryoverCandidates: carryoverCandidates ?? this.carryoverCandidates,
      isLoadingCandidates: isLoadingCandidates ?? this.isLoadingCandidates,
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

  // 이월 후보 불러오기
  Future<void> loadCarryoverCandidates(int activityId) async {
    state = state.copyWith(isLoadingCandidates: true);

    try {
      final data = await ActivityApi.getCarryoverCandidates(activityId);
      final candidates = data
          .map((json) => CarryoverCandidate.fromJson(json))
          .toList();

      state = state.copyWith(
        carryoverCandidates: candidates,
        isLoadingCandidates: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCandidates: false,
        errorMessage: '이월 후보를 불러오지 못했습니다.',
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
