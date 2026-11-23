import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/page/login_page.dart';
import '../../features/home/provider/auth_provider.dart';
import 'fake_auth.dart';
import 'screen_entry.dart';

/// `AuthNotifier`가 로그인 실패 때 주는 문구 (auth_provider.dart와 같은 글자: 테스트가 대조한다)
const loginNetworkErrorMessage = '네트워크 연결을 확인해 주세요.';
const loginTooManyMessage = '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해 주세요.';
const loginFailedMessage = '로그인에 실패했습니다.';

List<Override> _auth(AuthState initial, {OnLogin? onLogin}) => [
  authProvider.overrideWith(
    (ref) => FakeAuthNotifier(initial: initial, onLogin: onLogin),
  ),
];

typedef OnLogin =
    Future<void> Function(
      FakeAuthNotifier self,
      String studentNo,
      String password,
    );

/// 눌러 볼 수 있는 가짜 서버: 2초 뒤에 학번에 따라 결과를 돌려준다
Future<void> _slowServer(
  FakeAuthNotifier self,
  String studentNo,
  String password,
) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  switch (studentNo) {
    case '1':
      self.fail(loginNetworkErrorMessage);
    case '2':
      self.fail(loginTooManyMessage);
    case '3':
      self.succeed();
    default:
      self.fail(loginFailedMessage);
  }
}

final loginScreenEntry = ScreenEntry(
  name: '로그인 (S1a)',
  description: '학번과 비밀번호로 로그인. 가입하기는 /signup, 성공하면 앱의 redirect가 /home으로 보낸다',
  path: '/login',
  builder: (_) => const LoginPage(),
  stubPaths: const ['/signup', '/home'],
  states: [
    ScreenState('초기', overrides: _auth(const AuthState())),
    ScreenState(
      '입력 오류',
      hint: '두 칸을 비운 채 로그인을 눌러 보세요 (학번 칸에 안내가 뜨고 포커스가 간다). 학번만 채우면 비밀번호 칸에 뜬다',
      overrides: _auth(const AuthState()),
    ),
    ScreenState('제출 중', overrides: _auth(const AuthState(isLoading: true))),
    ScreenState(
      '서버·네트워크 오류',
      overrides: _auth(const AuthState(errorMessage: loginNetworkErrorMessage)),
    ),
    ScreenState(
      '제한·불가 (시도 횟수 초과)',
      overrides: _auth(const AuthState(errorMessage: loginTooManyMessage)),
    ),
    ScreenState(
      '직접 눌러 보기 (가짜 서버, 2초 뒤 결과)',
      hint: '학번 1: 네트워크 오류, 2: 시도 제한, 3: 성공, 그 외: 로그인 실패',
      overrides: _auth(const AuthState(), onLogin: _slowServer),
    ),
  ],
);
