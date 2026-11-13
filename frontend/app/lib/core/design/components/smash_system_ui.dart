import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';

/// 상태 표시줄과 시스템 내비게이션 바의 모양. 화면 배경이 밝으므로 아이콘은 어둡게 한다.
class SmashSystemUi {
  const SmashSystemUi._();

  static final SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS: 밝은 배경 = 어두운 아이콘
    systemNavigationBarColor: SmashColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );
}

/// 이 영역이 화면에 있는 동안 [SmashSystemUi.light]를 적용한다.
/// (화면마다 따로 SystemChrome을 호출하지 않고, 화면이 사라지면 이전 모양으로 자동으로 돌아간다)
class SmashSystemUiRegion extends StatelessWidget {
  const SmashSystemUiRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SmashSystemUi.light,
      child: child,
    );
  }
}
