import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

/// 화면 전체를 차지하는 위젯(Scaffold 등)을 위한 틀. 하네스와 달리 가운데 정렬/폭 제한이 없다.
Widget screen(Widget home, {double textScale = 1.0}) => MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: home,
    );

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 800), double topInset = 0, double bottomInset = 0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(top: topInset, bottom: bottomInset);
  tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: bottomInset);
  addTearDown(tester.view.reset);
}

const _tabs = [
  SmashNavDestination(label: '홈', icon: Icons.home_outlined, selectedIcon: Icons.home),
  SmashNavDestination(label: '일정', icon: Icons.calendar_today_outlined),
  SmashNavDestination(label: '내 정보', icon: Icons.person_outline),
];

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder f) => tester.getSemantics(f).getSemanticsData();

  group('SmashSystemUi', () {
    test('밝은 배경용: 상태 표시줄과 내비게이션 바 아이콘은 어둡다 (Android, iOS 모두)', () {
      final s = SmashSystemUi.light;
      expect(s.statusBarIconBrightness, Brightness.dark);
      expect(s.statusBarBrightness, Brightness.light);
      expect(s.systemNavigationBarIconBrightness, Brightness.dark);
      expect(s.statusBarColor, Colors.transparent);
      expect(s.systemNavigationBarColor, SmashColors.surface);
    });

    testWidgets('SmashScaffold와 SmashAppBar가 이 모양을 영역으로 적용한다', (tester) async {
      await tester.pumpWidget(screen(const SmashScaffold(appBar: SmashAppBar(title: '제목'), body: SizedBox())));

      final regions = tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
          .where((r) => r.value == SmashSystemUi.light);
      expect(regions.length, greaterThanOrEqualTo(2));
    });
  });

  group('SmashAppBar', () {
    testWidgets('onBack이 없으면 뒤로 가기 버튼이 없고, 있으면 눌렀을 때 불린다', (tester) async {
      await tester.pumpWidget(screen(const SmashScaffold(appBar: SmashAppBar(title: '홈'), body: SizedBox())));
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      var backs = 0;
      await tester.pumpWidget(screen(SmashScaffold(
        appBar: SmashAppBar(title: '상세', onBack: () => backs++),
        body: const SizedBox(),
      )));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backs, 1);
    });

    testWidgets('뒤로 가기 버튼은 "뒤로"로 읽히고 터치 영역이 48이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(screen(SmashScaffold(
        appBar: SmashAppBar(title: '상세', onBack: () {}),
        body: const SizedBox(),
      )));

      expect(find.bySemanticsLabel('뒤로'), findsOneWidget);
      expect(tester.getSize(find.byType(SmashIconButton)), const Size(48, 48));
      handle.dispose();
    });

    testWidgets('높이는 56에 상태 표시줄 높이가 더해진다', (tester) async {
      sizeScreen(tester, topInset: 44);
      await tester.pumpWidget(screen(const SmashScaffold(appBar: SmashAppBar(title: '제목'), body: SizedBox())));

      expect(tester.getSize(find.byType(SmashAppBar)).height, 56 + 44);
      // 제목은 상태 표시줄 아래에 있다
      expect(tester.getTopLeft(find.text('제목')).dy, greaterThanOrEqualTo(44));
    });

    testWidgets('제목은 제목(heading)으로 읽히고, 길면 한 줄 말줄임이며 글자 2.0배에서도 56 안에 있다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(screen(
        SmashScaffold(
          appBar: SmashAppBar(title: '이번 달에 참여하지 못한 날을 이월로 채우는 활동 목록 화면', onBack: () {}),
          body: const SizedBox(),
        ),
        textScale: 2.0,
      ));

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.textContaining('이번 달에'));
      expect([text.maxLines, text.overflow], [1, TextOverflow.ellipsis]);
      expect(tester.getSize(find.byType(SmashAppBar)).height, 56);
      expect(semanticsOf(tester, find.bySemanticsLabel(RegExp('이번 달에'))).flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('actions는 오른쪽에 놓이고 눌린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(screen(SmashScaffold(
        appBar: SmashAppBar(
          title: '활동',
          actions: [SmashIconButton(icon: Icons.add, semanticLabel: '추가', onPressed: () => taps++)],
        ),
        body: const SizedBox(),
      )));

      expect(tester.getTopLeft(find.byIcon(Icons.add)).dx, greaterThan(tester.getTopRight(find.text('활동')).dx));
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });

    testWidgets('showDivider false이면 아래 선이 없다', (tester) async {
      Future<bool> hasBottomBorder(bool show) async {
        await tester.pumpWidget(screen(SmashScaffold(
          appBar: SmashAppBar(title: '제목', showDivider: show),
          body: const SizedBox(),
        )));
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(SmashAppBar), matching: find.byType(DecoratedBox)).first,
        );
        return (box.decoration as BoxDecoration).border != null;
      }

      expect(await hasBottomBorder(true), isTrue);
      expect(await hasBottomBorder(false), isFalse);
    });
  });

  group('SmashBottomBar', () {
    testWidgets('홈 인디케이터 영역(아래 안전 영역)만큼 비워 둔다', (tester) async {
      sizeScreen(tester, bottomInset: 34);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: SizedBox(),
        bottom: SmashBottomBar(child: SizedBox(height: 52, child: Text('저장'))),
      )));

      final bar = tester.getRect(find.byType(SmashBottomBar));
      final content = tester.getRect(find.text('저장'));
      expect(bar.bottom, 800);
      expect(bar.bottom - content.bottom, greaterThanOrEqualTo(34 + 16 - 1));
    });

    testWidgets('키보드가 올라오면 키보드 위에 붙는다', (tester) async {
      sizeScreen(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: SizedBox.expand(),
        bottom: SmashBottomBar(child: SizedBox(height: 52)),
      )));

      expect(tester.getRect(find.byType(SmashBottomBar)).bottom, lessThanOrEqualTo(800 - 300));
    });

    testWidgets('키보드가 올라오면 홈 인디케이터 여백은 사라진다 (키보드 위에 여백이 이중으로 남지 않는다)', (tester) async {
      sizeScreen(tester, bottomInset: 34);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: SizedBox.expand(),
        bottom: SmashBottomBar(child: SizedBox(height: 52, child: Text('저장'))),
      )));

      final bar = tester.getRect(find.byType(SmashBottomBar));
      expect(bar.bottom, 500);
      expect(bar.bottom - tester.getRect(find.text('저장')).bottom, 16);
    });

    testWidgets('키보드가 올라와도 본문은 막대 위 남은 높이를 한 번만 줄인다 (이중 차감 없음)', (tester) async {
      sizeScreen(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: SizedBox.expand(key: Key('body')),
        bottom: SmashBottomBar(child: SizedBox(height: 52, child: Text('저장'))),
      )));

      // 화면 800 - 키보드 300 - 막대(52 + 위아래 16, 선 1)
      final bar = tester.getRect(find.byType(SmashBottomBar));
      expect(bar.bottom, 500);
      expect(tester.getSize(find.byKey(const Key('body'))).height, closeTo(bar.top, 0.5));
    });

    testWidgets('막대가 키보드 높이를 이미 반영했으므로 본문은 키보드 높이(viewInsets)를 다시 받지 않는다', (tester) async {
      sizeScreen(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      double? seen;
      await tester.pumpWidget(screen(SmashScaffold(
        body: Builder(builder: (c) {
          seen = MediaQuery.viewInsetsOf(c).bottom;
          return const SizedBox.expand();
        }),
        bottom: const SmashBottomBar(child: SizedBox(height: 52)),
      )));

      expect(seen, 0);
    });

    testWidgets('막대가 화면 폭 전체로 펼쳐진다 (안쪽이 좁아도)', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: SizedBox(),
        bottom: SmashBottomBar(child: SizedBox(height: 52, child: Text('저장'))),
      )));

      expect(tester.getSize(find.byType(SmashBottomBar)).width, 400);
    });
  });

  group('SmashScaffold', () {
    testWidgets('배경색은 기본이 SmashColors.background이고 바꿀 수 있다', (tester) async {
      await tester.pumpWidget(screen(const SmashScaffold(body: SizedBox())));
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, SmashColors.background);

      await tester.pumpWidget(screen(const SmashScaffold(body: SizedBox(), backgroundColor: SmashColors.surface)));
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, SmashColors.surface);
    });

    testWidgets('앱바가 없으면 본문이 상태 표시줄을 피하고, 있으면 앱바가 피한다', (tester) async {
      sizeScreen(tester, topInset: 44);
      await tester.pumpWidget(screen(const SmashScaffold(body: Align(alignment: Alignment.topLeft, child: Text('본문')))));
      expect(tester.getTopLeft(find.text('본문')).dy, greaterThanOrEqualTo(44));

      await tester.pumpWidget(screen(const SmashScaffold(
        appBar: SmashAppBar(title: '제목'),
        body: Align(alignment: Alignment.topLeft, child: Text('본문')),
      )));
      expect(tester.getTopLeft(find.text('본문')).dy, 56 + 44);
    });

    testWidgets('bottom이 있으면 본문은 막대 바로 위까지 쓰고 아래 안전 영역을 또 피하지 않는다', (tester) async {
      sizeScreen(tester, bottomInset: 34);
      await tester.pumpWidget(screen(const SmashScaffold(
        body: Align(alignment: Alignment.bottomLeft, child: Text('본문')),
        bottom: SmashBottomBar(child: SizedBox(height: 52)),
      )));

      expect(
        tester.getBottomLeft(find.text('본문')).dy,
        closeTo(tester.getTopLeft(find.byType(SmashBottomBar)).dy, 0.5),
      );
    });

    testWidgets('bottom이 없으면 본문이 아래 안전 영역을 피한다', (tester) async {
      sizeScreen(tester, bottomInset: 34);
      await tester.pumpWidget(screen(const SmashScaffold(body: Align(alignment: Alignment.bottomLeft, child: Text('본문')))));

      expect(tester.getBottomLeft(find.text('본문')).dy, lessThanOrEqualTo(800 - 34));
    });
  });

  group('SmashBottomNav', () {
    Widget nav({int selected = 0, ValueChanged<int>? onSelected, List<SmashNavDestination> tabs = _tabs, double width = 400}) =>
        smashHarness(
          SmashBottomNav(destinations: tabs, selectedIndex: selected, onSelected: onSelected ?? (_) {}),
          width: width,
        );

    testWidgets('탭을 누르면 그 위치가 전달되고, 이미 선택된 탭도 전달된다', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(nav(onSelected: taps.add));

      await tester.tap(find.text('일정'));
      await tester.tap(find.text('홈'));
      await tester.pump();

      expect(taps, [1, 0]);
    });

    testWidgets('선택은 색뿐 아니라 아이콘(채워진 모양), 굵은 글자, 알약으로도 구분된다', (tester) async {
      await tester.pumpWidget(nav(selected: 0));

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(
        tester.widget<Text>(find.text('홈')).style!.fontWeight,
        isNot(tester.widget<Text>(find.text('일정')).style!.fontWeight),
      );
      final pill = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.byIcon(Icons.home), matching: find.byType(AnimatedContainer)),
      );
      expect((pill.decoration as BoxDecoration).color, SmashColors.brandTint);
    });

    testWidgets('스크린리더: 라벨, 몇 번째/전체, 선택됨, 버튼', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(nav(selected: 1));

      final selected = semanticsOf(tester, find.bySemanticsLabel('일정, 2/3'));
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(selected.flagsCollection.isButton, isTrue);
      expect(
        semanticsOf(tester, find.bySemanticsLabel('홈, 1/3')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('배지: 숫자가 보이고 99를 넘으면 99+, 스크린리더는 "새 항목 n개"로 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(nav(tabs: const [
        SmashNavDestination(label: '홈', icon: Icons.home_outlined),
        SmashNavDestination(label: '임원', icon: Icons.shield_outlined, badgeCount: 120),
        SmashNavDestination(label: '일정', icon: Icons.event, badgeCount: 3),
      ]));

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('임원, 2/3, 새 항목 99+개'), findsOneWidget);
      expect(find.bySemanticsLabel('일정, 3/3, 새 항목 3개'), findsOneWidget);
      expect(find.bySemanticsLabel('홈, 1/3'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('높이는 64 이상, 탭 5개가 좁은 폭(320)에서도 각 48 이상의 너비를 가진다', (tester) async {
      await tester.pumpWidget(nav(
        width: 320,
        tabs: [for (var i = 0; i < 5; i++) SmashNavDestination(label: '탭$i', icon: Icons.circle_outlined)],
      ));

      expect(tester.getSize(find.byType(SmashBottomNav)).height, greaterThanOrEqualTo(64));
      for (final item in tester.widgetList<SmashPressable>(find.byType(SmashPressable))) {
        expect(item.minSize.width, greaterThanOrEqualTo(48));
        expect(item.minSize.height, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(find.byType(SmashPressable).first).width, 64);
    });

    testWidgets('라벨은 글자 확대를 1.3배까지만 따라가고, 2.0배에서도 넘치지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashBottomNav(
          destinations: [for (var i = 0; i < 5; i++) SmashNavDestination(label: '활동기록$i', icon: Icons.circle_outlined)],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        textScale: 2.0,
        width: 320,
      ));

      expect(tester.takeException(), isNull);
      final scaler = MediaQuery.textScalerOf(tester.element(find.text('활동기록0')));
      expect(scaler.scale(10), closeTo(13, 0.001));
    });

    testWidgets('햅틱: 다른 탭으로 바꿀 때만 울리고 이미 선택된 탭에서는 울리지 않는다', (tester) async {
      final haptics = captureHaptics(tester);
      await tester.pumpWidget(nav(selected: 0));

      await tester.tap(find.text('홈'));
      await tester.pump();
      expect(haptics, isEmpty);

      await tester.tap(find.text('일정'));
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    test('탭은 2~5개만 허용한다', () {
      expect(
        () => SmashBottomNav(destinations: _tabs.take(1).toList(), selectedIndex: 0, onSelected: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => SmashBottomNav(
          destinations: [for (var i = 0; i < 6; i++) _tabs[0]],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('SmashTabShell', () {
    testWidgets('탭을 누르면 화면(호스트)이 선택을 바꾸고 본문이 따라 바뀐다', (tester) async {
      await tester.pumpWidget(screen(const _ShellHost()));
      expect(find.text('본문 0'), findsOneWidget);

      await tester.tap(find.text('일정'));
      await tester.pump();

      expect(find.text('본문 1'), findsOneWidget);
      expect(find.text('본문 0'), findsNothing);
    });

    testWidgets('키보드가 올라오면 탭 막대를 숨기고 내려가면 다시 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(screen(const _ShellHost()));
      expect(find.byType(SmashBottomNav), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(find.byType(SmashBottomNav), findsNothing);

      tester.view.resetViewInsets();
      await tester.pump();
      expect(find.byType(SmashBottomNav), findsOneWidget);
    });

    testWidgets('appBar를 주면 함께 그려진다', (tester) async {
      await tester.pumpWidget(screen(SmashTabShell(
        destinations: _tabs,
        selectedIndex: 0,
        onSelected: (_) {},
        appBar: const SmashAppBar(title: '홈'),
        body: const SizedBox(),
      )));

      expect(find.byType(SmashAppBar), findsOneWidget);
    });
  });
}

class _ShellHost extends StatefulWidget {
  const _ShellHost();

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  int index = 0;

  @override
  Widget build(BuildContext context) => SmashTabShell(
        destinations: _tabs,
        selectedIndex: index,
        onSelected: (i) => setState(() => index = i),
        body: Center(child: Text('본문 $index')),
      );
}
