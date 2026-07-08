import 'package:dio/dio.dart';

import 'api_client.dart';

class MemberRegisterApi {
  static final Dio _dio = ApiClient.instance;

  // 단건 등록
  static Future<Map<String, dynamic>> registerOne({
    required String name,
    required String studentNo,
    String? department,
    String? phone,
    String? joinTerm,
  }) async {
    final response = await _dio.post(
      '/admin/members',
      data: {
        'name': name,
        'studentNo': studentNo,
        if (department != null) 'department': department,
        if (phone != null) 'phone': phone,
        if (joinTerm != null) 'joinTerm': joinTerm,
      },
    );
    return response.data['data'];
  }

  // 대량 등록
  static Future<Map<String, dynamic>> registerBulk(
    List<Map<String, String>> members,
  ) async {
    final response = await _dio.post(
      '/admin/members/bulk',
      data: {'members': members},
    );
    return response.data['data'];
  }
}
