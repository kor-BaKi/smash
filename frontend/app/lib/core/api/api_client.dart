import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio _dio = _createDio();

  // 진행 중인 토큰 갱신. 동시에 들어온 401 요청들이 이 하나를 공유한다.
  static Future<String?>? _refreshing;

  /// 토큰 갱신을 서버가 거부했을 때(4xx, 저장된 토큰은 이미 지웠다) 한 번 불린다. 네트워크 오류, 시간 초과,
  /// 5xx에서는 불리지 않는다. 이 파일이 인증 상태(features)를 직접 알지 않도록 바깥에서 넣어 준다
  /// (AuthNotifier가 자기를 연결한다).
  static void Function()? onSessionExpired;

  /// 테스트에서 토큰 갱신 요청을 가짜로 바꾼다 (갱신은 따로 만든 Dio로 보내기 때문)
  @visibleForTesting
  static HttpClientAdapter? refreshAdapterForTest;

  // 로그인, 가입, 갱신 요청의 401은 "세션이 만료됐다"는 뜻이 아니므로 갱신을 시도하지 않는다
  static bool _isAuthRequest(String path) =>
      path.endsWith('/auth/login') ||
      path.endsWith('/auth/signup') ||
      path.endsWith('/auth/refresh');

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401)
            return handler.next(error);

          if (_isAuthRequest(error.requestOptions.path)) {
            return handler.next(error);
          }

          if (error.requestOptions.extra['retried'] == true) {
            return handler.next(error);
          }

          final newAccessToken = await _refreshAccessToken();
          if (newAccessToken == null) return handler.next(error);

          final retryOptions = error.requestOptions
            ..headers['Authorization'] = 'Bearer $newAccessToken'
            ..extra['retried'] = true;
          try {
            return handler.resolve(await dio.fetch(retryOptions));
          } on DioException catch (e) {
            return handler.next(e);
          }
        },
      ),
    );

    return dio;
  }

  static Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(
      () => _refreshing = null,
    );
  }

  static Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (refreshAdapterForTest != null) {
        refreshDio.httpClientAdapter = refreshAdapterForTest!;
      }

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken =
          response.data['data']['accessToken'] as String;
      final newRefreshToken =
          response.data['data']['refreshToken'] as String;
      await TokenStorage.saveAccessToken(newAccessToken);
      await TokenStorage.saveRefreshToken(newRefreshToken);
      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await TokenStorage.deleteAll();
        // 서버가 갱신을 거부했다 = 세션이 끝났다. 화면이 로그인 상태로 남지 않도록 알린다
        onSessionExpired?.call();
      }
      return null;
    }
  }

  static Dio get instance => _dio;
}
