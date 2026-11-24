import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 가입 흐름(가입코드 → 학번 → 비밀번호) 동안 입력한 값. **메모리에만** 두고 디스크에 저장하지 않는다.
///
/// 각 단계가 별도 화면(경로)이라, 1단계로 되돌아가거나 실패 후에도 입력이 남도록 단계들이 이 상태를 함께 쓴다.
/// 가입 화면들이 모두 사라지면(가입 화면을 나가면) 자동으로 없어진다 (autoDispose).
/// 입력창에 적은 그대로(앞뒤 공백 포함)를 담고, 공백을 지우는 것은 서버에 보내는 쪽이 한다.
@immutable
class SignupDraft {
  const SignupDraft({
    this.code = '',
    this.studentNo = '',
    this.password = '',
    this.attempted = false,
  });

  final String code;
  final String studentNo;
  final String password;

  /// 이 가입 흐름에서 가입을 요청해 본 적이 있는지 (이전 흐름이나 로그인 화면의 오류 문구가 비밀번호 단계에
  /// 미리 보이지 않게 하려는 표시). 1단계로 돌아가면 다시 false가 된다
  final bool attempted;

  SignupDraft copyWith({
    String? code,
    String? studentNo,
    String? password,
    bool? attempted,
  }) => SignupDraft(
    code: code ?? this.code,
    studentNo: studentNo ?? this.studentNo,
    password: password ?? this.password,
    attempted: attempted ?? this.attempted,
  );
}

class SignupDraftNotifier extends StateNotifier<SignupDraft> {
  SignupDraftNotifier([super.initial = const SignupDraft()]);

  void setCode(String value) => state = state.copyWith(code: value);
  void setStudentNo(String value) => state = state.copyWith(studentNo: value);
  void setPassword(String value) => state = state.copyWith(password: value);
  void setAttempted(bool value) => state = state.copyWith(attempted: value);
}

final signupDraftProvider =
    StateNotifierProvider.autoDispose<SignupDraftNotifier, SignupDraft>(
      (ref) => SignupDraftNotifier(),
    );
