import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';

const _baseUrl = 'http://localhost:8080/api/v1';

// iOS 시뮬레이터는 macOS와 네트워크를 공유해서 localhost로 백엔드에 바로 접근 가능.
// (Android 에뮬레이터를 쓴다면 10.0.2.2로 바꿔야 함)
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));

  // refresh 호출 전용 Dio. 같은 인터셉터를 타면 401 -> refresh -> 401 무한루프가 될 수 있어 분리.
  final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));

  // 동시에 여러 요청이 401을 받아도 refresh는 한 번만 실행되도록 공유.
  Future<String?>? refreshing;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
        if (!isUnauthorized || isAuthEndpoint) {
          handler.next(error);
          return;
        }

        refreshing ??= _refresh(refreshDio, tokenStorage);
        final newAccessToken = await refreshing;
        refreshing = null;

        if (newAccessToken == null) {
          await tokenStorage.clear();
          handler.next(error);
          return;
        }

        final retryOptions = error.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final response = await dio.fetch(retryOptions);
          handler.resolve(response);
        } catch (_) {
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});

Future<String?> _refresh(Dio refreshDio, TokenStorage tokenStorage) async {
  final refreshToken = await tokenStorage.readRefreshToken();
  if (refreshToken == null) return null;

  try {
    final response = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    final data = response.data['data'] as Map<String, dynamic>;
    final newAccessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;
    await tokenStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
    return newAccessToken;
  } catch (_) {
    return null;
  }
}
