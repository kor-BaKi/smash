import 'package:flutter/widgets.dart';

/// 하위 [SmashPressable]을 눌린 모양으로 고정한다.
///
/// 개발용 카탈로그와 테스트에서 "눌림" 상태를 손가락 없이 보기 위한 것이다.
/// 앱 화면에서는 쓰지 않는다.
class SmashForcePressed extends InheritedWidget {
  const SmashForcePressed({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SmashForcePressed>() != null;

  @override
  bool updateShouldNotify(SmashForcePressed oldWidget) => false;
}
