import 'package:flutter/material.dart';

import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_pressable.dart';

/// 필터, 선택용 칩 (이번 주 | 이번 달, 정규 | 이월 등).
///
/// - 눈에 보이는 높이는 40이고 터치 영역은 48 (위아래 4씩 여백을 눌러도 반응한다)
/// - 선택은 색뿐 아니라 체크 아이콘과 굵은 글자로도 구분한다
/// - 눌렀을 때 선택을 바꾸는 일은 화면의 몫이다: [onPressed]에서 상태를 바꾸고 [selected]를 다시 넘긴다
/// - [onPressed]가 null이면 비활성
/// - 글자가 길거나 확대되면 줄바꿈으로 칩이 높아진다 (줄어들지 않는다)
class SmashChip extends StatelessWidget {
  const SmashChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.icon,
    this.haptic,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  /// 선택되지 않았을 때 글자 앞에 보이는 아이콘 (선택되면 체크 아이콘으로 바뀐다)
  final IconData? icon;
  final SmashHaptic? haptic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: SmashPressable(
        onPressed: onPressed,
        haptic: haptic,
        borderRadius: SmashRadius.circular(SmashRadius.full),
        builder: _buildFace,
      ),
    );
  }

  Widget _buildFace(BuildContext context, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);

    final Color background;
    final Color foreground;
    final Color border;
    if (disabled) {
      background = SmashColors.fillDisabled;
      foreground = SmashColors.textDisabled;
      border = SmashColors.line;
    } else if (selected) {
      background = pressed ? SmashColors.brandTint : SmashColors.brandTintSoft;
      foreground = SmashColors.brand;
      border = SmashColors.brand;
    } else {
      background = pressed ? SmashColors.background : SmashColors.surface;
      foreground = SmashColors.text;
      border = SmashColors.border;
    }

    final leadingIcon = selected ? Icons.check : icon;

    // Center(widthFactor, heightFactor: 1)는 칩을 자기 크기로 두고 48dp 터치 영역 안에 가운데 놓는다
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: AnimatedContainer(
        duration: SmashMotion.fast,
        curve: SmashMotion.easeOut,
        constraints: const BoxConstraints(minHeight: 40),
        // 세로 여백은 작게: 한 줄이면 minHeight 40이 높이를 정하고, 글자가 확대돼 줄이 늘면 그만큼 커진다
        padding: const EdgeInsets.symmetric(
          horizontal: SmashSpacing.md,
          vertical: SmashSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: SmashRadius.circular(SmashRadius.full),
          border: Border.all(
            color: states.contains(WidgetState.focused) ? SmashColors.text : border,
            width: selected || states.contains(WidgetState.focused) ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: foreground),
              const SizedBox(width: SmashSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: (selected ? SmashText.bodyStrong : SmashText.body)
                    .copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
