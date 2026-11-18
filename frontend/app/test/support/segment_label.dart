import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [SmashSegmentedControl] 조각의 글자 위젯을 라벨 원문으로 찾는다.
/// 화면에 그리는 글자에는 글자 사이에 WORD JOINER가 들어 있어서(`noCharBreak`) `find.text('오전')`로는 찾을 수 없고,
/// 원문은 `semanticsLabel`에 그대로 있다.
Finder segmentLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.semanticsLabel == label,
  description: 'segment label "$label"',
);
