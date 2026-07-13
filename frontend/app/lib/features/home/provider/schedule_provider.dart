import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/schedule_api.dart';
import '../model/schedule_model.dart';

class ScheduleState {
  final List<ScheduleItem> schedules;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool saved;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saved = false,
  });

  ScheduleState copyWith({
    List<ScheduleItem>? schedules,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? saved,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      saved: saved ?? this.saved,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier() : super(const ScheduleState());

  // 조회
  Future<void> loadSchedules() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      saved: false,
    );

    try {
      final data = await ScheduleApi.getSchedules();
      final schedules = data
          .map((json) => ScheduleItem.fromJson(json))
          .toList();
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '일정을 불러오지 못했습니다.',
      );
    }
  }

  // 화면에서 스위치 토글 (로컬에서만 변경)
  void toggle(int scheduleId) {
    final item = state.schedules.firstWhere((s) => s.id == scheduleId);
    item.isActive = !item.isActive;

    // 리스트 참조를 갱신해 화면 리빌드 유도
    state = state.copyWith(schedules: List.from(state.schedules));
  }

  // 저장 (전체 PUT)
  Future<void> save() async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      saved: false,
    );

    try {
      final payload = state.schedules
          .map(
            (s) => {
              'dayOfWeek': s.dayOfWeek,
              'timeSlot': s.timeSlot,
              'isActive': s.isActive,
            },
          )
          .toList();

      await ScheduleApi.updateSchedules(payload);
      state = state.copyWith(isSaving: false, saved: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: '저장에 실패했습니다.');
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
      return ScheduleNotifier();
    });
