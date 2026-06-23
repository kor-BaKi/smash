import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/day_of_week.dart';
import '../../core/domain/time_slot.dart';
import 'activity_schedule.dart';
import 'activity_schedule_repository.dart';

final activityScheduleControllerProvider =
    AsyncNotifierProvider<ActivityScheduleController, List<ActivitySchedule>>(ActivityScheduleController.new);

class ActivityScheduleController extends AsyncNotifier<List<ActivitySchedule>> {
  @override
  FutureOr<List<ActivitySchedule>> build() async {
    final existing = await ref.read(activityScheduleRepositoryProvider).getSchedules();
    return _fillAllSlots(existing);
  }

  // 서버는 등록된 것만 돌려준다. 10개 요일x타임슬롯 조합을 항상 전부 보여주기 위해
  // 없는 조합은 isActive=false로 채운다.
  List<ActivitySchedule> _fillAllSlots(List<ActivitySchedule> existing) {
    final byKey = {for (final s in existing) (s.dayOfWeek, s.timeSlot): s};
    return [
      for (final day in DayOfWeek.values)
        for (final slot in TimeSlot.values)
          byKey[(day, slot)] ?? ActivitySchedule(dayOfWeek: day, timeSlot: slot, isActive: false),
    ];
  }

  Future<void> toggle(DayOfWeek day, TimeSlot slot) async {
    final current = state.value ?? [];
    final updated = [
      for (final s in current)
        if (s.dayOfWeek == day && s.timeSlot == slot) s.copyWith(isActive: !s.isActive) else s,
    ];

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final saved = await ref.read(activityScheduleRepositoryProvider).replaceAll(updated);
      return _fillAllSlots(saved);
    });
  }
}
