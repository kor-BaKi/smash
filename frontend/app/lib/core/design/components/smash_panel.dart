import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import 'smash_pressable.dart';

enum SmashPanelVariant {
  /// 브랜드 색으로 채움. 화면에서 가장 중요한 한 곳(오늘 활동)에만 쓴다
  filled,

  /// 흰 배경 + 테두리. 일반 묶음
  outlined,

  /// 연한 브랜드 배경. 안내, 요약
  tinted,
}

/// 내용을 묶는 면. 안에 카드를 또 넣지 않는다.
///
/// - [onTap]이 있으면 누를 수 있는 면이 되어 눌림 모양(크기 0.97배, 색 변화)과 버튼 역할이 붙는다
/// - [SmashPanelVariant.filled] 안의 글자와 아이콘 기본색은 브랜드 위 흰색이다 (직접 색을 정한 글자는 그대로)
class SmashPanel extends StatelessWidget {
  const SmashPanel({
    super.key,
    required this.child,
    this.variant = SmashPanelVariant.outlined,
    this.padding = const EdgeInsets.all(SmashSpacing.md),
    this.onTap,
  });

  final Widget child;
  final SmashPanelVariant variant;
  final EdgeInsetsGeometry padding;

  /// null이면 눌러지지 않는 면
  final VoidCallback? onTap;

  Color get _foreground =>
      variant == SmashPanelVariant.filled ? SmashColors.onBrand : SmashColors.text;

  Color _background(bool pressed) => switch (variant) {
        SmashPanelVariant.filled => pressed ? SmashColors.brandPressed : SmashColors.brand,
        SmashPanelVariant.outlined => pressed ? SmashColors.background : SmashColors.surface,
        SmashPanelVariant.tinted => pressed ? SmashColors.brandTint : SmashColors.brandTintSoft,
      };

  Widget _face({required bool pressed}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _background(pressed),
        borderRadius: SmashRadius.circular(SmashRadius.lg),
        border: variant == SmashPanelVariant.outlined
            ? Border.all(color: SmashColors.line)
            : null,
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: _foreground),
          child: IconTheme.merge(
            data: IconThemeData(color: _foreground),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Semantics(container: true, child: _face(pressed: false));
    }
    return SmashPressable(
      onPressed: onTap,
      borderRadius: SmashRadius.circular(SmashRadius.lg),
      minSize: const Size.square(SmashSpacing.minTouchTarget),
      builder: (context, states) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: SmashRadius.circular(SmashRadius.lg),
          border: states.contains(WidgetState.focused)
              ? Border.all(color: SmashColors.text, width: 2)
              : null,
        ),
        child: _face(pressed: states.contains(WidgetState.pressed)),
      ),
    );
  }
}
