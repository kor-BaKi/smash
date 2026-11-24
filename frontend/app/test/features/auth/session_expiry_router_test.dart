import 'package:app/app.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/page/login_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';
import '../../support/screen_pump.dart';

/// 실제 `routerProvider` + 실제 `AuthNotifier` + 실제 `ApiClient`(네트워크만 가짜)로, 세션이 만료되면
/// 어디에 있든(Navigator.push로 쌓은 화면, 대화상자, 시트 위) /login으로 돌아오는지 본다.
void main() {
  setUpAll(loadPretendard);

  late HttpClientAdapter originalAdapter;
  late FakeHttpAdapter main;
  late FakeHttpAdapter refresh;
  late AuthNotifier auth;
  late List<bool> loggedInChanges;

  setUp(() {
    originalAdapter = ApiClient.instance.httpClientAdapter;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'A1',
      'refresh_token': 'R1',
    });
    // 서버: 새 토큰이 아니면 401, 토큰 갱신은 서버가 거부(401)
    main = FakeHttpAdapter((o) async => jsonResponse(401));
    refresh = FakeHttpAdapter((o) async => jsonResponse(401));
    ApiClient.instance.httpClientAdapter = main;
    ApiClient.refreshAdapterForTest = refresh;
    loggedInChanges = [];
  });

  tearDown(() {
    ApiClient.instance.httpClientAdapter = originalAdapter;
    ApiClient.refreshAdapterForTest = null;
  });

  Future<GoRouterProbe> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((r) {
            auth = AuthNotifier(
              initial: AuthState(user: FakeAuthNotifier.fakeUser),
            );
            return auth;
          }),
        ],
        child: Consumer(
          builder: (context, r, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(routerConfig: r.watch(routerProvider));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    container.listen<bool>(
      authProvider.select((s) => s.isLoggedIn),
      (previous, next) => loggedInChanges.add(next),
    );
    return GoRouterProbe(container.read(routerProvider));
  }

  bool on(Type page) => find.byType(page).hitTestable().evaluate().isNotEmpty;

  /// 홈 위에 Navigator.push 화면 두 장, 대화상자, 시트를 쌓는다
  Future<void> pileUp(WidgetTester tester) async {
    final nav = Navigator.of(tester.element(find.byType(HomePage)));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('PUSHED-1')),
      ),
    );
    await tester.pumpAndSettle();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('PUSHED-2')),
      ),
    );
    await tester.pumpAndSettle();
    showDialog<void>(
      context: tester.element(find.text('PUSHED-2')),
      builder: (_) => const AlertDialog(content: Text('DIALOG')),
    );
    await tester.pumpAndSettle();
    expect(find.text('DIALOG'), findsOneWidget);
  }

  void expectBackAtLogin(WidgetTester tester) {
    expect(on(LoginPage), isTrue, reason: '로그인 화면');
    for (final text in ['PUSHED-1', 'PUSHED-2', 'DIALOG']) {
      expect(
        find.text(text, skipOffstage: false),
        findsNothing,
        reason: '$text 가 남아 있지 않다',
      );
    }
    expect(find.byType(HomePage, skipOffstage: false), findsNothing);
  }

  testWidgets('쌓인 화면과 대화상자 위에서 토큰 갱신이 거부되면(실제 ApiClient 경로) 로그인 화면으로 돌아온다', (
    tester,
  ) async {
    await start(tester);
    expect(on(HomePage), isTrue);
    await pileUp(tester);

    await tester.runAsync(() async {
      try {
        await ApiClient.instance.get('/me');
      } on DioException catch (_) {}
    });
    await tester.pumpAndSettle();

    expectBackAtLogin(tester);
    expect(refresh.requests.length, 1);
    expect(
      find.text(AuthNotifier.sessionExpiredMessage),
      findsOneWidget,
      reason: '왜 로그인 화면인지 알려 준다',
    );
    expect(loggedInChanges, [false]);
  });

  testWidgets('동시에 401이 여러 개여도 로그아웃은 한 번이다 (로그인 여부 변화 한 번, 갱신 요청 한 번)', (
    tester,
  ) async {
    await start(tester);
    await pileUp(tester);

    await tester.runAsync(() async {
      await Future.wait([
        for (final path in ['/me', '/polls', '/activities', '/me/x'])
          ApiClient.instance.get(path).then<void>((_) {}, onError: (_) {}),
      ]);
    });
    await tester.pumpAndSettle();

    expectBackAtLogin(tester);
    expect(refresh.requests.length, 1);
    expect(loggedInChanges, [false]);
  });

  testWidgets('만료 처리를 직접 불러도(expireSession) 같은 결과이고, 두 번 불러도 한 번만 처리한다', (
    tester,
  ) async {
    await start(tester);
    await pileUp(tester);

    auth.expireSession();
    auth.expireSession();
    await tester.pumpAndSettle();

    expectBackAtLogin(tester);
    expect(loggedInChanges, [false]);
  });

  testWidgets('만료 뒤 시스템 뒤로 가기로 이전 화면(홈, 쌓였던 화면)에 돌아갈 수 없다', (tester) async {
    await start(tester);
    await pileUp(tester);
    auth.expireSession();
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expectBackAtLogin(tester);
  });

  testWidgets('갱신이 서버 거부가 아니면(네트워크 오류) 로그아웃하지 않고 화면이 그대로다', (tester) async {
    await start(tester);
    await pileUp(tester);
    refresh = FakeHttpAdapter(
      (o) async => throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline',
      ),
    );
    ApiClient.refreshAdapterForTest = refresh;

    await tester.runAsync(() async {
      try {
        await ApiClient.instance.get('/me');
      } on DioException catch (_) {}
    });
    await tester.pumpAndSettle();

    expect(find.text('DIALOG'), findsOneWidget);
    expect(on(LoginPage), isFalse);
    expect(loggedInChanges, isEmpty);
  });

  testWidgets('만료로 돌아온 로그인 화면에서 다시 로그인하면 /home으로 간다 (같은 라우터)', (tester) async {
    final probe = await start(tester);
    auth.expireSession();
    await tester.pumpAndSettle();
    expect(on(LoginPage), isTrue);

    auth.state = AuthState(user: FakeAuthNotifier.fakeUser);
    await tester.pumpAndSettle();
    expect(on(HomePage), isTrue);
    expect(
      identical(
        ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
        ).read(routerProvider),
        probe.router,
      ),
      isTrue,
    );
  });
}

class GoRouterProbe {
  GoRouterProbe(this.router);
  final Object router;
}
