import 'package:dio/dio.dart';

import 'api_client.dart';

class AttendanceApi {
  static final Dio _dio = ApiClient.instance;

  // E-1. 조별 충족 현황
  static Future<Map<String, dynamic>> getAttendance({
    required int groupId,
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/admin/attendance',
      queryParameters: {'groupId': groupId, 'year': year, 'month': month},
    );
    return response.data['data'];
  }

  // E-2. 미달 부원 목록
  static Future<List<dynamic>> getShortfall({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/admin/attendance/shortfall',
      queryParameters: {'year': year, 'month': month},
    );
    return response.data['data'];
  }

  // E-3. 타조참 인원
  static Future<List<dynamic>> getOtherGroup({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/admin/attendance/other-group',
      queryParameters: {'year': year, 'month': month},
    );
    return response.data['data'];
  }
}
