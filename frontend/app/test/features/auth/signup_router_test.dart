import 'dart:async';

import 'package:app/features/auth/auth_messages.dart';
import 'package:app/app.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/page/login_page.dart';
import 'package:app/features/auth/page/signup_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/screen_pump.dart';

/// 실제 `routerProvider`에서 가입 3단계: 로그인 화면에서 들어가기, 단계 이동, 제출 중/실패에도 3단계 유지,
/// 성공하면 /home, 비로그인 redirect 규칙(가입 하위 경로 포함)
void main() {
  setUpAll(loadPretendard);

  late FakeAuthNotifier fake;

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    fake = FakeAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((r) => fake)],
        child: Consumer(
          builder: (context, r, _) {
            return MaterialApp.router(routerConfig: r.watch(routerProvider));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool on(Type page) => find.byType(page).hitTestable().evaluate().isNotEmpty;
  Finder field() => find.byType(TextField).last;
  Future<void> tapText(
    WidgetTester tester,
    String label, {
    bool settle = true,
  }) async {
    final f = find.widgetWithText(SmashButton, label).hitTestable();
    await tester.ensureVisible(f);
    await tester.tap(f);
    // 처리 중 표시는 끝없이 움직이므로 제출은 짧게만 기다린다
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> goThroughSteps(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(SmashButton, '가입하기').hitTestable(),
    ); // 로그인 화면의 가입하기
    await tester.pumpAndSettle();
    expect(on(SignupPage), isTrue);
    await tester.enterText(field(), 'CODE');
    await tapText(tester, '다음');
    await tester.enterText(field(), '2025');
    await tapText(tester, '다음');
    await tester.enterText(field(), 'pw12');
  }

  Future<String> resolve(
    WidgetTester tester,
    bool loggedIn,
    String location,
  ) async {
    late GoRouter router;
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (r) => FakeAuthNotifier(
              initial: loggedIn
                  ? AuthState(user: FakeAuthNotifier.fakeUser)
                  : const AuthState(),
            ),
          ),
        ],
        child: Consumer(
          builder: (ctx, r, _) {
            router = r.watch(routerProvider);
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    final matches = await router.routeInformationParser
        .parseRouteInformationWithDependencies(
          RouteInformation(
            uri: Uri.parse(location),
            state: RouteInformationState<void>(type: NavigatingType.go),
          ),
          context,
        );
    return matches.uri.path;
  }

  group('redirect 규칙', () {
    testWidgets('비로그인이면 가입 3단계 경로가 모두 그대로 열린다', (tester) async {
      for (final path in [signupCodePath, signupIdPath, signupPasswordPath]) {
        expect(await resolve(tester, false, path), path);
      }
    });

    testWidgets('비로그인이면 /home은 /login으로, /login은 그대로', (tester) async {
      expect(await resolve(tester, false, '/home'), '/login');
      expect(await resolve(tester, false, '/login'), '/login');
    });

    testWidgets('로그인했으면 /login은 /home으로 보낸다', (tester) async {
      expect(await resolve(tester, true, '/login'), '/home');
    });

    testWidgets('/signupX 같은 다른 경로는 가입 경로로 보지 않는다', (tester) async {
      expect(await resolve(tester, false, '/signupx'), '/login');
    });
  });

  group('실제 라우터에서의 가입 흐름', () {
    testWidgets('로그인 화면 → 3단계 제출: 제출 중과 실패에도 3단계에 머문다 (로그인 화면으로 가지 않는다)', (
      tester,
    ) async {
      await start(tester);
      fake.onSignup = (self, c, s, p) async {};
      await goThroughSteps(tester);
      await tapText(tester, '가입하기', settle: false);
      expect(on(SignupPasswordPage), isTrue, reason: '요청 중에도 3단계');
      expect(on(LoginPage), isFalse);

      fake.fail(AuthMessages.signupRejected);
      await tester.pumpAndSettle();
      expect(on(SignupPasswordPage), isTrue, reason: '실패해도 3단계');
      expect(find.text(AuthMessages.signupRejected), findsOneWidget);
      expect(fake.signupCalls, [('CODE', '2025', 'pw12')]);

      await tester.tap(find.text('1단계로 가기'));
      await tester.pumpAndSettle();
      expect(on(SignupPage), isTrue);
      expect(tester.widget<TextField>(field()).controller!.text, 'CODE');
    });

    testWidgets('가입에 성공하면 /home으로 간다 (화면이 직접 이동하지 않고 라우터가 보낸다)', (
      tester,
    ) async {
      await start(tester);
      final response = Completer<void>();
      fake.onSignup = (self, c, s, p) async {
        await response.future;
        self.succeed();
      };
      await goThroughSteps(tester);
      await tapText(tester, '가입하기', settle: false);
      expect(on(HomePage), isFalse);

      response.complete();
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      expect(on(SignupPasswordPage), isFalse);
    });

    testWidgets('1단계에서 뒤로 가면 로그인 화면으로 돌아오고, 로그인 입력은 그대로다', (tester) async {
      await start(tester);
      await tester.enterText(find.byType(TextField).first, '20250001');
      await tester.tap(find.widgetWithText(SmashButton, '가입하기').hitTestable());
      await tester.pumpAndSettle();
      expect(on(SignupPage), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(on(LoginPage), isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '20250001',
      );
    });

    testWidgets('로그인한 뒤 로그아웃하면 /login으로 돌아온다 (가입 상태와 무관)', (tester) async {
      await start(tester);
      fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      fake.state = const AuthState();
      await tester.pumpAndSettle();
      expect(on(LoginPage), isTrue);
    });
  });
}
