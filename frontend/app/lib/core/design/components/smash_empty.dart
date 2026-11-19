import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';
import 'smash_label.dart';

/// 화면 가운데에 놓이는 안내 틀 (비어 있음, 오류에 함께 쓴다).
/// 빈 화면은 "무엇이 없는지"와 "무엇을 하면 되는지"를 알려준다.
class SmashStateMessage extends StatelessWidget {
  const SmashStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.liveRegion = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 나타날 때 스크린리더가 바로 읽게 한다 (오류에 쓴다)
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final showAction = actionLabel != null && onAction != null;
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Padding(
        padding: const EdgeInsets.all(SmashSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SmashColors.fillDisabled,
                  borderRadius: SmashRadius.circular(SmashRadius.full),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(SmashSpacing.md),
                  child: Icon(icon, size: 32, color: SmashColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: SmashSpacing.md),
            SmashLabel(title, textAlign: TextAlign.center, style: SmashText.heading),
            if (message != null) ...[
              const SizedBox(height: SmashSpacing.xs),
              SmashLabel(
                message!,
                textAlign: TextAlign.center,
                style: SmashText.body.copyWith(color: SmashColors.textSecondary),
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: SmashSpacing.lg),
              SmashButton(
                label: actionLabel!,
                variant: SmashButtonVariant.secondary,
                size: SmashButtonSize.medium,
                expanded: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [child]를 가운데에 놓는다. 공간보다 내용이 크면(큰 글자 설정 등) 넘치지 않고 스크롤된다.
///
/// - [alwaysScrollable]이 true이면 내용이 짧아도 당길 수 있다. RefreshIndicator 안에서 쓰면
///   내용이 비어 있어도 당겨서 새로고침이 된다
/// - 높이가 정해지지 않은 곳(Column 안 등)에서는 스크롤 없이 내용 크기로 그린다
class SmashFillScroll extends StatelessWidget {
  const SmashFillScroll({super.key, required this.child, this.alwaysScrollable = true});

  final Widget child;
  final bool alwaysScrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return Center(child: child);
        return CustomScrollView(
          // physics를 null로 두면 primary 스크롤뷰는 AlwaysScrollable이 자동으로 붙어서 alwaysScrollable: false가 소용없다.
          // 그래서 플랫폼 기본 물리를 직접 가져온다 (내용이 짧으면 스크롤되지 않는다)
          physics: alwaysScrollable
              ? const AlwaysScrollableScrollPhysics()
              : ScrollConfiguration.of(context).getScrollPhysics(context),
          slivers: [
            SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
          ],
        );
      },
    );
  }
}

/// 목록이나 화면이 비어 있을 때 보여준다.
///
/// - [scrollable]이 true이면 내용이 짧아도 당겨서 새로고침(RefreshIndicator)이 된다. false여도 공간보다 내용이 크면 넘치지 않고 스크롤된다
/// - [actionLabel]과 [onAction]이 모두 있을 때만 버튼이 붙는다
class SmashEmpty extends StatelessWidget {
  const SmashEmpty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.scrollable = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = SmashStateMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    return SmashFillScroll(alwaysScrollable: scrollable, child: content);
  }
}
