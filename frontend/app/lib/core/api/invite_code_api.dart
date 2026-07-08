import 'package:dio/dio.dart';

import 'api_client.dart';

class InviteCodeApi {
  static final Dio _dio = ApiClient.instance;

  // 가입코드 발급
  static Future<Map<String, dynamic>> create() async {
    final response = await _dio.post('/admin/invite-codes');
    return response.data['data'];
  }

  // 가입코드 목록 조회
  static Future<List<dynamic>> getList() async {
    final response = await _dio.get('/admin/invite-codes');
    return response.data['data'];
  }

  // 가입코드 활성/비활성 토글
  static Future<void> toggle(int id, bool isActive) async {
    await _dio.patch(
      '/admin/invite-codes/$id',
      data: {'isActive': isActive},
    );
  }
}
