import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/transport_api.dart';
import '../model/transport_model.dart';

class TransportState {
  final List<TransportGroupInfo> groups;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const TransportState({
    this.groups = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  TransportState copyWith({
    List<TransportGroupInfo>? groups,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TransportState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class TransportNotifier extends StateNotifier<TransportState> {
  TransportNotifier() : super(const TransportState());

  // 택시 그룹 조회
  Future<void> loadGroups(int activityId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await TransportApi.getGroups(activityId);
      final groups = data
          .map((json) => TransportGroupInfo.fromJson(json))
          .toList();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '그룹 정보를 불러오지 못했습니다.',
      );
    }
  }

  // 택시 그룹 배정 (임원)
  Future<void> assign(int activityId, List<List<int>> groups) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final data = await TransportApi.assign(activityId, groups);
      final result = data
          .map((json) => TransportGroupInfo.fromJson(json))
          .toList();
      state = state.copyWith(groups: result, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '그룹 배정에 실패했습니다.',
      );
    }
  }

  // 택시 그룹 초기화 (임원)
  Future<void> reset(int activityId) async {
    try {
      await TransportApi.reset(activityId);
      state = state.copyWith(groups: []);
    } catch (e) {
      state = state.copyWith(errorMessage: '초기화에 실패했습니다.');
    }
  }

  // 내가 속한 그룹 찾기 (부원)
  TransportGroupInfo? findMyGroup(int userId) {
    for (final group in state.groups) {
      if (group.members.any((m) => m.userId == userId)) {
        return group;
      }
    }
    return null;
  }
}

final transportProvider =
    StateNotifierProvider<TransportNotifier, TransportState>((ref) {
      return TransportNotifier();
    });

final transportByActivityProvider =
    StateNotifierProvider.family<TransportNotifier, TransportState, int>((
      ref,
      activityId,
    ) {
      return TransportNotifier();
    });
