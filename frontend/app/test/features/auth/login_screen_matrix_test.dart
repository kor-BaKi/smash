import 'package:app/features/auth/auth_messages.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/login_screen_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_pump.dart';

/// 로그인 화면의 상태 5가지를 기기 폭 320/360/390 × 글자 1.0/1.3/2.0 × 키보드(없음/올라옴) 행렬로 검증한다.
///
/// 모든 칸에서: 오류(오버플로) 없음, 글자가 폭을 넘지 않음, 입력창 두 개와 로그인, 가입하기가 스크롤로 닿을 수 있고
/// 닿았을 때 보이는 영역(상태 표시줄 아래, 키보드/홈 막대 위) 안에 온전히 들어오며, 조작 요소가 48 이상이고,
/// 입력창을 눌러 포커스를 주면 키보드 위에 남는다.
void main() {
  setUpAll(loadPretendard);

  // 인터랙션 상태(직접 눌러 보기)를 뺀 5가지
  final states = loginScreenEntry.states.take(5).toList();
  test('행렬이 검증하는 상태 5가지가 계획한 것이다', () {
    expect(states.map((s) => s.label), [
      '초기',
      '입력 오류',
      '제출 중',
      '서버·네트워크 오류',
      '제한·불가 (시도 횟수 초과)',
    ]);
  });

  final loginButton = find.widgetWithText(SmashButton, '로그인');
  final signupButton = find.widgetWithText(SmashButton, '가입하기');
  Finder textField(int i) => find.byType(TextField).at(i);

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
              loginScreenEntry,
              state,
              conditions: c,
              settle: state.label != '제출 중',
            );

            // 입력 오류 상태는 화면 안에서 만든다: 빈 칸으로 로그인을 누른다
            if (state.label == '입력 오류') {
              await tester.ensureVisible(loginButton);
              await tester.tap(loginButton);
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.text(AuthMessages.studentNoRequired), findsOneWidget);
              expect(find.text(AuthMessages.passwordRequired), findsOneWidget);
            }

            final viewTop = ScreenConditions.safeTop;
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

            // 핵심 요소가 모두 있고, 스크롤로 닿으면 보이는 영역 안에 온전히 들어온다
            final targets = <String, Finder>{
              '학번 입력창': textField(0),
              '비밀번호 입력창': textField(1),
              '로그인 버튼': loginButton,
              '가입하기 버튼': signupButton,
            };
            for (final e in targets.entries) {
              expect(e.value, findsOneWidget, reason: e.key);
              await tester.ensureVisible(e.value);
              await tester.pump();
              expectInside(e.value, e.key);
              final size = tester.getSize(e.value);
              expect(
                size.height,
                greaterThanOrEqualTo(48),
                reason: '${e.key} 높이',
              );
              if (e.key.contains('버튼')) {
                expect(
                  size.width,
                  greaterThanOrEqualTo(48),
                  reason: '${e.key} 폭',
                );
              }
            }

            // 오류 안내는 닿을 수 있고 온전히 보인다
            final notice = find.byType(SmashInlineNotice);
            if (state.label.startsWith('서버') || state.label.startsWith('제한')) {
              expect(notice, findsOneWidget);
              await tester.ensureVisible(notice);
              await tester.pump();
              expectInside(notice, '오류 안내');
            } else {
              expect(notice, findsNothing);
            }

            // 글자가 폭을 넘지 않는다 (가로 오버플로, 잘림)
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
            for (var i = 0; i < 2; i++) {
              await tester.ensureVisible(textField(i));
              await tester.tap(textField(i));
              await tester.pump(const Duration(milliseconds: 400));
              expectInside(textField(i), '포커스 받은 입력창 $i');
            }

            // 내용이 보이는 영역보다 길면 손가락으로 끌어서 스크롤된다
            final scrollable = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            if (scrollable.position.maxScrollExtent > 0) {
              scrollable.position.jumpTo(0);
              await tester.pump();
              await tester.drag(
                find.byType(SingleChildScrollView),
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
