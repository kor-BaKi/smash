import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/group_api.dart';
import '../../../core/domain/day_of_week.dart';
import '../../../core/domain/time_slot.dart';
import '../model/group.dart';

final groupControllerProvider = AsyncNotifierProvider<GroupController, List<Group>>(GroupController.new);

class GroupController extends AsyncNotifier<List<Group>> {
  @override
  FutureOr<List<Group>> build() => ref.read(groupApiProvider).getGroups();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(groupApiProvider).getGroups());
  }

  // B-1 명세: 월~금 x 1-3시/3-5시 = 최대 10개 조. 이미 있는 조합은 서버가 skip 처리.
  Future<void> createDefaultGroups() async {
    final slots = [
      for (final day in DayOfWeek.values)
        for (final slot in TimeSlot.values) (day, slot),
    ];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupApiProvider).createGroups(slots);
      return ref.read(groupApiProvider).getGroups();
    });
  }

  Future<void> assignLeader(int groupId, int leaderUserId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupApiProvider).assignLeader(groupId, leaderUserId);
      return ref.read(groupApiProvider).getGroups();
    });
  }
}
