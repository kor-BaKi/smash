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
}
