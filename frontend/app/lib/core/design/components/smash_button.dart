import 'package:flutter/material.dart';

import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_pressable.dart';

enum SmashButtonVariant { primary, secondary, text, danger }

/// large: 높이 52 (화면의 주 행동), medium: 높이 48 (보조 위치)
enum SmashButtonSize { large, medium }

void _doNothing() {}

/// SMASH 버튼.
///
/// - 비활성: [onPressed]가 null
/// - 로딩: [isLoading]이 true이면 글자 대신 진행 표시를 보이고 누름을 무시한다.
///   크기는 그대로라서 화면이 흔들리지 않는다. (요청이 시작되기 전에는 비활성으로 만들지 않는다)
/// - 글자 크기를 키우면 높이가 늘어난다 (줄어들지 않는다)
class SmashButton extends StatelessWidget {
  const SmashButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SmashButtonVariant.primary,
    this.size = SmashButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.haptic,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SmashButtonVariant variant;
  final SmashButtonSize size;
  final IconData? icon;
  final bool isLoading;

  /// true이면 가능한 너비를 모두 쓴다
  final bool expanded;
  final SmashHaptic? haptic;

  /// true이면 화면이 열릴 때 이 버튼에 포커스가 간다 (위험한 확인 대화상자에서 취소 버튼에 쓴다)
  final bool autofocus;

  double get _minHeight => size == SmashButtonSize.large ? 52 : 48;

  @override
  Widget build(BuildContext context) {
    final button = SmashPressable(
      onPressed: isLoading ? _doNothing : onPressed,
      haptic: isLoading ? null : haptic, // 로딩 중 누름은 무시하므로 햅틱도 없다
      borderRadius: SmashRadius.circular(SmashRadius.md),
      minSize: Size(SmashSpacing.minTouchTarget, _minHeight),
      semanticLabel: isLoading ? '$label, 처리 중' : null,
      autofocus: autofocus,
      builder: _buildFace,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildFace(BuildContext context, Set<WidgetState> states) {
    final colors = _colorsFor(states);
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: SmashText.bodyStrong.copyWith(color: colors.foreground),
    );
    final labelRow = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: colors.foreground),
          const SizedBox(width: SmashSpacing.sm),
        ],
        Flexible(child: text),
      ],
    );

    return AnimatedContainer(
      duration: SmashMotion.fast,
      curve: SmashMotion.easeOut,
      constraints: BoxConstraints(minHeight: _minHeight),
      // 세로 여백은 8: 글자 24 + 여백 16 + 테두리 2 = 42라서 최소 높이(48, 52)가 높이를 정한다
      padding: const EdgeInsets.symmetric(
        horizontal: SmashSpacing.lg,
        vertical: SmashSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: SmashRadius.circular(SmashRadius.md),
        border: colors.border == null
            ? null
            : Border.all(color: colors.border!, width: 1),
      ),
      foregroundDecoration: states.contains(WidgetState.focused)
          ? BoxDecoration(
              borderRadius: SmashRadius.circular(SmashRadius.md),
              border: Border.all(color: colors.focusRing, width: 2),
            )
          : null,
      // Stack은 안쪽 내용 크기에 맞춰지고 최소 높이까지만 늘어난다
      // (alignment를 쓰는 Container는 부모가 허용하는 높이를 모두 채워 버튼이 커진다)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 로딩 중에도 글자 자리를 유지해서 버튼 크기가 변하지 않게 한다
          Opacity(opacity: isLoading ? 0 : 1, child: labelRow),
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.foreground),
              ),
            ),
        ],
      ),
    );
  }

  _SmashButtonColors _colorsFor(Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);

    switch (variant) {
      case SmashButtonVariant.primary:
        return _SmashButtonColors(
          background: disabled
              ? SmashColors.fillDisabled
              : pressed
                  ? SmashColors.brandPressed
                  : SmashColors.brand,
          foreground: disabled ? SmashColors.textDisabled : SmashColors.onBrand,
          focusRing: SmashColors.onBrand,
        );
      case SmashButtonVariant.danger:
        return _SmashButtonColors(
          background: disabled
              ? SmashColors.fillDisabled
              : pressed
                  ? Color.lerp(SmashColors.danger, Colors.black, 0.12)!
                  : SmashColors.danger,
          foreground: disabled ? SmashColors.textDisabled : SmashColors.onBrand,
          focusRing: SmashColors.onBrand,
        );
      case SmashButtonVariant.secondary:
        return _SmashButtonColors(
          background: pressed ? SmashColors.background : SmashColors.surface,
          foreground: disabled ? SmashColors.textDisabled : SmashColors.text,
          border: disabled ? SmashColors.line : SmashColors.border,
          focusRing: SmashColors.brand,
        );
      case SmashButtonVariant.text:
        return _SmashButtonColors(
          background: pressed ? SmashColors.brandTintSoft : Colors.transparent,
          foreground: disabled ? SmashColors.textDisabled : SmashColors.brand,
          focusRing: SmashColors.brand,
        );
    }
  }
}

class _SmashButtonColors {
  const _SmashButtonColors({
    required this.background,
    required this.foreground,
    required this.focusRing,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color focusRing;
  final Color? border;
}
