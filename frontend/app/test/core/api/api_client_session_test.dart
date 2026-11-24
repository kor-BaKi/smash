import 'dart:io';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

/// 토큰 갱신이 서버에서 거부되면(4xx) 세션 만료를 한 번 알린다. 그 밖의 실패(네트워크, 시간 초과, 5xx)와
/// 로그인/가입 요청의 실패는 알리지 않는다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpClientAdapter originalAdapter;
  late FakeHttpAdapter main;
  late FakeHttpAdapter refresh;
  var expired = 0;

  /// 기본 서버: 새 토큰(A2)이 아니면 모든 요청이 401이고, 갱신은 [refreshHandler]대로 답한다
  void setUpServer(
    Future<ResponseBody> Function(RequestOptions) refreshHandler,
  ) {
    main = FakeHttpAdapter((o) async {
      final ok = o.headers['Authorization'] == 'Bearer A2';
      return jsonResponse(ok ? 200 : 401, {'success': ok});
    });
    refresh = FakeHttpAdapter(refreshHandler);
    ApiClient.instance.httpClientAdapter = main;
    ApiClient.refreshAdapterForTest = refresh;
  }

  setUp(() {
    originalAdapter = ApiClient.instance.httpClientAdapter;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'A1',
      'refresh_token': 'R1',
    });
    expired = 0;
    ApiClient.onSessionExpired = () => expired++;
  });

  tearDown(() {
    ApiClient.instance.httpClientAdapter = originalAdapter;
    ApiClient.refreshAdapterForTest = null;
    ApiClient.onSessionExpired = null;
  });

  Future<Object?> call(String path) async {
    try {
      return (await ApiClient.instance.get(path)).statusCode;
    } on DioException catch (e) {
      return e;
    }
  }

  group('서버가 갱신을 거부하면(4xx) 세션 만료를 알린다', () {
    for (final status in [400, 401, 403]) {
      test('갱신이 $status: 만료를 한 번 알리고 저장된 토큰을 지운다, 원래 요청은 401로 끝난다', () async {
        setUpServer((o) async => jsonResponse(status));
        final result = await call('/me');

        expect(expired, 1);
        expect(await TokenStorage.getAccessToken(), isNull);
        expect(await TokenStorage.getRefreshToken(), isNull);
        expect((result as DioException).response?.statusCode, 401);
        expect(refresh.requests.length, 1);
      });
    }

    test('동시에 401이 여러 개여도 갱신은 한 번, 만료 알림도 한 번이다', () async {
      setUpServer((o) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return jsonResponse(401);
      });
      final results = await Future.wait([
        call('/me'),
        call('/polls'),
        call('/activities'),
        call('/me/x'),
      ]);

      expect(results.every((r) => r is DioException), isTrue);
      expect(refresh.requests.length, 1, reason: '갱신 요청 공유');
      expect(expired, 1);
    });

    test('만료 뒤에 늦게 도착한 401은 다시 알리지 않는다 (저장된 갱신 토큰이 이미 없다)', () async {
      setUpServer((o) async => jsonResponse(401));
      await call('/me');
      expect(expired, 1);

      await call('/me');
      await call('/polls');
      expect(expired, 1);
      expect(refresh.requests.length, 1, reason: '갱신 토큰이 없으니 갱신을 다시 시도하지 않는다');
    });
  });

  group('갱신이 서버 거부가 아닌 이유로 실패하면 알리지 않는다', () {
    final failures = <String, Future<ResponseBody> Function(RequestOptions)>{
      '네트워크 오류': (o) async => throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline',
      ),
      '연결 시간 초과': (o) async => throw DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: o,
      ),
      '응답 시간 초과': (o) async => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: o,
      ),
      '500': (o) async => jsonResponse(500),
      '503': (o) async => jsonResponse(503),
    };
    for (final e in failures.entries) {
      test('${e.key}: 만료를 알리지 않고 토큰을 지우지 않는다', () async {
        setUpServer(e.value);
        final result = await call('/me');

        expect(result, isA<DioException>());
        expect(expired, 0);
        expect(await TokenStorage.getAccessToken(), 'A1');
        expect(await TokenStorage.getRefreshToken(), 'R1');
      });
    }
  });

  test('갱신에 성공하면 새 토큰으로 다시 보내 성공하고 만료를 알리지 않는다', () async {
    setUpServer((o) async => refreshOk('A2', 'R2'));
    final result = await call('/me');

    expect(result, 200);
    expect(expired, 0);
    expect(await TokenStorage.getAccessToken(), 'A2');
    expect(await TokenStorage.getRefreshToken(), 'R2');
    expect(main.requests.length, 2, reason: '처음 요청과 다시 보낸 요청');
  });

  group('로그인, 가입, 갱신 요청의 실패는 이 경로를 타지 않는다', () {
    for (final path in ['/auth/login', '/auth/signup']) {
      test('$path가 401이어도 갱신을 시도하지 않고 만료를 알리지 않고 토큰을 지우지 않는다', () async {
        // 갱신 토큰이 남아 있어도(예: 다른 계정으로 로그인 시도) 갱신 경로를 타면 안 된다
        setUpServer((o) async => jsonResponse(401));
        main = FakeHttpAdapter((o) async => jsonResponse(401));
        ApiClient.instance.httpClientAdapter = main;

        final result = await call(path);

        expect((result as DioException).response?.statusCode, 401);
        expect(refresh.requests, isEmpty, reason: '갱신 요청 없음');
        expect(expired, 0);
        expect(
          await TokenStorage.getRefreshToken(),
          'R1',
          reason: '저장된 토큰을 건드리지 않는다',
        );
      });
    }
  });

  test('lib/core는 features를 가져오지 않는다 (ApiClient와 인증 상태 사이에 순환 의존이 없다)', () {
    final offenders = <String>[];
    for (final file in Directory(
      'lib/core',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final m in RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(text)) {
        final target = m.group(1)!;
        if (target.contains('features/')) {
          offenders.add('${file.path} → $target');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
