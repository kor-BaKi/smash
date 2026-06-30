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
      'me/activities/$activityId/participation',
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
}
