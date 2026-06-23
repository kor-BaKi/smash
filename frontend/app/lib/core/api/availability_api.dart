import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/availability/model/availability.dart';
import 'api_client.dart';
import 'api_exception.dart';

final availabilityApiProvider = Provider<AvailabilityApi>((ref) {
  return AvailabilityApi(ref.watch(dioProvider));
});

class AvailabilityApi {
  AvailabilityApi(this._dio);

  final Dio _dio;

  Future<AvailabilityStatus> getAvailability() async {
    try {
      final response = await _dio.get('/me/availability');
      return AvailabilityStatus.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // C-1: 배정 전까지는 매번 전체교체. 배정 후 호출하면 서버가 ALREADY_ASSIGNED를 던진다.
  Future<void> submit(List<int> groupIds) async {
    try {
      await _dio.put('/me/availability', data: {'groupIds': groupIds});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
