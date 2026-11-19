import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

RenderParagraph _paragraph(WidgetTester tester, Finder textFinder) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: textFinder, matching: find.byType(RichText)).first,
    );

/// 글자가 그려진 줄 수. 한 줄이면 선택 영역 상자가 1개이고, 글자 단위로 쪼개지면 글자 수만큼 늘어난다
/// ([textFinder]는 `Text` 위젯 자체 또는 그것을 품은 위젯)
int lineCount(WidgetTester tester, Finder textFinder) {
  final paragraph = _paragraph(tester, textFinder);
  final length = paragraph.text.toPlainText().length;
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length))
      .length;
}

/// 줄바꿈이 낱말 한가운데에서 일어난 곳의 수 (공백에서 줄이 바뀌면 0).
/// 글자마다 상자를 구해 같은 낱말 안의 이웃한 두 글자의 세로 위치가 다르면 낱말 중간에서 줄이 바뀐 것이다
int midWordBreaks(WidgetTester tester, Finder textFinder) {
  final paragraph = _paragraph(tester, textFinder);
  final text = paragraph.text.toPlainText();
  double? previousTop;
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '⁠') continue;
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
