import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dues_api.dart';
import '../model/dues_model.dart';

class DuesState {
  final List<DuesMember> members;
  final bool isLoading;
  final String? errorMessage;

  const DuesState({
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DuesState copyWith({
    List<DuesMember>? members,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DuesState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DuesNotifier extends StateNotifier<DuesState> {
  DuesNotifier() : super(const DuesState());

  // 전체 조회
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await DuesApi.getAll();
      final members = data
          .map((json) => DuesMember.fromJson(json))
          .toList();
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '회비 현황을 불러오지 못했습니다.',
      );
    }
  }

  // 납부 처리 (낙관적 업데이트)
  Future<void> pay(int userId) async {
    final original = state.members;
    state = state.copyWith(
      members: state.members
          .map((m) => m.userId == userId ? m.copyWith(isPaid: true) : m)
          .toList(),
    );
    try {
      await DuesApi.pay(userId);
    } catch (e) {
      // 실패 시 롤백
      state = state.copyWith(
        members: original,
        errorMessage: '납부 처리에 실패했습니다.',
      );
    }
  }

  // 납부 취소 (낙관적 업데이트)
  Future<void> cancel(int userId) async {
    final original = state.members;
    state = state.copyWith(
      members: state.members
          .map((m) => m.userId == userId ? m.copyWith(isPaid: false) : m)
          .toList(),
    );
    try {
      await DuesApi.cancel(userId);
    } catch (e) {
      // 실패 시 롤백
      state = state.copyWith(
        members: original,
        errorMessage: '납부 취소에 실패했습니다.',
      );
    }
  }

  // 전체 초기화
  Future<void> reset() async {
    try {
      await DuesApi.reset();
      state = state.copyWith(
        members: state.members
            .map((m) => m.copyWith(isPaid: false))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '초기화에 실패했습니다.');
    }
  }
}

final duesProvider = StateNotifierProvider<DuesNotifier, DuesState>((ref) {
  return DuesNotifier();
});
