import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'availability.dart';
import 'availability_repository.dart';

final availabilityControllerProvider =
    AsyncNotifierProvider<AvailabilityController, AvailabilityStatus>(AvailabilityController.new);

class AvailabilityController extends AsyncNotifier<AvailabilityStatus> {
  @override
  FutureOr<AvailabilityStatus> build() => ref.read(availabilityRepositoryProvider).getAvailability();

  Future<void> submit(List<int> groupIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(availabilityRepositoryProvider).submit(groupIds);
      return ref.read(availabilityRepositoryProvider).getAvailability();
    });
  }
}
