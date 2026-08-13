import 'package:dio/dio.dart';

import 'api_client.dart';

class TransportApi {
  static final Dio _dio = ApiClient.instance;

  // 택시 그룹 조회
  static Future<List<dynamic>> getGroups(int activityId) async {
    final response = await _dio.get(
      '/activities/$activityId/transport-groups',
    );
    return response.data['data'];
  }

  // 택시 그룹 배정 (임원)
  static Future<List<dynamic>> assign(
    int activityId,
    List<List<int>> groups,
  ) async {
    final response = await _dio.post(
      '/admin/activities/$activityId/transport-groups',
      data: {
        'groups': groups.map((g) => {'memberIds': g}).toList(),
      },
    );
    return response.data['data'];
  }

  // 택시 그룹 초기화 (임원)
  static Future<void> reset(int activityId) async {
    await _dio.delete('/admin/activities/$activityId/transport-groups');
  }
}
