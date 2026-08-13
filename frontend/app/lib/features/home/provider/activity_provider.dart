import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity_detail_model.dart';
import '../model/activity_model.dart';
import '../model/carryover_candidate_model.dart';

class ActivityState {
  final List<TodayActivity> activities;
  final bool isLoading;
  final String? errorMessage;
  final List<CarryoverCandidate> carryoverCandidates;
  final bool isLoadingCandidates;
  final ActivityDetail? selectedDetail;
  final bool isLoadingDetail;
  final List<ActivityParticipant>? participants;

  const ActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
    this.carryoverCandidates = const [],
    this.isLoadingCandidates = false,
    this.selectedDetail,
    this.isLoadingDetail = false,
    this.participants,
  });

  ActivityState copyWith({
    List<TodayActivity>? activities,
    bool? isLoading,
    String? errorMessage,
    List<CarryoverCandidate>? carryoverCandidates,
    bool? isLoadingCandidates,
    ActivityDetail? selectedDetail,
    bool? isLoadingDetail,
    List<ActivityParticipant>? participants,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      carryoverCandidates: carryoverCandidates ?? this.carryoverCandidates,
      isLoadingCandidates: isLoadingCandidates ?? this.isLoadingCandidates,
      selectedDetail: selectedDetail ?? this.selectedDetail,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      participants: participants ?? this.participants,
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
    // 낙관적 업데이트 — 서버 응답 전에 로컬 상태 먼저 변경
    final original = state.activities;
    state = state.copyWith(
      activities: state.activities.map((a) {
        if (a.activityId != activityId) return a;
        return a.copyWith(
          myParticipation: ParticipationInfo(
            participationId: -1, // 임시 ID
            type: type,
            targetActivityId: targetActivityId,
          ),
        );
      }).toList(),
    );

    try {
      await ActivityApi.participate(
        activityId: activityId,
        type: type,
        targetActivityId: targetActivityId,
      );
      // 성공 후 정확한 서버 데이터로 갱신 (isLoading 없이)
      final data = await ActivityApi.getTodayActivities();
      final activities = data
          .map((json) => TodayActivity.fromJson(json))
          .toList();
      state = state.copyWith(activities: activities);
    } catch (e) {
      // 실패 시 롤백
      state = state.copyWith(
        activities: original,
        errorMessage: '참여 응답에 실패했습니다.',
      );
    }
  }

  Future<void> loadParticipants(int activityId) async {
    try {
      final data = await ActivityApi.getParticipants(activityId);
      final participants = data
          .map((json) => ActivityParticipant.fromJson(json))
          .toList();
      state = state.copyWith(participants: participants);
    } catch (e) {
      state = state.copyWith(errorMessage: '참여자 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> cancelParticipation(int activityId) async {
    final original = state.activities;
    state = state.copyWith(
      activities: state.activities.map((a) {
        if (a.activityId != activityId) return a;
        return a.copyWith(myParticipation: null);
      }).toList(),
    );

    try {
      await ActivityApi.cancelParticipation(activityId);
      final data = await ActivityApi.getTodayActivities();
      final activities = data
          .map((json) => TodayActivity.fromJson(json))
          .toList();
      state = state.copyWith(activities: activities);
    } catch (e) {
      state = state.copyWith(
        activities: original,
        errorMessage: '취소에 실패했습니다.',
      );
    }
  }

  // 활동 상세(투표 결과) 조회 - 추가
  Future<void> loadActivityDetail(int activityId) async {
    state = state.copyWith(isLoadingDetail: true, errorMessage: null);

    try {
      final data = await ActivityApi.getActivityDetail(activityId);
      state = state.copyWith(
        selectedDetail: ActivityDetail.fromJson(data),
        isLoadingDetail: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: '투표 결과를 불러오지 못했습니다.',
      );
    }
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
      return ActivityNotifier();
    });
