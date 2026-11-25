import 'package:app/features/auth/auth_messages.dart';
import 'package:app/app.dart';
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

/// 라우터는 한 번만 만들어지고(refreshListenable), 로그인 여부가 바뀔 때 redirect만 다시 돈다.
/// 앱이 시작할 때 이미 로그인한 상태면 로그인 화면이 한 프레임도 그려지지 않는다.
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

  bool on(Type page) => find.byType(page).hitTestable().evaluate().isNotEmpty;

  group('같은 GoRouter 인스턴스', () {
    testWidgets('로그인과 로그아웃을 거쳐도, 요청 중/오류가 바뀌어도 같은 라우터다', (tester) async {
      await start(tester);
      final first = ref.read(routerProvider);
      var rebuilds = 0;
      ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).listen<GoRouter>(routerProvider, (previous, next) => rebuilds++);

      fake.state = const AuthState(isLoading: true);
      await tester.pump();
      fake.state = const AuthState(errorMessage: AuthMessages.loginRejected);
      await tester.pump();
      expect(
        identical(ref.read(routerProvider), first),
        isTrue,
        reason: '요청 중/오류',
      );

      fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      expect(identical(ref.read(routerProvider), first), isTrue, reason: '로그인');

      fake.state = const AuthState();
      await tester.pumpAndSettle();
      expect(on(LoginPage), isTrue);
      expect(
        identical(ref.read(routerProvider), first),
        isTrue,
        reason: '로그아웃',
      );

      fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue, reason: '다시 로그인');
      expect(identical(ref.read(routerProvider), first), isTrue);
      expect(rebuilds, 0, reason: '라우터 Provider가 다시 만들어진 적이 없다');
    });

    testWidgets('로그인하면 가입 3단계 어느 화면에 있든 /home으로 가고 쌓였던 화면은 없어진다', (
      tester,
    ) async {
      await start(tester);
      final router = ref.read(routerProvider);
      router.push('/signup');
      await tester.pumpAndSettle();
      router.push('/signup/id');
      await tester.pumpAndSettle();
      router.push('/signup/password');
      await tester.pumpAndSettle();

      fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      expect(find.byType(LoginPage, skipOffstage: false), findsNothing);
      expect(identical(ref.read(routerProvider), router), isTrue);
    });
  });

  group('가입 화면이 기준 위치일 때(go로 열림)도 로그인하면 /home이다', () {
    testWidgets('가입 화면에 있다가 로그인 상태가 되면 /home으로 간다', (tester) async {
      await start(tester);
      ref.read(routerProvider).go('/signup/id');
      await tester.pumpAndSettle();
      expect(find.text('학번을 입력해 주세요'), findsOneWidget);

      fake.state = AuthState(user: FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      expect(find.text('학번을 입력해 주세요', skipOffstage: false), findsNothing);
    });

    testWidgets('로그인한 상태에서 가입 경로를 열면 /home으로 돌려보낸다', (tester) async {
      await start(tester, initial: AuthState(user: FakeAuthNotifier.fakeUser));
      expect(on(HomePage), isTrue);
      ref.read(routerProvider).go('/signup');
      await tester.pumpAndSettle();
      expect(on(HomePage), isTrue);
      expect(find.byType(SignupPage, skipOffstage: false), findsNothing);
    });
  });

  group('시작 중 상태: 앱이 시작할 때 이미 인증이 정해져 있다', () {
    // main()은 checkToken이 끝난 뒤에 runApp을 부르므로, 화면이 처음 그려질 때 로그인 여부는 이미 정해져 있다
    // (인증 상태에 "확인 중" 단계는 없다). 라우터는 첫 화면을 그리기 전에 redirect를 적용한다
    testWidgets('로그인한 상태로 시작하면 로그인 화면이 한 프레임도 그려지지 않는다', (tester) async {
      var sawLogin = false;
      fake = FakeAuthNotifier(
        initial: AuthState(user: FakeAuthNotifier.fakeUser),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((r) => fake)],
          child: Consumer(
            builder: (context, r, _) =>
                MaterialApp.router(routerConfig: r.watch(routerProvider)),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        if (find.byType(LoginPage, skipOffstage: false).evaluate().isNotEmpty) {
          sawLogin = true;
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(sawLogin, isFalse);
      expect(on(HomePage), isTrue);
    });

    testWidgets('로그인하지 않은 상태로 시작하면 홈 화면이 한 프레임도 그려지지 않는다', (tester) async {
      var sawHome = false;
      fake = FakeAuthNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((r) => fake)],
          child: Consumer(
            builder: (context, r, _) =>
                MaterialApp.router(routerConfig: r.watch(routerProvider)),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        if (find.byType(HomePage, skipOffstage: false).evaluate().isNotEmpty) {
          sawHome = true;
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(sawHome, isFalse);
      expect(on(LoginPage), isTrue);
    });
  });
}
