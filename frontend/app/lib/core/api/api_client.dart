import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  // 모든 API 호출의 공통 기반
  static final Dio _dio = Dio(
    // Dio : HTTP 클라이언트
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5), // 서버 연결 대기 시간. 5초 넘으면 에러
      receiveTimeout: const Duration(seconds: 5), // 응답 대기 시간. 5초 넘으면 에러
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get instance {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      // 요청/응답/에러를 가로채는 미들웨어
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 모든 요청에 Access Token 자동 첨부

          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // 401 에러 → Access Token 만료 → Refresh Token으로 재발급
          if (error.response?.statusCode == 401) {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken == null) {
              return handler.next(error);
            }

            try {
              final response = await _dio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(headers: {'Authorization': null}),
              );

              final newAccessToken = response.data['data']['accessToken'];
              final newRefreshToken = response.data['data']['refreshToken'];

              await TokenStorage.saveAccessToken(newAccessToken);
              await TokenStorage.saveRefreshToken(newRefreshToken);

              // 실패한 요청 재시도
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(retryOptions);
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
    return _dio;
  }
}
