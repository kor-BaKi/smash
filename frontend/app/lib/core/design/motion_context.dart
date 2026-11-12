import 'package:flutter/widgets.dart';

/// 모션 줄이기(시스템 접근성 설정) 대응.
///
/// 줄이기가 켜지면 위치와 크기가 움직이는 모션은 없애고, 색과 투명도 전환만 남긴다.
extension SmashMotionContext on BuildContext {
  /// 시스템에서 애니메이션 줄이기를 켰는지
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// 위치와 크기가 변하는 모션의 길이. 줄이기가 켜져 있으면 0
  Duration moveDuration(Duration duration) =>
      reduceMotion ? Duration.zero : duration;
}
