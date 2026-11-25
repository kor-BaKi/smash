import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/motion.dart';
import 'package:app/dev/screens/bottom_bar_compare_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/screen_pump.dart';

/// 탭 선택 애니메이션 (비교 화면의 막대 변종): 선택 표시가 이전 칸에서 새 칸으로 옮겨 가고,
/// 아이콘과 라벨의 색과 굵기가 같은 시간에 바뀐다. 시간과 곡선은 모션 토큰(`SmashMotion.base`, `easeInOut`).
/// 동작 줄이기에서는 바로 바뀐다. 터치 영역과 스크린리더 "선택됨"은 애니메이션과 상관없다.
void main() {
  setUpAll(loadPretendard);

  final states = bottomBarCompareScreenEntry.states;
  ScreenState byLabel(String label) =>
      states.firstWhere((s) => s.label == label);

  // 선택 표시가 알약인 막대, 칸 전체인 막대(안 2), 칸 전체 알약(안 3)을 칸 수가 다른 구성에서 본다
  final cases = <(String, ScreenState)>[
    ('안 1(알약, 칸 112)', byLabel('안 1 중앙 묶음 · 부원 2탭')),
    ('현재 막대(알약) 3칸', byLabel('구성 C · 현재 막대 · 부원 3탭')),
    ('안 2(칸 전체) 5칸', byLabel("구성 A' · 안 2 큰 칸 · 임원 5탭")),
    ('안 3(칸 전체 알약) 4칸', byLabel('구성 C · 안 3 떠 있는 막대 · 임원 4탭')),
  ];

  Finder bar() => find.byKey(barVisibleKey);
  Finder cells() =>
      find.descendant(of: bar(), matching: find.byType(SmashPressable));
  Rect highlight(WidgetTester tester) =>
      tester.getRect(find.byKey(barHighlightKey));

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

  Future<void> open(
    WidgetTester tester,
    ScreenState state, {
    double width = 360,
    double scale = 1.0,
    bool reduceMotion = false,
  }) async {
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }
    await pumpScreen(
      tester,
      bottomBarCompareScreenEntry,
      state,
      conditions: ScreenConditions(width: width, textScale: scale),
    );
  }

  bool isBetween(double v, double a, double b) =>
      v > (a < b ? a : b) + 0.01 && v < (a < b ? b : a) - 0.01;

  for (final (name, state) in cases) {
    group(name, () {
      testWidgets(
        '시작 직후에는 이전 값, 중간에는 이전과 새 값 사이, 끝나면 새 값이다 (선택 표시 위치, 색, 굵기)',
        (tester) async {
          await open(tester, state);
          final start = highlight(tester);
          final startColorNew = colorOf(tester, 1);
          final startColorOld = colorOf(tester, 0);
          expect(startColorNew, SmashColors.textSecondary);
          expect(startColorOld, SmashColors.brand);
          expect(weightOf(tester, 0), 600);
          expect(weightOf(tester, 1), 400);

          await tester.tap(cells().at(1));
          await tester.pump(); // 애니메이션 시작 프레임
          expect(
            highlight(tester).left,
            closeTo(start.left, 0.5),
            reason: '시작 직후는 아직 이전 자리',
          );
          expect(colorOf(tester, 1), startColorNew);

          await tester.pump(SmashMotion.base ~/ 2);
          final mid = highlight(tester);
          // 끝 위치는 애니메이션이 끝난 뒤에 알 수 있어서 나중에 비교한다
          final midColorNew = colorOf(tester, 1);
          final midColorOld = colorOf(tester, 0);
          expect(
            midColorNew,
            isNot(anyOf(SmashColors.textSecondary, SmashColors.brand)),
            reason: '새 칸의 색이 이동 중이다',
          );
          expect(
            midColorOld,
            isNot(anyOf(SmashColors.textSecondary, SmashColors.brand)),
            reason: '이전 칸의 색도 같은 시간에 바뀌는 중이다',
          );
          expect(weightOf(tester, 1), allOf(greaterThan(400), lessThan(600)));
          expect(weightOf(tester, 0), allOf(greaterThan(400), lessThan(600)));

          await tester.pumpAndSettle();
          final end = highlight(tester);
          expect(
            isBetween(mid.left, start.left, end.left),
            isTrue,
            reason: '중간 위치 ${mid.left}는 ${start.left}와 ${end.left} 사이',
          );
          expect(
            end.left,
            greaterThan(start.left + 1),
            reason: '선택 표시가 새 칸으로 옮겨 갔다',
          );
          // 끝난 뒤 최종 값
          expect(colorOf(tester, 1), SmashColors.brand);
          expect(colorOf(tester, 0), SmashColors.textSecondary);
          expect(weightOf(tester, 1), 600);
          expect(weightOf(tester, 0), 400);
          // 선택 표시는 새 칸에 맞는다 (칸 전체 표시는 칸과 같은 자리, 알약은 칸의 가운데)
          final cell = tester.getRect(cells().at(1));
          expect(
            (end.left + end.right) / 2,
            closeTo((cell.left + cell.right) / 2, 0.5),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('선택되면 채운 아이콘으로 바뀌고 해제되면 윤곽 아이콘으로 돌아온다', (tester) async {
        await open(tester, state);
        IconData iconOf(int cell) => tester
            .widget<Icon>(
              find
                  .descendant(of: cells().at(cell), matching: find.byType(Icon))
                  .first,
            )
            .icon!;
        final firstFilled = iconOf(0); // 처음에는 첫 칸이 선택됨(채운 모양)
        final secondOutline = iconOf(1);
        expect(firstFilled, isNot(secondOutline));

        await tester.tap(cells().at(1));
        await tester.pumpAndSettle();
        final secondFilled = iconOf(1);
        final firstOutline = iconOf(0);
        expect(secondFilled, isNot(secondOutline), reason: '새로 선택된 칸은 채운 아이콘');
        expect(firstOutline, isNot(firstFilled), reason: '선택이 풀린 칸은 윤곽 아이콘');

        await tester.tap(cells().at(0));
        await tester.pumpAndSettle();
        expect(iconOf(0), firstFilled, reason: '다시 선택하면 처음 채운 아이콘');
        expect(iconOf(1), secondOutline, reason: '다시 풀리면 처음 윤곽 아이콘');
      });

      testWidgets(
        '선택 표시는 한 개뿐이고 애니메이션이 끝나면 더 이상 움직이지 않는다 (pumpAndSettle이 끝난다)',
        (tester) async {
          await open(tester, state);
          await tester.tap(cells().at(1));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 40));
            expect(find.byKey(barHighlightKey), findsOneWidget);
          }
          await tester.pumpAndSettle();
          expect(
            tester.binding.hasScheduledFrame,
            isFalse,
            reason: '끝없이 도는 애니메이션이 없다',
          );
          final settled = highlight(tester);
          await tester.pump(const Duration(seconds: 1));
          expect(highlight(tester), settled);
        },
      );

      testWidgets('동작 줄이기가 켜져 있으면 바로 최종 값이다 (한 프레임 뒤에 이미 끝)', (tester) async {
        await open(tester, state, reduceMotion: true);
        final start = highlight(tester);
        await tester.tap(cells().at(1));
        await tester.pump();
        final end = highlight(tester);
        expect(
          end.left,
          greaterThan(start.left + 1),
          reason: '선택 표시가 바로 새 칸에 있다',
        );
        final cell = tester.getRect(cells().at(1));
        expect(
          (end.left + end.right) / 2,
          closeTo((cell.left + cell.right) / 2, 0.5),
        );
        expect(colorOf(tester, 1), SmashColors.brand);
        expect(colorOf(tester, 0), SmashColors.textSecondary);
        expect(weightOf(tester, 1), 600);
        expect(weightOf(tester, 0), 400);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('터치 영역과 스크린리더 "선택됨"은 애니메이션 중에도 변하지 않는다', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester, state);
        final before = [
          for (var i = 0; i < cells().evaluate().length; i++)
            tester.getRect(cells().at(i)),
        ];
        bool selected(String text) =>
            tester
                .getSemantics(find.bySemanticsLabel(RegExp('^$text, ')))
                .flagsCollection
                .isSelected ==
            Tristate.isTrue;
        final names = ['홈', '일정'];
        expect(selected('홈'), isTrue);

        await tester.tap(cells().at(1));
        await tester.pump(); // 애니메이션 첫 프레임: 겉모습은 아직 이전이어도 "선택됨"은 이미 새 칸이다
        expect(selected('일정'), isTrue);
        expect(selected('홈'), isFalse);
        for (var step = 0; step < 5; step++) {
          for (var i = 0; i < before.length; i++) {
            final r = tester.getRect(cells().at(i));
            expect(
              r.left,
              closeTo(before[i].left, 0.01),
              reason: '칸 $i 위치(${names.length}) 불변',
            );
            expect(r.width, closeTo(before[i].width, 0.01));
            expect(r.height, closeTo(before[i].height, 0.01));
            expect(r.width, greaterThanOrEqualTo(48));
            expect(r.height, greaterThanOrEqualTo(48));
          }
          expect(selected('일정'), isTrue);
          await tester.pump(const Duration(milliseconds: 40));
        }
        await tester.pumpAndSettle();
        expect(selected('일정'), isTrue);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });

      testWidgets('애니메이션 중 오류(넘침)가 없다 (폭 320, 글자 2.0배)', (tester) async {
        await open(tester, state, width: 320, scale: 2.0);
        await tester.tap(cells().at(1));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 30));
          expect(tester.takeException(), isNull, reason: '$i번째 프레임');
        }
        await tester.pumpAndSettle();
      });

      testWidgets('끝나기 전에 다른 칸을 연달아 눌러도 마지막으로 누른 칸에서 끝난다 (오류 없음, 표시 한 개)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await open(tester, state);
        final count = cells().evaluate().length;
        final lefts = <double>[highlight(tester).left];
        // 0 → 1 → (다시) 0 → 마지막 칸 → 1 순서로 50ms 간격
        for (final target in [1, 0, count - 1, 1]) {
          await tester.tap(cells().at(target));
          await tester.pump(const Duration(milliseconds: 50));
          lefts.add(highlight(tester).left);
          expect(find.byKey(barHighlightKey), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        final firstLeft = tester.getRect(cells().first).left;
        final lastRight = tester.getRect(cells().last).right;
        for (final l in lefts) {
          expect(
            l,
            greaterThanOrEqualTo(firstLeft - 1),
            reason: '표시가 막대 왼쪽 밖으로 나가지 않는다',
          );
          expect(
            l,
            lessThanOrEqualTo(lastRight),
            reason: '표시가 막대 오른쪽 밖으로 나가지 않는다',
          );
        }
        await tester.pumpAndSettle();
        final cell = tester.getRect(cells().at(1));
        final end = highlight(tester);
        expect(
          (end.left + end.right) / 2,
          closeTo((cell.left + cell.right) / 2, 0.5),
          reason: '마지막으로 누른 칸 1',
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(RegExp('^일정, ')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(colorOf(tester, 1), SmashColors.brand);
        for (var i = 0; i < count; i++) {
          if (i == 1) continue;
          expect(
            colorOf(tester, i),
            SmashColors.textSecondary,
            reason: '이전 애니메이션의 색이 남지 않는다 (칸 $i)',
          );
          expect(weightOf(tester, i), 400);
        }
        expect(tester.binding.hasScheduledFrame, isFalse);
        handle.dispose();
      });

      testWidgets('애니메이션 중에 화면 폭이 바뀌어 다시 그려져도 오류가 없고 새 폭의 칸에 맞는다', (
        tester,
      ) async {
        await open(tester, state, width: 320);
        await tester.tap(cells().at(1));
        await tester.pump(const Duration(milliseconds: 60));
        tester.view.physicalSize = const Size(390, 844);
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(360, 844);
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        final cell = tester.getRect(cells().at(1));
        final end = highlight(tester);
        expect(
          (end.left + end.right) / 2,
          closeTo((cell.left + cell.right) / 2, 0.5),
          reason: '새 폭의 칸 1에 맞는다',
        );
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('길이와 곡선은 모션 토큰이다', () {
    test('선택 애니메이션은 SmashMotion.base(200ms)이고 권장 범위 150~250ms 안이다', () {
      expect(SmashMotion.base, const Duration(milliseconds: 200));
      expect(SmashMotion.base.inMilliseconds, inInclusiveRange(150, 250));
    });

    test('비교 화면 소스는 길이와 곡선을 직접 적지 않고 토큰만 쓴다', () {
      final source = File(
        'lib/dev/screens/bottom_bar_compare_states.dart',
      ).readAsStringSync();
      expect(source.contains('SmashMotion.base'), isTrue);
      expect(source.contains('SmashMotion.easeInOut'), isTrue);
      expect(
        source.contains('moveDuration'),
        isTrue,
        reason: '동작 줄이기 대응(모션 토큰 확장)을 쓴다',
      );
      expect(
        RegExp(r'Duration\(milliseconds:').hasMatch(source),
        isFalse,
        reason: '시간을 직접 적지 않는다',
      );
      expect(source.contains('Curves.'), isFalse, reason: '곡선을 직접 고르지 않는다');
    });
  });
}
