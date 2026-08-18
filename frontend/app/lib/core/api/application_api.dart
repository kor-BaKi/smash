import 'package:dio/dio.dart';

import 'api_client.dart';

class ApplicationApi {
  static final Dio _dio = ApiClient.instance;

  // 현재 폼 조회 (임원)
  static Future<Map<String, dynamic>> getForm() async {
    final response = await _dio.get('/admin/application-form');
    return response.data['data'];
  }

  // 지원서 목록 조회
  static Future<List<dynamic>> getApplications() async {
    final response = await _dio.get('/admin/applications');
    return response.data['data'];
  }

  // 지원서 상세 조회
  static Future<Map<String, dynamic>> getApplication(int id) async {
    final response = await _dio.get('/admin/applications/$id');
    return response.data['data'];
  }

  // 합격 처리
  static Future<void> accept(int id) async {
    await _dio.patch('/admin/applications/$id/accept');
  }

  // 불합격 처리
  static Future<void> reject(int id) async {
    await _dio.patch('/admin/applications/$id/reject');
  }

  // 메모 수정
  static Future<void> updateMemo(int id, String memo) async {
    await _dio.patch(
      '/admin/applications/$id/memo',
      queryParameters: {'memo': memo},
    );
  }

  // 폼 활성/비활성 토글
  static Future<void> toggleForm(bool isActive) async {
    await _dio.patch(
      '/admin/application-form/toggle',
      queryParameters: {'isActive': isActive},
    );
  }

  // 질문 추가
  static Future<Map<String, dynamic>> addQuestion(
    String content,
    String questionType,
    bool isRequired,
  ) async {
    final response = await _dio.post(
      '/admin/application-form/questions',
      data: {
        'content': content,
        'questionType': questionType,
        'isRequired': isRequired,
        'orderIndex': 0,
      },
    );
    return response.data['data'];
  }

  // 질문 삭제
  static Future<Map<String, dynamic>> deleteQuestion(
    int questionId,
  ) async {
    final response = await _dio.delete(
      '/admin/application-form/questions/$questionId',
    );
    return response.data['data'];
  }
}
