import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import 'attendance.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  Future<GroupAttendance> getGroupAttendance(int groupId, int year, int month) async {
    try {
      final response = await _dio.get('/admin/attendance', queryParameters: {
        'groupId': groupId,
        'year': year,
        'month': month,
      });
      return GroupAttendance.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ShortfallMember>> getShortfallMembers(int year, int month) async {
    try {
      final response = await _dio.get('/admin/attendance/shortfall', queryParameters: {
        'year': year,
        'month': month,
      });
      final data = response.data['data'] as List;
      return data.map((e) => ShortfallMember.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<OtherGroupSummary>> getOtherGroupSummary(int year, int month) async {
    try {
      final response = await _dio.get('/admin/attendance/other-group', queryParameters: {
        'year': year,
        'month': month,
      });
      final data = response.data['data'] as List;
      return data.map((e) => OtherGroupSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
