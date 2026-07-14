import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/free_period_api.dart';
import '../model/free_period_model.dart';

class FreePeriodState {
  final FreePeriodInfo? period;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const FreePeriodState({
    this.period,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  FreePeriodState copyWith({
    FreePeriodInfo? period,
    bool clearPeriod = false,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return FreePeriodState(
      period: clearPeriod ? null : (period ?? this.period),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class FreePeriodNotifier extends StateNotifier<FreePeriodState> {
  FreePeriodNotifier() : super(const FreePeriodState());

  // 조회
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await FreePeriodApi.getCurrent();
      state = state.copyWith(
        period: data == null ? null : FreePeriodInfo.fromJson(data),
        clearPeriod: data == null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '자유활동 기간을 불러오지 못했습니다.',
      );
    }
  }

  // 설정
  Future<bool> setPeriod(String startDate, String endDate) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final data = await FreePeriodApi.setPeriod(startDate, endDate);
      state = state.copyWith(
        period: FreePeriodInfo.fromJson(data),
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '설정에 실패했습니다.',
      );
      return false;
    }
  }

  // 해제
  Future<void> clear() async {
    try {
      await FreePeriodApi.clear();
      state = state.copyWith(clearPeriod: true);
    } catch (e) {
      state = state.copyWith(errorMessage: '해제에 실패했습니다.');
    }
  }
}

final freePeriodProvider =
    StateNotifierProvider<FreePeriodNotifier, FreePeriodState>((ref) {
      return FreePeriodNotifier();
    });
