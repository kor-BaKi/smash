import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/home_shell_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/features/home/page/admin_menu_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_pump.dart';

/// 홈 셸 상태 5가지를 기기 폭 320/360/390 × 글자 1.0/1.3/2.0 × 키보드(없음/올라옴) 행렬로 검증한다.
///
/// 칸마다: 오류(오버플로) 없음, 탭 막대는 키보드가 없을 때만 보이고 라벨이 한 줄이며 폭 안에 있고 내용과 겹치지 않음,
/// 앱바는 많아야 하나(셸이 앱바를 더하지 않는다, 옛 화면 흉내의 자기 앱바 하나뿐), 운영 탭은 10개 항목이 모두 스크롤로 닿음.
void main() {
  setUpAll(loadPretendard);

  // 옛 홈 탭 내용(NeedGroupNotice)은 스크롤이 없는 Column이라 작은 화면, 큰 글자, 키보드에서 넘친다.
  // 예전 HomePage 안에서도 같은 구조였고 S3(홈 탭)에서 교체한다. 그 위젯의 넘침만 세어 두고 그 밖의 오류는 허용하지 않는다
  var legacyOverflowCells = 0;
  tearDownAll(() {
    // ignore: avoid_print
    print('LEGACY-NEEDGROUP-OVERFLOW-CELLS=$legacyOverflowCells');
  });

  final states = homeShellScreenEntry.states.take(5).toList();
  test('행렬이 검증하는 상태 5가지가 계획한 것이다', () {
    expect(states.map((s) => s.label), [
      '회원 홈 탭 (4탭, 조 미배정 안내)',
      '회원 투표 탭 (옛 화면 흉내: 자기 AppBar)',
      '운영진 홈 탭 (5탭)',
      '운영진 운영 탭 (10개 항목)',
      '운영진 설정 탭 (옛 화면 흉내: 자기 Scaffold와 AppBar)',
    ]);
  });

  const expectedTabs = {
    '회원 홈 탭 (4탭, 조 미배정 안내)': ['홈', '투표', '달력', '설정'],
    '회원 투표 탭 (옛 화면 흉내: 자기 AppBar)': ['홈', '투표', '달력', '설정'],
    '운영진 홈 탭 (5탭)': ['홈', '투표', '달력', '설정', '운영'],
    '운영진 운영 탭 (10개 항목)': ['홈', '투표', '달력', '설정', '운영'],
    '운영진 설정 탭 (옛 화면 흉내: 자기 Scaffold와 AppBar)': ['홈', '투표', '달력', '설정', '운영'],
  };

  for (final state in states) {
    for (final width in ScreenConditions.widths) {
      for (final scale in ScreenConditions.textScales) {
        for (final keyboard in [0.0, ScreenConditions.keyboardUp]) {
          final c = ScreenConditions(
            width: width,
            textScale: scale,
            keyboardHeight: keyboard,
          );
          testWidgets('${state.label} | $c', (tester) async {
            // 홈 탭 상태는 옛 NeedGroupNotice의 넘침을 따로 모은다 (다른 상태는 어떤 오류도 허용하지 않는다)
            final legacyHome = state.label.contains('홈 탭');
            final captured = <FlutterErrorDetails>[];
            // 가로챈 오류 처리는 테스트가 실패하더라도 본문 안에서 반드시 되돌린다 (그렇지 않으면 테스트 틀이 멈춘다)
            final originalOnError = FlutterError.onError;
            if (legacyHome) FlutterError.onError = captured.add;
            try {
              await pumpScreen(
                tester,
                homeShellScreenEntry,
                state,
                conditions: c,
              );

              // 앱바: 셸은 더하지 않는다
              expect(find.byType(SmashAppBar), findsNothing);
              expect(
                find.byType(AppBar).evaluate().length,
                lessThanOrEqualTo(1),
                reason: '앱바가 이중으로 보이지 않는다',
              );

              final tabs = expectedTabs[state.label]!;
              double bodyBottom =
                  c.height -
                  (keyboard > 0 ? keyboard : ScreenConditions.safeBottom);

              if (keyboard > 0) {
                expect(
                  find.byType(SmashBottomNav),
                  findsNothing,
                  reason: '키보드가 올라오면 탭 막대를 숨긴다',
                );
              } else {
                final navFinder = find.byType(SmashBottomNav);
                expect(navFinder, findsOneWidget);
                final navRect = tester.getRect(navFinder);
                expect(navRect.left, greaterThanOrEqualTo(-0.5));
                expect(navRect.right, lessThanOrEqualTo(width + 0.5));
                expect(
                  navRect.bottom,
                  closeTo(c.height, 0.5),
                  reason: '화면 맨 아래에 붙는다',
                );
                bodyBottom = navRect.top;

                final nav = tester.widget<SmashBottomNav>(navFinder);
                expect(nav.destinations.map((d) => d.label).toList(), tabs);
                // 라벨은 한 줄이고 폭 안에 있다 (글자 확대는 1.3배까지만 따라간다)
                final applied = scale > 1.3 ? 1.3 : scale;
                for (final label in tabs) {
                  final p = find
                      .descendant(
                        of: navFinder,
                        matching: find.byType(RichText),
                      )
                      .evaluate()
                      .map((e) => e.renderObject)
                      .whereType<RenderParagraph>()
                      .firstWhere(
                        (p) =>
                            p.text.toPlainText().replaceAll('⁠', '') == label,
                      );
                  expect(
                    (p.size.height / (13 * 1.2 * applied)).round(),
                    1,
                    reason: '$label 한 줄',
                  );
                  final left = p.localToGlobal(Offset.zero).dx;
                  expect(left, greaterThanOrEqualTo(-0.5), reason: label);
                  expect(
                    left + p.size.width,
                    lessThanOrEqualTo(width + 0.5),
                    reason: label,
                  );
                }
                // 탭 칸은 조작 크기 이상이다
                for (final item
                    in find
                        .descendant(
                          of: navFinder,
                          matching: find.byType(SmashPressable),
                        )
                        .evaluate()) {
                  final size = tester.getSize(find.byWidget(item.widget));
                  expect(size.width, greaterThanOrEqualTo(48));
                  expect(size.height, greaterThanOrEqualTo(48));
                }
              }

              // 운영 탭: 항목 10개가 모두 스크롤로 닿고 보이는 영역(상태 표시줄 아래, 탭 막대/키보드 위) 안에 들어온다
              if (state.label.contains('운영 탭')) {
                final labels = adminMenuSections
                    .expand((s) => s.items)
                    .map((i) => i.label)
                    .toList();
                expect(labels.length, 10);
                for (final label in labels) {
                  await tester.ensureVisible(find.text(label));
                  await tester.pump();
                  final rect = tester.getRect(find.text(label));
                  expect(
                    rect.top,
                    greaterThanOrEqualTo(ScreenConditions.safeTop - 0.5),
                    reason: label,
                  );
                  expect(
                    rect.bottom,
                    lessThanOrEqualTo(bodyBottom + 0.5),
                    reason: label,
                  );
                  expect(
                    rect.right,
                    lessThanOrEqualTo(width + 0.5),
                    reason: label,
                  );
                }
                // 끌어서 스크롤된다
                final scrollable = tester.state<ScrollableState>(
                  find.byType(Scrollable).first,
                );
                scrollable.position.jumpTo(0);
                await tester.pump();
                await tester.drag(
                  find.byType(ListView).first,
                  const Offset(0, -100),
                );
                await tester.pump();
                expect(scrollable.position.pixels, greaterThan(0));
              }

              // 글자가 폭을 넘지 않는다 (옛 화면 흉내의 글자는 옛 디자인이라 제외하고, 새 디자인 글자만)
              for (final element in find.byType(SmashLabel).evaluate()) {
                final box = element.renderObject;
                if (box is! RenderParagraph) continue;
                final left = box.localToGlobal(Offset.zero).dx;
                expect(
                  left,
                  greaterThanOrEqualTo(-0.5),
                  reason: box.text.toPlainText(),
                );
                expect(
                  left + box.size.width,
                  lessThanOrEqualTo(width + 0.5),
                  reason: box.text.toPlainText(),
                );
              }

              if (legacyHome) {
                for (final error in captured) {
                  final text = error.toString();
                  expect(
                    text,
                    contains('overflowed'),
                    reason: '넘침 말고 다른 오류는 없다: $text',
                  );
                  expect(
                    text,
                    contains('home_need_group_notice.dart'),
                    reason: '옛 NeedGroupNotice의 넘침뿐이다',
                  );
                }
                if (captured.isNotEmpty) legacyOverflowCells++;
              }
              expect(tester.takeException(), isNull);
            } finally {
              FlutterError.onError = originalOnError;
            }
          });
        }
      }
    }
  }
}
