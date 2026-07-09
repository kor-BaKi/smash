import 'package:dio/dio.dart';

import 'api_client.dart';

class GroupApi {
  static final Dio _dio = ApiClient.instance;

  // 조 목록 조회
  static Future<List<dynamic>> getGroups() async {
    final response = await _dio.get('/groups');
    return response.data['data'];
  }

  // 조 생성 (요일+시간대 조합 여러 개)
  static Future<void> createGroups(
    List<Map<String, String>> groups,
  ) async {
    await _dio.post('/admin/groups', data: {'groups': groups});
  }

  // 조장 지정
  static Future<void> assignLeader(int groupId, int leaderUserId) async {
    await _dio.patch(
      '/admin/groups/$groupId/leader',
      data: {'leaderUserId': leaderUserId},
    );
  }

  // 조장 취소 - 추가
  static Future<void> removeLeader(int groupId) async {
    await _dio.delete('/admin/groups/$groupId/leader');
  }
}
