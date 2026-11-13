import 'package:flutter/material.dart';

import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_pressable.dart';

/// 하단 탭 한 칸의 내용. 라벨은 항상 보인다 (아이콘만 두지 않는다).
class SmashNavDestination {
  const SmashNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount = 0,
  }) : assert(badgeCount >= 0);

  final String label;
  final IconData icon;

  /// 선택됐을 때의 아이콘. 없으면 [icon]
  final IconData? selectedIcon;

  /// 0이면 숨긴다. 99를 넘으면 "99+"
  final int badgeCount;
}

/// 하단 탭 막대 (탭 2~5개).
///
/// - 선택은 색뿐 아니라 아이콘 뒤의 알약, 굵은 글자, 스크린리더의 "선택됨"으로 구분한다
/// - 라벨은 글자 확대를 1.3배까지만 따라간다 (탭 5개가 한 줄에 들어가야 하므로). 시스템 설정은 바꾸지 않는다
/// - 이미 선택된 탭을 다시 눌러도 [onSelected]가 불린다 (맨 위로 돌아가기 등은 화면이 정한다)
class SmashBottomNav extends StatelessWidget {
  const SmashBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  })  : assert(destinations.length >= 2 && destinations.length <= 5, '탭은 2~5개'),
        assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  static const double minHeight = 64;
  static const double maxLabelScale = 1.3;

  final List<SmashNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static String badgeText(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SmashColors.surface,
        border: Border(top: BorderSide(color: SmashColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxLabelScale,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    position: i + 1,
                    total: destinations.length,
                    onPressed: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.position,
    required this.total,
    required this.onPressed,
  });

  final SmashNavDestination destination;
  final bool selected;
  final int position;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final count = destination.badgeCount;
    final label = '${destination.label}, $position/$total'
        '${count > 0 ? ', 새 항목 ${SmashBottomNav.badgeText(count)}개' : ''}';

    return Semantics(
      selected: selected,
      child: SmashPressable(
        onPressed: onPressed,
        semanticLabel: label,
        haptic: selected ? null : SmashHaptic.selection,
        borderRadius: SmashRadius.circular(SmashRadius.md),
        minSize: const Size(SmashSpacing.minTouchTarget, SmashBottomNav.minHeight),
        builder: (context, states) {
          final color = selected ? SmashColors.brand : SmashColors.textSecondary;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SmashBottomNav.minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SmashSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: SmashMotion.fast,
                        curve: SmashMotion.easeOut,
                        width: 56,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? SmashColors.brandTint : Colors.transparent,
                          borderRadius: SmashRadius.circular(SmashRadius.full),
                          border: states.contains(WidgetState.focused)
                              ? Border.all(color: SmashColors.text, width: 2)
                              : null,
                        ),
                        child: Icon(
                          selected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
                          size: 24,
                          color: color,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2,
                          right: 2,
                          child: _Badge(text: SmashBottomNav.badgeText(count)),
                        ),
                    ],
                  ),
                  const SizedBox(height: SmashSpacing.xs),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: (selected ? SmashText.bodyStrong : SmashText.body)
                        .copyWith(fontSize: 12, height: 1.2, color: color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SmashColors.danger,
          borderRadius: SmashRadius.circular(SmashRadius.full),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                text,
                style: SmashText.caption.copyWith(
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: SmashColors.onBrand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
