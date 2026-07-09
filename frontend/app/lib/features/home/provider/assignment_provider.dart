import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/assignment_api.dart';
import '../model/assignment_model.dart';

class AssignmentState {
  final AssignmentPreview? preview;
  final bool isLoadingPreview;
  final bool isConfirming;
  final bool confirmed;
  final String? errorMessage;

  const AssignmentState({
    this.preview,
    this.isLoadingPreview = false,
    this.isConfirming = false,
    this.confirmed = false,
    this.errorMessage,
  });

  AssignmentState copyWith({
    AssignmentPreview? preview,
    bool? isLoadingPreview,
    bool? isConfirming,
    bool? confirmed,
    String? errorMessage,
  }) {
    return AssignmentState(
      preview: preview ?? this.preview,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isConfirming: isConfirming ?? this.isConfirming,
      confirmed: confirmed ?? this.confirmed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AssignmentNotifier extends StateNotifier<AssignmentState> {
  AssignmentNotifier() : super(const AssignmentState());

  // 미리보기 실행
  Future<void> loadPreview() async {
    state = state.copyWith(
      isLoadingPreview: true,
      errorMessage: null,
      confirmed: false,
    );

    try {
      final data = await AssignmentApi.preview();
      state = state.copyWith(
        preview: AssignmentPreview.fromJson(data),
        isLoadingPreview: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPreview: false,
        errorMessage: '미리보기를 불러오지 못했습니다.',
      );
    }
  }

  // 개별 수동 조정 (특정 부원의 배정 조 변경)
  void changeAssignedGroup(int userId, int newGroupId) {
    final preview = state.preview;
    if (preview == null) return;

    final item = preview.assignments.firstWhere((a) => a.userId == userId);
    item.assignedGroupId = newGroupId;

    // groupDistribution 재계산
    final counts = <int, int>{};
    for (final a in preview.assignments) {
      counts[a.assignedGroupId] = (counts[a.assignedGroupId] ?? 0) + 1;
    }
    final newDistribution = preview.groupDistribution.map((g) {
      return GroupDistribution(
        groupId: g.groupId,
        label: g.label,
        count: counts[g.groupId] ?? 0,
      );
    }).toList();

    // 새 AssignmentPreview로 교체 (리스트 내용은 바뀌었지만 참조를 갱신해 화면 리빌드 유도)
    state = state.copyWith(
      preview: AssignmentPreview(
        previewToken: preview.previewToken,
        basedOnMemberIds: preview.basedOnMemberIds,
        assignments: preview.assignments,
        unassigned: preview.unassigned,
        groupDistribution: newDistribution,
      ),
    );
  }

  // 배정 확정
  Future<bool> confirm() async {
    final preview = state.preview;
    if (preview == null) return false;

    state = state.copyWith(isConfirming: true, errorMessage: null);

    try {
      final assignments = preview.assignments
          .map((a) => {'userId': a.userId, 'groupId': a.assignedGroupId})
          .toList();

      await AssignmentApi.confirm(
        previewToken: preview.previewToken,
        basedOnMemberIds: preview.basedOnMemberIds,
        assignments: assignments,
      );

      state = state.copyWith(isConfirming: false, confirmed: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: '배정 확정에 실패했습니다. 미리보기를 다시 실행해주세요.',
      );
      return false;
    }
  }

  // 미배정자 수동 배정
  Future<void> assignUnassignedMember(int userId, int groupId) async {
    try {
      await AssignmentApi.assignMember(userId, groupId);

      // 해당 인원을 unassigned 목록에서 제거
      final preview = state.preview;
      if (preview == null) return;

      final newUnassigned = preview.unassigned
          .where((u) => u.userId != userId)
          .toList();

      state = state.copyWith(
        preview: AssignmentPreview(
          previewToken: preview.previewToken,
          basedOnMemberIds: preview.basedOnMemberIds,
          assignments: preview.assignments,
          unassigned: newUnassigned,
          groupDistribution: preview.groupDistribution,
        ),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '수동 배정에 실패했습니다.');
    }
  }
}

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
      return AssignmentNotifier();
    });
