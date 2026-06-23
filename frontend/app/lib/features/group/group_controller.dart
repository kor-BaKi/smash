import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/day_of_week.dart';
import '../../core/domain/time_slot.dart';
import 'group.dart';
import 'group_repository.dart';

final groupControllerProvider = AsyncNotifierProvider<GroupController, List<Group>>(GroupController.new);

class GroupController extends AsyncNotifier<List<Group>> {
  @override
  FutureOr<List<Group>> build() => ref.read(groupRepositoryProvider).getGroups();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(groupRepositoryProvider).getGroups());
  }

  // B-1 명세: 월~금 x 1-3시/3-5시 = 최대 10개 조. 이미 있는 조합은 서버가 skip 처리.
  Future<void> createDefaultGroups() async {
    final slots = [
      for (final day in DayOfWeek.values)
        for (final slot in TimeSlot.values) (day, slot),
    ];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupRepositoryProvider).createGroups(slots);
      return ref.read(groupRepositoryProvider).getGroups();
    });
  }

  Future<void> assignLeader(int groupId, int leaderUserId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupRepositoryProvider).assignLeader(groupId, leaderUserId);
      return ref.read(groupRepositoryProvider).getGroups();
    });
  }
}
