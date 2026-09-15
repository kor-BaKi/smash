import 'package:dio/dio.dart';

import 'api_client.dart';

class NotificationSettingApi {
  static final Dio _dio = ApiClient.instance;

  static Future<Map<String, dynamic>> getSetting() async {
    final response = await _dio.get('/notification/setting');
    return response.data['data'];
  }

  static Future<Map<String, dynamic>> updateSetting({
    required bool pollNotification,
    required bool settlementNotification,
    required bool activityNotification,
  }) async {
    final response = await _dio.put(
      '/notification/setting',
      data: {
        'pollNotification': pollNotification,
        'settlementNotification': settlementNotification,
        'activityNotification': activityNotification,
      },
    );
    return response.data['data'];
  }
}
