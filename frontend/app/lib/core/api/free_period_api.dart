import 'package:dio/dio.dart';

import 'api_client.dart';

class FreePeriodApi {
  static final Dio _dio = ApiClient.instance;

  // 전체 목록 조회
  static Future<List<dynamic>> getAll() async {
    final response = await _dio.get('/admin/free-periods');
    return response.data['data'];
  }

  // 추가
  static Future<Map<String, dynamic>> add(
    String startDate,
    String endDate,
  ) async {
    final response = await _dio.post(
      '/admin/free-periods',
      data: {'startDate': startDate, 'endDate': endDate},
    );
    return response.data['data'];
  }

  // 개별 삭제
  static Future<void> delete(int id) async {
    await _dio.delete('/admin/free-periods/$id');
  }
}
