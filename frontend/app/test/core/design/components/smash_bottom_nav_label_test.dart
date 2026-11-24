import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';
import '../../../support/screen_pump.dart';

/// 하단 탭 라벨은 13sp(caption 토큰)이고, 탭 5개 × 폭 320/360/390 × 글자 1.0/1.3/2.0배(1.3으로 제한)에서 한 줄에 들어간다
void main() {
  setUpAll(loadPretendard);

  const tabs = [
    SmashNavDestination(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    SmashNavDestination(
      label: '투표',
      icon: Icons.how_to_vote_outlined,
      selectedIcon: Icons.how_to_vote,
    ),
    SmashNavDestination(
      label: '달력',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    SmashNavDestination(
      label: '설정',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
    SmashNavDestination(
      label: '운영',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
    ),
  ];

  /// 탭 라벨의 글자 그리기 객체들 (배지 글자는 제외)
  List<RenderParagraph> labelParagraphs(WidgetTester tester) {
    final names = tabs.map((t) => t.label).toSet();
    return [
      for (final e in find.byType(RichText).evaluate())
        if (e.renderObject is RenderParagraph &&
            names.contains(
              (e.renderObject! as RenderParagraph).text
                  .toPlainText()
                  .replaceAll('⁠', ''),
            ))
          e.renderObject! as RenderParagraph,
    ];
  }

  test('라벨 크기는 caption 토큰과 같은 13이다', () {
    expect(SmashText.caption.fontSize, 13);
  });

  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (var selected = 0; selected < tabs.length; selected++) {
        testWidgets('5탭 | 폭 $width | 글자 $scale배 | ${tabs[selected].label} 선택', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            smashHarness(
              SmashBottomNav(
                destinations: tabs,
                selectedIndex: selected,
                onSelected: (_) {},
              ),
              textScale: scale,
              width: width,
            ),
          );
          await tester.pumpAndSettle();

          final labels = labelParagraphs(tester);
          expect(labels.length, 5);
          for (final p in labels) {
            final text = p.text.toPlainText().replaceAll('⁠', '');
            // 줄 수 = 글자 높이 / (13sp × 줄 높이 1.2 × 적용된 글자 배율)
            final applied = scale > 1.3 ? 1.3 : scale;
            expect(
              (p.size.height / (13 * 1.2 * applied)).round(),
              1,
              reason: '$text 한 줄',
            );
            final left = p.localToGlobal(Offset.zero).dx;
            expect(left, greaterThanOrEqualTo(-0.5), reason: text);
            expect(
              left + p.size.width,
              lessThanOrEqualTo(width + 0.5),
              reason: text,
            );
            // 라벨 크기 13 (글자 배율은 1.3까지만 곱해진다)
            expect(p.text.style?.fontSize, 13, reason: text);
            expect(
              p.textScaler.scale(13),
              closeTo(13 * (scale > 1.3 ? 1.3 : scale), 0.01),
              reason: text,
            );
          }
          // 각 칸은 조작 크기 이상이다
          for (final item in find.byType(SmashPressable).evaluate()) {
            final size = tester.getSize(find.byWidget(item.widget));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
