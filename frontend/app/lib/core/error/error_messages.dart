import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

/// 잡힌 예외를 사용자에게 보여줄 한국어 문장으로 바꾼다.
///
/// 원칙
/// - 예외 객체의 글자(`$e`, `e.toString()`)는 화면에 절대 보이지 않는다. 항상 이 클래스를 거친다
/// - 서버가 준 사용자용 문구(BusinessException의 message)는 4xx이고 한글이 들어 있을 때만 그대로 쓴다.
///   5xx나 서버 내부 코드(SERVER_ERROR, FILE_ERROR)의 문구, 한글이 없는 문구(검증 어노테이션에 message를
///   안 적었을 때 서버 JVM이 만드는 영어 기본 문구 "must not be null" 등)는 쓰지 않고 앱의 문구로 바꾼다
/// - 네트워크가 끊긴 경우는 [isOffline]으로 따로 알 수 있다 (오프라인 안내는 API 오류를 기준으로 한다)
class ErrorMessages {
  const ErrorMessages._();

  static const offline = '인터넷에 연결되지 않았어요. 연결을 확인해 주세요.';
  static const timeout = '응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.';
  static const server = '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
  static const generic = '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
  static const unauthorized = '로그인이 만료됐어요. 다시 로그인해 주세요.';
  static const forbidden = '이 작업을 할 수 없어요.';
  static const notFound = '찾을 수 없어요. 이미 삭제됐을 수 있어요.';
  static const tooManyRequests = '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.';
  static const fileTooLarge = '파일 용량이 너무 커요.';
  static const invalidInput = '입력한 내용을 확인해 주세요.';

  /// 서버 내부 사정이라 서버의 문구를 사용자에게 보여주지 않는 코드
  static const _internalCodes = {'SERVER_ERROR', 'FILE_ERROR', 'METHOD_NOT_ALLOWED'};

  /// 서버 문구가 이 길이를 넘으면 사용자용 문구가 아니라고 보고 쓰지 않는다
  static const _maxServerMessageLength = 120;

  static final _hangul = RegExp('[가-힣]');

  static String of(Object? error) {
    if (error is! DioException) return generic;

    switch (error.type) {
      case DioExceptionType.connectionError:
        return offline;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return timeout;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return generic;
      case DioExceptionType.unknown:
        return error.error is SocketException ? offline : generic;
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
    }
  }

  /// 인터넷 연결 문제인가 (연결 실패, 소켓 오류, 시간 초과). 오프라인 안내를 띄울지 정할 때 쓴다
  static bool isOffline(Object? error) {
    if (error is! DioException) return false;
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        true,
      DioExceptionType.unknown => error.error is SocketException,
      _ => false,
    };
  }

  /// 로그인이 만료돼 다시 로그인해야 하는가 (401). 이동은 화면이 정한다
  static bool isUnauthorized(Object? error) =>
      error is DioException && error.response?.statusCode == 401;

  static String _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final (code, message) = _readError(response?.data);

    if (code == 'TOO_MANY_ATTEMPTS') return tooManyRequests;
    if (code == 'FILE_TOO_LARGE') return fileTooLarge;
    if (code == 'INVALID_REFRESH_TOKEN') return unauthorized;
    if (code != null && _internalCodes.contains(code)) {
      return status != null && status >= 500 ? server : generic;
    }

    final isClientError = status != null && status >= 400 && status < 500;
    if (isClientError &&
        message != null &&
        message.isNotEmpty &&
        message.length <= _maxServerMessageLength &&
        _hangul.hasMatch(message)) {
      return message;
    }

    // 입력 검증 오류인데 쓸 수 있는 문구가 없으면(영어 기본 문구 등) 입력을 확인하라고만 알린다
    if (code == 'INVALID_INPUT') return invalidInput;

    return switch (status) {
      401 => unauthorized,
      403 => forbidden,
      404 => notFound,
      429 => tooManyRequests,
      413 => fileTooLarge,
      final s? when s >= 500 => server,
      _ => generic,
    };
  }

  /// 서버 오류 본문 `{ success: false, error: { code, message } }`에서 코드와 문구를 읽는다
  static (String? code, String? message) _readError(Object? body) {
    if (body is! Map) return (null, null);
    final error = body['error'];
    if (error is! Map) return (null, null);
    final code = error['code'];
    final message = error['message'];
    return (
      code is String ? code : null,
      message is String ? message.trim() : null,
    );
  }
}
