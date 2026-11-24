import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Dio의 네트워크를 가짜로 바꾸는 어댑터. [handler]가 요청마다 응답을 만들거나 DioException을 던진다.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// 받은 요청들 (순서대로)
  final List<RequestOptions> requests = [];

  int count(String path) => requests.where((r) => r.path.endsWith(path)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, [Object? body]) =>
    ResponseBody.fromString(
      jsonEncode(body ?? <String, Object>{}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// 서버가 토큰을 새로 내려 주는 갱신 성공 응답
ResponseBody refreshOk(String access, String refresh) => jsonResponse(200, {
  'success': true,
  'data': {'accessToken': access, 'refreshToken': refresh},
});
