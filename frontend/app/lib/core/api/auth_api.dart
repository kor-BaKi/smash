import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/model/auth_user.dart';
import 'api_client.dart';
import 'api_exception.dart';
import '../storage/token_storage.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthApi {
  AuthApi(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login(
    String studentNo,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'studentNo': studentNo, 'password': password},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return AuthUser.fromJson(
        data['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // 서버 호출이 실패해도(토큰 만료 등) 로컬 토큰은 항상 지워서 로그아웃을 보장한다.
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // ignore
    } finally {
      await _tokenStorage.clear();
    }
  }
}
