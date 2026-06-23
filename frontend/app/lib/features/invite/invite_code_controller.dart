import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'invite_code.dart';
import 'invite_code_repository.dart';

final inviteCodeControllerProvider =
    AsyncNotifierProvider<InviteCodeController, List<InviteCode>>(InviteCodeController.new);

class InviteCodeController extends AsyncNotifier<List<InviteCode>> {
  @override
  FutureOr<List<InviteCode>> build() => ref.read(inviteCodeRepositoryProvider).getInviteCodes();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(inviteCodeRepositoryProvider).getInviteCodes());
  }

  Future<void> createInviteCode() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inviteCodeRepositoryProvider).createInviteCode();
      return ref.read(inviteCodeRepositoryProvider).getInviteCodes();
    });
  }

  Future<void> setActive(int id, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inviteCodeRepositoryProvider).setActive(id, isActive);
      return ref.read(inviteCodeRepositoryProvider).getInviteCodes();
    });
  }
}
