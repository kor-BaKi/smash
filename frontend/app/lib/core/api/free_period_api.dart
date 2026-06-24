import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/free_period/model/free_period.dart';
import 'api_client.dart';
import 'api_exception.dart';

final freePeriodApiProvider = Provider<FreePeriodApi>((ref) {
  return FreePeriodApi(ref.watch(dioProvider));
});

class FreePeriodApi {
  FreePeriodApi(this._dio);

  final Dio _dio;

  Future<List<FreePeriod>> getAll() async {
    try {
      final response = await _dio.get('/admin/free-periods');
      final data = response.data['data'] as List;
      return data.map((e) => FreePeriod.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> create({String? name, required String startDate, required String endDate}) async {
    try {
      await _dio.post('/admin/free-periods', data: {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/free-periods/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
