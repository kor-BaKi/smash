import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/member_register_api.dart';
import '../model/member_register_model.dart';

class MemberRegisterState {
  final List<RegisteredMember> pendingApplicants;
  final List<RegisteredMember> allMembers;
  final bool isLoading;
  final bool isSubmitting;
  final BulkRegisterResult? lastResult;
  final String? errorMessage;

  const MemberRegisterState({
    this.pendingApplicants = const [],
    this.allMembers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.lastResult,
    this.errorMessage,
  });

  MemberRegisterState copyWith({
    List<RegisteredMember>? pendingApplicants,
    List<RegisteredMember>? allMembers,
    bool? isLoading,
    bool? isSubmitting,
    BulkRegisterResult? lastResult,
    String? errorMessage,
  }) {
    return MemberRegisterState(
      pendingApplicants: pendingApplicants ?? this.pendingApplicants,
      allMembers: allMembers ?? this.allMembers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MemberRegisterNotifier extends StateNotifier<MemberRegisterState> {
  MemberRegisterNotifier() : super(const MemberRegisterState());

  // 지원자 목록 조회
  Future<void> loadPendingApplicants() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await MemberRegisterApi.getPendingApplicants();
      final applicants = data
          .map((json) => RegisteredMember.fromJson(json))
          .toList();
      applicants.sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(
        pendingApplicants: applicants,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '지원자 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 텍스트 붙여넣기 파싱 후 대량 등록
  // 형식: "이름\t학번" 한 줄에 한 명
  Future<void> registerFromText(String text) async {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      state = state.copyWith(errorMessage: '등록할 내용이 없습니다.');
      return;
    }

    final members = <Map<String, String>>[];
    for (final line in lines) {
      final parts = line.split('\t');
      if (parts.length < 2) continue; // 형식 안 맞는 줄은 건너뜀
      members.add({'name': parts[0].trim(), 'studentNo': parts[1].trim()});
    }

    if (members.isEmpty) {
      state = state.copyWith(errorMessage: '올바른 형식이 아닙니다. (이름 [탭] 학번)');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final data = await MemberRegisterApi.registerBulk(members);
      final result = BulkRegisterResult.fromJson(data);
      state = state.copyWith(isSubmitting: false, lastResult: result);
      await loadPendingApplicants(); // 최신 목록 갱신
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '등록에 실패했습니다.',
      );
    }
  }

  Future<void> registerMember({
    required String name,
    required String studentNo,
    String? department,
    String? phone,
  }) async {
    try {
      await MemberRegisterApi.registerOne(
        name: name,
        studentNo: studentNo,
        department: department,
        phone: phone,
      );
      await loadPendingApplicants();
    } catch (e) {
      state = state.copyWith(errorMessage: '등록에 실패했습니다.');
    }
  }

  // 불합격 처리
  Future<void> reject(int userId) async {
    final original = state.pendingApplicants;
    state = state.copyWith(
      pendingApplicants: state.pendingApplicants
          .map(
            (m) => m.id == userId
                ? RegisteredMember(
                    id: m.id,
                    name: m.name,
                    studentNo: m.studentNo,
                    status: 'REJECTED',
                    role: m.role,
                    groupId: m.groupId,
                  )
                : m,
          )
          .toList(),
    );
    try {
      await MemberRegisterApi.reject(userId);
    } catch (e) {
      state = state.copyWith(
        pendingApplicants: original,
        errorMessage: '불합격 처리에 실패했습니다.',
      );
    }
  }

  // 불합격 취소
  Future<void> restore(int userId) async {
    final original = state.pendingApplicants;
    state = state.copyWith(
      pendingApplicants: state.pendingApplicants
          .map(
            (m) => m.id == userId
                ? RegisteredMember(
                    id: m.id,
                    name: m.name,
                    studentNo: m.studentNo,
                    status: 'PENDING',
                    role: m.role,
                    groupId: m.groupId,
                  )
                : m,
          )
          .toList(),
    );
    try {
      await MemberRegisterApi.restore(userId);
    } catch (e) {
      state = state.copyWith(
        pendingApplicants: original,
        errorMessage: '복구에 실패했습니다.',
      );
    }
  }

  // 전체 부원 목록 조회
  Future<void> loadAllMembers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await MemberRegisterApi.getAllMembers();
      final members = data
          .map((json) => RegisteredMember.fromJson(json))
          .toList();
      state = state.copyWith(allMembers: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '부원 목록을 불러오지 못했습니다.',
      );
    }
  }

  // 지원자 삭제
  Future<void> deleteMember(int userId) async {
    final original = state.pendingApplicants;
    state = state.copyWith(
      pendingApplicants: state.pendingApplicants
          .where((m) => m.id != userId)
          .toList(),
    );
    try {
      await MemberRegisterApi.deleteMember(userId);
    } catch (e) {
      state = state.copyWith(
        pendingApplicants: original,
        errorMessage: '삭제에 실패했습니다.',
      );
    }
  }
}

final memberRegisterProvider =
    StateNotifierProvider<MemberRegisterNotifier, MemberRegisterState>((
      ref,
    ) {
      return MemberRegisterNotifier();
    });
