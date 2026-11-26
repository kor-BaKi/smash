import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_pump.dart';

/// 실제 `SmashBottomNav`의 선택 애니메이션: 알약이 이전 칸에서 새 칸으로 옮겨 가고, 아이콘과 라벨의 색과 굵기가 같은 시간에 바뀐다.
/// 시간과 곡선은 모션 토큰(`SmashMotion.base`, `easeInOut`), 동작 줄이기에서는 바로 바뀐다.
/// 칸 위치와 크기, 터치 영역, 스크린리더 "선택됨"은 애니메이션과 상관없다.
void main() {
  setUpAll(loadPretendard);

  const all = [
    SmashNavDestination(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    SmashNavDestination(
      label: '일정',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    SmashNavDestination(
      label: '운영',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
    ),
    SmashNavDestination(
      label: '내 정보',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    SmashNavDestination(
      label: '기록',
      icon: Icons.history,
      selectedIcon: Icons.history_toggle_off,
    ),
  ];

  /// 선택을 스스로 바꾸는 막대를 화면 아래에 놓는다
  Future<void> open(
    WidgetTester tester,
    int count, {
    double width = 360,
    double scale = 1.0,
    bool reduceMotion = false,
    List<SmashNavDestination>? tabs,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(scale),
            // 시스템 동작 줄이기 설정(MediaQuery.disableAnimations)
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(
            backgroundColor: SmashColors.background,
            body: const SizedBox.expand(),
            bottomNavigationBar: _Host(tabs: tabs ?? all.take(count).toList()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder nav() => find.byType(SmashBottomNav);
  Finder cells() =>
      find.descendant(of: nav(), matching: find.byType(SmashPressable));
  Rect pill(WidgetTester tester) =>
      tester.getRect(find.byKey(SmashBottomNav.highlightKey));

  RenderParagraph label(WidgetTester tester, int cell) => find
      .descendant(of: cells().at(cell), matching: find.byType(RichText))
      .evaluate()
      .map((e) => e.renderObject)
      .whereType<RenderParagraph>()
      .last;
  Color colorOf(WidgetTester tester, int cell) =>
      label(tester, cell).text.style!.color!;
  int weightOf(WidgetTester tester, int cell) =>
      label(tester, cell).text.style!.fontWeight!.value;
  IconData iconOf(WidgetTester tester, int cell) => tester
      .widget<Icon>(
        find
            .descendant(of: cells().at(cell), matching: find.byType(Icon))
            .first,
      )
      .icon!;

  double centerX(Rect r) => (r.left + r.right) / 2;
  bool isBetween(double v, double a, double b) =>
      v > (a < b ? a : b) + 0.01 && v < (a < b ? b : a) - 0.01;

  for (final count in [2, 3, 4, 5]) {
    group('칸 $count개', () {
      testWidgets('시작 직후는 이전 값, 중간은 이전과 새 값 사이, 끝나면 새 값 (알약 위치, 색, 굵기)', (
        tester,
      ) async {
        await open(tester, count);
        final start = pill(tester);
        expect(colorOf(tester, 0), SmashColors.brand);
        expect(colorOf(tester, 1), SmashColors.textSecondary);
        expect(weightOf(tester, 0), 600);
        expect(weightOf(tester, 1), 400);

        await tester.tap(cells().at(1));
        await tester.pump();
        expect(
          pill(tester).left,
          closeTo(start.left, 0.5),
          reason: '시작 직후는 아직 이전 자리',
        );
        expect(colorOf(tester, 1), SmashColors.textSecondary);

        await tester.pump(SmashMotion.base ~/ 2);
        final mid = pill(tester);
        for (final cell in [0, 1]) {
          expect(
            colorOf(tester, cell),
            isNot(anyOf(SmashColors.textSecondary, SmashColors.brand)),
            reason: '칸 $cell 색이 이동 중',
          );
          expect(
            weightOf(tester, cell),
            allOf(greaterThan(400), lessThan(600)),
            reason: '칸 $cell 굵기가 이동 중',
          );
        }

        await tester.pumpAndSettle();
        final end = pill(tester);
        expect(
          isBetween(mid.left, start.left, end.left),
          isTrue,
          reason: '중간 ${mid.left}는 ${start.left}와 ${end.left} 사이',
        );
        expect(
          centerX(end),
          closeTo(centerX(tester.getRect(cells().at(1))), 0.5),
          reason: '알약은 새 칸의 가운데',
        );
        expect(end.width, closeTo(56, 0.5), reason: '알약은 지금과 같은 56×32');
        expect(end.height, closeTo(32, 0.5));
        expect(colorOf(tester, 1), SmashColors.brand);
        expect(colorOf(tester, 0), SmashColors.textSecondary);
        expect(weightOf(tester, 1), 600);
        expect(weightOf(tester, 0), 400);
        expect(tester.takeException(), isNull);
      });

      testWidgets('알약은 한 개이고 끝나면 더 움직이지 않는다 (pumpAndSettle이 끝난다)', (
        tester,
      ) async {
        await open(tester, count);
        await tester.tap(cells().at(1));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          expect(find.byKey(SmashBottomNav.highlightKey), findsOneWidget);
        }
        await tester.pumpAndSettle();
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason: '끝없는 애니메이션이 없다',
        );
      });

      testWidgets('동작 줄이기에서는 한 프레임 만에 최종 값이다', (tester) async {
        await open(tester, count, reduceMotion: true);
        final start = pill(tester);
        await tester.tap(cells().at(1));
        await tester.pump();
        final end = pill(tester);
        expect(end.left, greaterThan(start.left + 1));
        expect(
          centerX(end),
          closeTo(centerX(tester.getRect(cells().at(1))), 0.5),
        );
        expect(colorOf(tester, 1), SmashColors.brand);
        expect(colorOf(tester, 0), SmashColors.textSecondary);
        expect(weightOf(tester, 1), 600);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('연타해도 마지막으로 누른 칸에서 끝나고 이전 값이 안 남는다 (알약 한 개, 오류 없음)', (
        tester,
      ) async {
        await open(tester, count);
        final targets = [1, 0, count - 1, 1];
        final lefts = <double>[pill(tester).left];
        for (final t in targets) {
          await tester.tap(cells().at(t));
          await tester.pump(const Duration(milliseconds: 50));
          lefts.add(pill(tester).left);
          expect(find.byKey(SmashBottomNav.highlightKey), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        final first = tester.getRect(cells().first).left;
        final last = tester.getRect(cells().last).right;
        for (final l in lefts) {
          expect(l, greaterThanOrEqualTo(first - 1));
          expect(l, lessThanOrEqualTo(last));
        }
        await tester.pumpAndSettle();
        expect(
          centerX(pill(tester)),
          closeTo(centerX(tester.getRect(cells().at(1))), 0.5),
        );
        for (var i = 0; i < count; i++) {
          expect(
            colorOf(tester, i),
            i == 1 ? SmashColors.brand : SmashColors.textSecondary,
            reason: '칸 $i',
          );
          expect(weightOf(tester, i), i == 1 ? 600 : 400);
        }
      });

      testWidgets('애니메이션 중 화면 폭이 바뀌어도 오류가 없고 새 폭의 칸에 맞는다', (tester) async {
        await open(tester, count, width: 320);
        await tester.tap(cells().at(1));
        await tester.pump(const Duration(milliseconds: 60));
        tester.view.physicalSize = const Size(390, 700);
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(
          centerX(pill(tester)),
          closeTo(centerX(tester.getRect(cells().at(1))), 0.5),
        );
      });

      testWidgets('칸 위치와 크기, 터치 영역(48 이상), 스크린리더 "선택됨"은 애니메이션 중에도 그대로다', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await open(tester, count);
        final before = [
          for (var i = 0; i < count; i++) tester.getRect(cells().at(i)),
        ];
        bool selected(String text) =>
            tester
                .getSemantics(find.bySemanticsLabel(RegExp('^$text, ')))
                .flagsCollection
                .isSelected ==
            Tristate.isTrue;
        await tester.tap(cells().at(1));
        await tester.pump(); // 첫 프레임: 겉모습은 아직 이전이어도 "선택됨"은 이미 새 칸이다
        expect(selected('일정'), isTrue);
        expect(selected('홈'), isFalse);
        for (var step = 0; step < 5; step++) {
          for (var i = 0; i < count; i++) {
            final r = tester.getRect(cells().at(i));
            expect(r.left, closeTo(before[i].left, 0.01));
            expect(r.width, closeTo(before[i].width, 0.01));
            expect(r.height, closeTo(before[i].height, 0.01));
            expect(r.width, greaterThanOrEqualTo(48));
            expect(r.height, greaterThanOrEqualTo(48));
          }
          expect(selected('일정'), isTrue);
          await tester.pump(const Duration(milliseconds: 40));
        }
        await tester.pumpAndSettle();
        handle.dispose();
      });

      testWidgets('폭 320, 글자 2.0배에서도 애니메이션 중 오류(넘침)가 없다', (tester) async {
        await open(tester, count, width: 320, scale: 2.0);
        await tester.tap(cells().at(1));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 30));
          expect(tester.takeException(), isNull, reason: '$i번째 프레임');
        }
        await tester.pumpAndSettle();
      });

      testWidgets('선택되면 채운 아이콘이 되고 풀리면 윤곽 아이콘으로 돌아온다 (아이콘 크기는 그대로 24)', (
        tester,
      ) async {
        await open(tester, count);
        final firstFilled = iconOf(tester, 0);
        final secondOutline = iconOf(tester, 1);
        double size(int cell) => tester
            .widget<Icon>(
              find
                  .descendant(of: cells().at(cell), matching: find.byType(Icon))
                  .first,
            )
            .size!;
        expect(size(0), 24);
        await tester.tap(cells().at(1));
        await tester.pump(SmashMotion.base ~/ 2);
        expect(size(1), 24, reason: '애니메이션 중에도 아이콘 크기는 그대로');
        await tester.pumpAndSettle();
        expect(iconOf(tester, 1), isNot(secondOutline));
        expect(iconOf(tester, 0), isNot(firstFilled));
        await tester.tap(cells().at(0));
        await tester.pumpAndSettle();
        expect(iconOf(tester, 0), firstFilled);
        expect(iconOf(tester, 1), secondOutline);
      });
    });
  }

  group('구현 규칙', () {
    test(
      '시간과 곡선은 모션 토큰이다: 길이는 SmashMotion.base(200ms, 권장 150~250ms), 곡선은 easeInOut 하나, 동작 줄이기 확장을 쓴다',
      () {
        expect(SmashMotion.base, const Duration(milliseconds: 200));
        expect(SmashMotion.base.inMilliseconds, inInclusiveRange(150, 250));
        final source = File(
          'lib/core/design/components/smash_bottom_nav.dart',
        ).readAsStringSync();
        expect(
          RegExp(
            r'moveDuration\(SmashMotion\.base\)',
          ).allMatches(source).length,
          2,
          reason: '알약과 칸 내용 둘 다',
        );
        expect(
          RegExp(r'curve: SmashMotion\.easeInOut').allMatches(source).length,
          2,
        );
        expect(
          RegExp(r'Duration\(milliseconds:').hasMatch(source),
          isFalse,
          reason: '시간을 직접 적지 않는다',
        );
        expect(source.contains('Curves.'), isFalse, reason: '곡선을 직접 고르지 않는다');
      },
    );

    testWidgets('알약은 아이콘과 라벨 뒤에 그려진다 (Stack의 첫 자식이고 터치를 가로채지 않는다)', (
      tester,
    ) async {
      await open(tester, 3);
      final stack = tester.widget<Stack>(
        find
            .ancestor(
              of: find.byType(AnimatedPositioned),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(stack.children.first, isA<AnimatedPositioned>());
      expect(stack.children.last, isA<Row>(), reason: '칸 줄이 알약 위에 그려진다');
      expect(
        find.descendant(
          of: find.byType(AnimatedPositioned),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    });
  });

  testWidgets('배지는 애니메이션 중에도 보이고 스크린리더 라벨이 그대로다', (tester) async {
    final handle = tester.ensureSemantics();
    await open(
      tester,
      3,
      tabs: const [
        SmashNavDestination(
          label: '홈',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        SmashNavDestination(label: '일정', icon: Icons.event, badgeCount: 3),
        SmashNavDestination(
          label: '운영',
          icon: Icons.shield_outlined,
          badgeCount: 120,
        ),
      ],
    );
    await tester.tap(cells().at(1));
    await tester.pump(SmashMotion.base ~/ 2);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(find.bySemanticsLabel('일정, 2/3, 새 항목 3개'), findsOneWidget);
    expect(find.bySemanticsLabel('운영, 3/3, 새 항목 99+개'), findsOneWidget);
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('이미 선택된 칸을 다시 눌러도 알약은 움직이지 않는다 (onSelected는 불린다)', (
    tester,
  ) async {
    await open(tester, 3);
    final start = pill(tester);
    await tester.tap(cells().at(0));
    await tester.pump(SmashMotion.base ~/ 2);
    expect(pill(tester).left, closeTo(start.left, 0.01));
    await tester.pumpAndSettle();
    expect(pill(tester).left, closeTo(start.left, 0.01));
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.tabs});

  final List<SmashNavDestination> tabs;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => SmashBottomNav(
    destinations: widget.tabs,
    selectedIndex: _selected,
    onSelected: (i) => setState(() => _selected = i),
  );
}
