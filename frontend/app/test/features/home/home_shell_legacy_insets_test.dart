import 'package:app/core/api/api_client.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:app/features/home/page/admin_menu_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/page/profile_page.dart';
import 'package:app/features/home/page/setting_page.dart';
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

/// 홈 셸 안에서 진짜 옛 탭 화면(서버는 가짜로 실패)이 아래 안전 영역(홈 인디케이터)을 두 번 비우지 않는다.
///
/// 하단 탭이 아래 안전 영역을 맡으므로 탭 안쪽의 옛 화면은 아래 inset을 받지 않아야 한다.
/// 예전에는 옛 달력/설정 화면의 자기 SafeArea가 34를 또 비워서 iPhone 16 Pro급 기기에서 5줄 달 달력이 넘쳤다.
///
/// 일정 탭의 달력은 셸 앱바(56)와 "달력 | 투표" 전환이 위에 생겨 쓸 높이가 줄었다. 그래서 옛 달력을 세로로 스크롤되게 감싼
/// 임시 처치가 들어 있고(S5에서 달력을 새로 만들 때 제거), 4/5/6줄 달이 어느 기기 크기에서도 넘치지 않는지 여기서 확인한다.
/// (처치 전에는 6줄 달과 iPhone SE처럼 작은 화면에서 이전부터 넘쳤다)
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

  final member = UserInfo(
    id: 1,
    name: '회원',
    role: 'MEMBER',
    groupId: 1,
    studentNo: '1',
  );

  /// 화면 크기와 안전 영역을 정해 홈 셸(진짜 탭 화면)을 띄운다
  Future<void> open(
    WidgetTester tester,
    HomeTab tab, {
    UserInfo? user,
    Size size = const Size(402, 874),
    double top = 62,
    double bottom = 34,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final fake = FakeAuthNotifier(initial: AuthState(user: user ?? member));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((r) => fake)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ko', 'KR'),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(top: top, bottom: bottom),
              viewPadding: EdgeInsets.only(top: top, bottom: bottom),
            ),
            child: app!,
          ),
          home: HomePage(initialTab: tab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// table_calendar 기본(일요일 시작) 기준 그 달이 몇 줄인지
  int rowsOf(int year, int month) {
    final offset = DateTime(year, month, 1).weekday % 7;
    final days = DateTime(year, month + 1, 0).day;
    return ((offset + days) / 7).ceil();
  }

  /// 오늘 달에서 가장 가까운, [rows]줄인 달까지 몇 달을 움직여야 하는지 (오늘 달이 이미 맞으면 0)
  int monthsToNearest(int rows) {
    final now = DateTime.now();
    for (var d = 0; d <= 12; d++) {
      for (final delta in d == 0 ? [0] : [d, -d]) {
        final t = DateTime(now.year, now.month + delta);
        // 달력 범위(2020~2030) 안만
        if (t.year < 2020 || t.year > 2030) continue;
        if (rowsOf(t.year, t.month) == rows) return delta;
      }
    }
    throw StateError('가까운 $rows줄 달이 없다');
  }

  Future<void> goMonths(WidgetTester tester, int delta) async {
    final icon = delta > 0 ? Icons.chevron_right : Icons.chevron_left;
    for (var i = 0; i < delta.abs(); i++) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
    }
  }

  /// 오류 보고를 가로채서 [body] 동안의 오류를 모은다 (본문 안에서 반드시 되돌린다)
  Future<List<String>> capture(
    Future<void> Function(List<String> errors) body,
  ) async {
    final errors = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    try {
      await body(errors);
    } finally {
      FlutterError.onError = original;
    }
    return errors;
  }

  /// 목표 달에 도착한 뒤의 넘침만 센다. 이동하면서 지나친 달(6줄 달은 이전부터 넘친다)의 오류는 버리고,
  /// 화면 크기를 1픽셀 바꿔 다시 배치시켜서 지금 보이는 달의 넘침만 새로 보고받는다
  Future<List<String>> overflowsAtTarget(
    WidgetTester tester,
    List<String> errors,
  ) async {
    errors.clear();
    final size = tester.view.physicalSize;
    tester.view.physicalSize = Size(size.width + 1, size.height);
    await tester.pumpAndSettle();
    tester.view.physicalSize = size;
    await tester.pumpAndSettle();
    return errors.where((e) => e.contains('overflowed')).toList();
  }

  group('일정 탭의 달력: 줄 수를 아는 달로 옮겨서 확인 (날짜와 무관)', () {
    // (이름, 크기, 위 안전 영역, 아래 안전 영역)
    const devices = <(String, Size, double, double)>[
      ('iPhone 16 Pro', Size(402, 874), 62, 34),
      ('iPhone 15', Size(393, 852), 59, 34),
      ('Android 360×800', Size(360, 800), 24, 0),
      ('Android 360×640', Size(360, 640), 24, 0),
      ('iPhone SE', Size(375, 667), 20, 0),
      ('갤러리 320×568', Size(320, 568), 44, 34),
    ];
    for (final d in devices) {
      for (final rows in [4, 5, 6]) {
        testWidgets('${d.$1}: $rows줄 달이 넘치지 않는다', (tester) async {
          late List<String> overflows;
          await capture((errors) async {
            await open(
              tester,
              HomeTab.schedule,
              size: d.$2,
              top: d.$3,
              bottom: d.$4,
            );
            await goMonths(tester, monthsToNearest(rows));
            overflows = await overflowsAtTarget(tester, errors);
          });
          expect(find.byType(TableCalendar), findsOneWidget);
          expect(
            overflows,
            isEmpty,
            reason: overflows.join('\n').split('\n').take(4).join(' | '),
          );
        });
      }
    }

    testWidgets('달력 아래 줄까지 스크롤로 닿는다 (높이가 모자란 기기: 6줄 달)', (tester) async {
      await capture((errors) async {
        await open(
          tester,
          HomeTab.schedule,
          size: const Size(360, 640),
          top: 24,
          bottom: 0,
        );
        await goMonths(tester, monthsToNearest(6));
      });
      final view = tester.view.physicalSize.height;
      final nav = tester.getRect(find.byType(SmashBottomNav));
      expect(nav.top, lessThan(view));
      // 달력을 끌어 올리면 마지막 줄(말일이 있는 줄)이 탭 막대 위에 나타난다
      // (손가락이 놓이는 곳은 화면 안이어야 하므로 달력 위젯이 아니라 화면에 보이는 스크롤 영역을 끈다)
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.pixels, greaterThan(0), reason: '세로로 스크롤된다');
      expect(
        scroll.position.pixels,
        scroll.position.maxScrollExtent,
        reason: '끝까지 닿는다 (마지막 줄이 탭 막대 위에 보인다)',
      );
    });

    testWidgets('달력 동작은 그대로다: 좌우로 밀면 달이 바뀌고 날짜를 누르면 선택된다', (tester) async {
      await capture((errors) async {
        await open(tester, HomeTab.schedule);
      });
      String header() => tester
          .widgetList<Text>(find.textContaining('년'))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .firstWhere((t) => t.contains('월'), orElse: () => '');
      final before = header();
      await tester.flingFrom(
        tester.getTopLeft(find.byType(TableCalendar)) + const Offset(180, 150),
        const Offset(-400, 0),
        1500,
      );
      await tester.pumpAndSettle();
      final after = header();
      expect(after, isNot(before), reason: '왼쪽으로 밀면 다음 달');
      await tester.flingFrom(
        tester.getTopLeft(find.byType(TableCalendar)) + const Offset(180, 150),
        const Offset(400, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(header(), before, reason: '오른쪽으로 밀면 돌아온다');

      final calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
      final today = DateTime.now();
      final target = DateTime(
        today.year,
        today.month,
        today.day == 15 ? 16 : 15,
      );
      expect(calendar.selectedDayPredicate!(target), isFalse);
      await tester.tap(find.text('${target.day}').first);
      await tester.pumpAndSettle();
      final selected = tester.widget<TableCalendar>(find.byType(TableCalendar));
      expect(
        selected.selectedDayPredicate!(target),
        isTrue,
        reason: '누른 날짜가 선택된다',
      );
    });

    testWidgets('달력의 세로 제스처는 꺼져 있다 (스크롤과 겹치지 않는다)', (tester) async {
      await capture((errors) async {
        await open(tester, HomeTab.schedule);
      });
      expect(
        tester
            .widget<TableCalendar>(find.byType(TableCalendar))
            .availableGestures,
        AvailableGestures.horizontalSwipe,
      );
    });
  });

  group('내 정보 탭: 옛 설정 화면이 안전 영역을 두 번 비우지 않는다', () {
    testWidgets(
      '앱바(제목 내 정보)가 있고 뒤로 가기는 없고, 옛 설정 화면의 SafeArea는 위와 아래를 또 비우지 않는다',
      (tester) async {
        await open(tester, HomeTab.profile);
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.byType(SettingPage), findsOneWidget);
        expect(find.byType(SmashAppBar), findsOneWidget);
        expect(
          tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title,
          '내 정보',
        );
        expect(find.bySemanticsLabel('뒤로'), findsNothing);

        final safeArea = find.descendant(
          of: find.byType(SettingPage),
          matching: find.byType(SafeArea),
        );
        expect(safeArea, findsOneWidget);
        final padding = tester
            .widget<Padding>(
              find
                  .descendant(of: safeArea, matching: find.byType(Padding))
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect(padding.top, 0, reason: '앱바가 위 안전 영역을 맡고 있다');
        expect(padding.bottom, 0, reason: '하단 탭이 아래 안전 영역을 이미 맡고 있다');
      },
    );

    testWidgets('다른 탭으로 갔다가 내 정보 탭으로 오가도 오류가 없고 선택이 따라간다', (tester) async {
      await open(tester, HomeTab.schedule);
      await tester.tap(find.bySemanticsLabel(RegExp('^내 정보, ')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(
        tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title,
        '내 정보',
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^일정, ')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsNothing);
      expect(tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title, '일정');
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭 막대는 여전히 아래 안전 영역(34)을 자기 안쪽에서 비운다', (tester) async {
      await open(tester, HomeTab.home);
      final nav = tester.getRect(find.byType(SmashBottomNav));
      expect(nav.bottom, 874);
      expect(nav.height, greaterThan(34 + 48));
    });
  });

  group('운영 탭 (새 디자인 ListView)', () {
    testWidgets('아래 여백은 명시한 값(24)뿐이다: 끝까지 스크롤하면 마지막 항목이 탭 막대 위 24에서 끝난다', (
      tester,
    ) async {
      await open(tester, HomeTab.admin, user: FakeAuthNotifier.fakeAdmin);
      await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
      final labels = adminMenuSections
          .expand((s) => s.items)
          .map((i) => i.label)
          .toList();
      final last = tester.getRect(find.text(labels.last));
      final nav = tester.getRect(find.byType(SmashBottomNav));
      final lastRow = tester.getRect(
        find
            .ancestor(
              of: find.text(labels.last),
              matching: find.byType(SmashListRow),
            )
            .first,
      );
      expect(last.bottom, lessThan(nav.top));
      expect(
        nav.top - lastRow.bottom,
        closeTo(24, 0.5),
        reason: 'ListView에 명시한 아래 여백(SmashSpacing.lg)뿐이다',
      );
    });
  });

  group('안전 영역이 없는 기기', () {
    testWidgets('아래 inset 0인 기기에서도 달력과 탭 막대 위치가 그대로다 (회귀 없음)', (tester) async {
      await open(
        tester,
        HomeTab.schedule,
        size: const Size(360, 800),
        top: 24,
        bottom: 0,
      );
      final nav = tester.getRect(find.byType(SmashBottomNav));
      expect(nav.bottom, 800);
      expect(find.byType(TableCalendar), findsOneWidget);
    });
  });
}
