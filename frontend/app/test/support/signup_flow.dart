import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:app/features/auth/page/signup_page.dart';
import 'package:app/features/auth/provider/signup_draft_provider.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screen_pump.dart';

/// 앱처럼 로그인 화면(자리 표시) 위에 가입 화면이 쌓인 흐름: 1단계에서 뒤로 가면 로그인 자리 표시 화면이 보인다
final signupFlowEntry = ScreenEntry(
  name: '가입 흐름 (테스트)',
  description: '',
  path: '/login',
  builder: (_) => const SizedBox(),
  routes: () => [
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Text('LOGIN-STUB', key: ValueKey('login-stub'))),
    ),
    ...signupRoutes(),
  ],
  stubPaths: const ['/home'],
  states: const [],
);

class SignupFlow {
  SignupFlow(this.fake, this.router);

  final FakeAuthNotifier fake;
  final GoRouter router;
}

/// 가입 흐름을 띄운다. [steps]는 로그인 화면 위에 쌓을 경로들 (기본은 1단계만)
Future<SignupFlow> openSignupFlow(
  WidgetTester tester, {
  AuthState initial = const AuthState(),
  OnSignupCall? onSignup,
  SignupDraft draft = const SignupDraft(),
  List<String> steps = const [signupCodePath],
  double width = 360,
  bool settle = true,
}) async {
  final fake = FakeAuthNotifier(initial: initial, onSignup: onSignup);
  final router = await pumpScreen(
    tester,
    signupFlowEntry,
    ScreenState(
      'test',
      overrides: [
        authProvider.overrideWith((ref) => fake),
        signupDraftProvider.overrideWith((ref) => SignupDraftNotifier(draft)),
      ],
      pushes: steps,
    ),
    settle: settle,
  );
  return SignupFlow(fake, router);
}

typedef OnSignupCall =
    Future<void> Function(
      FakeAuthNotifier self,
      String code,
      String studentNo,
      String password,
    );
