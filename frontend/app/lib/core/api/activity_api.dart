import 'package:app/core/api/api_client.dart';
import 'package:dio/dio.dart';

// API 호출 함수
class ActivityApi {
  static final Dio _dio = ApiClient.instance;

  // 오늘 내 활동 조회
  static Future<List<dynamic>> getTodayActivities() async {
    final response = await _dio.get('/me/activities/today');
    return response.data['data'];
  }

  // 이월 후보 조회
  static Future<List<dynamic>> getCarryoverCandidates(
    int activityId,
  ) async {
    final response = await _dio.get(
      '/me/activities/$activityId/carryover-candidates',
    );
    return response.data['data'];
  }

  // 참여 응답
  static Future<void> participate({
    required int activityId,
    required String type,
    int? targetActivityId,
  }) async {
    await _dio.post(
      '/me/activities/$activityId/participation',
      data: {
        'type': type,
        if (targetActivityId != null) 'targetActivityId': targetActivityId,
      },
    );
  }

  // 응답 취소
  static Future<void> cancelParticipation(int activityId) async {
    await _dio.delete('/me/activities/$activityId/participation');
  }

  // 활동 상세 조회 (투표 결과) - 추가
  static Future<Map<String, dynamic>> getActivityDetail(
    int activityId,
  ) async {
    final response = await _dio.get('/activities/$activityId');
    return response.data['data'];
  }

  // 개별 수동 배정 (미배정자 등 즉시 배정)
  static Future<void> assignMember(int userId, int groupId) async {
    await _dio.patch('/admin/members/$userId/group', data: groupId);
  }

  // 이동 방법 선택
  static Future<void> updateTravelType(
    int activityId,
    String travelType,
  ) async {
    await _dio.patch(
      '/me/activities/$activityId/travel-type',
      data: {'travelType': travelType},
    );
  }

  // 참여자 목록 조회 (임원)
  static Future<List<dynamic>> getParticipants(int activityId) async {
    final response = await _dio.get(
      '/admin/activities/$activityId/participants',
    );
    return response.data['data'];
  }
}
