import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import 'statistics.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(dioProvider));
});

class StatisticsRepository {
  StatisticsRepository(this._dio);

  final Dio _dio;

  Future<List<MonthlyFulfillment>> getFulfillmentTrend({
    int? groupId,
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    try {
      final response = await _dio.get('/admin/statistics/fulfillment-trend', queryParameters: {
        if (groupId != null) 'groupId': groupId,
        'fromYear': fromYear,
        'fromMonth': fromMonth,
        'toYear': toYear,
        'toMonth': toMonth,
      });
      final data = response.data['data'] as List;
      return data.map((e) => MonthlyFulfillment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<GroupComparisonItem>> getGroupComparison(int year, int month) async {
    try {
      final response = await _dio.get('/admin/statistics/group-comparison', queryParameters: {
        'year': year,
        'month': month,
      });
      final data = response.data['data'] as List;
      return data.map((e) => GroupComparisonItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MonthlyCarryoverCount>> getCarryoverTrend({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    try {
      final response = await _dio.get('/admin/statistics/carryover-trend', queryParameters: {
        'fromYear': fromYear,
        'fromMonth': fromMonth,
        'toYear': toYear,
        'toMonth': toMonth,
      });
      final data = response.data['data'] as List;
      return data.map((e) => MonthlyCarryoverCount.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
