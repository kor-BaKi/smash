import 'dart:io';

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:app/features/home/page/admin_menu_page.dart';
import 'package:app/features/home/page/home_need_group_notice.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/page/legacy_tab_frame.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pixels.dart';
import '../../support/screen_pump.dart';

/// 탭 내용 자리에 놓는 가짜 화면: 만들어지고 사라지는 것을 기록한다
class _Probe extends StatefulWidget {
  const _Probe(this.tab, this.events);

  final HomeTab tab;
  final List<String> events;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.events.add('init ${widget.tab.name}');
  }

  @override
  void dispose() {
    widget.events.add('dispose ${widget.tab.name}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('TAB-${widget.tab.name}'));
}

/// 홈 셸: 탭 구성(부원 2, 운영진 3), 앱바와 프로필 버튼, 탭 전환(현재 탭만 새로 만듦), 역할 변경, 키보드, 옛 화면 바탕
void main() {
  setUpAll(loadPretendard);

  late List<String> events;

  Future<FakeAuthNotifier> open(
    WidgetTester tester, {
    UserInfo? user,
    HomeTab initialTab = HomeTab.home,
    bool probes = true,
    ScreenConditions conditions = const ScreenConditions(),
    Key? boundaryKey,
  }) async {
    events = [];
    final fake = FakeAuthNotifier(initial: AuthState(user: user));
    final entry = ScreenEntry(
      name: 'test',
      description: '',
      path: '/home',
      builder: (_) => HomePage(
        initialTab: initialTab,
        tabBuilder: probes
            ? (context, tab, user) => _Probe(tab, events)
            : buildHomeTab,
      ),
      stubPaths: const ['/login'],
      states: const [],
    );
    await pumpScreen(
      tester,
      entry,
      ScreenState('t', overrides: [authProvider.overrideWith((ref) => fake)]),
      conditions: conditions,
      boundaryKey: boundaryKey,
    );
    return fake;
  }

  SmashBottomNav nav(WidgetTester tester) =>
      tester.widget<SmashBottomNav>(find.byType(SmashBottomNav));
  List<String> labels(WidgetTester tester) =>
      nav(tester).destinations.map((d) => d.label).toList();
  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^$label, ')));
    await tester.pumpAndSettle();
  }

  group('탭 구성', () {
    test('역할별 탭 목록: 부원은 홈, 일정, 내 정보 / 운영진은 일정 다음에 운영, 내 정보는 항상 마지막', () {
      expect(homeTabsFor(isAdmin: false), [
        HomeTab.home,
        HomeTab.schedule,
        HomeTab.profile,
      ]);
      expect(homeTabsFor(isAdmin: true), [
        HomeTab.home,
        HomeTab.schedule,
        HomeTab.admin,
        HomeTab.profile,
      ]);
    });

    test(
      '탭 이름은 홈, 일정, 운영, 내 정보이고 아이콘은 선택 아이콘이 따로 있다 (내 정보는 person_outline / person)',
      () {
        expect(HomeTab.values.map((t) => t.label), ['홈', '일정', '운영', '내 정보']);
        expect(HomeTab.profile.icon, Icons.person_outline);
        expect(HomeTab.profile.selectedIcon, Icons.person);
        for (final tab in HomeTab.values) {
          expect(tab.selectedIcon, isNot(tab.icon), reason: tab.label);
        }
      },
    );

    testWidgets('부원: 탭 3개(홈, 일정, 내 정보), 첫 탭 선택', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeUser);
      expect(labels(tester), ['홈', '일정', '내 정보']);
      expect(nav(tester).selectedIndex, 0);
      expect(find.text('TAB-home'), findsOneWidget);
    });

    testWidgets('운영진: 탭 4개(홈, 일정, 운영, 내 정보), 운영은 일정 다음이고 내 정보가 마지막', (
      tester,
    ) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      expect(labels(tester), ['홈', '일정', '운영', '내 정보']);
    });

    testWidgets('투표, 달력, 설정 탭은 없다 (투표는 일정 안에서, 설정은 내 정보 탭에서 만난다)', (
      tester,
    ) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      for (final gone in ['투표', '달력', '설정']) {
        expect(find.bySemanticsLabel(RegExp('^$gone, ')), findsNothing);
      }
    });

    testWidgets('로그인 정보가 없으면 안내만 보인다', (tester) async {
      await open(tester);
      expect(find.text('로그인이 필요합니다'), findsOneWidget);
      expect(find.byType(SmashBottomNav), findsNothing);
    });
  });

  group('탭 전환: 현재 탭만 만들고 상태를 유지하지 않는다', () {
    testWidgets('처음에는 선택한 탭만 만들어진다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      expect(events, ['init home']);
    });

    testWidgets('다른 탭으로 가면 이전 탭은 사라지고, 돌아오면 처음부터 다시 만든다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      await select(tester, '일정');
      expect(find.text('TAB-schedule'), findsOneWidget);
      expect(find.text('TAB-home'), findsNothing);
      await select(tester, '홈');
      expect(find.text('TAB-home'), findsOneWidget);

      // 새 탭이 먼저 만들어지고 이전 탭이 나중에 정리되는 순서는 상관없다. 탭마다 만든 횟수와 정리한 횟수가 중요하다
      int count(String what) => events.where((e) => e == what).length;
      expect(count('init home'), 2, reason: '홈은 돌아올 때 새로 만든다');
      expect(count('dispose home'), 1);
      expect(count('init schedule'), 1);
      expect(count('dispose schedule'), 1);
      expect(events.length, 5);
      expect(nav(tester).selectedIndex, 0);
    });

    testWidgets('이미 선택한 탭을 다시 눌러도 다시 만들지 않는다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      await select(tester, '홈');
      expect(events, ['init home']);
    });

    testWidgets('운영 탭까지 모두 눌러 볼 수 있다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      for (final label in ['일정', '운영', '내 정보', '홈']) {
        await select(tester, label);
        expect(
          nav(tester).destinations[nav(tester).selectedIndex].label,
          label,
        );
      }
    });
  });

  group('역할이 바뀌어 탭 수가 달라질 때 선택이 범위를 벗어나지 않는다', () {
    testWidgets('운영진 → 부원 (4 → 3탭): 운영 탭에 있었다면 홈으로 돌아간다', (tester) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.admin,
      );
      expect(nav(tester).selectedIndex, 2);

      fake.setUser(FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(labels(tester), ['홈', '일정', '내 정보']);
      expect(nav(tester).selectedIndex, 0);
      expect(find.text('TAB-home'), findsOneWidget);
    });

    testWidgets('운영진 → 부원: 내 정보 탭에 있었다면 칸 번호는 3에서 2로 바뀌어도 내 정보가 그대로 선택된다', (
      tester,
    ) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.profile,
      );
      expect(nav(tester).selectedIndex, 3);
      fake.setUser(FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(labels(tester), ['홈', '일정', '내 정보']);
      expect(nav(tester).selectedIndex, 2);
      expect(find.text('TAB-profile'), findsOneWidget);
    });

    testWidgets('운영진 → 부원: 운영이 아닌 탭에 있었다면 그 탭이 그대로다', (tester) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.schedule,
      );
      expect(nav(tester).selectedIndex, 1);

      fake.setUser(FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(labels(tester).length, 3);
      expect(nav(tester).selectedIndex, 1);
      expect(find.text('TAB-schedule'), findsOneWidget);
    });

    testWidgets('부원 → 운영진 (3 → 4탭): 선택은 그대로이고 운영 탭이 일정 다음에 생긴다', (
      tester,
    ) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeUser,
        initialTab: HomeTab.schedule,
      );
      fake.setUser(FakeAuthNotifier.fakeAdmin);
      await tester.pumpAndSettle();

      expect(labels(tester), ['홈', '일정', '운영', '내 정보']);
      expect(nav(tester).selectedIndex, 1);
    });

    testWidgets('부원 → 운영진: 내 정보 탭에 있었다면 칸 번호는 2에서 3으로 바뀌어도 내 정보가 그대로 선택된다', (
      tester,
    ) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeUser,
        initialTab: HomeTab.profile,
      );
      expect(nav(tester).selectedIndex, 2);
      fake.setUser(FakeAuthNotifier.fakeAdmin);
      await tester.pumpAndSettle();
      expect(labels(tester), ['홈', '일정', '운영', '내 정보']);
      expect(nav(tester).selectedIndex, 3);
      expect(find.text('TAB-profile'), findsOneWidget);
    });

    testWidgets('운영 탭에서 부원이 되었다가 다시 운영진이 되어도 운영 탭이 되살아나지 않는다 (홈에 머문다)', (
      tester,
    ) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.admin,
      );
      fake.setUser(FakeAuthNotifier.fakeUser);
      await tester.pumpAndSettle();
      fake.setUser(FakeAuthNotifier.fakeAdmin);
      await tester.pumpAndSettle();

      expect(nav(tester).selectedIndex, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('로그아웃(사용자 없음)이 되어도 오류 없이 안내로 바뀐다', (tester) async {
      final fake = await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.admin,
      );
      fake.state = const AuthState();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('로그인이 필요합니다'), findsOneWidget);
    });
  });

  group('키보드와 상태 표시줄', () {
    testWidgets('키보드가 올라오면 탭 막대가 숨고, 내려가면 다시 보인다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeUser);
      expect(find.byType(SmashBottomNav), findsOneWidget);
    });

    testWidgets('키보드가 올라온 조건에서는 탭 막대가 없다', (tester) async {
      await open(
        tester,
        user: FakeAuthNotifier.fakeUser,
        conditions: const ScreenConditions(
          keyboardHeight: ScreenConditions.keyboardUp,
        ),
      );
      expect(find.byType(SmashBottomNav), findsNothing);
    });

    testWidgets('상태 표시줄 아이콘은 밝은 셸에 맞게 어둡다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeUser);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, SmashSystemUi.light);
      expect(region.value.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('셸이 앱바를 하나 그린다: 제목은 지금 탭 이름이고 탭을 바꾸면 따라 바뀐다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      String title() =>
          tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title;
      expect(find.byType(SmashAppBar), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(title(), '홈');
      await select(tester, '일정');
      expect(title(), '일정');
      await select(tester, '운영');
      expect(title(), '운영');
      await select(tester, '내 정보');
      expect(title(), '내 정보');
    });

    testWidgets('앱바에는 프로필 버튼도 뒤로 가기도 없다 (모든 탭, 내 정보 탭 포함)', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, user: FakeAuthNotifier.fakeAdmin);
      for (final label in ['홈', '일정', '운영', '내 정보']) {
        await select(tester, label);
        expect(
          find.descendant(
            of: find.byType(SmashAppBar),
            matching: find.byType(SmashIconButton),
          ),
          findsNothing,
          reason: label,
        );
        expect(
          find.descendant(
            of: find.byType(SmashAppBar),
            matching: find.byType(SmashAvatar),
          ),
          findsNothing,
          reason: label,
        );
        expect(find.bySemanticsLabel('뒤로'), findsNothing, reason: label);
      }
      handle.dispose();
    });

    test('프로필 버튼 소스와 진입 경로가 없다 (파일이 없고 홈 셸이 부르지 않는다)', () {
      expect(
        File('lib/features/home/page/home_profile_button.dart').existsSync(),
        isFalse,
      );
      final home = File(
        'lib/features/home/page/home_page.dart',
      ).readAsStringSync();
      expect(home.contains('HomeProfileButton'), isFalse);
      expect(home.contains('profileBuilder'), isFalse);
      expect(
        home.contains('MaterialPageRoute'),
        isFalse,
        reason: '내 정보는 쌓는 화면이 아니라 탭이다',
      );
    });
  });

  group('옛 화면 탭의 바탕 (밝은 셸 안에서 흰 글자가 읽히도록)', () {
    testWidgets('홈 탭 내용(옛 화면)은 어두운 바탕 틀 안에 놓인다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeUser, probes: false);
      expect(find.byType(NeedGroupNotice), findsOneWidget);
      final frame = find.ancestor(
        of: find.byType(NeedGroupNotice),
        matching: find.byType(LegacyTabFrame),
      );
      expect(frame, findsOneWidget);
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(of: frame, matching: find.byType(ColoredBox))
                  .first,
            )
            .color,
        AppColors.bg,
      );
    });

    testWidgets('홈 탭의 빈 자리는 실제로 어두운 색으로 그려진다 (밝은 셸 색이 아니다)', (tester) async {
      const boundary = ValueKey('shell-shot');
      await open(
        tester,
        user: FakeAuthNotifier.fakeUser,
        probes: false,
        boundaryKey: boundary,
      );
      final pixel = await readPixels(tester, boundary);
      // 안전 영역(위 44)과 앱바(56) 아래 왼쪽 위 모서리
      final color = pixel(5, 110);
      expect(colorDistance(color, AppColors.bg), lessThan(25));
      expect(colorDistance(color, SmashColors.background), greaterThan(10000));
    });

    testWidgets('조가 배정된 회원도 같은 틀 안에 있다 (운영 탭만 새 디자인)', (tester) async {
      await open(
        tester,
        user: FakeAuthNotifier.fakeAdmin,
        initialTab: HomeTab.admin,
        probes: false,
      );
      expect(find.byType(AdminMenuPage), findsOneWidget);
      expect(find.byType(LegacyTabFrame), findsNothing);
    });

    testWidgets(
      '조 미배정 안내 문구: 운영진은 운영 탭을 안내하고(Drawer가 없어졌다), 회원은 가능 요일 제출 버튼이 있다',
      (tester) async {
        await open(tester, user: FakeAuthNotifier.fakeAdmin, probes: false);
        expect(find.text('운영 탭에서 운영 기능을 이용할 수 있습니다.'), findsOneWidget);
        expect(find.textContaining('왼쪽 상단'), findsNothing);
        expect(find.text('가능 요일 제출하기'), findsNothing);
      },
    );

    testWidgets('조 미배정 회원에게는 가능 요일 제출 버튼이 보인다', (tester) async {
      await open(tester, user: FakeAuthNotifier.fakeUser, probes: false);
      expect(find.text('참여 가능한 요일을 먼저 제출해주세요.'), findsOneWidget);
      expect(find.text('가능 요일 제출하기'), findsOneWidget);
    });

    test('옛 화면(홈, 일정 안의 달력과 투표, 프로필 안의 설정)은 모두 틀을 쓴다 (소스 확인)', () {
      int uses(String path) => RegExp(
        r'LegacyTabFrame\(',
      ).allMatches(File(path).readAsStringSync()).length;
      expect(uses('lib/features/home/page/home_page.dart'), 1, reason: '홈');
      expect(
        uses('lib/features/home/page/schedule_tab.dart'),
        1,
        reason: '달력과 투표',
      );
      expect(
        uses('lib/features/home/page/profile_page.dart'),
        1,
        reason: '내 정보 탭의 옛 설정',
      );
    });
  });
}
