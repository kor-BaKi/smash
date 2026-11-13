import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// 목록 한 줄. 높이는 56dp 이상이고, [onTap]이 있으면 줄 어디를 눌러도 반응한다.
///
/// - 제목과 부제는 각각 최대 2줄까지 보이고 넘치면 말줄임(…)으로 줄인다 (긴 이름, 긴 메모 대비)
/// - 선택됨은 배경색뿐 아니라 왼쪽의 굵은 막대와 스크린리더의 "선택됨"으로도 구분한다
/// - 눌렀을 때는 배경이 진해진다 (줄 전체가 작아지지는 않는다)
/// - 구분선은 [showDivider]가 true일 때 아래에 그려진다 (목록의 마지막 줄은 false)
class SmashListRow extends StatelessWidget {
  const SmashListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// null이면 눌러지지 않는 줄
  final VoidCallback? onTap;
  final bool selected;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmashSpacing.md,
          vertical: SmashSpacing.sm,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: SmashSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SmashText.body,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SmashText.caption,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SmashSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );

    Widget content = Stack(
      children: [
        if (selected)
          Positioned.fill(child: ColoredBox(color: SmashColors.brandTintSoft)),
        row,
        if (selected)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(width: 4, child: ColoredBox(color: SmashColors.brand)),
          ),
      ],
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: SmashColors.fillDisabled,
          focusColor: SmashColors.brandTintSoft,
          child: content,
        ),
      );
    }

    return Semantics(
      button: onTap != null,
      selected: selected,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (showDivider)
            const Padding(
              padding: EdgeInsets.only(left: SmashSpacing.md),
              child: Divider(height: 1, thickness: 1, color: SmashColors.line),
            ),
        ],
      ),
    );
  }
}
