import 'dart:io';

import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pixels.dart';
import '../../../support/pump.dart';
import '../../../support/semantics_tree.dart';

/// 폭 [w], 높이 [h]가 고유 크기인 자식. 눌리면 [onTap]이 불린다
Widget box(int i, double w, {double h = 30, VoidCallback? onTap}) => Semantics(
  container: true,
  label: 'c$i',
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(key: ValueKey('c$i'), width: w, height: h),
  ),
);

Widget row(
  List<Widget> children, {
  double spacing = 8,
  double? runSpacing,
  int? maxColumns,
  double minCellWidth = 0,
}) => SmashAdaptiveRow(
  spacing: spacing,
  runSpacing: runSpacing,
  maxColumns: maxColumns,
  minCellWidth: minCellWidth,
  children: children,
);

/// 자식 [i]의 위치와 크기 (SmashAdaptiveRow의 왼쪽 위 모서리를 원점으로)
Rect rectOf(WidgetTester tester, int i) {
  final finder = find.byKey(ValueKey('c$i'));
  final origin = tester.getTopLeft(find.byType(SmashAdaptiveRow));
  return (tester.getTopLeft(finder) - origin) & tester.getSize(finder);
}

RenderBox rowBox(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(SmashAdaptiveRow));

/// 열 수: 첫 줄에 놓인 자식 수
int columnsOf(WidgetTester tester, int count) {
  final firstTop = rectOf(tester, 0).top;
  var columns = 0;
  for (var i = 0; i < count; i++) {
    if ((rectOf(tester, i).top - firstTop).abs() < 0.5) columns++;
  }
  return columns;
}

/// 의미 트리에서 'c숫자' 라벨을 읽는 순서대로 모은다
List<String> semanticOrder(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (RegExp(r'^c\d+$').hasMatch(label)) labels.add(label);
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      walk(child);
    }
  }

  walk(semanticsOwner(tester).rootSemanticsNode!);
  return labels;
}

