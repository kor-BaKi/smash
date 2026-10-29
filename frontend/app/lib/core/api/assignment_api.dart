import 'package:dio/dio.dart';

import 'api_client.dart';

class AssignmentApi {
  static final Dio _dio = ApiClient.instance;

  // 자동 배정 미리보기
  static Future<Map<String, dynamic>> preview() async {
    final response = await _dio.post('/admin/assignment/preview');
    return response.data['data'];
  }

  // 배정 확정
  static Future<void> confirm({
    required String previewToken,
    required List<int> basedOnMemberIds,
    required List<Map<String, int>> assignments,
  }) async {
    await _dio.post(
      '/admin/assignment/confirm',
      data: {
        'previewToken': previewToken,
        'basedOnMemberIds': basedOnMemberIds,
        'assignments': assignments,
      },
    );
  }

  // 새 학기 초기화 (조 배정 해제 + 가용 시간 삭제 + 조장/부조장 해제)
  static Future<int> resetSemester() async {
    final response = await _dio.post('/admin/semester/reset');
    return response.data['data']['releasedCount'] as int;
  }

  // 개별 수동 배정 (미배정자 등 즉시 배정)
  static Future<void> assignMember(int userId, int groupId) async {
    await _dio.patch(
      '/admin/members/$userId/group',
      data: {'groupId': groupId},
    );
  }
}
