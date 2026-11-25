import 'dart:io';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/home/model/dues_model.dart';
import 'package:app/features/home/model/group_model.dart';
import 'package:app/features/home/page/dues_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:app/features/home/provider/dues_provider.dart';
import 'package:app/features/home/provider/group_management_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';
import '../../support/screen_pump.dart';

/// 회비 관리 화면의 탭: 조 목록의 길이가 바뀌어도(0 → 3 → 4, 줄어듦) 탭 컨트롤러 오류가 나지 않는다.
///
/// 예전에는 build 안에서 TabController를 dispose한 뒤 다시 만들었고, 조가 하나라도 있으면
/// "SingleTickerProviderStateMixin ... multiple tickers were created", 이어서
/// "A TabController was used after being disposed."가 났다. 서버를 실패시켜 조가 비는 경우만 시험하면 잡히지 않는다.
///
/// 부원 6명: 1~6번. 조(groupId)는 짝수 번호는 1, 홀수 번호는 2이고 3의 배수는 미배정이다.
///   조1: 부원2, 부원4 / 조2: 부원1, 부원5 / 미배정: 부원3, 부원6 (조3 이후는 비어 있다)
class _FakeDues extends DuesNotifier {
  @override
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(
      isLoading: false,
      members: [
        for (var i = 1; i <= 6; i++)
          DuesMember(
            userId: i,
            name: '부원$i',
            studentNo: '$i',
            groupId: i % 3 == 0 ? null : (i % 2 == 0 ? 1 : 2),
            isPaid: i.isEven,
          ),
      ],
    );
  }
}

List<GroupDetail> _groups(int n) => [
  for (var i = 1; i <= n; i++)
    GroupDetail(
      id: i,
      dayOfWeek: 'MON',
      timeSlot: 'S$i',
      label: '조$i',
      memberCount: 1,
    ),
];

class _FakeGroups extends GroupManagementNotifier {
  _FakeGroups(this.loadCounts);

  /// loadAll을 부를 때마다 차례로 쓰는 조 개수 (마지막 값을 계속 쓴다)
  final List<int> loadCounts;
  int calls = 0;

  @override
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final n =
        loadCounts[calls < loadCounts.length ? calls : loadCounts.length - 1];
    calls++;
    state = state.copyWith(isLoading: false, groups: _groups(n));
  }

  /// 열려 있는 동안 조 목록이 바뀐 것처럼 만든다
  void setCount(int n) => state = state.copyWith(groups: _groups(n));
}

