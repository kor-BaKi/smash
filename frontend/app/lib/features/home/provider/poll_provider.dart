import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/poll_api.dart';
import '../model/poll_model.dart';

class PollState {
  final List<PollInfo> polls;
  final PollInfo? selectedPoll;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const PollState({
    this.polls = const [],
    this.selectedPoll,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  PollState copyWith({
    List<PollInfo>? polls,
    PollInfo? selectedPoll,
    bool clearSelected = false,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return PollState(
      polls: polls ?? this.polls,
      selectedPoll: clearSelected
          ? null
          : (selectedPoll ?? this.selectedPoll),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class PollNotifier extends StateNotifier<PollState> {
  PollNotifier() : super(const PollState());

  // 목록 조회
  Future<void> loadPolls() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await PollApi.getList();
      final polls = data.map((json) => PollInfo.fromJson(json)).toList();
      state = state.copyWith(polls: polls, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '투표 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 상세 조회
  Future<void> loadDetail(int pollId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await PollApi.getDetail(pollId);
      state = state.copyWith(
        selectedPoll: PollInfo.fromJson(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '투표를 불러오지 못했습니다.',
      );
    }
  }

  // 투표 참여
  Future<void> vote(int pollId, int optionId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final data = await PollApi.vote(pollId, optionId);
      final updated = PollInfo.fromJson(data);
      // 상세 + 목록 둘 다 갱신
      state = state.copyWith(
        selectedPoll: updated,
        polls: state.polls
            .map((p) => p.id == pollId ? updated : p)
            .toList(),
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '투표에 실패했습니다.',
      );
    }
  }

  // 투표 생성
  Future<bool> create({
    required String title,
    String? description,
    required bool isAnonymous,
    String? closedAt,
    required List<String> options,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await PollApi.create(
        title: title,
        description: description,
        isAnonymous: isAnonymous,
        closedAt: closedAt,
        options: options,
      );
      await loadPolls();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '투표 생성에 실패했습니다.',
      );
      return false;
    }
  }

  // 투표 취소
  Future<void> cancelVote(int pollId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final data = await PollApi.cancelVote(pollId);
      final updated = PollInfo.fromJson(data);
      state = state.copyWith(
        selectedPoll: updated,
        polls: state.polls
            .map((p) => p.id == pollId ? updated : p)
            .toList(),
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '투표 취소에 실패했습니다.',
      );
    }
  }

  // 투표 종료
  Future<void> close(int pollId) async {
    try {
      await PollApi.close(pollId);
      await loadPolls();
      // 상세 화면이 열려있으면 갱신
      if (state.selectedPoll?.id == pollId) {
        await loadDetail(pollId);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '투표 종료에 실패했습니다.');
    }
  }
}

final pollProvider = StateNotifierProvider<PollNotifier, PollState>((ref) {
  return PollNotifier();
});
