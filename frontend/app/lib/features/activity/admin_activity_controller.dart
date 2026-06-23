import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/domain/activity_type.dart';
import 'activity.dart';
import 'activity_repository.dart';

String _today() => DateTime.now().toIso8601String().substring(0, 10);

final adminActivityDateProvider = StateProvider<String>((ref) => _today());

final adminActivitiesProvider =
    AsyncNotifierProvider<AdminActivitiesController, List<ActivitySummary>>(AdminActivitiesController.new);

class AdminActivitiesController extends AsyncNotifier<List<ActivitySummary>> {
  @override
  FutureOr<List<ActivitySummary>> build() {
    final date = ref.watch(adminActivityDateProvider);
    return ref.read(activityRepositoryProvider).getAdminActivities(date: date);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(activityRepositoryProvider).getAdminActivities(date: ref.read(adminActivityDateProvider)),
    );
  }

  Future<void> updateActivity(int activityId, {bool? isCancelled, ActivityType? activityType}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(activityRepositoryProvider)
          .updateActivity(activityId, isCancelled: isCancelled, activityType: activityType);
      return ref.read(activityRepositoryProvider).getAdminActivities(date: ref.read(adminActivityDateProvider));
    });
  }
}
