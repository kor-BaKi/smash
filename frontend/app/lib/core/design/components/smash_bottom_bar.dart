import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// 화면 아래에 붙어 있는 행동 영역 (예: 저장 버튼 하나). 위에 선이 있고, 홈 인디케이터 영역을 피한다.
/// [SmashScaffold.bottom]에 넣어 쓴다: 키보드가 올라오면 키보드 위에 붙고, 그때는 홈 인디케이터 여백을 빼 준다.
class SmashBottomBar extends StatelessWidget {
  const SmashBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SmashSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SmashColors.surface,
        border: Border(top: BorderSide(color: SmashColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
