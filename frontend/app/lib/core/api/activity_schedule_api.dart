import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/schedule/model/activity_schedule.dart';
import 'api_client.dart';
import 'api_exception.dart';

final activityScheduleApiProvider = Provider<ActivityScheduleApi>((ref) {
  return ActivityScheduleApi(ref.watch(dioProvider));
});

class ActivityScheduleApi {
  ActivityScheduleApi(this._dio);

  final Dio _dio;

  Future<List<ActivitySchedule>> getSchedules() async {
    try {
      final response = await _dio.get('/admin/activity-schedules');
      final data = response.data['data'] as List;
      return data.map((e) => ActivitySchedule.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // B-4: 전체교체. 항상 전체 목록을 보내야 한다.
  Future<List<ActivitySchedule>> replaceAll(List<ActivitySchedule> schedules) async {
    try {
      final response = await _dio.put('/admin/activity-schedules', data: {
        'schedules': schedules
            .map((s) => {
                  'dayOfWeek': s.dayOfWeek.apiValue,
                  'timeSlot': s.timeSlot.apiValue,
                  'isActive': s.isActive,
                })
            .toList(),
      });
      final data = response.data['data'] as List;
      return data.map((e) => ActivitySchedule.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
