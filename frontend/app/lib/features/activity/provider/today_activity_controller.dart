import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity.dart';

final todayScopeProvider = StateProvider<String>((ref) => 'MY');

final todayActivitiesProvider =
    AsyncNotifierProvider<TodayActivitiesController, List<TodayActivity>>(TodayActivitiesController.new);

class TodayActivitiesController extends AsyncNotifier<List<TodayActivity>> {
  @override
  FutureOr<List<TodayActivity>> build() {
    final scope = ref.watch(todayScopeProvider);
    return ref.read(activityApiProvider).getToday(scope: scope);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(activityApiProvider).getToday(scope: ref.read(todayScopeProvider)),
    );
  }

  Future<void> submit(int activityId, ClientParticipationType type, {int? targetActivityId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(activityApiProvider)
          .submitParticipation(activityId, type, targetActivityId: targetActivityId);
      return ref.read(activityApiProvider).getToday(scope: ref.read(todayScopeProvider));
    });
  }

  Future<void> cancel(int activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(activityApiProvider).cancelParticipation(activityId);
      return ref.read(activityApiProvider).getToday(scope: ref.read(todayScopeProvider));
    });
  }
}
