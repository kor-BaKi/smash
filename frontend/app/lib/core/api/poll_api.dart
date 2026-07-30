import 'package:dio/dio.dart';

import 'api_client.dart';

class PollApi {
  static final Dio _dio = ApiClient.instance;

  // 투표 목록 조회
  static Future<List<dynamic>> getList() async {
    final response = await _dio.get('/polls');
    return response.data['data'];
  }

  // 투표 상세 조회
  static Future<Map<String, dynamic>> getDetail(int pollId) async {
    final response = await _dio.get('/polls/$pollId');
    return response.data['data'];
  }

  // 투표 참여
  static Future<Map<String, dynamic>> vote(
    int pollId,
    int optionId,
  ) async {
    final response = await _dio.post(
      '/polls/$pollId/vote',
      data: {'optionId': optionId},
    );
    return response.data['data'];
  }

  // 투표 생성 (ADMIN)
  static Future<Map<String, dynamic>> create({
    required String title,
    String? description,
    required bool isAnonymous,
    String? closedAt,
    required List<String> options,
  }) async {
    final response = await _dio.post(
      '/admin/polls',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'isAnonymous': isAnonymous,
        if (closedAt != null) 'closedAt': closedAt,
        'options': options,
      },
    );
    return response.data['data'];
  }

  // 투표 취소
  static Future<Map<String, dynamic>> cancelVote(int pollId) async {
    final response = await _dio.delete('/polls/$pollId/vote');
    return response.data['data'];
  }

  // 투표 수동 종료 (ADMIN)
  static Future<void> close(int pollId) async {
    await _dio.patch('/admin/polls/$pollId/close');
  }
}
