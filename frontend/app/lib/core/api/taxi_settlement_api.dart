import 'package:dio/dio.dart';

import 'api_client.dart';

class TaxiSettlementApi {
  static final Dio _dio = ApiClient.instance;

  // 정산 생성
  static Future<Map<String, dynamic>> create(
    int activityId,
    int groupId,
    int totalAmount,
    String accountBank,
    String accountNumber,
  ) async {
    final response = await _dio.post(
      '/activities/$activityId/transport-groups/$groupId/settlement',
      data: {
        'totalAmount': totalAmount,
        'accountBank': accountBank,
        'accountNumber': accountNumber,
      },
    );
    return response.data['data'];
  }

  // 정산 조회
  static Future<Map<String, dynamic>?> getSettlement(
    int activityId,
    int groupId,
  ) async {
    try {
      final response = await _dio.get(
        '/activities/$activityId/transport-groups/$groupId/settlement',
      );
      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  // 납부 확인 토글
  static Future<void> togglePayment(int settlementId, int userId) async {
    await _dio.patch('/settlements/$settlementId/payments/$userId');
  }

  // 정산 삭제
  static Future<void> delete(int settlementId) async {
    await _dio.delete('/settlements/$settlementId');
  }
}
