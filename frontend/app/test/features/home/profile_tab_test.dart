import 'dart:io';

import 'package:app/app.dart';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/page/profile_page.dart';
import 'package:app/features/home/page/setting_page.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../support/fake_http.dart';
import '../../support/screen_pump.dart';

/// "내 정보" 하단 탭: 옛 설정 내용이 탭 안에 보이고(쌓는 화면이 아니다), 뒤로 가기 화살표와 프로필 버튼이 없고,
/// 탭을 오가면 기존 탭과 같게 처음부터 다시 만든다 (탭 상태를 유지하지 않는다).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    await loadPretendard();
  });

  late HttpClientAdapter originalAdapter;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    originalAdapter = ApiClient.instance.httpClientAdapter;
    ApiClient.instance.httpClientAdapter = FakeHttpAdapter(
      (o) async => jsonResponse(500),
    );
  });
  tearDown(() => ApiClient.instance.httpClientAdapter = originalAdapter);

  Future<FakeAuthNotifier> openHome(WidgetTester tester, UserInfo user) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final fake = FakeAuthNotifier(initial: AuthState(user: user));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((r) => fake)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ko', 'KR'),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^$label, ')));
    await tester.pumpAndSettle();
  }

  group('내 정보 탭의 내용', () {
    testWidgets('옛 설정 화면이 탭 안에 보인다 (비밀번호 변경, 로그아웃, 회원 탈퇴)', (tester) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      await select(tester, '내 정보');
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(SettingPage), findsOneWidget);
      expect(find.text('로그아웃'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('회원 탈퇴'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('회원 탈퇴'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('쌓는 화면이 아니라 탭이다: 화면이 하나 더 쌓이지 않고(뒤로 갈 곳이 없다) 하단 탭 막대가 그대로 있다', (
      tester,
    ) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      NavigatorState navigator() =>
          tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator().canPop(), isFalse);
      await select(tester, '내 정보');
      expect(navigator().canPop(), isFalse, reason: '내 정보를 열어도 쌓인 화면이 없다');
      expect(find.byType(SmashBottomNav), findsOneWidget);
      expect(
        tester
            .widget<SmashBottomNav>(find.byType(SmashBottomNav))
            .selectedIndex,
        2,
      );
    });

    testWidgets('앱바 제목은 "내 정보"이고 뒤로 가기 화살표가 없다 (탭의 첫 화면)', (tester) async {
      final handle = tester.ensureSemantics();
      await openHome(tester, FakeAuthNotifier.fakeUser);
      await select(tester, '내 정보');
      final appBar = tester.widget<SmashAppBar>(find.byType(SmashAppBar));
      expect(appBar.title, '내 정보');
      expect(appBar.onBack, isNull);
      expect(
        find.descendant(
          of: find.byType(SmashAppBar),
          matching: find.byType(SmashIconButton),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('뒤로'), findsNothing);
      handle.dispose();
    });

    testWidgets('프로필 버튼이 없다: 앱바에 이름 첫 글자 원이 없고, 홈에도 앱바 버튼이 없다', (tester) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      for (final label in ['홈', '일정', '내 정보']) {
        await select(tester, label);
        expect(
          find.descendant(
            of: find.byType(SmashAppBar),
            matching: find.byType(SmashAvatar),
          ),
          findsNothing,
          reason: label,
        );
      }
    });

    testWidgets('운영진은 내 정보가 4번째(마지막) 탭이고 같은 내용이 보인다', (tester) async {
      await openHome(tester, FakeAuthNotifier.fakeAdmin);
      final nav = tester.widget<SmashBottomNav>(find.byType(SmashBottomNav));
      expect(nav.destinations.map((d) => d.label), ['홈', '일정', '운영', '내 정보']);
      await select(tester, '내 정보');
      expect(nav.destinations.length, 4);
      expect(find.byType(SettingPage), findsOneWidget);
      expect(
        tester
            .widget<SmashBottomNav>(find.byType(SmashBottomNav))
            .selectedIndex,
        3,
      );
    });
  });

  group('탭을 오가면 기존 탭과 같게 처음부터 다시 만든다 (상태를 유지하지 않는다)', () {
    testWidgets('일정 탭의 달력: 다음 달로 넘겼다가 다른 탭에 갔다 오면 이번 달로 돌아와 있다', (
      tester,
    ) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      await select(tester, '일정');
      String header() => tester
          .widgetList<Text>(find.textContaining('년'))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .firstWhere((t) => t.contains('월'), orElse: () => '');
      final thisMonth = header();
      expect(thisMonth, isNotEmpty);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(header(), isNot(thisMonth));

      await select(tester, '내 정보');
      await select(tester, '일정');
      expect(find.byType(TableCalendar), findsOneWidget);
      expect(header(), thisMonth, reason: '탭을 오가면 달력이 처음 상태(이번 달)로 다시 만들어진다');
    });

    testWidgets('내 정보 탭: 아래로 스크롤했다가 다른 탭에 갔다 오면 맨 위에서 다시 시작한다', (tester) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      await select(tester, '내 정보');
      ScrollableState scrollable() => tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SettingPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable().position.pixels, 0);
      await tester.drag(find.byType(SettingPage), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(scrollable().position.pixels, greaterThan(0));

      await select(tester, '홈');
      await select(tester, '내 정보');
      expect(
        scrollable().position.pixels,
        0,
        reason: '탭을 오가면 내 정보가 처음부터 다시 만들어진다',
      );
    });

    testWidgets('같은 탭을 다시 눌러도 다시 만들지 않는다 (스크롤이 그대로)', (tester) async {
      await openHome(tester, FakeAuthNotifier.fakeUser);
      await select(tester, '내 정보');
      await tester.drag(find.byType(SettingPage), const Offset(0, -400));
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(SettingPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
      await select(tester, '내 정보');
      final after = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(SettingPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
      expect(after, before);
    });
  });

  group('실제 routerProvider 경로', () {
    Future<GoRouter> startApp(WidgetTester tester, UserInfo user) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      late WidgetRef ref;
      final fake = FakeAuthNotifier(initial: AuthState(user: user));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((r) => fake)],
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return MaterialApp.router(
                theme: AppTheme.dark(),
                locale: const Locale('ko', 'KR'),
                routerConfig: r.watch(routerProvider),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ref.read(routerProvider);
    }

    testWidgets('로그인한 채 시작하면 /home이고, 내 정보 탭을 눌러도 경로는 /home이다 (탭은 경로가 아니다)', (
      tester,
    ) async {
      final router = await startApp(tester, FakeAuthNotifier.fakeUser);
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(HomePage), findsOneWidget);
      await select(tester, '내 정보');
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(SettingPage), findsOneWidget);
      expect(
        tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title,
        '내 정보',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('임원도 같은 경로로 홈에서 내 정보 탭까지 간다', (tester) async {
      await startApp(tester, FakeAuthNotifier.fakeAdmin);
      await select(tester, '내 정보');
      expect(find.byType(SettingPage), findsOneWidget);
    });
  });

  test('소스 확인: 프로필 버튼 파일이 없고 내 정보 탭은 LegacyTabFrame으로 옛 설정을 감싼다', () {
    expect(
      File('lib/features/home/page/home_profile_button.dart').existsSync(),
      isFalse,
    );
    final source = File(
      'lib/features/home/page/profile_page.dart',
    ).readAsStringSync();
    expect(source.contains('LegacyTabFrame'), isTrue);
    expect(source.contains('SettingPage'), isTrue);
    expect(source.contains('SmashScaffold'), isFalse, reason: '앱바는 셸이 그린다');
    expect(source.contains('Navigator'), isFalse, reason: '쌓지 않는다');
  });
}
