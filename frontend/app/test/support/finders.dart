import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화면의 모든 `Text` 위젯 (하위 클래스인 `SmashLabel` 포함).
///
/// `find.byType(Text)`는 타입을 정확히 비교해서 `Text`의 하위 클래스인 `SmashLabel`을 찾지 못한다.
/// 컴포넌트의 글자는 모두 `SmashLabel`이므로 "모든 글자"가 필요한 곳에서는 이것을 쓴다.
Finder anyText() => find.byWidgetPredicate(
  (widget) => widget is Text,
  description: 'any Text (SmashLabel 포함)',
);
