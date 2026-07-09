import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/group_api.dart';
import '../../../core/api/member_register_api.dart';
import '../model/group_model.dart';
import '../model/member_register_model.dart';

class GroupManagementState {
  final List<GroupDetail> groups;
  final List<RegisteredMember> admins;
  final List<RegisteredMember> selectedGroupMembers;
  final bool isLoading;
  final bool isSubmitting;
  final bool isLoadingMembers;
  final String? errorMessage;

  const GroupManagementState({
    this.groups = const [],
    this.admins = const [],
    this.selectedGroupMembers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isLoadingMembers = false,
    this.errorMessage,
  });

  GroupManagementState copyWith({
    List<GroupDetail>? groups,
    List<RegisteredMember>? admins,
    List<RegisteredMember>? selectedGroupMembers,
    bool? isLoading,
    bool? isSubmitting,
    bool? isLoadingMembers,
    String? errorMessage,
  }) {
    return GroupManagementState(
      groups: groups ?? this.groups,
      admins: admins ?? this.admins,
      selectedGroupMembers:
          selectedGroupMembers ?? this.selectedGroupMembers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GroupManagementNotifier extends StateNotifier<GroupManagementState> {
  GroupManagementNotifier() : super(const GroupManagementState());

  // 조 목록 + ADMIN 목록 함께 조회
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final groupData = await GroupApi.getGroups();
      final groups = groupData
          .map((json) => GroupDetail.fromJson(json))
          .toList();

      final memberData = await MemberRegisterApi.getAllMembers();
      final admins = memberData
          .map((json) => RegisteredMember.fromJson(json))
          .where((m) => m.role == 'ADMIN')
          .toList();

      state = state.copyWith(
        groups: groups,
        admins: admins,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '데이터를 불러오지 못했습니다.',
      );
    }
  }

  // 조 생성
  Future<bool> createGroups(List<Map<String, String>> groups) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await GroupApi.createGroups(groups);
      state = state.copyWith(isSubmitting: false);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '조 생성에 실패했습니다.',
      );
      return false;
    }
  }

  // 조장 지정
  Future<void> assignLeader(int groupId, int leaderUserId) async {
    try {
      await GroupApi.assignLeader(groupId, leaderUserId);
      await loadAll();
    } catch (e) {
      state = state.copyWith(errorMessage: '조장 지정에 실패했습니다.');
    }
  }

  // 조 소속 부원 목록 조회
  Future<void> loadGroupMembers(int groupId) async {
    state = state.copyWith(isLoadingMembers: true, errorMessage: null);

    try {
      final data = await MemberRegisterApi.getGroupMembers(groupId);
      final members = data
          .map((json) => RegisteredMember.fromJson(json))
          .toList();
      state = state.copyWith(
        selectedGroupMembers: members,
        isLoadingMembers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMembers: false,
        errorMessage: '부원 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 조장 취소
  Future<void> removeLeader(int groupId) async {
    try {
      await GroupApi.removeLeader(groupId);
      await loadAll();
    } catch (e) {
      state = state.copyWith(errorMessage: '조장 취소에 실패했습니다.');
    }
  }
}

final groupManagementProvider =
    StateNotifierProvider<GroupManagementNotifier, GroupManagementState>((
      ref,
    ) {
      return GroupManagementNotifier();
    });
