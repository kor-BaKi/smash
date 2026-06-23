import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import 'assignment.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(dioProvider));
});

class AssignmentRepository {
  AssignmentRepository(this._dio);

  final Dio _dio;

  Future<List<UnassignedMember>> getUnassignedMembers() async {
    try {
      final response = await _dio.get('/admin/members/unassigned');
      final data = response.data['data'] as List;
      return data.map((e) => UnassignedMember.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AssignmentPreview> preview() async {
    try {
      final response = await _dio.post('/admin/assignment/preview');
      return AssignmentPreview.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // C-4 정합성: confirm 호출 시점에도 preview에서 받은 previewToken/basedOnMemberIds를
  // 그대로 되돌려줘야 서버가 그 사이 변동 여부(ASSIGNMENT_CONFLICT)를 검증할 수 있다.
  Future<ConfirmResult> confirm({
    required String previewToken,
    required List<int> basedOnMemberIds,
    required List<MemberAssignment> assignments,
  }) async {
    try {
      final response = await _dio.post('/admin/assignment/confirm', data: {
        'previewToken': previewToken,
        'basedOnMemberIds': basedOnMemberIds,
        'assignments': assignments
            .map((a) => {'userId': a.userId, 'groupId': a.assignedGroupId})
            .toList(),
      });
      return ConfirmResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateMemberGroup(int userId, int groupId) async {
    try {
      await _dio.patch('/admin/members/$userId/group', data: {'groupId': groupId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