void main() {
  group('열 수 결정 (columnsFor)', () {
    int columns(
      int count,
      double width,
      double minCell, {
      double spacing = 8,
      int? maxColumns,
    }) => SmashAdaptiveRow.columnsFor(
      count: count,
      width: width,
      minCell: minCell,
      spacing: spacing,
      maxColumns: maxColumns,
    );

    test('칸 폭이 최소 폭과 정확히 같으면 들어가고, 1px 모자라면 한 단계 줄어든다 (4개, 간격 8, 최소 80)', () {
      // 4열: 4칸 + 간격 3 = 344
      expect(columns(4, 344, 80), 4);
      expect(columns(4, 343, 80), 2, reason: '4열은 1px 모자라서 2열 (칸 167.5)');
      // 2열: 2칸 + 간격 1 = 168
      expect(columns(4, 168, 80), 2);
      expect(columns(4, 167, 80), 1, reason: '2열도 1px 모자라서 1열');
      expect(columns(4, 1000, 80), 4);
    });

    test('2개: 2열 또는 1열', () {
      expect(columns(2, 168, 80), 2);
      expect(columns(2, 167, 80), 1);
    });

    test('열 수는 자식 수의 약수다 (3개: 3열 → 1열, 5개: 5열 → 1열, 6개: 6 → 3 → 2 → 1)', () {
      expect(
        columns(3, 200, 80),
        1,
        reason: '3열은 안 들어가고 2열은 3+... 약수가 아니라 건너뛴다',
      );
      expect(columns(3, 256, 80), 3);
      expect(columns(5, 300, 80), 1);
      expect(columns(6, 6 * 80 + 40, 80), 6);
      expect(columns(6, 3 * 80 + 16, 80), 3);
      expect(columns(6, 2 * 80 + 8, 80), 2);
      expect(columns(6, 2 * 80 + 7, 80), 1);
    });

    test('maxColumns는 상한이다', () {
      expect(columns(4, 1000, 80, maxColumns: 2), 2);
      expect(columns(4, 1000, 80, maxColumns: 1), 1);
      expect(columns(4, 1000, 80, maxColumns: 3), 2, reason: '3은 4의 약수가 아니다');
    });

    test('자식이 0개나 1개면 1열', () {
      expect(columns(0, 300, 80), 1);
      expect(columns(1, 300, 80), 1);
    });
  });

  group('배치', () {
    testWidgets('폭이 넉넉하면 한 줄, 칸은 모두 같은 폭으로 폭을 채운다 (간격 8)', (tester) async {
      await tester.pumpWidget(
        smashHarness(row([for (var i = 0; i < 4; i++) box(i, 80)]), width: 344),
      );
      expect(columnsOf(tester, 4), 4);
      for (var i = 0; i < 4; i++) {
        final r = rectOf(tester, i);
        expect(r.width, 80, reason: '칸 $i');
        expect(r.left, i * 88.0);
      }
      expect(tester.getSize(find.byType(SmashAdaptiveRow)).width, 344);
    });

    testWidgets('1px 모자라면 2×2 격자: 같은 폭의 칸, 줄 간격 = runSpacing', (tester) async {
      await tester.pumpWidget(
        smashHarness(
          row([for (var i = 0; i < 4; i++) box(i, 80)], runSpacing: 4),
          width: 343,
        ),
      );
      expect(columnsOf(tester, 4), 2);
      for (var i = 0; i < 4; i++) {
        expect(rectOf(tester, i).width, closeTo(167.5, 0.001));
      }
      expect(rectOf(tester, 2).top, 30 + 4);
      expect(rectOf(tester, 2).left, 0);
      expect(rectOf(tester, 3).left, closeTo(167.5 + 8, 0.001));
      expect(tester.getSize(find.byType(SmashAdaptiveRow)).height, 64);
    });

    testWidgets('더 좁으면 세로: 칸이 폭 전체', (tester) async {
      await tester.pumpWidget(
        smashHarness(row([for (var i = 0; i < 4; i++) box(i, 80)]), width: 100),
      );
      expect(columnsOf(tester, 4), 1);
      for (var i = 0; i < 4; i++) {
        expect(rectOf(tester, i).width, 100);
        expect(rectOf(tester, i).top, i * (30 + 8.0));
      }
    });

    testWidgets('minCellWidth가 자식의 고유 폭보다 크면 그 값이 기준이다', (tester) async {
      // 자식 고유 폭 50, 하한 100: 4열은 4*100+24 = 424 필요
      await tester.pumpWidget(
        smashHarness(
          row([for (var i = 0; i < 4; i++) box(i, 50)], minCellWidth: 100),
          width: 424,
        ),
      );
      expect(columnsOf(tester, 4), 4);
      await tester.pumpWidget(
        smashHarness(
          row([for (var i = 0; i < 4; i++) box(i, 50)], minCellWidth: 100),
          width: 423,
        ),
      );
      expect(columnsOf(tester, 4), 2);
    });

    testWidgets('가장 넓은 자식이 기준이다 (80, 80, 120, 80 → 4열은 4*120+24 = 504)', (
      tester,
    ) async {
      final children = [box(0, 80), box(1, 80), box(2, 120), box(3, 80)];
      await tester.pumpWidget(smashHarness(row(children), width: 504));
      expect(columnsOf(tester, 4), 4);
      await tester.pumpWidget(smashHarness(row(children), width: 503));
      expect(columnsOf(tester, 4), 2);
    });

    testWidgets('같은 줄의 칸은 가장 큰 높이로 늘어난다 (30, 50)', (tester) async {
      await tester.pumpWidget(
        smashHarness(row([box(0, 80, h: 30), box(1, 80, h: 50)]), width: 200),
      );
      expect(columnsOf(tester, 2), 2);
      expect(rectOf(tester, 0).height, 50);
      expect(rectOf(tester, 1).height, 50);
    });

    testWidgets('줄마다 높이가 따로다 (2×2: 첫 줄 30/50 → 50, 둘째 줄 20/20 → 20)', (
      tester,
    ) async {
      await tester.pumpWidget(
        smashHarness(
          row([
            box(0, 80, h: 30),
            box(1, 80, h: 50),
            box(2, 80, h: 20),
            box(3, 80, h: 20),
          ], runSpacing: 8),
          width: 200,
        ),
      );
      expect(columnsOf(tester, 4), 2);
      expect(rectOf(tester, 0).height, 50);
      expect(rectOf(tester, 2).top, 58);
      expect(rectOf(tester, 2).height, 20);
      expect(tester.getSize(find.byType(SmashAdaptiveRow)).height, 78);
    });

    testWidgets('자식 0개는 높이 0이고, 자식 1개는 폭 전체다', (tester) async {
      await tester.pumpWidget(smashHarness(row(const []), width: 200));
      expect(tester.getSize(find.byType(SmashAdaptiveRow)), const Size(200, 0));
      await tester.pumpWidget(smashHarness(row([box(0, 80)]), width: 200));
      expect(rectOf(tester, 0).width, 200);
    });

    testWidgets('폭이 무한(가로 스크롤 안)이면 가장 넓은 고유 폭으로 한 줄에 놓는다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row([box(0, 80), box(1, 120), box(2, 60)]),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, 3), 3);
      for (var i = 0; i < 3; i++) {
        expect(rectOf(tester, i).width, 120);
      }
      expect(
        tester.getSize(find.byType(SmashAdaptiveRow)).width,
        3 * 120 + 2 * 8,
      );
    });
  });

  group('그리기', () {
    testWidgets('각 칸의 색이 자기 자리에 그려진다 (2×2: 첫 줄 빨강/초록, 둘째 줄 파랑/노랑)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      const colors = [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFFFFFF00),
      ];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: screenshotBoundary(
              const ValueKey('shot'),
              SizedBox(
                width: 200,
                child: row(
                  [
                    for (final c in colors)
                      ColoredBox(
                        color: c,
                        child: const SizedBox(width: 80, height: 30),
                      ),
                  ],
                  spacing: 8,
                  runSpacing: 4,
                ),
              ),
            ),
          ),
        ),
      );
      final pixel = await readPixels(tester, const ValueKey('shot'));
      // 칸 폭 (200 - 8) / 2 = 96
      expect(colorDistance(pixel(10, 10), colors[0]), 0);
      expect(colorDistance(pixel(96 + 8 + 10, 10), colors[1]), 0);
      expect(colorDistance(pixel(10, 30 + 4 + 10), colors[2]), 0);
      expect(colorDistance(pixel(96 + 8 + 10, 30 + 4 + 10), colors[3]), 0);
      expect(pixel(96 + 4, 10).a, 0, reason: '칸 사이 간격에는 아무것도 그려지지 않는다');
    });
  });

  group('속성이 바뀌면 다시 배치한다', () {
    testWidgets(
      'spacing, runSpacing, maxColumns, minCellWidth를 같은 위젯에서 바꾸면 바로 반영된다',
      (tester) async {
        Widget build({
          double spacing = 8,
          double? runSpacing,
          int? maxColumns,
          double minCellWidth = 0,
        }) => smashHarness(
          row(
            [for (var i = 0; i < 4; i++) box(i, 80)],
            spacing: spacing,
            runSpacing: runSpacing,
            maxColumns: maxColumns,
            minCellWidth: minCellWidth,
          ),
          width: 400,
        );
        await tester.pumpWidget(build(runSpacing: 6));
        expect(columnsOf(tester, 4), 4);
        expect(
          rectOf(tester, 1).left,
          (400 - 24) / 4 + 8,
          reason: '간격 8: 칸 94, 둘째 칸 시작 102',
        );
        await tester.pumpWidget(
          build(spacing: 20, runSpacing: 6),
        ); // spacing만 바뀐다
        expect(rectOf(tester, 1).left, (400 - 60) / 4 + 20, reason: '간격 20');
        await tester.pumpWidget(
          build(spacing: 20, runSpacing: 6, maxColumns: 2),
        ); // maxColumns만 바뀐다
        expect(columnsOf(tester, 4), 2);
        await tester.pumpWidget(
          build(spacing: 20, runSpacing: 10, maxColumns: 2),
        ); // runSpacing만 바뀐다
        expect(rectOf(tester, 2).top, 30 + 10, reason: 'runSpacing 10');
        await tester.pumpWidget(
          build(spacing: 20, runSpacing: 2, maxColumns: 2),
        );
        expect(rectOf(tester, 2).top, 30 + 2, reason: 'runSpacing 2');
        await tester.pumpWidget(
          build(spacing: 20, runSpacing: 2, minCellWidth: 150),
        ); // minCellWidth만 바뀐다 (maxColumns 해제)
        expect(columnsOf(tester, 4), 2, reason: '하한 150: 4열은 4*150+60 > 400');
        await tester.pumpWidget(build(spacing: 20, runSpacing: 2));
        expect(columnsOf(tester, 4), 4);
      },
    );
  });

  group('최소와 최대 고유 폭이 다른 자식 (여러 낱말 글자)', () {
    const sentence = '같이 가요 따로 가요 정규 참여';

    testWidgets('폭이 무한이면 칸 폭 = 가장 넓은 자식의 최대 고유 폭(한 줄로 펼친 폭)이다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row([
                const SmashLabel(sentence),
                const SmashLabel('이월'),
                const SmashLabel('다른 조 참여'),
              ]),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final widest = tester
          .renderObject<RenderBox>(find.text(sentence))
          .getMaxIntrinsicWidth(double.infinity);
      final b = rowBox(tester);
      expect(
        tester.getSize(find.byType(SmashAdaptiveRow)).width,
        closeTo(3 * widest + 2 * 8, 0.01),
      );
      expect(
        b.getMaxIntrinsicWidth(double.infinity),
        closeTo(3 * widest + 2 * 8, 0.01),
      );
    });

    for (final width in [120.0, 200.0, 330.0, 700.0]) {
      testWidgets('폭 $width: 줄바꿈되는 글자 자식도 dry layout 크기 = 실제 크기 = 고유 높이', (
        tester,
      ) async {
        await tester.pumpWidget(
          smashHarness(
            row([
              const SmashLabel(sentence),
              const SmashLabel('이월'),
              const SmashLabel(sentence),
              const SmashLabel('불참'),
            ]),
            width: width,
          ),
        );
        final b = rowBox(tester);
        expect(b.getDryLayout(b.constraints), b.size, reason: 'dry layout');
        expect(b.getMinIntrinsicHeight(width), b.size.height, reason: '고유 높이');
      });
    }
  });

  group('고유 크기와 dry layout', () {
    testWidgets('최소 고유 폭 = 가장 넓은 자식(하한 포함), 최대 고유 폭 = 칸 폭 × 개수 + 간격', (
      tester,
    ) async {
      await tester.pumpWidget(
        smashHarness(
          row([box(0, 80), box(1, 120), box(2, 60), box(3, 80)]),
          width: 600,
        ),
      );
      final b = rowBox(tester);
      expect(b.getMinIntrinsicWidth(double.infinity), 120);
      expect(b.getMaxIntrinsicWidth(double.infinity), 4 * 120 + 3 * 8);
      await tester.pumpWidget(
        smashHarness(
          row([box(0, 80), box(1, 120)], minCellWidth: 150),
          width: 600,
        ),
      );
      expect(rowBox(tester).getMinIntrinsicWidth(double.infinity), 150);
    });

    for (final width in [
      60.0,
      100.0,
      167.0,
      168.0,
      200.0,
      343.0,
      344.0,
      500.0,
    ]) {
      testWidgets('폭 $width: dry layout 크기 = 실제 크기 = 고유 높이', (tester) async {
        await tester.pumpWidget(
          smashHarness(
            row([
              box(0, 80, h: 30),
              box(1, 80, h: 50),
              box(2, 80, h: 20),
              box(3, 80, h: 40),
            ], runSpacing: 6),
            width: width,
          ),
        );
        final b = rowBox(tester);
        expect(b.getDryLayout(b.constraints), b.size, reason: 'dry layout');
        expect(
          b.getMinIntrinsicHeight(width),
          b.size.height,
          reason: '고유 높이(최소)',
        );
        expect(
          b.getMaxIntrinsicHeight(width),
          b.size.height,
          reason: '고유 높이(최대)',
        );
      });
    }

    testWidgets('자식을 늘리거나 줄이면(2개 → 3개 → 4개) 배치가 바로 따라간다', (tester) async {
      await tester.pumpWidget(
        smashHarness(row([box(0, 80), box(1, 80)]), width: 344),
      );
      expect(columnsOf(tester, 2), 2);
      await tester.pumpWidget(
        smashHarness(
          row([box(0, 80), box(1, 80), box(2, 80), box(3, 80)]),
          width: 344,
        ),
      );
      expect(columnsOf(tester, 4), 4);
      await tester.pumpWidget(
        smashHarness(row([box(0, 80), box(1, 80), box(2, 80)]), width: 344),
      );
      expect(columnsOf(tester, 3), 3);
    });
  });

  group('히트 테스트와 의미 순서', () {
    for (final width in [344.0, 200.0, 100.0]) {
      testWidgets('폭 $width: 각 칸을 누르면 그 칸의 onTap이 불린다 (가로, 2×2, 세로)', (
        tester,
      ) async {
        final tapped = <int>[];
        await tester.pumpWidget(
          smashHarness(
            row([
              for (var i = 0; i < 4; i++)
                box(i, 80, onTap: () => tapped.add(i)),
            ]),
            width: width,
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byKey(ValueKey('c$i')));
        }
        expect(tapped, [0, 1, 2, 3]);
      });
    }

    testWidgets('칸 사이 틈(간격)을 눌러도 아무 칸도 반응하지 않는다', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        smashHarness(
          row([
            for (var i = 0; i < 2; i++) box(i, 80, onTap: () => tapped.add(i)),
          ]),
          width: 200,
        ),
      );
      final gap =
          tester.getTopLeft(find.byKey(const ValueKey('c0'))) +
          Offset(
            tester.getSize(find.byKey(const ValueKey('c0'))).width + 4,
            15,
          );
      await tester.tapAt(gap);
      expect(tapped, isEmpty);
    });

    for (final width in [344.0, 200.0, 100.0]) {
      testWidgets('폭 $width: 스크린리더 읽는 순서는 자식 순서 그대로다 (열 수와 무관)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          smashHarness(
            row([for (var i = 0; i < 4; i++) box(i, 80)]),
            width: width,
          ),
        );
        expect(semanticOrder(tester), ['c0', 'c1', 'c2', 'c3']);
        handle.dispose();
      });
    }
  });

  group('안전 영역', () {
    testWidgets('SafeArea가 좌우를 줄이면 줄어든 폭으로 열 수를 정한다 (360 → 좌우 20씩 → 320)', (
      tester,
    ) async {
      Widget host(EdgeInsets padding) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: padding),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: row([for (var i = 0; i < 4; i++) box(i, 75)]),
            ),
          ),
        ),
      );
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(EdgeInsets.zero));
      expect(tester.getSize(find.byType(SmashAdaptiveRow)).width, 360);
      expect(columnsOf(tester, 4), 4, reason: '4*75 + 24 = 324 ≤ 360');

      await tester.pumpWidget(host(const EdgeInsets.symmetric(horizontal: 20)));
      expect(tester.getSize(find.byType(SmashAdaptiveRow)).width, 320);
      expect(columnsOf(tester, 4), 2, reason: '324 > 320: 2×2');
      expect(
        tester.getTopLeft(find.byType(SmashAdaptiveRow)).dx,
        20,
        reason: '안전 영역 안쪽에서 시작',
      );
      expect(
        rectOf(tester, 1).right,
        lessThanOrEqualTo(340 + 0.001),
        reason: '안전 영역을 넘지 않는다',
      );
    });
  });

  group('고유 폭을 지원하지 않는 자식 (디버그 오류)', () {
    /// 그리는 동안 나는 오류를 모두 모은다 (레이아웃 실패는 프레임마다 반복해서 보고된다)
    Future<List<Object>> errorsWhilePumping(
      Future<void> Function() body,
    ) async {
      final errors = <Object>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details.exception);
      try {
        await body();
      } finally {
        FlutterError.onError = previous;
      }
      return errors;
    }

    testWidgets('LayoutBuilder를 자식으로 두면 SmashAdaptiveRow가 원인을 알려 주는 오류를 낸다', (
      tester,
    ) async {
      final errors = await errorsWhilePumping(
        () => tester.pumpWidget(
          smashHarness(
            row([
              box(0, 80),
              LayoutBuilder(
                builder: (context, constraints) => const SizedBox(height: 30),
              ),
            ]),
            width: 300,
          ),
        ),
      );
      expect(errors, isNotEmpty);
      expect(errors.first, isA<FlutterError>());
      final message = errors.first.toString();
      expect(message, contains('SmashAdaptiveRow'));
      expect(message, contains('고유 폭'));
      expect(message, contains('LayoutBuilder'), reason: '어떤 위젯이 문제인지 알려 준다');
      expect(message, contains('원래 오류'), reason: 'Flutter의 원래 메시지도 함께 보여 준다');
      expect(
        message,
        contains('intrinsic width'),
        reason: '요약에 원인(고유 폭 = intrinsic width)이 있다',
      );
      expect(message, contains('문제의 자식'), reason: '문제의 위젯을 가리킨다');
      expect(message, contains('고유 크기를 지원하는 위젯'), reason: '해결 방법을 알려 준다');
    });

    testWidgets('자식의 깊은 곳에 있어도 같은 오류가 난다', (tester) async {
      final errors = await errorsWhilePumping(
        () => tester.pumpWidget(
          smashHarness(
            row([
              Padding(
                padding: const EdgeInsets.all(4),
                child: LayoutBuilder(
                  builder: (context, constraints) => const SizedBox(height: 30),
                ),
              ),
            ]),
            width: 300,
          ),
        ),
      );
      expect(errors, isNotEmpty);
      expect(errors.first.toString(), contains('SmashAdaptiveRow'));
    });

    testWidgets('고유 폭을 지원하는 자식(Container, Row, Padding, SmashLabel)은 오류가 없다', (
      tester,
    ) async {
      await tester.pumpWidget(
        smashHarness(
          row([
            Container(
              padding: const EdgeInsets.all(8),
              child: const SmashLabel('같이 가요'),
            ),
            const Padding(
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Icon(Icons.check),
                  Flexible(child: SmashLabel('따로 가요')),
                ],
              ),
            ),
          ]),
          width: 300,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('문서', () {
    test('클래스 문서에 쓰는 곳(행 수가 적은 고정 영역)과 자식 조건이 적혀 있다', () {
      final source = File(
        'lib/core/design/components/smash_adaptive_row.dart',
      ).readAsStringSync();
      expect(source, contains('행 수가 적은 고정 영역(버튼 줄, 조각 선택 등)에만 쓴다'));
      expect(source, contains('긴 스크롤 목록'));
      expect(source, contains('고유 폭을 지원해야 한다'));
    });
  });
}
