import 'package:dio/dio.dart';

import 'api_client.dart';

class ActivityAdminApi {
  static final Dio _dio = ApiClient.instance;

  // 날짜별 활동 목록 조회 (date 없으면 오늘)
  static Future<List<dynamic>> getActivitiesByDate(String? date) async {
    final response = await _dio.get(
      '/admin/activities',
      queryParameters: date == null ? null : {'date': date},
    );
    return response.data['data'];
  }

  // 활동 수동 제어 (취소/복구, REGULAR<->FREE 전환)
  static Future<void> updateActivity(
    int activityId, {
    bool? isCancelled,
    String? activityType,
  }) async {
    await _dio.patch(
      '/admin/activities/$activityId',
      data: {
        if (isCancelled != null) 'isCancelled': isCancelled,
        if (activityType != null) 'activityType': activityType,
      },
    );
  }
}
