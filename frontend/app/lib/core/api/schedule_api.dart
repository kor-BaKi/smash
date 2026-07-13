import 'package:dio/dio.dart';

import 'api_client.dart';

class ScheduleApi {
  static final Dio _dio = ApiClient.instance;

  // 정규활동 일정 조회
  static Future<List<dynamic>> getSchedules() async {
    final response = await _dio.get('/admin/activity-schedules');
    return response.data['data'];
  }

  // 정규활동 일정 전체 저장 (PUT - 전체 교체)
  static Future<void> updateSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    await _dio.put(
      '/admin/activity-schedules',
      data: {'schedules': schedules},
    );
  }
}
