import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/availability_api.dart';
import '../model/availability_model.dart';

class AvailabilityState {
  final List<GroupItem> groups;
  final Set<int> selectedGroupIds;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const AvailabilityState({
    this.groups = const [],
    this.selectedGroupIds = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  AvailabilityState copyWith({
    List<GroupItem>? groups,
    Set<int>? selectedGroupIds,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AvailabilityState(
      groups: groups ?? this.groups,
      selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  AvailabilityNotifier() : super(const AvailabilityState());

  // 조 목록 + 기존 선택 요일 로드
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 전체 조 목록 조회
      final groupData = await AvailabilityApi.getGroups();
      final groups = groupData
          .map((json) => GroupItem.fromJson(json))
          .toList();

      // 기존에 제출한 가능 요일 조회
      final myData = await AvailabilityApi.getMyAvailability();
      final myGroupIds = myData
          .map((json) => json['groupId'] as int)
          .toSet();

      state = state.copyWith(
        groups: groups,
        selectedGroupIds: myGroupIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '조 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 체크박스 토글
  void toggleGroup(int groupId) {
    final current = Set<int>.from(state.selectedGroupIds);
    if (current.contains(groupId)) {
      current.remove(groupId);
    } else {
      current.add(groupId);
    }
    state = state.copyWith(selectedGroupIds: current);
  }

  // 가능 요일 제출
  Future<bool> submitAvailability() async {
    if (state.selectedGroupIds.isEmpty) {
      state = state.copyWith(errorMessage: '최소 하나의 조를 선택해주세요.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await AvailabilityApi.submitAvailability(
        state.selectedGroupIds.toList(),
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '제출에 실패했습니다.',
      );
      return false;
    }
  }
}

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
      return AvailabilityNotifier();
    });
