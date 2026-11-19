import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [SmashSegmentedControl] 조각의 글자 위젯을 라벨 원문으로 찾는다.
/// 조각 글자는 `SmashLabel`이라 `data`가 원문이므로 `find.text(label)`로도 찾을 수 있다. 이 함수는 `Text`의 의미 라벨이
/// 지정된 경우(`semanticsLabel`)도 함께 원문으로 본다.
Finder segmentLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Text && (widget.semanticsLabel ?? widget.data) == label,
  description: 'segment label "$label"',
);
