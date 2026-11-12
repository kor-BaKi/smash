import 'package:flutter/material.dart';

import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../radius.dart';
import 'smash_pressable.dart';

/// 아이콘만 있는 버튼. 터치 영역은 48x48, 아이콘은 24.
///
/// 글자가 없으므로 스크린리더가 읽을 [semanticLabel]이 반드시 필요하다.
class SmashIconButton extends StatelessWidget {
  const SmashIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.haptic,
  }) : assert(semanticLabel != '', 'semanticLabel은 비워 둘 수 없습니다');

  final IconData icon;
  final String semanticLabel;

  /// null이면 비활성
  final VoidCallback? onPressed;

  /// 아이콘 색. 기본은 본문색
  final Color? color;
  final SmashHaptic? haptic;

  @override
  Widget build(BuildContext context) {
    return SmashPressable(
      onPressed: onPressed,
      haptic: haptic,
      semanticLabel: semanticLabel,
      borderRadius: SmashRadius.circular(SmashRadius.full),
      builder: (context, states) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        return AnimatedContainer(
          duration: SmashMotion.fast,
          curve: SmashMotion.easeOut,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pressed ? SmashColors.fillDisabled : Colors.transparent,
            border: states.contains(WidgetState.focused)
                ? Border.all(color: SmashColors.brand, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            size: 24,
            color: disabled
                ? SmashColors.textDisabled
                : (color ?? SmashColors.text),
          ),
        );
      },
    );
  }
}
