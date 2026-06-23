import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activity/model/activity.dart';
import '../domain/activity_type.dart';
import 'api_client.dart';
import 'api_exception.dart';

final activityApiProvider = Provider<ActivityApi>((ref) {
  return ActivityApi(ref.watch(dioProvider));
});

class ActivityApi {
  ActivityApi(this._dio);

  final Dio _dio;

  Future<List<TodayActivity>> getToday({required String scope}) async {
    try {
      final response = await _dio.get('/me/activities/today', queryParameters: {'scope': scope});
      final data = response.data['data'] as List;
      return data.map((e) => TodayActivity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> submitParticipation(int activityId, ClientParticipationType type, {int? targetActivityId}) async {
    try {
      await _dio.post('/me/activities/$activityId/participation', data: {
        'type': type.apiValue,
        'targetActivityId': ?targetActivityId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> cancelParticipation(int activityId) async {
    try {
      await _dio.delete('/me/activities/$activityId/participation');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<CarryoverCandidate>> getCarryoverCandidates(int activityId) async {
    try {
      final response = await _dio.get('/me/activities/$activityId/carryover-candidates');
      final data = response.data['data'] as List;
      return data.map((e) => CarryoverCandidate.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ActivityDetail> getActivityDetail(int activityId) async {
    try {
      final response = await _dio.get('/activities/$activityId');
      return ActivityDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ActivitySummary>> getAdminActivities({String? date}) async {
    try {
      final response = await _dio.get('/admin/activities', queryParameters: {'date': ?date});
      final data = response.data['data'] as List;
      return data.map((e) => ActivitySummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateActivity(int activityId, {bool? isCancelled, ActivityType? activityType}) async {
    try {
      await _dio.patch('/admin/activities/$activityId', data: {
        'isCancelled': ?isCancelled,
        'activityType': ?activityType?.apiValue,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
