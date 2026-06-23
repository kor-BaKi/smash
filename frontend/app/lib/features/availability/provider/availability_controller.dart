import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/availability_api.dart';
import '../model/availability.dart';

final availabilityControllerProvider =
    AsyncNotifierProvider<AvailabilityController, AvailabilityStatus>(AvailabilityController.new);

class AvailabilityController extends AsyncNotifier<AvailabilityStatus> {
  @override
  FutureOr<AvailabilityStatus> build() => ref.read(availabilityApiProvider).getAvailability();

  Future<void> submit(List<int> groupIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(availabilityApiProvider).submit(groupIds);
      return ref.read(availabilityApiProvider).getAvailability();
    });
  }
}
