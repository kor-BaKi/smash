import 'dart:async';

import 'package:app/app.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/page/login_page.dart';
import 'package:app/features/auth/page/signup_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_pump.dart';

/// 실제 `routerProvider`(app.dart)가 인증 상태 변화에 어떻게 반응하는지.
///
/// 라우터는 "로그인 여부"가 바뀔 때만 다시 만들어져야 한다. 요청 중(isLoading)이나 오류 문구(errorMessage)가 바뀔 때마다
/// 다시 만들어지면 GoRouter가 시작 경로(/login)로 돌아가 지금 화면이 새로 만들어지고 입력이 사라진다.
/// (화면 갤러리의 가짜 라우터는 이것을 잡지 못하므로 실제 라우터로 본다)
void main() {
  setUpAll(loadPretendard);

  late FakeAuthNotifier fake;
  late WidgetRef ref;

  Future<void> start(
    WidgetTester tester, {
    AuthState initial = const AuthState(),
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    fake = FakeAuthNotifier(initial: initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((r) => fake)],
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return MaterialApp.router(routerConfig: r.watch(routerProvider));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  bool onLogin() => find.byType(LoginPage).evaluate().isNotEmpty;
  bool onSignup() => find.byType(SignupPage).evaluate().isNotEmpty;
  bool onHome() => find.byType(HomePage).evaluate().isNotEmpty;

  testWidgets('로그인하지 않았으면 처음에 로그인 화면이 열린다', (tester) async {
    await start(tester);
    expect(onLogin(), isTrue);
  });

  testWidgets('가입 화면에서 제출을 시작해도(요청 중) 가입 화면이 그대로이고 입력이 남는다', (tester) async {
    await start(tester);
    ref.read(routerProvider).push('/signup');
    await tester.pumpAndSettle();
    expect(onSignup(), isTrue);
    await tester.enterText(find.byType(TextFormField).first, 'CODE');

    fake.state = const AuthState(isLoading: true);
    await settle(tester);
    expect(onSignup(), isTrue, reason: '요청 중에도 가입 화면에 머문다');
    expect(onLogin(), isFalse);

    fake.state = const AuthState(errorMessage: '회원가입에 실패했습니다.');
    await settle(tester);
    expect(onSignup(), isTrue, reason: '실패해도 가입 화면에 머문다 (로그인 화면으로 가지 않는다)');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'CODE',
    );
  });

  testWidgets('로그인 실패 후에도 입력한 학번이 남는다', (tester) async {
    await start(tester);
    await tester.enterText(find.byType(TextField).at(0), '20250001');

    fake.state = const AuthState(isLoading: true);
    await settle(tester);
    fake.state = const AuthState(errorMessage: '로그인에 실패했습니다.');
    await settle(tester);

    expect(onLogin(), isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      '20250001',
    );
    expect(find.text('로그인에 실패했습니다.'), findsOneWidget);
  });

  testWidgets('로그인에 성공하면 /home으로 간다', (tester) async {
    await start(tester);
    fake.state = const AuthState(isLoading: true);
    await settle(tester);
    expect(onHome(), isFalse);

    fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
    await tester.pumpAndSettle();
    expect(onHome(), isTrue);
    expect(onLogin(), isFalse);
  });

  testWidgets('가입 화면에서 가입에 성공해도 /home으로 간다', (tester) async {
    await start(tester);
    ref.read(routerProvider).push('/signup');
    await tester.pumpAndSettle();
    expect(onSignup(), isTrue);

    fake.state = const AuthState(isLoading: true);
    await settle(tester);
    expect(onSignup(), isTrue);
    fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
    await tester.pumpAndSettle();

    expect(onHome(), isTrue);
    expect(onSignup(), isFalse);
  });

  testWidgets('로그아웃(로그인 → 아님)하면 로그인 화면으로 돌아온다', (tester) async {
    await start(tester, initial: AuthState(user: FakeAuthNotifier.fakeUser));
    expect(onHome(), isTrue);

    fake.state = const AuthState();
    await tester.pumpAndSettle();
    expect(onLogin(), isTrue);
    expect(onHome(), isFalse);
  });

  testWidgets('이미 로그인한 상태로 앱이 시작하면 로그인 화면이 깜빡이지 않고 /home이다', (tester) async {
    await start(tester, initial: AuthState(user: FakeAuthNotifier.fakeUser));
    expect(onHome(), isTrue);
    expect(onLogin(), isFalse);
  });

  testWidgets('로그인 화면의 자동완성 저장이 실제 라우터에서도 동작한다 (요청 시작에 화면이 다시 만들어지지 않는다)', (
    tester,
  ) async {
    await start(tester);
    // 서버 응답을 기다리는 동안 화면이 몇 번 그려진다 (실제 앱처럼)
    final response = Completer<void>();
    fake.onLogin = (self, s, p) async {
      await response.future;
      self.succeed();
    };
    await tester.enterText(find.byType(TextField).at(0), '3');
    await tester.enterText(find.byType(TextField).at(1), 'pw');
    tester.testTextInput.log.clear();

    await tester.tap(find.text('로그인').last);
    await settle(tester);
    expect(onLogin(), isTrue);
    response.complete();
    await tester.pumpAndSettle();

    final finish = tester.testTextInput.log
        .where((c) => c.method == 'TextInput.finishAutofillContext')
        .toList();
    expect(
      finish.where((c) => c.arguments == true).length,
      1,
      reason: '저장(shouldSave: true) 한 번',
    );
    expect(onHome(), isTrue);
  });
}
