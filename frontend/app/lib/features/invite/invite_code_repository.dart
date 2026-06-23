import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import 'invite_code.dart';

final inviteCodeRepositoryProvider = Provider<InviteCodeRepository>((ref) {
  return InviteCodeRepository(ref.watch(dioProvider));
});

class InviteCodeRepository {
  InviteCodeRepository(this._dio);

  final Dio _dio;

  Future<List<InviteCode>> getInviteCodes() async {
    try {
      final response = await _dio.get('/admin/invite-codes');
      final data = response.data['data'] as List;
      return data.map((e) => InviteCode.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> createInviteCode() async {
    try {
      await _dio.post('/admin/invite-codes');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> setActive(int id, bool isActive) async {
    try {
      await _dio.patch('/admin/invite-codes/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
