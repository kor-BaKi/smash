import 'package:dio/dio.dart';

import 'api_client.dart';

class DuesApi {
  static final Dio _dio = ApiClient.instance;

  // 전체 납부 현황 조회
  static Future<List<dynamic>> getAll() async {
    final response = await _dio.get('/admin/dues');
    return response.data['data'];
  }

  // 납부 처리
  static Future<void> pay(int userId) async {
    await _dio.post('/admin/dues/$userId');
  }

  // 납부 취소
  static Future<void> cancel(int userId) async {
    await _dio.delete('/admin/dues/$userId');
  }

  // 전체 초기화
  static Future<void> reset() async {
    await _dio.delete('/admin/dues');
  }
}
