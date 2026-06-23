import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/day_of_week.dart';
import '../../core/domain/time_slot.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import 'group.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(dioProvider));
});

class GroupRepository {
  GroupRepository(this._dio);

  final Dio _dio;

  Future<List<Group>> getGroups() async {
    try {
      final response = await _dio.get('/groups');
      final data = response.data['data'] as List;
      return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> createGroups(List<(DayOfWeek, TimeSlot)> slots) async {
    try {
      await _dio.post('/admin/groups', data: {
        'groups': slots
            .map((slot) => {'dayOfWeek': slot.$1.apiValue, 'timeSlot': slot.$2.apiValue})
            .toList(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> assignLeader(int groupId, int leaderUserId) async {
    try {
      await _dio.patch('/admin/groups/$groupId/leader', data: {'leaderUserId': leaderUserId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
