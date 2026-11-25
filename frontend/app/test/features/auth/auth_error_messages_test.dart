import 'dart:io';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/error/error_messages.dart';
import 'package:app/features/auth/auth_messages.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';

/// 로그인과 가입이 실패했을 때 화면에 남는 문구: 연결 상태와 상태 코드만 보고 고른다.
/// 서버가 준 문구는 쓰지 않고, 서버가 거절한 경우(400, 401, 403 ...)는 계정 상태를 드러내지 않도록 같은 문구다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpClientAdapter originalAdapter;
  late AuthNotifier auth;

  setUp(() {
    originalAdapter = ApiClient.instance.httpClientAdapter;
    FlutterSecureStorage.setMockInitialValues({});
    auth = AuthNotifier();
  });

  tearDown(() {
    ApiClient.instance.httpClientAdapter = originalAdapter;
    ApiClient.onSessionExpired = null;
    auth.dispose();
  });

  void serverReplies(Future<ResponseBody> Function(RequestOptions) handler) {
    ApiClient.instance.httpClientAdapter = FakeHttpAdapter(handler);
  }

  Future<String?> loginMessage() async {
    await auth.login('2025001', 'pw12');
    expect(auth.state.isLoading, isFalse);
    expect(auth.state.isLoggedIn, isFalse);
    return auth.state.errorMessage;
  }

  Future<String?> signupMessage() async {
    await auth.signup('CODE', '2025001', 'pw12');
    expect(auth.state.isLoading, isFalse);
    expect(auth.state.isLoggedIn, isFalse);
    return auth.state.errorMessage;
  }

  DioException networkError(DioExceptionType type, {Object? error}) =>
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: type,
        error: error,
      );

  group('로그인 실패 문구', () {
    for (final status in [400, 401, 403, 404, 409, 422]) {
      test('서버가 $status로 거절하면 같은 "확인해 주세요" 문구다', () async {
        serverReplies((o) async => jsonResponse(status, {'success': false}));
        expect(await loginMessage(), AuthMessages.loginRejected);
      });
    }

    test('400과 403의 문구가 같다 (계정이 있는지, 어떤 상태인지 드러내지 않는다)', () async {
      serverReplies(
        (o) async => jsonResponse(400, {
          'success': false,
          'error': {'code': 'INVALID_PASSWORD', 'message': '비밀번호가 맞지 않아요.'},
        }),
      );
      final wrongPassword = await loginMessage();
      serverReplies(
        (o) async => jsonResponse(403, {
          'success': false,
          'error': {'code': 'NOT_ACTIVE', 'message': '아직 승인되지 않은 계정이에요.'},
        }),
      );
      final notActive = await loginMessage();
      serverReplies(
        (o) async => jsonResponse(400, {
          'success': false,
          'error': {'code': 'USER_NOT_FOUND', 'message': '없는 학번이에요.'},
        }),
      );
      final noUser = await loginMessage();

      expect(wrongPassword, AuthMessages.loginRejected);
      expect(notActive, wrongPassword);
      expect(noUser, wrongPassword);
    });

    test('서버가 준 문구는 화면에 남지 않는다', () async {
      serverReplies(
        (o) async => jsonResponse(400, {
          'success': false,
          'error': {'code': 'X', 'message': '서버가 보낸 한글 문구예요.'},
        }),
      );
      expect(await loginMessage(), isNot(contains('서버가 보낸')));
    });

    test('429는 시도 과다 문구다', () async {
      serverReplies((o) async => jsonResponse(429, {'success': false}));
      expect(await loginMessage(), AuthMessages.loginTooMany);
    });

    for (final status in [500, 502, 503]) {
      test('$status는 서버 문제 문구다', () async {
        serverReplies((o) async => jsonResponse(status, {'success': false}));
        expect(await loginMessage(), AuthMessages.loginServer);
      });
    }

    test('연결 실패는 인터넷 연결 문구다', () async {
      serverReplies(
        (o) async => throw networkError(DioExceptionType.connectionError),
      );
      expect(await loginMessage(), AuthMessages.loginOffline);
    });

    test('소켓 오류(unknown)도 인터넷 연결 문구다', () async {
      serverReplies(
        (o) async => throw networkError(
          DioExceptionType.unknown,
          error: const SocketException('x'),
        ),
      );
      expect(await loginMessage(), AuthMessages.loginOffline);
    });

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type은 응답 지연 문구다', () async {
        serverReplies((o) async => throw networkError(type));
        expect(await loginMessage(), AuthMessages.loginTimeout);
      });
    }

    test('응답을 읽을 수 없으면 그 밖의 오류 문구다 (예외 글자는 보이지 않는다)', () async {
      serverReplies((o) async => jsonResponse(200, {'unexpected': true}));
      final message = await loginMessage();
      expect(message, AuthMessages.loginUnknown);
      expect(message, isNot(contains('Exception')));
    });

    test('다른 이유로 다시 실패하면 문구가 새 이유로 바뀐다', () async {
      serverReplies((o) async => jsonResponse(429, {'success': false}));
      expect(await loginMessage(), AuthMessages.loginTooMany);
      serverReplies((o) async => jsonResponse(400, {'success': false}));
      expect(await loginMessage(), AuthMessages.loginRejected);
      serverReplies((o) async => jsonResponse(503, {'success': false}));
      expect(await loginMessage(), AuthMessages.loginServer);
    });
  });

  group('가입 실패 문구', () {
    for (final status in [400, 401, 403, 404, 409, 422]) {
      test('서버가 $status로 거절하면 가입코드와 학번을 확인하라는 문구다', () async {
        serverReplies((o) async => jsonResponse(status, {'success': false}));
        expect(await signupMessage(), AuthMessages.signupRejected);
      });
    }

    test('서버가 준 문구는 화면에 남지 않는다', () async {
      serverReplies(
        (o) async => jsonResponse(400, {
          'success': false,
          'error': {'code': 'ALREADY_REGISTERED', 'message': '이미 가입된 학번입니다.'},
        }),
      );
      expect(await signupMessage(), AuthMessages.signupRejected);
    });

    test('429는 시도 과다 문구다', () async {
      serverReplies((o) async => jsonResponse(429, {'success': false}));
      expect(await signupMessage(), AuthMessages.signupTooMany);
    });

    test('5xx는 서버 문제 문구다 (입력을 확인하라고 하지 않는다)', () async {
      serverReplies((o) async => jsonResponse(503, {'success': false}));
      expect(await signupMessage(), AuthMessages.signupServer);
    });

    test('연결 실패와 시간 초과는 각각 연결, 응답 지연 문구다', () async {
      serverReplies(
        (o) async => throw networkError(DioExceptionType.connectionError),
      );
      expect(await signupMessage(), AuthMessages.signupOffline);
      serverReplies(
        (o) async => throw networkError(DioExceptionType.receiveTimeout),
      );
      expect(await signupMessage(), AuthMessages.signupTimeout);
    });

    test('응답을 읽을 수 없으면 가입코드와 학번 확인 문구다', () async {
      serverReplies((o) async => jsonResponse(200, {'unexpected': true}));
      expect(await signupMessage(), AuthMessages.signupRejected);
    });
  });

  group('중앙 문구와 중복이 없다', () {
    test('연결, 시간 초과, 서버, 그 밖의 오류, 세션 만료는 ErrorMessages와 같은 글자다', () {
      expect(AuthMessages.loginOffline, ErrorMessages.offline);
      expect(AuthMessages.loginTimeout, ErrorMessages.timeout);
      expect(AuthMessages.loginServer, ErrorMessages.server);
      expect(AuthMessages.loginUnknown, ErrorMessages.generic);
      expect(AuthMessages.signupOffline, ErrorMessages.offline);
      expect(AuthMessages.signupTimeout, ErrorMessages.timeout);
      expect(AuthMessages.signupServer, ErrorMessages.server);
      expect(AuthMessages.signupTooMany, ErrorMessages.tooManyRequests);
      expect(AuthMessages.sessionExpired, ErrorMessages.unauthorized);
      expect(AuthNotifier.sessionExpiredMessage, ErrorMessages.unauthorized);
    });

    test('AuthMessages 소스에 같은 글자를 다시 적지 않는다', () {
      final source = File(
        'lib/features/auth/auth_messages.dart',
      ).readAsStringSync();
      for (final shared in [
        ErrorMessages.offline,
        ErrorMessages.timeout,
        ErrorMessages.server,
        ErrorMessages.generic,
        ErrorMessages.unauthorized,
        ErrorMessages.tooManyRequests,
      ]) {
        expect(source.contains(shared), isFalse, reason: shared);
      }
    });
  });
}
