import 'package:dio/dio.dart';

import 'api_client.dart';

class FreePeriodApi {
  static final Dio _dio = ApiClient.instance;

  // 현재 자유활동 기간 조회 (없으면 null)
  static Future<Map<String, dynamic>?> getCurrent() async {
    final response = await _dio.get('/admin/free-period');
    return response.data['data'];
  }

  // 설정 (덮어쓰기)
  static Future<Map<String, dynamic>> setPeriod(
    String startDate,
    String endDate,
  ) async {
    final response = await _dio.put(
      '/admin/free-period',
      data: {'startDate': startDate, 'endDate': endDate},
    );
    return response.data['data'];
  }

  // 해제
  static Future<void> clear() async {
    await _dio.delete('/admin/free-period');
  }
}
