import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';
import '../../../support/segment_label.dart';

enum Travel { together, alone }

const travelSegments = [
  SmashSegment(value: Travel.together, label: '같이 가요'),
  SmashSegment(value: Travel.alone, label: '따로 가요'),
];

Widget control({
  Travel selected = Travel.together,
  ValueChanged<Travel>? onChanged,
  List<SmashSegment<Travel>> segments = travelSegments,
  String? semanticLabel,
}) {
  return SmashSegmentedControl<Travel>(
    segments: segments,
    selected: selected,
    onChanged: onChanged,
    semanticLabel: semanticLabel,
  );
}

Finder segment(String label) => find.ancestor(
      of: segmentLabel(label),
      matching: find.byType(SmashPressable),
    );

BoxDecoration faceOf(WidgetTester tester, String label) => tester
    .widget<Container>(find
        .descendant(of: segment(label), matching: find.byType(Container))
        .first)
    .decoration as BoxDecoration;

void main() {
  group('선택과 탭', () {
    testWidgets('조각 글자가 모두 보이고 선택된 조각에만 체크 아이콘이 있다', (tester) async {
      await tester.pumpWidget(smashHarness(control(onChanged: (_) {})));

      expect(segmentLabel('같이 가요'), findsOneWidget);
      expect(segmentLabel('따로 가요'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(of: segment('같이 가요'), matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
    });

    testWidgets('선택된 조각은 연한 브랜드 배경과 굵은 브랜드 글자 (색 + 아이콘 + 굵기)', (tester) async {
      await tester.pumpWidget(smashHarness(control(onChanged: (_) {})));

      expect(faceOf(tester, '같이 가요').color, SmashColors.brandTint);
      expect(tester.widget<Text>(segmentLabel('같이 가요')).style!.fontWeight, FontWeight.w600);
      expect(tester.widget<Text>(segmentLabel('같이 가요')).style!.color, SmashColors.brand);
      expect(faceOf(tester, '따로 가요').color, Colors.transparent);
      expect(tester.widget<Text>(segmentLabel('따로 가요')).style!.fontWeight, FontWeight.w400);
    });

    testWidgets('다른 조각을 누르면 onChanged가 그 값으로 불린다', (tester) async {
      final changes = <Travel>[];
      await tester.pumpWidget(smashHarness(control(onChanged: changes.add)));

      await tester.tap(segmentLabel('따로 가요'));
      await tester.pump();

      expect(changes, [Travel.alone]);
    });

    testWidgets('이미 선택된 조각을 다시 눌러도 onChanged는 불리지 않는다', (tester) async {
      final changes = <Travel>[];
      await tester.pumpWidget(smashHarness(control(onChanged: changes.add)));

      await tester.tap(segmentLabel('같이 가요'));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('selected를 바꾸면 선택 표시가 따라 옮겨 간다', (tester) async {
      await tester.pumpWidget(smashHarness(control(onChanged: (_) {})));
      await tester.pumpWidget(smashHarness(control(selected: Travel.alone, onChanged: (_) {})));

      expect(
        find.descendant(of: segment('따로 가요'), matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: segment('같이 가요'), matching: find.byIcon(Icons.check)),
        findsNothing,
      );
    });

    testWidgets('조각은 같은 너비로 나뉜다', (tester) async {
      await tester.pumpWidget(smashHarness(control(onChanged: (_) {})));

      final first = tester.getSize(segment('같이 가요'));
      final second = tester.getSize(segment('따로 가요'));

      expect(first.width, second.width);
    });
  });

  group('비활성', () {
    testWidgets('onChanged가 null이면 모든 조각이 비활성이다', (tester) async {
      await tester.pumpWidget(smashHarness(control(onChanged: null)));

      await tester.tap(segmentLabel('따로 가요'), warnIfMissed: false);
      await tester.pump();

      expect(tester.widget<Text>(segmentLabel('따로 가요')).style!.color, SmashColors.textDisabled);
    });

    testWidgets('일부 조각만 비활성이면 그 조각만 눌리지 않는다', (tester) async {
      final changes = <Travel>[];
      await tester.pumpWidget(smashHarness(control(
        onChanged: changes.add,
        segments: const [
          SmashSegment(value: Travel.together, label: '같이 가요'),
          SmashSegment(value: Travel.alone, label: '따로 가요', enabled: false),
        ],
      )));

      await tester.tap(segmentLabel('따로 가요'), warnIfMissed: false);
      await tester.pump();

      expect(changes, isEmpty);
      expect(tester.widget<Text>(segmentLabel('따로 가요')).style!.color, SmashColors.textDisabled);
      expect(tester.widget<Text>(segmentLabel('같이 가요')).style!.color, isNot(SmashColors.textDisabled));
    });
  });

  group('스크린리더', () {
    testWidgets('조각마다 버튼 역할, 글자, 선택 여부, 같은 그룹 중 하나 선택임을 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(control(onChanged: (_) {})));

      final selected = tester.getSemantics(segment('같이 가요')).getSemanticsData();
      final other = tester.getSemantics(segment('따로 가요')).getSemanticsData();

      expect(selected.label, contains('같이 가요'));
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(selected.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(selected.flagsCollection.isButton, isTrue);
      expect(other.label, contains('따로 가요'));
      expect(other.flagsCollection.isSelected, Tristate.isFalse);
      expect(other.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('그룹 문구를 지정하면 스크린리더가 읽는다 (무엇을 고르는지)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        control(onChanged: (_) {}, semanticLabel: '이동 방식'),
      ));

      expect(find.bySemanticsLabel('이동 방식'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('비활성 조각은 활성 상태가 꺼진 것으로 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(control(onChanged: null)));

      final data = tester.getSemantics(segment('따로 가요')).getSemanticsData();

      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('크기와 글자 확대', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 조각 높이 48 이상, 두 조각 높이가 같다', (tester) async {
        await tester.pumpWidget(smashHarness(
          control(onChanged: (_) {}),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        final first = tester.getSize(segment('같이 가요'));
        final second = tester.getSize(segment('따로 가요'));
        expect(first.height, greaterThanOrEqualTo(48));
        expect(first.height, second.height);
      });
    }

    testWidgets('글자가 길고 확대되어도 줄바꿈될 뿐 잘리거나 넘치지 않는다 (2.0배, 조각 3개)', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashSegmentedControl<int>(
          segments: const [
            SmashSegment(value: 0, label: '정규 참여'),
            SmashSegment(value: 1, label: '이월 참여'),
            SmashSegment(value: 2, label: '다른 조 참여'),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
        textScale: 2.0,
      ));

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(segmentLabel('다른 조 참여'));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('조각은 2~4개만 허용한다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashSegmentedControl<int>(
          segments: const [SmashSegment(value: 0, label: '하나')],
          selected: 0,
          onChanged: (_) {},
        ),
      ));

      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
