import 'package:dio/dio.dart';

import 'api_client.dart';

class FcmApi {
  static final Dio _dio = ApiClient.instance;

  // FCM 토큰 저장
  static Future<void> saveToken(String token, String deviceType) async {
    await _dio.post(
      '/fcm/token',
      data: {'token': token, 'deviceType': deviceType},
    );
  }

  // FCM 토큰 삭제 (로그아웃 시)
  static Future<void> deleteToken() async {
    await _dio.delete('/fcm/token');
  }
}
