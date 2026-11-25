import 'package:app/features/auth/auth_messages.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/signup_screen_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_pump.dart';

/// 가입 화면의 상태 5가지를 기기 폭 320/360/390 × 글자 1.0/1.3/2.0 × 키보드(없음/올라옴) 행렬로 검증한다.
///
/// 칸마다: 오류(오버플로) 없음, 글자가 폭을 넘지 않음, 진행 표시와 입력창과 주 버튼(실패 상태는 안내 상자와 1단계로 가기)이
/// 스크롤로 닿아 보이는 영역(앱바 아래, 키보드/홈 막대 위) 안에 온전히 들어옴, 조작 요소 48 이상,
/// 입력창을 눌러 포커스를 주면 키보드 위에 남음, 끌어서 스크롤됨.
void main() {
  setUpAll(loadPretendard);

  final states = signupScreenEntry.states.take(5).toList();
  test('행렬이 검증하는 상태 5가지가 계획한 것이다', () {
    expect(states.map((s) => s.label), [
      '1단계 초기',
      '입력 오류 (1단계)',
      '2단계 학번',
      '제출 중 (3단계)',
      '가입 실패 (3단계)',
    ]);
  });

  // 상태 → 맨 위 화면의 주 버튼 이름
  const primary = {
    '1단계 초기': '다음',
    '입력 오류 (1단계)': '다음',
    '2단계 학번': '다음',
    '제출 중 (3단계)': '가입하기',
    '가입 실패 (3단계)': '가입하기',
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
            await pumpScreen(
              tester,
              signupScreenEntry,
              state,
              conditions: c,
              settle: !state.label.startsWith('제출 중'),
            );

            // 쌓인 화면이 여럿이면(예: 2단계 아래의 1단계) 맨 위 화면의 것이 마지막이다
            final button = find
                .widgetWithText(SmashButton, primary[state.label]!)
                .last;
            final field = find.byType(TextField).last;

            // 입력 오류 상태는 화면 안에서 만든다: 빈 칸으로 다음을 누른다
            if (state.label.startsWith('입력 오류')) {
              await tester.ensureVisible(button);
              await tester.tap(button);
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.text(AuthMessages.codeRequired), findsOneWidget);
            }

            final viewTop = tester
                .getRect(find.byType(SmashAppBar).last)
                .bottom;
            final viewBottom =
                c.height -
                (keyboard > 0 ? keyboard : ScreenConditions.safeBottom);

            void expectInside(Finder f, String name) {
              final r = tester.getRect(f);
              final reason =
                  '$name $r, 보이는 영역 0..$width × $viewTop..$viewBottom';
              expect(r.left, greaterThanOrEqualTo(-0.5), reason: reason);
              expect(r.right, lessThanOrEqualTo(width + 0.5), reason: reason);
              expect(
                r.top,
                greaterThanOrEqualTo(viewTop - 0.5),
                reason: reason,
              );
              expect(
                r.bottom,
                lessThanOrEqualTo(viewBottom + 0.5),
                reason: reason,
              );
            }

            final targets = <String, Finder>{
              '진행 표시': find.byType(SmashStepIndicator).last,
              '입력창': field,
              '주 버튼': button,
            };
            final failed = state.label.startsWith('가입 실패');
            if (failed) {
              targets['안내 상자'] = find.byType(SmashInlineNotice);
              targets['1단계로 가기 버튼'] = find.widgetWithText(
                SmashButton,
                '1단계로 가기',
              );
            }
            final viewHeight = viewBottom - viewTop;
            for (final e in targets.entries) {
              expect(e.value, findsOneWidget, reason: e.key);
              await tester.ensureVisible(e.value);
              await tester.pump();
              final height = tester.getSize(e.value).height;
              if (height <= viewHeight) {
                expectInside(e.value, e.key);
              } else {
                // 보이는 영역(키보드 위)보다 큰 요소는 한 번에 다 보일 수 없다: 위쪽 끝과 아래쪽 끝이 각각 스크롤로 닿아야 한다
                final top = tester.getRect(e.value).top;
                expect(
                  top,
                  greaterThanOrEqualTo(viewTop - 0.5),
                  reason: '${e.key} 위쪽 끝',
                );
                Scrollable.ensureVisible(tester.element(e.value), alignment: 1);
                await tester.pump();
                final bottom = tester.getRect(e.value).bottom;
                expect(
                  bottom,
                  lessThanOrEqualTo(viewBottom + 0.5),
                  reason: '${e.key} 아래쪽 끝',
                );
              }
              if (e.key.contains('버튼') || e.key == '입력창') {
                expect(height, greaterThanOrEqualTo(48), reason: '${e.key} 높이');
              }
            }
            expect(
              find.byType(SmashInlineNotice),
              failed ? findsOneWidget : findsNothing,
            );

            // 글자가 폭을 넘지 않는다
            for (final element in find.byType(RichText).evaluate()) {
              final box = element.renderObject! as RenderParagraph;
              final left = box.localToGlobal(Offset.zero).dx;
              expect(
                left,
                greaterThanOrEqualTo(-0.5),
                reason: box.text.toPlainText(),
              );
              expect(
                left + box.size.width,
                lessThanOrEqualTo(width + 0.5),
                reason: '${box.text.toPlainText()} 폭 ${box.size.width}',
              );
            }

            // 입력창을 눌러 포커스를 주면 키보드 위에 남는다
            await tester.ensureVisible(field);
            await tester.tap(field);
            await tester.pump(const Duration(milliseconds: 400));
            expectInside(field, '포커스 받은 입력창');

            // 내용이 보이는 영역보다 길면 끌어서 스크롤된다
            final scrollable = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            if (scrollable.position.maxScrollExtent > 0) {
              scrollable.position.jumpTo(0);
              await tester.pump();
              await tester.drag(
                find.byType(SingleChildScrollView).last,
                const Offset(0, -100),
              );
              await tester.pump();
              expect(
                scrollable.position.pixels,
                greaterThan(0),
                reason: '끌어서 스크롤된다',
              );
            }

            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
