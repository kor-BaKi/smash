import 'package:flutter/painting.dart';

import 'colors.dart';

/// 그림자 토큰. 화면은 구분선과 배경 단차로 나누고, 그림자는 떠 있는 요소에만 쓴다.
abstract final class SmashShadows {
  /// 하단 고정 버튼 바 위쪽 테두리 (번지지 않는 1px 선)
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: SmashColors.line, offset: Offset(0, -1), blurRadius: 0),
  ];

  /// 시트, 다이얼로그, 스낵바
  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x1F14171C), // 12%
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
