import 'dart:ui' show Tristate;

import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';
import '../../../support/segment_label.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

/// 조각 선택의 세로 전환: 칸이 가장 긴 낱말(선택 표시 포함)을 담지 못하면 2열/세로로 쌓인다.
/// 실제 글꼴(Pretendard)로 잰다 (테스트 글꼴은 한글 폭이 달라 경계가 어긋난다).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const two = ['같이 가요', '따로 가요'];
  const three = ['정규', '이월', '다른 조'];
  const four = ['정규참여', '이월참여신청', '다른조참여', '불참신청'];
  const shortFour = ['정규', '이월', '다른 조', '불참'];

  Widget control(
    List<String> labels, {
    int selected = 0,
    ValueChanged<int>? onChanged,
    Set<int> disabled = const {},
    bool allDisabled = false,
  }) => SmashSegmentedControl<int>(
    semanticLabel: '참석 구분',
    segments: [
      for (var i = 0; i < labels.length; i++)
        SmashSegment(
          value: i,
          label: labels[i],
          enabled: !disabled.contains(i),
        ),
    ],
    selected: selected,
    onChanged: allDisabled ? null : (onChanged ?? (_) {}),
  );

  Rect segRect(WidgetTester tester, String label) {
    final finder = find
        .ancestor(
          of: segmentLabel(label),
          matching: find.byType(SmashPressable),
        )
        .first;
    return tester.getTopLeft(finder) & tester.getSize(finder);
  }

  /// 첫 줄에 놓인 조각 수
  int columns(WidgetTester tester, List<String> labels) {
    final top = segRect(tester, labels.first).top;
    return labels
        .where((l) => (segRect(tester, l).top - top).abs() < 0.5)
        .length;
  }

  /// 조각 칸 폭 하한(= 선택 표시까지 담는 데 필요한 폭)
  double need(WidgetTester tester) => tester
      .renderObject<RenderBox>(find.byType(SmashAdaptiveRow))
      .getMinIntrinsicWidth(double.infinity);

  /// 바깥 틀의 여백(4) × 2 + 테두리(1) × 2
  const frame = 10.0;

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 320,
    double scale = 1.0,
  }) => tester.pumpWidget(smashHarness(child, width: width, textScale: scale));

  group('판단 경계: 칸 폭 = 필요한 폭이면 가로, 1px 모자라면 한 단계 줄어든다', () {
    testWidgets('2개: 한 줄 ↔ 세로', (tester) async {
      await pump(tester, control(two), width: 400);
      final n = need(tester);
      await pump(tester, control(two), width: 2 * n + frame);
      expect(columns(tester, two), 2, reason: '칸 폭 = 필요한 폭 → 가로');
      await pump(tester, control(two), width: 2 * n + frame - 1);
      expect(columns(tester, two), 1, reason: '1px 모자람 → 세로');
    });

    testWidgets('4개: 4열 ↔ 2열 ↔ 1열', (tester) async {
      await pump(tester, control(four), width: 800);
      final n = need(tester);
      await pump(tester, control(four), width: 4 * n + frame);
      expect(columns(tester, four), 4);
      await pump(tester, control(four), width: 4 * n + frame - 1);
      expect(columns(tester, four), 2);
      await pump(tester, control(four), width: 2 * n + frame);
      expect(columns(tester, four), 2);
      await pump(tester, control(four), width: 2 * n + frame - 1);
      expect(columns(tester, four), 1);
    });

    testWidgets('3개: 3열 ↔ 1열 (2+1 배치는 만들지 않는다)', (tester) async {
      await pump(tester, control(three), width: 400);
      final n = need(tester);
      await pump(tester, control(three), width: 3 * n + frame);
      expect(columns(tester, three), 3);
      await pump(tester, control(three), width: 3 * n + frame - 1);
      expect(columns(tester, three), 1);
    });

    testWidgets('필요한 폭은 가장 긴 낱말 + 체크 아이콘(22) + 좌우 여백(16)이다 (굵은 글자 기준)', (
      tester,
    ) async {
      await pump(tester, control(two), width: 400);
      final painter = TextPainter(
        text: const TextSpan(
          text: '같이⁠',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(
        need(tester),
        greaterThan(22 + 16 + painter.width - 1),
        reason: '낱말 하나 + 체크 + 여백보다 작을 수 없다',
      );
      painter.dispose();
    });
  });

  group('선택을 바꿔도 열 수와 칸 폭이 바뀌지 않는다', () {
    // 높이는 바뀔 수 있다: 경계 폭에서 선택된 조각(굵은 글자 + 체크)의 여러 낱말 라벨이 공백에서 줄바꿈되면 그 줄이 높아진다
    for (final labels in [two, three, four]) {
      testWidgets(
        '${labels.length}개: 경계 폭에서 어느 조각을 선택해도 열 수와 칸의 가로 위치, 폭이 같다',
        (tester) async {
          await pump(tester, control(labels), width: 800);
          final n = need(tester);
          final widths = [
            labels.length * n + frame,
            labels.length * n + frame - 1,
            2 * n + frame,
            2 * n + frame - 1,
          ];
          for (final width in widths) {
            List<Rect>? baseline;
            int? baselineColumns;
            for (var selected = 0; selected < labels.length; selected++) {
              await pump(
                tester,
                control(labels, selected: selected),
                width: width,
              );
              final rects = [for (final l in labels) segRect(tester, l)];
              baseline ??= rects;
              baselineColumns ??= columns(tester, labels);
              expect(
                columns(tester, labels),
                baselineColumns,
                reason: '열 수: 폭 $width, 선택 $selected',
              );
              for (var i = 0; i < labels.length; i++) {
                expect(
                  rects[i].left,
                  baseline[i].left,
                  reason: '폭 $width, 선택 $selected, 조각 ${labels[i]}',
                );
                expect(
                  rects[i].width,
                  baseline[i].width,
                  reason: '폭 $width, 선택 $selected, 조각 ${labels[i]}',
                );
              }
            }
          }
        },
      );
    }
  });

  group('칸 폭 하한 = 어느 조각이 선택돼도 필요한 폭 (실제로 그려지는 선택된 조각의 최소 폭과 같다)', () {
    // 영문/숫자는 굵기에 따라 폭이 달라진다 (한글 음절은 Pretendard에서 굵기와 무관하게 폭이 같다)
    for (final entry in {
      '2개': two,
      '3개': three,
      '4개(긴 낱말)': four,
      '영문 3개': ['MMMMM', 'iiiiiiiiii', 'WWW 77'],
    }.entries) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('${entry.key}, 글자 $scale배', (tester) async {
          final labels = entry.value;
          var widestSelected = 0.0;
          final needs = <double>[];
          for (var selected = 0; selected < labels.length; selected++) {
            await pump(
              tester,
              control(labels, selected: selected),
              width: 1000,
              scale: scale,
            );
            needs.add(need(tester));
            final box = tester.renderObject<RenderBox>(
              find
                  .ancestor(
                    of: segmentLabel(labels[selected]),
                    matching: find.byType(SmashPressable),
                  )
                  .first,
            );
            final actual = box.getMinIntrinsicWidth(double.infinity);
            widestSelected = widestSelected < actual ? actual : widestSelected;
          }
          for (final n in needs) {
            expect(n, needs.first, reason: '선택이 바뀌어도 필요한 폭이 같다');
          }
          expect(
            needs.first,
            closeTo(widestSelected, 0.01),
            reason: '하한 = 선택됐을 때 가장 넓은 조각의 실제 최소 폭',
          );
        });
      }
    }
  });

  group('폭 × 글자 크기 행렬 (실제 Pretendard)', () {
    for (final entry in {
      '2개': two,
      '3개': three,
      '4개(짧은 낱말)': shortFour,
      '4개(긴 낱말)': four,
    }.entries) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
            '${entry.key}, 폭 $width, 글자 $scale배: 낱말 중간 끊김 0, 넘침 0, 터치 48 이상, 칸 폭 같음',
            (tester) async {
              final labels = entry.value;
              for (var selected = 0; selected < labels.length; selected++) {
                await pump(
                  tester,
                  control(labels, selected: selected),
                  width: width,
                  scale: scale,
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '넘침이나 오류 (선택 $selected)',
                );

                final container = tester.getRect(
                  find.byType(SmashSegmentedControl<int>),
                );
                final rects = [for (final l in labels) segRect(tester, l)];
                for (var i = 0; i < labels.length; i++) {
                  expect(
                    midWordBreaks(tester, segmentLabel(labels[i])),
                    0,
                    reason: '낱말 중간 끊김: ${labels[i]} (선택 $selected)',
                  );
                  expect(
                    rects[i].height,
                    greaterThanOrEqualTo(48),
                    reason: '터치 높이 ${labels[i]}',
                  );
                  expect(
                    rects[i].width,
                    greaterThanOrEqualTo(48),
                    reason: '터치 폭 ${labels[i]}',
                  );
                  expect(
                    rects[i].left,
                    greaterThanOrEqualTo(container.left - 0.001),
                  );
                  expect(
                    rects[i].right,
                    lessThanOrEqualTo(container.right + 0.001),
                    reason: '${labels[i]}가 틀 밖으로 나감',
                  );
                  expect(
                    (rects[i].width - rects[0].width).abs(),
                    lessThan(0.001),
                    reason: '칸 폭이 모두 같다',
                  );
                }
                // 같은 줄은 높이가 같다
                final top = rects[0].top;
                final firstRow = [
                  for (final r in rects)
                    if ((r.top - top).abs() < 0.5) r,
                ];
                for (final r in firstRow) {
                  expect(
                    (r.height - firstRow.first.height).abs(),
                    lessThan(0.001),
                  );
                }
              }
            },
          );
        }
      }
    }
  });

  group('세로 전환 상태: 조각 4개, 폭 320, 글자 2.0배', () {
    testWidgets('한 줄씩 쌓이고(같은 왼쪽, 위에서 아래), 모든 조각이 틀 폭 전체다', (tester) async {
      await pump(tester, control(shortFour), width: 320, scale: 2.0);
      final rects = [for (final l in shortFour) segRect(tester, l)];
      final container = tester.getRect(find.byType(SmashSegmentedControl<int>));
      expect(columns(tester, shortFour), anyOf(1, 2), reason: '4개는 4열이 아니다');
      await pump(tester, control(four), width: 320, scale: 2.0);
      final longRects = [for (final l in four) segRect(tester, l)];
      expect(columns(tester, four), 1);
      for (var i = 1; i < longRects.length; i++) {
        expect(
          longRects[i].top,
          greaterThan(longRects[i - 1].top),
          reason: '위에서 아래로',
        );
        expect(longRects[i].left, longRects[0].left, reason: '같은 왼쪽');
        expect(longRects[i].width, container.width - frame, reason: '틀 폭 전체');
      }
      expect(rects, isNotEmpty);
    });
  });

  group('dry layout', () {
    for (final width in [320.0, 360.0, 800.0]) {
      testWidgets('폭 $width: 조각 선택의 dry layout 크기 = 실제 크기 (가로/2×2/세로)', (
        tester,
      ) async {
        for (final labels in [two, three, four]) {
          for (final scale in [1.0, 2.0]) {
            await pump(tester, control(labels), width: width, scale: scale);
            final box = tester.renderObject<RenderBox>(
              find.byType(SmashSegmentedControl<int>),
            );
            expect(
              box.getDryLayout(box.constraints),
              box.size,
              reason: '${labels.length}개, 글자 $scale배',
            );
          }
        }
      });
    }
  });

  group('간격', () {
    testWidgets('가로에서는 조각이 붙어 있고(간격 0), 세로에서는 줄 사이가 4다', (tester) async {
      await pump(tester, control(two), width: 800);
      expect(
        segRect(tester, two[1]).left,
        segRect(tester, two[0]).right,
        reason: '가로: 붙어 있다',
      );
      await pump(tester, control(four), width: 320, scale: 2.0);
      expect(columns(tester, four), 1, reason: '세로');
      for (var i = 1; i < four.length; i++) {
        expect(
          segRect(tester, four[i]).top - segRect(tester, four[i - 1]).bottom,
          4,
          reason: '세로: 줄 사이 4',
        );
      }
    });
  });

  group('스크린리더: 위치가 아니라 목록 순서로 읽는다', () {
    for (final width in [800.0, 320.0]) {
      testWidgets('폭 $width: 각 조각이 "N개 중 M번째"를 읽고, 선택 상태는 선택된 조각에만 있다', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        for (var selected = 0; selected < four.length; selected++) {
          await pump(
            tester,
            control(four, selected: selected),
            width: width,
            scale: 1.3,
          );
          for (var i = 0; i < four.length; i++) {
            final node = semanticsNode(
              tester,
              (d) => d.label.contains(four[i]) && d.hint.isNotEmpty,
            );
            expect(node, isNotNull, reason: '${four[i]} 노드');
            final data = node!.getSemanticsData();
            expect(
              data.hint,
              '4개 중 ${i + 1}번째',
              reason: '${four[i]} 가로/세로와 무관하게 목록 순서',
            );
            expect(
              data.flagsCollection.isSelected == Tristate.isTrue,
              i == selected,
              reason: '선택은 상태로 표시: ${four[i]}',
            );
          }
        }
        handle.dispose();
      });
    }

    testWidgets('같은 조각의 읽는 말은 가로와 세로에서 같다 (라벨 원문 + 힌트)', (tester) async {
      final handle = tester.ensureSemantics();
      Future<List<String>> read(double width) async {
        await pump(tester, control(four, selected: 2), width: width);
        return [
          for (var i = 0; i < four.length; i++)
            () {
              final d = semanticsNode(
                tester,
                (d) => d.label.contains(four[i]) && d.hint.isNotEmpty,
              )!.getSemanticsData();
              return '${d.label}|${d.hint}|${d.flagsCollection.isSelected}';
            }(),
        ];
      }

      expect(await read(320), await read(800));
      handle.dispose();
    });

    testWidgets('읽는 순서(트리 순서)는 조각 순서다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, control(four), width: 320);
      final order = <String>[];
      void walk(SemanticsNode node) {
        final d = node.getSemanticsData();
        for (final label in four) {
          if (d.label.contains(label) &&
              d.hint.isNotEmpty &&
              !order.contains(label)) {
            order.add(label);
          }
        }
        for (final child in node.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )) {
          walk(child);
        }
      }

      walk(semanticsOwner(tester).rootSemanticsNode!);
      expect(order, four);
      handle.dispose();
    });
  });

  group('선택 표시는 위치와 무관하다', () {
    for (final width in [800.0, 320.0]) {
      testWidgets('폭 $width: 체크 아이콘은 선택된 조각 안에만 1개 있고, 굵은 글자도 선택된 조각뿐이다', (
        tester,
      ) async {
        for (var selected = 0; selected < four.length; selected++) {
          await pump(
            tester,
            control(four, selected: selected),
            width: width,
            scale: 1.3,
          );
          expect(find.byIcon(Icons.check), findsOneWidget);
          for (var i = 0; i < four.length; i++) {
            final pressable = find
                .ancestor(
                  of: segmentLabel(four[i]),
                  matching: find.byType(SmashPressable),
                )
                .first;
            expect(
              find
                  .descendant(of: pressable, matching: find.byIcon(Icons.check))
                  .evaluate()
                  .length,
              i == selected ? 1 : 0,
              reason: '체크: ${four[i]}',
            );
            final style = tester.widget<Text>(segmentLabel(four[i])).style!;
            expect(
              style.fontWeight,
              i == selected ? FontWeight.w600 : FontWeight.w400,
              reason: '굵기: ${four[i]}',
            );
          }
        }
      });
    }
  });

  group('누르기', () {
    for (final width in [800.0, 320.0]) {
      testWidgets('폭 $width: 어느 줄의 조각을 눌러도 그 값으로 바뀐다 (선택된 조각은 불리지 않는다)', (
        tester,
      ) async {
        final changed = <int>[];
        await pump(
          tester,
          control(four, onChanged: changed.add),
          width: width,
          scale: 1.3,
        );
        for (var i = 0; i < four.length; i++) {
          await tester.tap(segmentLabel(four[i]));
        }
        expect(changed, [1, 2, 3], reason: '0번이 선택된 상태라 0번은 불리지 않는다');
      });
    }

    testWidgets('세로에서 비활성 조각은 눌러도 반응하지 않고, 전체 비활성이면 아무 것도 반응하지 않는다', (
      tester,
    ) async {
      final changed = <int>[];
      await pump(
        tester,
        control(four, onChanged: changed.add, disabled: {2}),
        width: 320,
      );
      await tester.tap(segmentLabel(four[2]));
      await tester.tap(segmentLabel(four[3]));
      expect(changed, [3]);
      await pump(tester, control(four, allDisabled: true), width: 320);
      await tester.tap(segmentLabel(four[1]));
      expect(changed, [3]);
    });
  });

  group('안전 영역', () {
    testWidgets(
      'SafeArea가 좌우를 줄이면 줄어든 폭으로 판단한다 (360, 여백 없음 → 가로 / 좌우 24 → 세로)',
      (tester) async {
        Widget host(EdgeInsets padding) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: padding),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(
              child: Align(alignment: Alignment.topLeft, child: control(two)),
            ),
          ),
        );
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pump(tester, control(two), width: 800);
        final n = need(tester);
        final available = 2 * n + frame; // 가로가 되는 가장 좁은 폭
        tester.view.physicalSize = Size(available + 48, 800);
        await tester.pumpWidget(host(EdgeInsets.zero));
        expect(columns(tester, two), 2, reason: '여백 없이 ${available + 48}');
        await tester.pumpWidget(
          host(const EdgeInsets.symmetric(horizontal: 24)),
        );
        expect(
          tester.getSize(find.byType(SmashSegmentedControl<int>)).width,
          available,
          reason: '안전 영역을 뺀 폭',
        );
        expect(columns(tester, two), 2, reason: '정확히 들어간다');
        await tester.pumpWidget(
          host(const EdgeInsets.symmetric(horizontal: 25)),
        );
        expect(columns(tester, two), 1, reason: '2px 모자라서 세로');
        expect(
          tester.getTopLeft(find.byType(SmashSegmentedControl<int>)).dx,
          25,
          reason: '안전 영역 안쪽에서 시작',
        );
      },
    );
  });
}
