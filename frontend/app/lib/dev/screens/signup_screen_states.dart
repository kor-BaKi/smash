import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_messages.dart';
import '../../features/auth/page/signup_page.dart';
import '../../features/auth/provider/signup_draft_provider.dart';
import '../../features/home/provider/auth_provider.dart';
import 'fake_auth.dart';
import 'screen_entry.dart';

/// 앞 단계를 이미 채운 입력 (뒷 단계 상태를 보여 줄 때)
const _filled = SignupDraft(
  code: 'SMASH2025',
  studentNo: '20250001',
  password: '',
);

List<Override> _overrides(
  AuthState initial, {
  SignupDraft draft = const SignupDraft(),
  OnSignup? onSignup,
}) => [
  authProvider.overrideWith(
    (ref) => FakeAuthNotifier(initial: initial, onSignup: onSignup),
  ),
  signupDraftProvider.overrideWith((ref) => SignupDraftNotifier(draft)),
];

typedef OnSignup =
    Future<void> Function(
      FakeAuthNotifier self,
      String code,
      String studentNo,
      String password,
    );

/// 눌러 볼 수 있는 가짜 서버: 2초 뒤에 가입코드에 따라 결과를 돌려준다
Future<void> _slowServer(
  FakeAuthNotifier self,
  String code,
  String studentNo,
  String password,
) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  if (code == 'OK') {
    self.succeed();
  } else {
    self.fail(AuthMessages.signupRejected);
  }
}

const _toPassword = [signupIdPath, signupPasswordPath];

final signupScreenEntry = ScreenEntry(
  name: '가입 3단계 (S1b)',
  description:
      '가입코드 → 학번 → 비밀번호. 단계마다 별도 경로(/signup, /signup/id, /signup/password), 가입은 3단계 제출 때 한 번',
  path: signupCodePath,
  builder: (_) => const SignupPage(),
  routes: signupRoutes,
  states: [
    ScreenState('1단계 초기', overrides: _overrides(const AuthState())),
    ScreenState(
      '입력 오류 (1단계)',
      hint: '가입코드를 비운 채 다음을 눌러 보세요. 2단계는 학번, 3단계는 비밀번호(4자 미만도)로 같은 확인을 해 보세요',
      overrides: _overrides(const AuthState()),
    ),
    ScreenState(
      '2단계 학번',
      overrides: _overrides(const AuthState(), draft: _filled),
      pushes: const [signupIdPath],
    ),
    ScreenState(
      '제출 중 (3단계)',
      overrides: _overrides(
        const AuthState(isLoading: true),
        draft: _filled.copyWith(password: 'pass1234', attempted: true),
      ),
      pushes: _toPassword,
    ),
    ScreenState(
      '가입 실패 (3단계)',
      overrides: _overrides(
        const AuthState(errorMessage: AuthMessages.signupRejected),
        draft: _filled.copyWith(password: 'pass1234', attempted: true),
      ),
      pushes: _toPassword,
    ),
    ScreenState(
      '직접 눌러 보기 (가짜 서버, 2초 뒤 결과)',
      hint: '가입코드 OK: 성공, 그 외: 가입 실패. 3단계에서 뒤로 가기, 1단계로 가기, 입력이 남는지 확인해 보세요',
      overrides: _overrides(const AuthState(), onSignup: _slowServer),
    ),
  ],
);