void main() {
  setUpAll(loadPretendard);

  late HttpClientAdapter originalAdapter;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    originalAdapter = ApiClient.instance.httpClientAdapter;
    // 가짜가 아닌 요청(기본 화면들)은 서버 실패로 둔다
    ApiClient.instance.httpClientAdapter = FakeHttpAdapter(
      (o) async => jsonResponse(500),
    );
  });
  tearDown(() => ApiClient.instance.httpClientAdapter = originalAdapter);

  /// 임원으로 홈을 띄우고 운영 탭까지 간다 (조와 회비는 가짜, [fakeProviders]가 false면 진짜 + 서버 실패)
  Future<_FakeGroups> openOps(
    WidgetTester tester,
    List<int> loadCounts, {
    bool fakeProviders = true,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final groups = _FakeGroups(loadCounts);
    final auth = FakeAuthNotifier(
      initial: AuthState(user: FakeAuthNotifier.fakeAdmin),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((r) => auth),
          if (fakeProviders) duesProvider.overrideWith((r) => _FakeDues()),
          if (fakeProviders)
            groupManagementProvider.overrideWith((r) => groups),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^운영, ')));
    await tester.pumpAndSettle();
    return groups;
  }

  Future<void> enterDues(WidgetTester tester) async {
    await tester.tap(find.text('회비 관리'));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  TabController controller(WidgetTester tester) => DefaultTabController.of(
    tester.element(
      find.descendant(
        of: find.byType(DuesPage),
        matching: find.byType(Scaffold),
      ),
    ),
  );

  List<String> tabLabels(WidgetTester tester) => tester
      .widget<TabBar>(find.byType(TabBar))
      .tabs
      .map((t) => (t as Tab).text!)
      .toList();

  Finder shown(String name) => find.text(name).hitTestable();

  group('조 목록이 있을 때 (조가 비어 있다가 채워지는 경우 포함)', () {
    testWidgets('첫 진입: 조가 0개였다가 3개로 채워지면 탭이 조1~조3과 미배정으로 생긴다', (tester) async {
      await openOps(tester, [3]);
      await enterDues(tester);
      expect(find.byType(DuesPage), findsOneWidget);
      expect(tabLabels(tester), ['조1', '조2', '조3', '미배정']);
      expect(controller(tester).length, 4);
      expect(controller(tester).index, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('나갔다 다시 들어가기를 여러 번 해도 오류가 없다 (조는 그대로 3개)', (tester) async {
      await openOps(tester, [3, 3, 3]);
      for (var i = 0; i < 3; i++) {
        await enterDues(tester);
        expect(tabLabels(tester), ['조1', '조2', '조3', '미배정'], reason: '$i번째');
        expect(tester.takeException(), isNull, reason: '$i번째');
        await back(tester);
      }
    });

    testWidgets('조 목록이 3 → 4로 바뀌어도 오류가 없고 탭이 늘어난다 (선택은 숫자 위치 그대로)', (
      tester,
    ) async {
      final groups = await openOps(tester, [3]);
      await enterDues(tester);
      await tester.tap(find.text('조2'));
      await tester.pumpAndSettle();
      expect(controller(tester).index, 1);

      groups.setCount(4);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tabLabels(tester), ['조1', '조2', '조3', '조4', '미배정']);
      expect(controller(tester).length, 5);
      expect(controller(tester).index, 1, reason: '늘어날 때는 선택한 위치가 그대로다');
      expect(shown('부원1'), findsOneWidget, reason: '조2의 부원이 보인다');
    });

    testWidgets('조 목록이 줄어 선택한 탭이 범위를 벗어나면 새 마지막 탭이 선택된다 (4 → 2)', (
      tester,
    ) async {
      final groups = await openOps(tester, [4]);
      await enterDues(tester);
      await tester.tap(find.text('미배정'));
      await tester.pumpAndSettle();
      expect(controller(tester).index, 4);
      expect(shown('부원3'), findsOneWidget);

      groups.setCount(2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tabLabels(tester), ['조1', '조2', '미배정']);
      expect(controller(tester).length, 3);
      expect(
        controller(tester).index,
        2,
        reason: '범위 밖(4)이 아니라 새 마지막 탭(미배정)이다',
      );
      expect(shown('부원3'), findsOneWidget);
      expect(shown('부원6'), findsOneWidget);
    });

    testWidgets('줄어들되 선택이 범위 안이면 그 위치를 지킨다 (4 → 3, 조1 선택)', (tester) async {
      final groups = await openOps(tester, [4]);
      await enterDues(tester);
      groups.setCount(3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller(tester).index, 0);
      expect(tabLabels(tester), ['조1', '조2', '조3', '미배정']);
    });

    testWidgets('탭을 눌러서, 밀어서 바꾸면 그 조의 부원이 보인다', (tester) async {
      await openOps(tester, [3]);
      await enterDues(tester);
      expect(shown('부원2'), findsOneWidget);
      expect(shown('부원4'), findsOneWidget);
      expect(shown('부원1'), findsNothing);

      await tester.tap(find.text('조2'));
      await tester.pumpAndSettle();
      expect(shown('부원1'), findsOneWidget);
      expect(shown('부원5'), findsOneWidget);
      expect(shown('부원2'), findsNothing);

      await tester.tap(find.text('미배정'));
      await tester.pumpAndSettle();
      expect(shown('부원3'), findsOneWidget);
      expect(shown('부원6'), findsOneWidget);

      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1500);
      await tester.pumpAndSettle();
      expect(controller(tester).index, 2, reason: '오른쪽으로 밀면 한 칸 앞(조3)');
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭이 바뀌는 중에 뒤로 가도 오류가 없다', (tester) async {
      await openOps(tester, [3]);
      await enterDues(tester);
      await tester.tap(find.text('조3'));
      await tester.pump(const Duration(milliseconds: 50));
      await back(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(DuesPage), findsNothing);
    });

    testWidgets('조가 줄어 0개가 되어도(길이 1) 탭 줄이 사라지고 전체 부원이 보인다', (tester) async {
      final groups = await openOps(tester, [3]);
      await enterDues(tester);
      await tester.tap(find.text('조2'));
      await tester.pumpAndSettle();

      groups.setCount(0);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(TabBarView), findsNothing);
      expect(controller(tester).length, 1);
      for (var i = 1; i <= 6; i++) {
        expect(shown('부원$i'), findsOneWidget, reason: '부원$i');
      }
    });

    testWidgets('조 목록이 바뀌는 중에 다시 불러와도(회비 목록 새로고침) 오류가 없다', (tester) async {
      final groups = await openOps(tester, [3, 4, 2]);
      await enterDues(tester);
      groups.setCount(4);
      await tester.pumpAndSettle();
      await tester.tap(find.text('조3'));
      await tester.pumpAndSettle();
      // 다시 불러오면 회비 목록이 로딩 중이 되어 탭 내용이 잠깐 사라졌다 돌아온다
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DuesPage)),
      );
      container.read(duesProvider.notifier).load();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tabLabels(tester).length, 5);
    });
  });

  group('조가 비어 있을 때 (서버 실패 등)', () {
    testWidgets('진짜 제공자와 서버 실패: 탭 줄 없이 열리고 나갔다 다시 들어와도 오류가 없다', (tester) async {
      await openOps(tester, [0], fakeProviders: false);
      for (var i = 0; i < 2; i++) {
        await enterDues(tester);
        expect(find.byType(DuesPage), findsOneWidget);
        expect(find.byType(TabBar), findsNothing);
        expect(controller(tester).length, 1);
        expect(tester.takeException(), isNull);
        await back(tester);
      }
    });

    testWidgets('조 0개 + 회비 목록이 있는 가짜: 길이 1이고 전체 부원이 한 목록으로 보인다', (
      tester,
    ) async {
      await openOps(tester, [0]);
      await enterDues(tester);
      expect(find.byType(TabBar), findsNothing);
      expect(controller(tester).length, 1);
      for (var i = 1; i <= 6; i++) {
        expect(shown('부원$i'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  test('소스 확인: 컨트롤러를 직접 만들거나 dispose하지 않고 DefaultTabController를 쓴다', () {
    final source = File(
      'lib/features/home/page/dues_page.dart',
    ).readAsStringSync();
    expect(source.contains('DefaultTabController('), isTrue);
    expect(
      RegExp(r'(?<!Default)TabController\(').hasMatch(source),
      isFalse,
      reason: '직접 만들지 않는다',
    );
    expect(source.contains('SingleTickerProviderStateMixin'), isFalse);
    expect(source.contains('TickerProviderStateMixin'), isFalse);
    expect(source.contains('_tabController'), isFalse);
    expect(
      source.contains('.dispose()'),
      isFalse,
      reason: 'build에서 컨트롤러를 정리하지 않는다',
    );
  });
}
