import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/bottom_bar_compare_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:app/dev/screens/screen_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/screen_pump.dart';

/// 하단 막대 모양 비교(개발 전용 갤러리 항목): 상태 8개, 기계 확인 행렬(폭 320/360/390 × 글자 1.0/2.0 × 키보드 없음/올라옴),
/// 그리고 안 3(떠 있는 막대)이 SmashScaffold의 아래 처리(S2b-fix에서 고친 이중 비우기)와 겹치지 않는지.
void main() {
  setUpAll(loadPretendard);

  final states = bottomBarCompareScreenEntry.states;

  const variantOf = <String, BarVariant>{
    '현재': BarVariant.current,
    '안 1 중앙 묶음': BarVariant.centered,
    '안 2 큰 칸': BarVariant.bigCell,
    '안 3 떠 있는 막대': BarVariant.floating,
  };

  (BarVariant, bool) parse(ScreenState state) {
    final parts = state.label.split(' · ');
    return (variantOf[parts[0]]!, parts[1].startsWith('임원'));
  }

  group('등록과 상태 목록', () {
    test('상태 8개: {현재, 안 1, 안 2, 안 3} × {부원 2탭, 임원 3탭}', () {
      expect(states.map((s) => s.label), [
        '현재 · 부원 2탭',
        '현재 · 임원 3탭',
        '안 1 중앙 묶음 · 부원 2탭',
        '안 1 중앙 묶음 · 임원 3탭',
        '안 2 큰 칸 · 부원 2탭',
        '안 2 큰 칸 · 임원 3탭',
        '안 3 떠 있는 막대 · 부원 2탭',
        '안 3 떠 있는 막대 · 임원 3탭',
      ]);
      expect(screenGalleryEntries, contains(bottomBarCompareScreenEntry));
    });

    test('실제 컴포넌트 SmashBottomNav는 비교 화면을 모르고(건드리지 않았고), 변종은 lib/dev에만 있다', () {
      final nav = File(
        'lib/core/design/components/smash_bottom_nav.dart',
      ).readAsStringSync();
      expect(nav.contains('BarVariant'), isFalse);
      expect(nav.contains('dev/screens'), isFalse);
      for (final path in [
        'lib/core/design/components/smash_tab_shell.dart',
        'lib/core/design/components/smash_scaffold.dart',
        'lib/features/home/page/home_page.dart',
      ]) {
        expect(
          File(path).readAsStringSync().contains('bottom_bar_compare'),
          isFalse,
          reason: '$path가 개발 전용 비교 화면을 불러오면 앱 번들에 들어간다',
        );
      }
    });
  });

  group('기계 확인 행렬', () {
    for (final state in states) {
      for (final width in ScreenConditions.widths) {
        for (final scale in [1.0, 2.0]) {
          for (final keyboard in [0.0, ScreenConditions.keyboardUp]) {
            final c = ScreenConditions(
              width: width,
              textScale: scale,
              keyboardHeight: keyboard,
            );
            testWidgets('${state.label} | $c', (tester) async {
              final (variant, admin) = parse(state);
              final handle = tester.ensureSemantics();
              await pumpScreen(
                tester,
                bottomBarCompareScreenEntry,
                state,
                conditions: c,
              );
              final height = c.height;
              final tabs = admin ? ['홈', '일정', '운영'] : ['홈', '일정'];
              final body = find.byType(ListView);

              if (keyboard > 0) {
                // 키보드가 올라오면 막대를 숨기고 본문은 키보드 위까지만 쓴다
                expect(find.byKey(barOuterKey), findsNothing);
                expect(
                  tester.getRect(body).bottom,
                  lessThanOrEqualTo(height - keyboard + 0.5),
                );
                expect(tester.takeException(), isNull);
                handle.dispose();
                return;
              }

              final outer = tester.getRect(find.byKey(barOuterKey));
              final visible = tester.getRect(find.byKey(barVisibleKey));
              final bar = find.byKey(barVisibleKey);
              final cells = find.descendant(
                of: bar,
                matching: find.byType(SmashPressable),
              );
              expect(cells, findsNWidgets(tabs.length));

              // 막대는 화면 폭 안이고 아래는 화면 끝(떠 있는 막대는 안전 영역과 여백 위)이다
              expect(visible.left, greaterThanOrEqualTo(-0.5));
              expect(visible.right, lessThanOrEqualTo(width + 0.5));
              if (variant == BarVariant.floating) {
                expect(
                  visible.bottom,
                  closeTo(
                    height -
                        ScreenConditions.safeBottom -
                        BarMetrics.floatingVerticalMargin,
                    0.5,
                  ),
                  reason: '홈 인디케이터 영역과 아래 여백 위에 뜬다',
                );
                expect(outer.bottom, closeTo(height, 0.5));
              } else {
                expect(visible.bottom, closeTo(height, 0.5));
              }

              // 본문은 막대 위까지만이고, 막대 아래 영역은 막대 하나가 맡는다 (이중으로 비우지 않는다)
              final bodyRect = tester.getRect(body);
              expect(
                bodyRect.bottom,
                closeTo(outer.top, 0.5),
                reason: '본문과 막대 사이에 빈틈도 겹침도 없다',
              );
              expect(height - bodyRect.bottom, closeTo(outer.height, 0.5));

              // 칸: 터치 영역 48 이상, 막대 안, 라벨은 한 줄이고 폭 안
              final applied = scale > 1.3 ? 1.3 : scale;
              for (var i = 0; i < tabs.length; i++) {
                final rect = tester.getRect(cells.at(i));
                expect(rect.width, greaterThanOrEqualTo(48), reason: tabs[i]);
                expect(rect.height, greaterThanOrEqualTo(48), reason: tabs[i]);
                expect(rect.left, greaterThanOrEqualTo(visible.left - 0.5));
                expect(rect.right, lessThanOrEqualTo(visible.right + 0.5));
                final paragraph = find
                    .descendant(
                      of: cells.at(i),
                      matching: find.byType(RichText),
                    )
                    .evaluate()
                    .map((e) => e.renderObject)
                    .whereType<RenderParagraph>()
                    .firstWhere(
                      (p) =>
                          p.text.toPlainText().replaceAll('⁠', '') == tabs[i],
                    );
                expect(
                  paragraph.size.height,
                  lessThan(variant.labelSize * 1.2 * applied * 1.5),
                  reason: '${tabs[i]} 한 줄',
                );
                final left = paragraph.localToGlobal(Offset.zero).dx;
                expect(left, greaterThanOrEqualTo(-0.5));
                expect(
                  left + paragraph.size.width,
                  lessThanOrEqualTo(width + 0.5),
                );
              }

              // 변종마다 정한 크기
              final n = tabs.length;
              switch (variant) {
                case BarVariant.current:
                  expect(visible.width, closeTo(width, 0.5));
                case BarVariant.centered:
                  expect(
                    visible.width,
                    closeTo(width, 0.5),
                    reason: '막대는 전체 폭',
                  );
                  final cell = tester.getRect(cells.first).width;
                  expect(
                    cell,
                    closeTo(
                      width / n < BarMetrics.centeredCell
                          ? width / n
                          : BarMetrics.centeredCell,
                      0.5,
                    ),
                  );
                  final pill = tester.getRect(find.byKey(barHighlightKey));
                  expect(
                    pill.width,
                    closeTo(56, 0.5),
                    reason: '선택 표시는 지금과 같은 알약',
                  );
                  expect(pill.height, closeTo(32, 0.5));
                  final group =
                      tester.getRect(cells.last).right -
                      tester.getRect(cells.first).left;
                  expect(
                    (tester.getRect(cells.first).left + group / 2),
                    closeTo(width / 2, 0.5),
                    reason: '항목 묶음이 가운데에 있다',
                  );
                case BarVariant.bigCell:
                  expect(visible.width, closeTo(width, 0.5));
                  expect(
                    outer.height,
                    closeTo(
                      BarMetrics.bigCellHeight + ScreenConditions.safeBottom,
                      1.0,
                    ),
                    reason: '안 2 막대 높이는 72 + 아래 안전 영역(34)이다 (칸 56 + 위아래 여백 8씩)',
                  );
                  final highlight = tester.getRect(find.byKey(barHighlightKey));
                  expect(
                    highlight.width,
                    closeTo(tester.getRect(cells.first).width, 0.5),
                    reason: '선택 표시가 칸 전체다',
                  );
                  // 아이콘과 라벨이 가로로 나란히 놓인다 (모든 조건에서 칸 안에 들어간다)
                  final icon = tester.getRect(
                    find
                        .descendant(
                          of: cells.first,
                          matching: find.byType(Icon),
                        )
                        .first,
                  );
                  final text = find
                      .descendant(
                        of: cells.first,
                        matching: find.byType(RichText),
                      )
                      .evaluate()
                      .map((e) => e.renderObject)
                      .whereType<RenderParagraph>()
                      .firstWhere(
                        (p) =>
                            p.text.toPlainText().replaceAll('\u2060', '') ==
                            tabs.first,
                      );
                  expect(
                    text.localToGlobal(Offset.zero).dx,
                    greaterThanOrEqualTo(icon.right - 0.5),
                    reason: '라벨이 아이콘 오른쪽에 있다',
                  );
                case BarVariant.floating:
                  expect(
                    visible.width,
                    closeTo(
                      width - 32 < n * BarMetrics.floatingCellMax
                          ? width - 32
                          : n * BarMetrics.floatingCellMax,
                      0.5,
                    ),
                  );
                  expect(
                    (visible.left + visible.right) / 2,
                    closeTo(width / 2, 0.5),
                    reason: '가운데 정렬',
                  );
                  final floatingHighlight = tester.getRect(
                    find.byKey(barHighlightKey),
                  );
                  expect(
                    floatingHighlight.width,
                    closeTo(tester.getRect(cells.first).width, 0.5),
                    reason: '선택 표시가 칸 전체 알약이다',
                  );
                  expect(
                    outer.height,
                    closeTo(
                      BarMetrics.floatingHeight +
                          BarMetrics.floatingVerticalMargin * 2 +
                          ScreenConditions.safeBottom,
                      0.5,
                    ),
                  );
              }

              // 선택 표시: 알약/칸 채움(현재 막대는 컴포넌트 안의 알약), 굵은 글자, 스크린리더 "선택됨"이 선택된 칸 하나에만
              if (variant != BarVariant.current) {
                expect(find.byKey(barHighlightKey), findsOneWidget);
              }
              FontWeight? weightOf(String label) => find
                  .descendant(of: bar, matching: find.byType(RichText))
                  .evaluate()
                  .map((e) => e.renderObject)
                  .whereType<RenderParagraph>()
                  .firstWhere(
                    (p) => p.text.toPlainText().replaceAll('⁠', '') == label,
                  )
                  .text
                  .style
                  ?.fontWeight;
              expect(
                weightOf('홈'),
                isNot(weightOf('일정')),
                reason: '선택된 칸은 글자 굵기도 다르다',
              );
              bool isSelected(String label) =>
                  tester
                      .getSemantics(find.bySemanticsLabel(RegExp('^$label, ')))
                      .flagsCollection
                      .isSelected ==
                  Tristate.isTrue;
              expect(isSelected('홈'), isTrue);
              expect(isSelected('일정'), isFalse);

              // 칸을 누르면 선택과 앱바 제목이 바뀐다
              await tester.tap(cells.at(1));
              await tester.pumpAndSettle();
              expect(isSelected('일정'), isTrue);
              expect(isSelected('홈'), isFalse);
              expect(
                tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title,
                '일정',
              );

              // 맨 아래까지 스크롤하면 마지막 카드가 막대 위에 보인다 (막대에 가려지지 않는다)
              await tester.drag(body, const Offset(0, -3000));
              await tester.pumpAndSettle();
              final last = tester.getRect(
                find.byKey(const ValueKey('compare-last-card')),
              );
              expect(last.bottom, lessThanOrEqualTo(outer.top + 0.5));
              expect(tester.takeException(), isNull);
              handle.dispose();
            });
          }
        }
      }
    }
  });

  group('안 3(떠 있는 막대)과 SmashScaffold의 아래 처리 (이중 비우기 방지)', () {
    final floatingStates = states.where(
      (s) => parse(s).$1 == BarVariant.floating,
    );

    for (final state in floatingStates) {
      for (final width in ScreenConditions.widths) {
        testWidgets('${state.label} | 폭 $width: 아래 안전 영역을 막대 안쪽 한 곳에서만 비운다', (
          tester,
        ) async {
          final c = ScreenConditions(width: width);
          await pumpScreen(
            tester,
            bottomBarCompareScreenEntry,
            state,
            conditions: c,
          );
          final height = c.height;
          final outer = tester.getRect(find.byKey(barOuterKey));
          final visible = tester.getRect(find.byKey(barVisibleKey));
          final body = tester.getRect(find.byType(ListView));

          // 1. 본문은 아래 안전 영역을 받지 않는다 (막대가 맡는다)
          expect(compareBodyBottomPadding.value, 0);
          // 2. 막대 바깥 영역이 화면 맨 아래까지 닿고, 본문 아래부터 화면 끝까지가 막대 영역 하나다
          expect(outer.bottom, closeTo(height, 0.5));
          expect(height - body.bottom, closeTo(outer.height, 0.5));
          // 3. 그 영역 안에서 안전 영역(34)은 한 번만 쓴다: 막대 높이 + 위아래 여백 + 안전 영역 = 영역 높이
          expect(
            outer.height,
            closeTo(
              BarMetrics.floatingHeight +
                  BarMetrics.floatingVerticalMargin * 2 +
                  ScreenConditions.safeBottom,
              0.5,
            ),
            reason: '34를 두 번 더하면 148이 된다',
          );
          // 4. 막대는 안전 영역 위에 여백만큼 떠 있다
          expect(
            height - visible.bottom,
            closeTo(
              ScreenConditions.safeBottom + BarMetrics.floatingVerticalMargin,
              0.5,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets(
          '${state.label} | 폭 $width: 키보드가 올라오면 막대가 숨고 본문이 키보드 위까지 쓴다 (남는 빈틈 없음)',
          (tester) async {
            final c = ScreenConditions(
              width: width,
              keyboardHeight: ScreenConditions.keyboardUp,
            );
            await pumpScreen(
              tester,
              bottomBarCompareScreenEntry,
              state,
              conditions: c,
            );
            expect(find.byKey(barOuterKey), findsNothing);
            expect(compareBodyBottomPadding.value, 0);
            expect(
              tester.getRect(find.byType(ListView)).bottom,
              closeTo(c.height - ScreenConditions.keyboardUp, 0.5),
            );
          },
        );
      }
    }

    testWidgets('같은 조건에서 안 3은 현재 막대보다 본문을 정확히 12만큼 덜 쓴다 (여백 8+8 − 높이 차 4)', (
      tester,
    ) async {
      final c = const ScreenConditions(width: 320);
      await pumpScreen(
        tester,
        bottomBarCompareScreenEntry,
        states[0],
        conditions: c,
      );
      final currentBody = tester.getRect(find.byType(ListView)).height;
      await pumpScreen(
        tester,
        bottomBarCompareScreenEntry,
        states[6],
        conditions: c,
      );
      final floatingBody = tester.getRect(find.byType(ListView)).height;
      expect(currentBody - floatingBody, closeTo(12, 0.5));
    });
  });
}
