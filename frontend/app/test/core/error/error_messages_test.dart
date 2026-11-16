import 'dart:io' show SocketException;

import 'package:app/core/error/error_messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException dio(
  DioExceptionType type, {
  int? status,
  Object? body,
  Object? error,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response: status == null ? null : Response<dynamic>(requestOptions: options, statusCode: status, data: body),
  );
}

DioException bad(int status, {String? code, String? message, Object? body}) => dio(
      DioExceptionType.badResponse,
      status: status,
      body: body ??
          {
            'success': false,
            'error': {'code': ?code, 'message': ?message},
          },
    );

void main() {
  group('네트워크', () {
    test('연결 실패와 소켓 오류는 오프라인 문구', () {
      expect(ErrorMessages.of(dio(DioExceptionType.connectionError)), ErrorMessages.offline);
      expect(
        ErrorMessages.of(dio(DioExceptionType.unknown, error: const SocketException('끊김'))),
        ErrorMessages.offline,
      );
    });

    test('시간 초과(연결, 보내기, 받기)는 응답 지연 문구', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ErrorMessages.of(dio(type)), ErrorMessages.timeout, reason: '$type');
      }
    });

    test('소켓이 아닌 알 수 없는 오류, 취소, 인증서 오류는 일반 문구', () {
      expect(ErrorMessages.of(dio(DioExceptionType.unknown, error: StateError('x'))), ErrorMessages.generic);
      expect(ErrorMessages.of(dio(DioExceptionType.cancel)), ErrorMessages.generic);
      expect(ErrorMessages.of(dio(DioExceptionType.badCertificate)), ErrorMessages.generic);
    });

    test('isOffline: 연결 실패, 시간 초과, 소켓 오류만 true', () {
      expect(ErrorMessages.isOffline(dio(DioExceptionType.connectionError)), isTrue);
      expect(ErrorMessages.isOffline(dio(DioExceptionType.receiveTimeout)), isTrue);
      expect(ErrorMessages.isOffline(dio(DioExceptionType.unknown, error: const SocketException('x'))), isTrue);
      expect(ErrorMessages.isOffline(dio(DioExceptionType.unknown, error: StateError('x'))), isFalse);
      expect(ErrorMessages.isOffline(bad(500)), isFalse);
      expect(ErrorMessages.isOffline(StateError('x')), isFalse);
      expect(ErrorMessages.isOffline(null), isFalse);
    });
  });

  group('서버 응답', () {
    test('4xx이고 서버가 사용자용 문구를 주면 그대로 쓴다', () {
      expect(ErrorMessages.of(bad(409, code: 'ALREADY_VOTED', message: '이미 투표했어요.')), '이미 투표했어요.');
      expect(ErrorMessages.of(bad(400, code: 'INVALID_PASSWORD', message: '비밀번호가 맞지 않아요.')), '비밀번호가 맞지 않아요.');
    });

    test('서버 문구 앞뒤 공백은 지운다', () {
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: '  이름을 입력해 주세요.  ')), '이름을 입력해 주세요.');
    });

    test('5xx는 서버 문구가 있어도 앱의 문구를 쓴다 (서버 내부 사정을 보이지 않는다)', () {
      expect(ErrorMessages.of(bad(500, code: 'SERVER_ERROR', message: 'NullPointerException at ...')), ErrorMessages.server);
      expect(ErrorMessages.of(bad(503, message: '내부 점검 중입니다')), ErrorMessages.server);
    });

    test('서버 내부 코드(SERVER_ERROR, FILE_ERROR)는 4xx여도 서버 문구를 쓰지 않는다', () {
      expect(ErrorMessages.of(bad(400, code: 'FILE_ERROR', message: 'java.io.IOException: /tmp/x')), ErrorMessages.generic);
      expect(ErrorMessages.of(bad(500, code: 'FILE_ERROR', message: 'java.io.IOException')), ErrorMessages.server);
    });

    test('코드별 앱 문구: 시도 제한, 파일 용량, 토큰 만료', () {
      expect(ErrorMessages.of(bad(429, code: 'TOO_MANY_ATTEMPTS', message: '서버 문구')), ErrorMessages.tooManyRequests);
      expect(ErrorMessages.of(bad(413, code: 'FILE_TOO_LARGE', message: '서버 문구')), ErrorMessages.fileTooLarge);
      expect(ErrorMessages.of(bad(401, code: 'INVALID_REFRESH_TOKEN', message: '서버 문구')), ErrorMessages.unauthorized);
    });

    test('본문이 없거나 형식이 달라도 상태 코드로 문구를 정한다', () {
      expect(ErrorMessages.of(bad(401, body: '')), ErrorMessages.unauthorized);
      expect(ErrorMessages.of(bad(403, body: null)), ErrorMessages.forbidden);
      expect(ErrorMessages.of(bad(404, body: '<html>Not Found</html>')), ErrorMessages.notFound);
      expect(ErrorMessages.of(bad(429, body: <String, dynamic>{})), ErrorMessages.tooManyRequests);
      expect(ErrorMessages.of(bad(502, body: '<html>Bad Gateway</html>')), ErrorMessages.server);
      expect(ErrorMessages.of(bad(418, body: 'x')), ErrorMessages.generic);
    });

    test('서버 문구가 비었거나 너무 길면 쓰지 않고 상태 코드 문구로 간다', () {
      expect(ErrorMessages.of(bad(404, code: 'RESOURCE_NOT_FOUND', message: '')), ErrorMessages.notFound);
      expect(ErrorMessages.of(bad(404, code: 'RESOURCE_NOT_FOUND', message: '가' * 121)), ErrorMessages.notFound);
      expect(ErrorMessages.of(bad(400, code: 'X', message: '가' * 120)), '가' * 120);
    });

    test('서버 문구에 한글이 없으면(영어 기본 검증 문구 등) 쓰지 않고 앱 문구로 바꾼다', () {
      // message를 안 적은 @NotNull은 서버 JVM의 기본 문구("must not be null")가 내려간다
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: 'must not be null')), ErrorMessages.invalidInput);
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: 'must match "^(?=.*[a-z]).{8,}\$"')), ErrorMessages.invalidInput);
      expect(ErrorMessages.of(bad(400, code: 'OTHER_CODE', message: 'Something went wrong')), ErrorMessages.generic);
      expect(ErrorMessages.of(bad(404, code: 'RESOURCE_NOT_FOUND', message: 'Not Found')), ErrorMessages.notFound);
    });

    test('한글이 조금이라도 있으면 영문이 섞여 있어도 서버 문구를 쓴다', () {
      expect(
        ErrorMessages.of(bad(400, code: 'INVALID_FILE', message: 'JPG, PNG, GIF, WEBP 이미지만 업로드할 수 있습니다.')),
        'JPG, PNG, GIF, WEBP 이미지만 업로드할 수 있습니다.',
      );
    });

    test('입력 검증 오류(INVALID_INPUT)가 한국어 문구를 주면 그대로 쓴다', () {
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: '이름을 입력해 주세요.')), '이름을 입력해 주세요.');
    });

    test('입력 검증 코드의 대체 문구는 문구가 비었거나 너무 길 때도 쓴다', () {
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: '')), ErrorMessages.invalidInput);
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT', message: '가' * 121)), ErrorMessages.invalidInput);
      expect(ErrorMessages.of(bad(400, code: 'INVALID_INPUT')), ErrorMessages.invalidInput);
    });

    test('error 필드의 형식이 달라도 죽지 않는다', () {
      expect(ErrorMessages.of(bad(400, body: {'error': 'oops'})), ErrorMessages.generic);
      expect(ErrorMessages.of(bad(400, body: {'error': {'code': 1, 'message': 2}})), ErrorMessages.generic);
      expect(ErrorMessages.of(bad(400, body: {'success': false})), ErrorMessages.generic);
    });

    test('isUnauthorized: 401만 true', () {
      expect(ErrorMessages.isUnauthorized(bad(401)), isTrue);
      expect(ErrorMessages.isUnauthorized(bad(403)), isFalse);
      expect(ErrorMessages.isUnauthorized(StateError('x')), isFalse);
    });
  });

  group('예외 객체의 글자는 절대 보이지 않는다', () {
    test('Dio가 아닌 예외는 모두 일반 문구', () {
      for (final error in <Object?>[
        StateError('secret state'),
        const FormatException('bad json {"token":"abc"}'),
        ArgumentError('x'),
        TypeError(),
        'raw string error',
        null,
        42,
      ]) {
        expect(ErrorMessages.of(error), ErrorMessages.generic, reason: '$error');
      }
    });

    test('어떤 경우에도 결과에 예외 이름이나 내부 정보가 섞이지 않는다', () {
      final errors = <Object?>[
        dio(DioExceptionType.connectionError, error: const SocketException('Connection refused 10.0.0.5')),
        dio(DioExceptionType.unknown, error: StateError('internal')),
        bad(500, code: 'SERVER_ERROR', message: 'at com.smash.Service.run(Service.java:42)'),
        bad(400, code: 'FILE_ERROR', message: '/var/data/secret.png'),
        bad(400, code: 'INVALID_INPUT', message: 'must not be null'),
        StateError('Bad state: token=abc'),
      ];
      for (final error in errors) {
        final text = ErrorMessages.of(error);
        for (final leak in ['must not', 'Exception', 'DioException', 'StateError', 'Bad state', 'com.smash', '.java', '/var/', '10.0.0.5', 'token=']) {
          expect(text.contains(leak), isFalse, reason: '"$text"에 "$leak"가 섞임 ($error)');
        }
      }
    });
  });
}
