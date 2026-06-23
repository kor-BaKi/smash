import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/attendance_api.dart';
import '../model/attendance.dart';

final attendanceYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final attendanceMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final attendanceGroupIdProvider = StateProvider<int?>((ref) => null);

// E-1: 그룹 선택 전까지는 null. 계산 기반·저장 안 함 정책이라 매번 새로 조회한다.
final groupAttendanceProvider = FutureProvider<GroupAttendance?>((ref) async {
  final groupId = ref.watch(attendanceGroupIdProvider);
  if (groupId == null) return null;
  final year = ref.watch(attendanceYearProvider);
  final month = ref.watch(attendanceMonthProvider);
  return ref.read(attendanceApiProvider).getGroupAttendance(groupId, year, month);
});

final shortfallMembersProvider = FutureProvider<List<ShortfallMember>>((ref) {
  final year = ref.watch(attendanceYearProvider);
  final month = ref.watch(attendanceMonthProvider);
  return ref.read(attendanceApiProvider).getShortfallMembers(year, month);
});

final otherGroupSummaryProvider = FutureProvider<List<OtherGroupSummary>>((ref) {
  final year = ref.watch(attendanceYearProvider);
  final month = ref.watch(attendanceMonthProvider);
  return ref.read(attendanceApiProvider).getOtherGroupSummary(year, month);
});
