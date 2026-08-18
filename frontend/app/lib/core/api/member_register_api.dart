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

  // 지원자(PENDING) 목록 조회
  static Future<List<dynamic>> getPendingApplicants() async {
    final response = await _dio.get('/admin/members/pending');
    return response.data['data'];
  }

  // 불합격 처리
  static Future<void> reject(int userId) async {
    await _dio.patch('/admin/members/$userId/reject');
  }

  // 불합격 취소(복구)
  static Future<void> restore(int userId) async {
    await _dio.patch('/admin/members/$userId/restore');
  }

  // 전체 유저 목록 조회
  static Future<List<dynamic>> getAllMembers() async {
    final response = await _dio.get('/admin/members');
    return response.data['data'];
  }

  // 특정 조 소속 부원 목록
  static Future<List<dynamic>> getGroupMembers(int groupId) async {
    final response = await _dio.get('/admin/groups/$groupId/members');
    return response.data['data'];
  }

  // 지원자 삭제
  static Future<void> deleteMember(int userId) async {
    await _dio.delete('/admin/members/$userId');
  }
}
