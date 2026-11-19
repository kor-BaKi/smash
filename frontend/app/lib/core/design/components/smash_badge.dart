import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 배지의 의미. 색과 함께 아이콘과 문구로 전달한다 (색만으로 구분하지 않는다).
enum SmashBadgeTone { neutral, info, success, warning, danger }

/// 상태를 짧게 알리는 알약형 표시 (참석, 불참, 마감, 종료, 납부 완료, 미납 등).
///
/// - 아이콘은 [tone]마다 기본이 정해져 있고, [showIcon]이 false이면 숨긴다 (neutral은 기본 아이콘이 없다)
/// - 눌러지지 않는다. 스크린리더는 [label]을 읽고 아이콘은 읽지 않는다
/// - 글자가 확대되면 줄바꿈으로 높아진다
class SmashBadge extends StatelessWidget {
  const SmashBadge({
    super.key,
    required this.label,
    this.tone = SmashBadgeTone.neutral,
    this.showIcon = true,
  });

  final String label;
  final SmashBadgeTone tone;
  final bool showIcon;

  static IconData? iconFor(SmashBadgeTone tone) => switch (tone) {
        SmashBadgeTone.neutral => null,
        SmashBadgeTone.info => Icons.info_outline,
        SmashBadgeTone.success => Icons.check_circle_outline,
        SmashBadgeTone.warning => Icons.warning_amber_outlined,
        SmashBadgeTone.danger => Icons.error_outline,
      };

  /// tone의 (배경색, 글자색). 대비 검사가 화면에 쓰이는 값을 그대로 읽도록 공개한다.
  static (Color background, Color foreground) colorsFor(SmashBadgeTone tone) => switch (tone) {
        SmashBadgeTone.neutral => (SmashColors.fillDisabled, SmashColors.textSecondary),
        SmashBadgeTone.info => (SmashColors.brandTint, SmashColors.brand),
        SmashBadgeTone.success => (SmashColors.successBg, SmashColors.success),
        SmashBadgeTone.warning => (SmashColors.warningBg, SmashColors.warning),
        SmashBadgeTone.danger => (SmashColors.dangerBg, SmashColors.danger),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(tone);
    final icon = showIcon ? iconFor(tone) : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: SmashRadius.circular(SmashRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmashSpacing.sm,
          vertical: SmashSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(child: Icon(icon, size: 14, color: foreground)),
              const SizedBox(width: SmashSpacing.xs),
            ],
            Flexible(
              child: SmashLabel(
                label,
                style: SmashText.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
