import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio _dio = _createDio();

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
          if (error.response?.statusCode == 401) {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken == null) return handler.next(error);

            try {
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: AppConstants.baseUrl,
                  headers: {'Content-Type': 'application/json'},
                ),
              );

              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final newAccessToken = response.data['data']['accessToken'];
              final newRefreshToken =
                  response.data['data']['refreshToken'];

              await TokenStorage.saveAccessToken(newAccessToken);
              await TokenStorage.saveRefreshToken(newRefreshToken);

              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              await TokenStorage.deleteAll();
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Dio get instance => _dio;
}
