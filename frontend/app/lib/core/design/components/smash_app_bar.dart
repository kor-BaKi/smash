import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_icon_button.dart';
import 'smash_label.dart';
import 'smash_system_ui.dart';

/// 화면 위쪽 막대. 높이 56 (상태 표시줄 영역은 따로 더해진다), 그림자 없이 아래 선 하나.
///
/// - [onBack]을 주면 왼쪽에 뒤로 가기 버튼이 생긴다. 어디로 돌아갈지는 화면이 정한다
///   (이 위젯은 내비게이션을 모른다). 첫 화면에는 주지 않는다
/// - 제목은 한 줄이고 길면 말줄임이다. 스크린리더는 제목(heading)으로 읽는다
/// - [actions]의 각 위젯은 48dp 터치 영역을 스스로 지킨다 (SmashIconButton 권장)
class SmashAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SmashAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.backLabel = '뒤로',
    this.leading,
    this.actions = const [],
    this.showDivider = true,
  });

  static const double height = 56;

  final String title;
  final VoidCallback? onBack;
  final String backLabel;

  /// 지정하면 뒤로 가기 버튼 대신 쓴다
  final Widget? leading;
  final List<Widget> actions;
  final bool showDivider;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final start = leading ??
        (onBack == null
            ? null
            : SmashIconButton(
                icon: Icons.arrow_back,
                semanticLabel: backLabel,
                onPressed: onBack,
              ));

    return SmashSystemUiRegion(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SmashColors.surface,
          border: showDivider
              ? const Border(bottom: BorderSide(color: SmashColors.line))
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                if (start != null)
                  Padding(
                    padding: const EdgeInsets.only(left: SmashSpacing.xs),
                    child: start,
                  )
                else
                  const SizedBox(width: SmashSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SmashSpacing.sm),
                    child: Semantics(
                      header: true,
                      child: SmashLabel(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SmashText.heading,
                      ),
                    ),
                  ),
                ),
                for (final action in actions) action,
                const SizedBox(width: SmashSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
