import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/free_period_api.dart';
import '../model/free_period.dart';

final freePeriodControllerProvider =
    AsyncNotifierProvider<FreePeriodController, List<FreePeriod>>(FreePeriodController.new);

class FreePeriodController extends AsyncNotifier<List<FreePeriod>> {
  @override
  FutureOr<List<FreePeriod>> build() => ref.read(freePeriodApiProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(freePeriodApiProvider).getAll());
  }

  Future<void> create({String? name, required String startDate, required String endDate}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(freePeriodApiProvider).create(name: name, startDate: startDate, endDate: endDate);
      return ref.read(freePeriodApiProvider).getAll();
    });
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(freePeriodApiProvider).delete(id);
      return ref.read(freePeriodApiProvider).getAll();
    });
  }
}
