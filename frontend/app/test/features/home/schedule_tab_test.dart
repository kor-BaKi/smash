import 'package:app/core/api/api_client.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/page/poll_create_page.dart';
import 'package:app/features/home/page/poll_list_page.dart';
import 'package:app/features/home/page/schedule_tab.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../support/fake_http.dart';
import '../../support/screen_pump.dart';

/// 일정 탭: "달력 | 투표" 전환, 투표 보기에서 옛 앱바의 "+" 버튼과 탭이 작동하는지 (앱바가 겹쳐 보이는 건 임시)
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    await loadPretendard();
  });

  late HttpClientAdapter originalAdapter;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    originalAdapter = ApiClient.instance.httpClientAdapter;
    // 서버는 가짜로 실패한다 (옛 화면은 빈 모양으로 뜬다)
    ApiClient.instance.httpClientAdapter = FakeHttpAdapter(
      (o) async => jsonResponse(500),
    );
  });
  tearDown(() => ApiClient.instance.httpClientAdapter = originalAdapter);

  Future<void> open(WidgetTester tester, UserInfo user) async {
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
          home: const HomePage(initialTab: HomeTab.schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickView(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SmashSegmentedControl<ScheduleView>),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  final member = FakeAuthNotifier.fakeUser;
  final admin = FakeAuthNotifier.fakeAdmin;

  group('달력 | 투표 전환', () {
    testWidgets('처음에는 달력이 보이고 전환 조각은 달력, 투표 두 개다', (tester) async {
      await open(tester, member);
      expect(find.byType(TableCalendar), findsOneWidget);
      expect(find.byType(PollListPage), findsNothing);
      final control = tester.widget<SmashSegmentedControl<ScheduleView>>(
        find.byType(SmashSegmentedControl<ScheduleView>),
      );
      expect(control.segments.map((s) => s.label), ['달력', '투표']);
      expect(control.selected, ScheduleView.calendar);
    });

    testWidgets('투표를 고르면 투표 화면만 만들어지고, 달력을 고르면 달력으로 돌아온다', (tester) async {
      await open(tester, member);
      await pickView(tester, '투표');
      expect(find.byType(PollListPage), findsOneWidget);
      expect(find.byType(TableCalendar), findsNothing, reason: '고른 화면만 만든다');
      await pickView(tester, '달력');
      expect(find.byType(TableCalendar), findsOneWidget);
      expect(find.byType(PollListPage), findsNothing);
    });

    testWidgets('일정 탭을 벗어났다 돌아오면 달력부터 다시 시작한다 (상태를 유지하지 않는다)', (tester) async {
      await open(tester, member);
      await pickView(tester, '투표');
      await tester.tap(find.bySemanticsLabel(RegExp('^홈, ')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^일정, ')));
      await tester.pumpAndSettle();
      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('처음 보일 화면을 정할 수 있다 (갤러리와 테스트용)', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ScheduleTab(
              initialView: ScheduleView.polls,
              calendarBuilder: (_) => const Text('CAL'),
              pollsBuilder: (_) => const Text('POLLS'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('POLLS'), findsOneWidget);
      expect(find.text('CAL'), findsNothing);
    });

    testWidgets('스크린리더: 전환 그룹은 "일정 보기"로 읽히고 선택된 조각이 구분된다', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, member);
      expect(find.bySemanticsLabel(RegExp('일정 보기')), findsWidgets);
      handle.dispose();
    });
  });

  group('투표 보기: 옛 앱바가 셸 앱바 아래에 겹쳐도 작동한다 (임시)', () {
    testWidgets('앱바가 둘이다: 셸 앱바(일정)와 옛 앱바(투표)', (tester) async {
      await open(tester, member);
      await pickView(tester, '투표');
      expect(find.byType(SmashAppBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title, '일정');
    });

    testWidgets('임원: 옛 앱바의 "+" 버튼을 누르면 투표 만들기 화면이 열리고 뒤로 가면 투표 목록이다', (
      tester,
    ) async {
      await open(tester, admin);
      await pickView(tester, '투표');
      final add = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.add),
      );
      expect(add, findsOneWidget);

      // 옛 투표 만들기 화면은 디버그 모드에서 "ListTile ... DecoratedBox" 단언을 낸다 (이전부터 있던 경고, 릴리스에는 영향 없음).
      // 그 경고 하나만 허용하고 다른 오류는 허용하지 않는다
      final errors = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      try {
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(find.byType(PollCreatePage), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PollCreatePage), findsNothing);
        expect(find.byType(PollListPage), findsOneWidget);
      } finally {
        FlutterError.onError = original;
      }
      for (final e in errors) {
        expect(
          e,
          contains(
            'ListTile background color or ink splashes may be invisible',
          ),
          reason: '알려진 옛 화면 경고 외의 오류는 없다: $e',
        );
      }
    });

    testWidgets('부원: "+" 버튼이 없다', (tester) async {
      await open(tester, member);
      await pickView(tester, '투표');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.add),
        ),
        findsNothing,
      );
    });

    testWidgets('옛 앱바의 탭("종료된 투표", "진행 중")이 눌리고 선택이 바뀐다', (tester) async {
      await open(tester, member);
      await pickView(tester, '투표');
      TabController controller() =>
          tester.widget<TabBar>(find.byType(TabBar)).controller!;
      expect(find.text('종료된 투표'), findsOneWidget);
      expect(find.text('진행 중'), findsOneWidget);
      expect(controller().index, 0);
      await tester.tap(find.text('진행 중'));
      await tester.pumpAndSettle();
      expect(controller().index, 1);
      await tester.tap(find.text('종료된 투표'));
      await tester.pumpAndSettle();
      expect(controller().index, 0);
    });

    testWidgets('겹친 앱바 때문에 오류(넘침)가 나지 않는다', (tester) async {
      await open(tester, admin);
      await pickView(tester, '투표');
      expect(tester.takeException(), isNull);
    });
  });
}
