import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/invite_code_api.dart';
import '../model/invite_code.dart';

final inviteCodeControllerProvider =
    AsyncNotifierProvider<InviteCodeController, List<InviteCode>>(InviteCodeController.new);

class InviteCodeController extends AsyncNotifier<List<InviteCode>> {
  @override
  FutureOr<List<InviteCode>> build() => ref.read(inviteCodeApiProvider).getInviteCodes();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(inviteCodeApiProvider).getInviteCodes());
  }

  Future<void> createInviteCode() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inviteCodeApiProvider).createInviteCode();
      return ref.read(inviteCodeApiProvider).getInviteCodes();
    });
  }

  Future<void> setActive(int id, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inviteCodeApiProvider).setActive(id, isActive);
      return ref.read(inviteCodeApiProvider).getInviteCodes();
    });
  }
}
