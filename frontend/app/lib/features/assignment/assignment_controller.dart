import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assignment.dart';
import 'assignment_repository.dart';

final unassignedMembersProvider =
    AsyncNotifierProvider<
      UnassignedMembersController,
      List<UnassignedMember>
    >(UnassignedMembersController.new);

class UnassignedMembersController
    extends AsyncNotifier<List<UnassignedMember>> {
  @override
  FutureOr<List<UnassignedMember>> build() => ref
      .read(assignmentRepositoryProvider)
      .getUnassignedMembers();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(assignmentRepositoryProvider)
          .getUnassignedMembers(),
    );
  }

  Future<void> updateMemberGroup(int userId, int groupId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(assignmentRepositoryProvider)
          .updateMemberGroup(userId, groupId);
      return ref
          .read(assignmentRepositoryProvider)
          .getUnassignedMembers();
    });
  }
}

final assignmentPreviewProvider =
    AsyncNotifierProvider<
      AssignmentPreviewController,
      AssignmentPreview?
    >(AssignmentPreviewController.new);

class AssignmentPreviewController
    extends AsyncNotifier<AssignmentPreview?> {
  @override
  FutureOr<AssignmentPreview?> build() => null;

  Future<void> runPreview() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(assignmentRepositoryProvider).preview(),
    );
  }

  // C-4: 확정 성공 시 미배정자 목록(C-6)도 같이 갱신해야 화면이 최신 상태를 반영한다.
  Future<void> confirmAll() async {
    final preview = state.value;
    if (preview == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(assignmentRepositoryProvider)
          .confirm(
            previewToken: preview.previewToken,
            basedOnMemberIds: preview.basedOnMemberIds,
            assignments: preview.assignments,
          );
      await ref
          .read(unassignedMembersProvider.notifier)
          .refresh();
      return null;
    });
  }

  void clear() {
    state = const AsyncData(null);
  }
}
