import 'package:flutter/material.dart';

import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../motion_context.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';
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
/// - **선택 애니메이션:** 탭을 누르면 알약이 이전 칸에서 새 칸으로 옮겨 가고, 아이콘과 라벨의 색과 글자 굵기가 같은 시간에 바뀌며,
///   아이콘은 가운데쯤에서 채운 모양으로 바뀐다 (아이콘 크기는 바꾸지 않아 칸 높이가 흔들리지 않는다). 길이는 모션 토큰
///   [SmashMotion.base](200ms), 곡선은 [SmashMotion.easeInOut] 하나다. 시스템에서 동작 줄이기를 켜면 바로 바뀐다.
///   끝나기 전에 다른 탭을 눌러도 지금 값에서 이어서 움직이고 알약은 항상 하나다. 칸의 위치와 크기, 터치 영역, 스크린리더 "선택됨"은
///   애니메이션과 상관없이 바로 바뀐다
/// - 라벨은 13sp(caption 토큰과 같은 크기)이고 글자 확대를 1.3배까지만 따라간다 (탭 5개가 한 줄에 들어가야 하므로). 시스템 설정은 바꾸지 않는다
/// - 이미 선택된 탭을 다시 눌러도 [onSelected]가 불린다 (맨 위로 돌아가기 등은 화면이 정한다)
class SmashBottomNav extends StatelessWidget {
  const SmashBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(destinations.length >= 2 && destinations.length <= 5, '탭은 2~5개'),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  static const double minHeight = 64;
  static const double maxLabelScale = 1.3;

  /// 선택 알약의 크기
  static const double pillWidth = 56;
  static const double pillHeight = 32;

  /// 선택 알약 위젯의 키 (테스트가 알약 위치를 찾는다)
  static const highlightKey = ValueKey('smash-bottom-nav-highlight');

  final List<SmashNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static String badgeText(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    final count = destinations.length;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SmashColors.surface,
        border: Border(top: BorderSide(color: SmashColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxLabelScale,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / count;
              return Stack(
                children: [
                  // 선택 알약: 선택된 칸으로 옮겨 간다 (동작 줄이기에서는 바로 옮겨 간다)
                  AnimatedPositioned(
                    duration: context.moveDuration(SmashMotion.base),
                    curve: SmashMotion.easeInOut,
                    left:
                        selectedIndex * cellWidth + (cellWidth - pillWidth) / 2,
                    top: SmashSpacing.sm,
                    width: pillWidth,
                    height: pillHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: highlightKey,
                        decoration: BoxDecoration(
                          color: SmashColors.brandTint,
                          borderRadius: SmashRadius.circular(SmashRadius.full),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: _NavItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            position: i + 1,
                            total: count,
                            onPressed: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
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
    final label =
        '${destination.label}, $position/$total'
        '${count > 0 ? ', 새 항목 ${SmashBottomNav.badgeText(count)}개' : ''}';

    return Semantics(
      selected: selected,
      child: SmashPressable(
        onPressed: onPressed,
        semanticLabel: label,
        haptic: selected ? null : SmashHaptic.selection,
        borderRadius: SmashRadius.circular(SmashRadius.md),
        minSize: const Size(
          SmashSpacing.minTouchTarget,
          SmashBottomNav.minHeight,
        ),
        builder: (context, states) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: selected ? 1.0 : 0.0),
            duration: context.moveDuration(SmashMotion.base),
            curve: SmashMotion.easeInOut,
            builder: (context, t, _) {
              final color = Color.lerp(
                SmashColors.textSecondary,
                SmashColors.brand,
                t,
              )!;
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: SmashBottomNav.minHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: SmashSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: SmashBottomNav.pillWidth,
                            height: SmashBottomNav.pillHeight,
                            alignment: Alignment.center,
                            // 알약 배경은 위에서 옮겨 다니는 하나가 그린다. 여기서는 키보드 포커스 표시만 그린다
                            decoration: states.contains(WidgetState.focused)
                                ? BoxDecoration(
                                    borderRadius: SmashRadius.circular(
                                      SmashRadius.full,
                                    ),
                                    border: Border.all(
                                      color: SmashColors.text,
                                      width: 2,
                                    ),
                                  )
                                : null,
                            child: Icon(
                              t >= 0.5
                                  ? (destination.selectedIcon ??
                                        destination.icon)
                                  : destination.icon,
                              size: 24,
                              color: color,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -2,
                              right: 2,
                              child: _Badge(
                                text: SmashBottomNav.badgeText(count),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: SmashSpacing.xs),
                      SmashLabel(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: SmashText.body.copyWith(
                          fontSize: 13,
                          height: 1.2,
                          color: color,
                          fontWeight: FontWeight.lerp(
                            FontWeight.w400,
                            FontWeight.w600,
                            t,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
              child: SmashLabel(
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
