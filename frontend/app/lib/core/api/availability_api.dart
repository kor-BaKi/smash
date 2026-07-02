import 'package:app/core/api/api_client.dart';
import 'package:dio/dio.dart';

class AvailabilityApi {
  static final Dio _dio = ApiClient.instance;

  // 전체 조 목록 조회
  static Future<List<dynamic>> getGroups() async {
    final response = await _dio.get('/groups');
    return response.data['data'];
  }

  // 가능 요일 제출
  static Future<void> submitAvailability(List<int> groupIds) async {
    await _dio.put('/me/availability', data: {'groupIds': groupIds});
  }

  // 내 가능 요일 조회
  static Future<List<dynamic>> getMyAvailability() async {
    final response = await _dio.get('/me/availability');
    return response.data['data'];
  }
}
