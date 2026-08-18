import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/application_api.dart';
import '../model/application_model.dart';

class ApplicationState {
  final ApplicationFormInfo? form;
  final List<ApplicationInfo> applications;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const ApplicationState({
    this.form,
    this.applications = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  ApplicationState copyWith({
    ApplicationFormInfo? form,
    List<ApplicationInfo>? applications,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ApplicationState(
      form: form ?? this.form,
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class ApplicationNotifier extends StateNotifier<ApplicationState> {
  ApplicationNotifier() : super(const ApplicationState());

  // 폼 + 지원서 목록 로드
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final formData = await ApplicationApi.getForm();
      final listData = await ApplicationApi.getApplications();

      state = state.copyWith(
        form: ApplicationFormInfo.fromJson(formData),
        applications: listData
            .map((json) => ApplicationInfo.fromJson(json))
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      print('application load error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '데이터를 불러오지 못했습니다.',
      );
    }
  }

  // 합격 처리 (낙관적 업데이트)
  Future<void> accept(int applicationId) async {
    final original = state.applications;
    state = state.copyWith(
      applications: state.applications
          .map(
            (a) => a.id == applicationId
                ? ApplicationInfo.fromJson({
                    'id': a.id,
                    'name': a.name,
                    'studentNo': a.studentNo,
                    'department': a.department,
                    'phone': a.phone,
                    'availabilities': a.availabilities,
                    'status': 'ACCEPTED',
                    'memo': a.memo,
                    'createdAt': a.createdAt,
                  })
                : a,
          )
          .toList(),
    );
    try {
      await ApplicationApi.accept(applicationId);
    } catch (e) {
      state = state.copyWith(
        applications: original,
        errorMessage: '합격 처리에 실패했습니다.',
      );
    }
  }

  // 불합격 처리 (낙관적 업데이트)
  Future<void> reject(int applicationId) async {
    final original = state.applications;
    state = state.copyWith(
      applications: state.applications
          .map(
            (a) => a.id == applicationId
                ? ApplicationInfo.fromJson({
                    'id': a.id,
                    'name': a.name,
                    'studentNo': a.studentNo,
                    'department': a.department,
                    'phone': a.phone,
                    'availabilities': a.availabilities,
                    'status': 'REJECTED',
                    'memo': a.memo,
                    'createdAt': a.createdAt,
                  })
                : a,
          )
          .toList(),
    );
    try {
      await ApplicationApi.reject(applicationId);
    } catch (e) {
      state = state.copyWith(
        applications: original,
        errorMessage: '불합격 처리에 실패했습니다.',
      );
    }
  }

  // 메모 수정
  Future<void> updateMemo(int applicationId, String memo) async {
    try {
      await ApplicationApi.updateMemo(applicationId, memo);
      state = state.copyWith(
        applications: state.applications
            .map(
              (a) => a.id == applicationId
                  ? ApplicationInfo.fromJson({
                      'id': a.id,
                      'name': a.name,
                      'studentNo': a.studentNo,
                      'department': a.department,
                      'phone': a.phone,
                      'availabilities': a.availabilities,
                      'status': a.status,
                      'memo': memo,
                      'createdAt': a.createdAt,
                    })
                  : a,
            )
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '메모 저장에 실패했습니다.');
    }
  }

  // 폼 활성/비활성 토글
  Future<void> toggleForm(bool isActive) async {
    try {
      await ApplicationApi.toggleForm(isActive);
      if (state.form != null) {
        await load();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '폼 상태 변경에 실패했습니다.');
    }
  }
}

final applicationProvider =
    StateNotifierProvider<ApplicationNotifier, ApplicationState>((ref) {
      return ApplicationNotifier();
    });
