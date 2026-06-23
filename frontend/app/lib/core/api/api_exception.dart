import 'package:dio/dio.dart';

// 백엔드 공통 에러 포맷 { success:false, error:{code,message} }을 그대로 들고 올리기 위한 예외.
class ApiException implements Exception {
  ApiException(this.code, this.message);

  final String code;
  final String message;

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(error['code'] as String? ?? 'UNKNOWN', error['message'] as String? ?? '알 수 없는 오류');
    }
    return ApiException('NETWORK_ERROR', '서버와 통신할 수 없습니다.');
  }

  @override
  String toString() => message;
}
