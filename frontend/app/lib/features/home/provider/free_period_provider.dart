import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/free_period_api.dart';
import '../model/free_period_model.dart';

class FreePeriodState {
  final List<FreePeriodInfo> periods;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const FreePeriodState({
    this.periods = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  FreePeriodState copyWith({
    List<FreePeriodInfo>? periods,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return FreePeriodState(
      periods: periods ?? this.periods,
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
      final data = await FreePeriodApi.getAll();
      final periods = data
          .map((json) => FreePeriodInfo.fromJson(json))
          .toList();
      state = state.copyWith(periods: periods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '자유활동 기간을 불러오지 못했습니다.',
      );
    }
  }

  // 추가
  Future<bool> add(String startDate, String endDate) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await FreePeriodApi.add(startDate, endDate);
      state = state.copyWith(isSubmitting: false);
      await load();
      return true;
    } catch (e) {
      String message = '설정에 실패했습니다.';
      if (e is DioException &&
          e.response?.data['error']?['message'] != null) {
        message = e.response!.data['error']['message'];
      }
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return false;
    }
  }

  // 삭제
  Future<void> delete(int id) async {
    try {
      await FreePeriodApi.delete(id);
      await load();
    } catch (e) {
      state = state.copyWith(errorMessage: '삭제에 실패했습니다.');
    }
  }
}

final freePeriodProvider =
    StateNotifierProvider<FreePeriodNotifier, FreePeriodState>((ref) {
      return FreePeriodNotifier();
    });
