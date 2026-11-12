import 'package:flutter/services.dart';

import 'haptics.dart';

/// 햅틱 호출. 어느 지점에서 어떤 종류를 쓸지는 [SmashHaptic]의 설명을 따른다.
///
/// 오류에는 쓰지 않는다. 호출하는 쪽은 결과가 성공으로 확정된 뒤에 부른다.
abstract final class SmashHaptics {
  static Future<void> fire(SmashHaptic haptic) {
    return switch (haptic) {
      SmashHaptic.selection => HapticFeedback.selectionClick(),
      SmashHaptic.light => HapticFeedback.lightImpact(),
      SmashHaptic.medium => HapticFeedback.mediumImpact(),
    };
  }
}
