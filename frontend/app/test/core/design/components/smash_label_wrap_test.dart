import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/no_char_break.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/design/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/segment_label.dart';

/// 글자가 그려진 줄 수. 한 줄이면 선택 영역 상자가 1개이고, 글자 단위로 쪼개지면 글자 수만큼 늘어난다.
int lineCount(WidgetTester tester, Finder textFinder) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: textFinder, matching: find.byType(RichText)).first,
  );
  final length = paragraph.text.toPlainText().length;
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length))
      .length;
}

/// 줄바꿈이 낱말 한가운데에서 일어난 곳의 수 (공백에서 줄이 바뀌면 0).
/// 글자마다 상자를 구해 같은 낱말 안의 이웃한 두 글자의 세로 위치가 다르면 낱말 중간에서 줄이 바뀐 것이다
int midWordBreaks(WidgetTester tester, Finder textFinder) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: textFinder, matching: find.byType(RichText)).first,
  );
  final text = paragraph.text.toPlainText();
  double? previousTop;
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '\u2060') continue;
    if (ch.trim().isEmpty) {
      previousTop = null;
      continue;
    }
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + 1),
    );
    if (boxes.isEmpty) continue;
    final top = boxes.first.top;
    if (previousTop != null && (top - previousTop).abs() > 1) count++;
    previousTop = top;
  }
  return count;
}

