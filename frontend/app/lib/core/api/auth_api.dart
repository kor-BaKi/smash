import 'package:app/core/api/api_client.dart';
import 'package:dio/dio.dart';

class AuthApi {
  static final Dio _dio = ApiClient.instance;

  // 로그인
  // Map<String, dynamic> : JSON 응답을 Dart에서 표현하는 타입
  static Future<Map<String, dynamic>> login({
    required String studentNo,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'studentNo': studentNo, 'password': password},
    );
    return response.data;
  }

  // 회원가입
  static Future<Map<String, dynamic>> signup({
    required String code,
    required String studentNo,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/signup',
      data: {'code': code, 'studentNo': studentNo, 'password': password},
    );
    return response.data;
  }

  // 로그아웃
  static Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  // 내 정보 조회
  static Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/me');
    return response.data;
  }

  // 비밀번호 변경
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch(
      '/auth/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
