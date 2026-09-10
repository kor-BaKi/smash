import 'package:dio/dio.dart';

import 'api_client.dart';

class CalendarApi {
  static final Dio _dio = ApiClient.instance;

  // 월별 일정 조회
  static Future<List<Map<String, dynamic>>> getEvents(
    int year,
    int month,
  ) async {
    final response = await _dio.get(
      '/calendar',
      queryParameters: {'year': year, 'month': month},
    );
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // 일정 생성 (임원만)
  static Future<Map<String, dynamic>> create(
    String title,
    String date,
    String? memo,
  ) async {
    final response = await _dio.post(
      '/admin/calendar',
      data: {'title': title, 'date': date, 'memo': memo},
    );
    return response.data['data'];
  }

  // 일정 삭제 (임원만)
  static Future<void> delete(int scheduleId) async {
    await _dio.delete('/admin/calendar/$scheduleId');
  }
}
