import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/attendance_api.dart';
import '../model/attendance_model.dart';

class AttendanceState {
  final GroupAttendance? groupAttendance;
  final List<ShortfallMember> shortfallMembers;
  final List<OtherGroupMember> otherGroupMembers;
  final bool isLoading;
  final String? errorMessage;

  const AttendanceState({
    this.groupAttendance,
    this.shortfallMembers = const [],
    this.otherGroupMembers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AttendanceState copyWith({
    GroupAttendance? groupAttendance,
    List<ShortfallMember>? shortfallMembers,
    List<OtherGroupMember>? otherGroupMembers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AttendanceState(
      groupAttendance: groupAttendance ?? this.groupAttendance,
      shortfallMembers: shortfallMembers ?? this.shortfallMembers,
      otherGroupMembers: otherGroupMembers ?? this.otherGroupMembers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState());

  // E-1. 조별 현황
  Future<void> loadGroupAttendance({
    required int groupId,
    required int year,
    required int month,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await AttendanceApi.getAttendance(
        groupId: groupId,
        year: year,
        month: month,
      );
      state = state.copyWith(
        groupAttendance: GroupAttendance.fromJson(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '출석 현황을 불러오지 못했습니다.',
      );
    }
  }

  // E-2. 미달자
  Future<void> loadShortfall({
    required int year,
    required int month,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await AttendanceApi.getShortfall(
        year: year,
        month: month,
      );
      final members = data
          .map((json) => ShortfallMember.fromJson(json))
          .toList();
      state = state.copyWith(shortfallMembers: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '미달자 목록을 불러오지 못했습니다.',
      );
    }
  }

  // E-3. 타조참
  Future<void> loadOtherGroup({
    required int year,
    required int month,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await AttendanceApi.getOtherGroup(
        year: year,
        month: month,
      );
      final members = data
          .map((json) => OtherGroupMember.fromJson(json))
          .toList();
      state = state.copyWith(otherGroupMembers: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '타조참 목록을 불러오지 못했습니다.',
      );
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      return AttendanceNotifier();
    });