/// 낱말 하나를 한 줄로 그렸을 때의 폭
double naturalWidth(String word, double scale, {required bool bold}) {
  final painter = TextPainter(
    text: TextSpan(
      text: word,
      style: bold ? SmashText.bodyStrong : SmashText.body,
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
  )..layout();
  return painter.width;
}

Widget harness(
  Widget child, {
  required double width,
  double scale = 1.0,
  double height = 1200,
}) => MaterialApp(
  theme: SmashTheme.light(),
  builder: (context, a) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(size: Size(width, height), textScaler: TextScaler.linear(scale)),
    child: a!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void sizeScreen(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('noCharBreak', () {
    test('낱말의 글자 사이에만 WORD JOINER를 넣고 공백 옆에는 넣지 않는다', () {
      expect(noCharBreak('오전'), '오\u2060전');
      expect(noCharBreak('같이 가요'), '같\u2060이 가\u2060요');
      expect(noCharBreak('다른  조'), '다\u2060른  조');
      expect(noCharBreak('A'), 'A');
      expect(noCharBreak(''), '');
      expect(noCharBreak(' 가 '), ' 가 ');
    });

    test('원문에서 WORD JOINER만 지우면 원문과 같다', () {
      for (final s in ['오후', '같이 가요', '1주일 뒤', 'abc def', '']) {
        expect(noCharBreak(s).replaceAll('\u2060', ''), s);
      }
    });

    test('이모지 같은 여러 코드 조각 글자는 가운데를 끊지 않는다', () {
      const family = '👨‍👩‍👧';
      expect(noCharBreak('$family가').replaceAll('\u2060', ''), '$family가');
      expect(noCharBreak(family), family);
    });
  });

  group('오전/오후 토글: 선택된 조각도 한 줄이다', () {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final pm in [false, true]) {
          testWidgets(
            '폭 $width, 글자 $scale배, 선택=${pm ? '오후' : '오전'}: 두 조각 모두 한 줄',
            (tester) async {
              sizeScreen(tester, width);
              await tester.pumpWidget(
                harness(
                  SmashTimeFieldPicker(
                    value: DateTime(2026, 11, 12, pm ? 15 : 9, 30),
                    isSelectable: (_) => true,
                    onChanged: (_) {},
                  ),
                  width: width,
                  scale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
              for (final label in ['오전', '오후']) {
                final text = segmentLabel(label);
                expect(lineCount(tester, text), 1, reason: '$label 줄 수');
                expect(midWordBreaks(tester, text), 0, reason: label);
              }
              // 선택된 조각은 체크 아이콘과 글자가 조각 안에 모두 들어 있다
              final selected = segmentLabel(pm ? '오후' : '오전');
              final face = find.ancestor(
                of: selected,
                matching: find.byType(SmashPressable),
              );
              final faceRect = tester.getRect(face);
              final textRect = tester.getRect(selected);
              expect(textRect.left, greaterThanOrEqualTo(faceRect.left));
              expect(textRect.right, lessThanOrEqualTo(faceRect.right));
            },
          );
        }
      }
    }

    testWidgets('두 조각의 폭은 같고, 오전과 오후를 바꿔 눌러도 토글 폭이 변하지 않는다', (tester) async {
      sizeScreen(tester, 360);
      var value = DateTime(2026, 11, 12, 9, 30);
      late StateSetter set;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return SmashTimeFieldPicker(
                value: value,
                isSelectable: (_) => true,
                onChanged: (_) {},
              );
            },
          ),
          width: 360,
          scale: 2.0,
        ),
      );
      final control = find.byType(SmashSegmentedControl<bool>);
      final amWidth = tester.getSize(control).width;
      final am = tester
          .getSize(
            find.ancestor(
              of: segmentLabel('오전'),
              matching: find.byType(SmashPressable),
            ),
          )
          .width;
      final pm = tester
          .getSize(
            find.ancestor(
              of: segmentLabel('오후'),
              matching: find.byType(SmashPressable),
            ),
          )
          .width;
      expect(am, pm);

      set(() => value = DateTime(2026, 11, 12, 15, 30));
      await tester.pump();
      expect(tester.getSize(control).width, closeTo(amWidth, 1.0));
    });
  });

  group('SmashSegmentedControl: 한글 라벨은 글자 단위로 쪼개지지 않는다', () {
    Widget control(List<String> labels, {int selected = 0}) =>
        SmashSegmentedControl<int>(
          segments: [
            for (var i = 0; i < labels.length; i++)
              SmashSegment(value: i, label: labels[i]),
          ],
          selected: selected,
          onChanged: (_) {},
        );

    for (final selected in [0, 1]) {
      testWidgets(
        '"같이 가요 | 따로 가요" 폭 320, 글자 2.0배, 선택=$selected: 줄바꿈은 공백에서만 일어난다',
        (tester) async {
          sizeScreen(tester, 320);
          await tester.pumpWidget(
            harness(
              control(['같이 가요', '따로 가요'], selected: selected),
              width: 320,
              scale: 2.0,
            ),
          );
          expect(tester.takeException(), isNull);
          for (final label in ['같이 가요', '따로 가요']) {
            expect(
              midWordBreaks(tester, segmentLabel(label)),
              0,
              reason: label,
            );
            expect(
              lineCount(tester, segmentLabel(label)),
              lessThanOrEqualTo(2),
            );
          }
        },
      );
    }

    // 한 줄에 들어가는 낱말은 어떤 폭에서도 낱말 중간에서 줄이 바뀌지 않는다.
    // (한 낱말이 한 줄 폭보다 길면 엔진이 어쩔 수 없이 글자 단위로 끊으므로 그 경우는 제외한다)
    testWidgets(
      '폭 140~400 × 글자 1.0/1.3/2.0 × 선택 조각 3가지: 낱말이 들어갈 폭이면 낱말 중간에서 줄이 바뀌지 않는다',
      (tester) async {
        final labels = ['같이 가요', '따로 가요', '다른 조 참여', '이월 참여', '정규 참여'];
        var checked = 0;
        for (final scale in [1.0, 1.3, 2.0]) {
          for (var width = 140.0; width <= 400; width += 10) {
            for (final selected in [0, 2]) {
              sizeScreen(tester, width);
              await tester.pumpWidget(
                KeyedSubtree(
                  key: UniqueKey(),
                  child: harness(
                    control(labels.sublist(0, 3), selected: selected),
                    width: width,
                    scale: scale,
                  ),
                ),
              );
              // 조각이 너무 좁아 아이콘과 글자가 안 들어가는 조합은 넘침 경고가 나는데, 아래에서 걸러지므로 여기서는 지운다
              tester.takeException();
              for (var i = 0; i < 3; i++) {
                final label = labels[i];
                final face = tester.getSize(
                  find.ancestor(
                    of: segmentLabel(label),
                    matching: find.byType(SmashPressable),
                  ),
                );
                final content = face.width - 16 - (i == selected ? 22 : 0);
                final widest = label
                    .split(' ')
                    .map((w) => naturalWidth(w, scale, bold: i == selected))
                    .reduce((a, b) => a > b ? a : b);
                // WORD JOINER가 글자마다 아주 작은 폭(테스트 엔진에서 약 0.3px)을 가지므로 2px 여유를 둔다
                if (content < widest + 2) continue;
                checked++;
                expect(
                  midWordBreaks(tester, segmentLabel(label)),
                  0,
                  reason: '$label 폭 $width 글자 $scale배 선택 $selected',
                );
              }
            }
          }
        }
        expect(checked, greaterThan(100), reason: '충분한 조합을 검사했는지');
      },
    );

    testWidgets('스크린리더는 라벨 원문을 읽는다 (WORD JOINER가 섞이지 않는다)', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester, 360);
      await tester.pumpWidget(harness(control(['같이 가요', '따로 가요']), width: 360));

      expect(find.bySemanticsLabel('같이 가요'), findsOneWidget);
      expect(find.bySemanticsLabel('따로 가요'), findsOneWidget);
      for (final label in ['같이 가요', '따로 가요']) {
        final text = tester.widget<Text>(segmentLabel(label));
        expect(text.semanticsLabel, label);
        expect(text.semanticsLabel!.contains('\u2060'), isFalse);
        expect(
          tester.getSemantics(segmentLabel(label)).label.contains('\u2060'),
          isFalse,
        );
      }
      handle.dispose();
    });
  });
}
