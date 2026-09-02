import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/invite_code_api.dart';
import '../model/invite_code_model.dart';

class InviteCodeState {
  final InviteCode? code;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;

  const InviteCodeState({
    this.code,
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
  });

  InviteCodeState copyWith({
    InviteCode? code,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
  }) {
    return InviteCodeState(
      code: code ?? this.code,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class InviteCodeNotifier extends StateNotifier<InviteCodeState> {
  InviteCodeNotifier() : super(const InviteCodeState());

  // 현재 가입코드 조회 (없으면 null 유지)
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await InviteCodeApi.getList();
      final code = data.isEmpty ? null : InviteCode.fromJson(data.first);
      state = state.copyWith(code: code, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '가입코드를 불러오지 못했습니다.',
      );
    }
  }

  // 발급 / 재발급
  Future<void> createOrRegenerate() async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    try {
      final data = await InviteCodeApi.create();
      state = state.copyWith(
        code: InviteCode.fromJson(data),
        isCreating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: '가입코드 발급에 실패했습니다.',
      );
    }
  }

  // 활성/비활성 토글
  Future<void> toggle() async {
    final current = state.code;
    if (current == null) return;

    // 로컬에서 먼저 토글 (깜빡임 없이 즉시 반영)
    final optimistic = InviteCode(
      id: current.id,
      code: current.code,
      isActive: !current.isActive,
    );
    state = state.copyWith(code: optimistic);

    try {
      await InviteCodeApi.toggle(current.id, !current.isActive);
      // 성공하면 그대로 유지 (이미 로컬에서 바뀜)
    } catch (e) {
      // 실패하면 원래 값으로 되돌림
      state = state.copyWith(
        code: current,
        errorMessage: '가입코드 상태 변경에 실패했습니다.',
      );
    }
  }
}

final inviteCodeProvider =
    StateNotifierProvider<InviteCodeNotifier, InviteCodeState>((ref) {
      return InviteCodeNotifier();
    });
