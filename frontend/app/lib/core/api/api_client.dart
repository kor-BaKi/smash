import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio _dio = _createDio();

  // 진행 중인 토큰 갱신. 동시에 들어온 401 요청들이 이 하나를 공유한다.
  static Future<String?>? _refreshing;

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
      }
      return null;
    }
  }

  static Dio get instance => _dio;
}
