import 'package:flutter/material.dart';

import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_badge.dart';
import 'smash_button.dart';

enum SmashNoticeTone { info, success, warning, danger }

/// 화면 안에 계속 보이는 안내 (사라지지 않는 스낵바). 폼 전체에 대한 오류, 상태 설명에 쓴다.
/// 입력창 하나에 대한 오류는 입력창의 오류 문구([SmashTextField.errorText])를 쓴다.
///
/// - 색과 함께 아이콘으로 구분한다. 오류(danger)는 나타날 때 스크린리더가 바로 읽는다
/// - [actionLabel]과 [onAction]이 모두 있으면 아래에 텍스트 버튼이 붙는다 (예: "다시 시도")
class SmashInlineNotice extends StatelessWidget {
  const SmashInlineNotice({
    super.key,
    required this.message,
    this.tone = SmashNoticeTone.info,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SmashNoticeTone tone;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  static SmashBadgeTone _badgeTone(SmashNoticeTone tone) => switch (tone) {
        SmashNoticeTone.info => SmashBadgeTone.info,
        SmashNoticeTone.success => SmashBadgeTone.success,
        SmashNoticeTone.warning => SmashBadgeTone.warning,
        SmashNoticeTone.danger => SmashBadgeTone.danger,
      };

  /// tone의 (배경색, 강조색). 대비 검사가 화면에 쓰이는 값을 그대로 읽는다.
  static (Color background, Color accent) colorsFor(SmashNoticeTone tone) =>
      SmashBadge.colorsFor(_badgeTone(tone));

  static IconData iconFor(SmashNoticeTone tone) => SmashBadge.iconFor(_badgeTone(tone))!;

  @override
  Widget build(BuildContext context) {
    final (background, accent) = colorsFor(tone);
    final showAction = actionLabel != null && onAction != null;

    return Semantics(
      container: true,
      liveRegion: tone == SmashNoticeTone.danger,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: SmashRadius.circular(SmashRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SmashSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Icon(iconFor(tone), size: 20, color: accent)),
                  const SizedBox(width: SmashSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null) Text(title!, style: SmashText.bodyStrong),
                        Text(message, style: SmashText.body),
                      ],
                    ),
                  ),
                ],
              ),
              if (showAction)
                Align(
                  alignment: Alignment.centerRight,
                  child: SmashButton(
                    label: actionLabel!,
                    variant: SmashButtonVariant.text,
                    size: SmashButtonSize.medium,
                    expanded: false,
                    onPressed: onAction,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
