import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/components/components.dart';
import '../../core/design/haptics.dart';
import '../../core/design/radius.dart';
import '../../core/design/shadows.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../features/home/page/home_page.dart';
import 'screen_entry.dart';

/// 하단 막대 모양 비교 (개발 전용). 탭 구조(부원 홈/일정, 임원 홈/일정/운영)는 그대로이고 막대 모양만 다르다.
/// `SmashBottomNav`는 건드리지 않고, 변종은 이 파일 안에서만 그린다. 한 안이 정해지면 그 안을 실제 컴포넌트에 반영한다.
enum BarVariant {
  /// 지금 쓰는 `SmashBottomNav` 그대로
  current('현재'),

  /// 안 1: 전체 폭 막대는 그대로, 항목을 가운데로 모으고 칸 폭에 상한(112)
  centered('안 1 중앙 묶음'),

  /// 안 2: 칸을 키우고 선택 표시를 칸 전체 둥근 사각으로, 아이콘과 라벨을 가로로 나란히(안 들어가면 세로)
  bigCell('안 2 큰 칸'),

  /// 안 3: 화면 양옆에서 띄운 둥근 막대(폭 = 칸 수 × 136, 최대 화면 − 32), 그림자, 선택은 칸 전체 알약
  floating('안 3 떠 있는 막대');

  const BarVariant(this.label);

  final String label;

  /// 라벨 글자 크기
  double get labelSize => this == BarVariant.bigCell ? 14 : 13;
}

/// 막대 변종의 크기 약속 (측정과 테스트가 같은 값을 쓴다)
abstract final class BarMetrics {
  static const double centeredCell = 112;
  static const double floatingCellMax = 136;
  static const double floatingMargin = 16;
  static const double floatingVerticalMargin = 8;
  static const double floatingHeight = 64;
  static const double bigCellHeight = 72;
  static const double currentHeight = SmashBottomNav.minHeight;
}

/// 비교용 막대 키 (테스트가 막대 위치를 찾는다)
const barOuterKey = ValueKey('compare-bar-outer');
const barVisibleKey = ValueKey('compare-bar-visible');
const barHighlightKey = ValueKey('compare-bar-highlight');

/// 본문이 받은 아래 안전 영역 값 (테스트가 읽는다. 이중으로 비우지 않는지 확인하려는 것)
final ValueNotifier<double?> compareBodyBottomPadding = ValueNotifier(null);

final _variantProvider = Provider<BarVariant>((ref) => BarVariant.current);
final _adminProvider = Provider<bool>((ref) => false);

List<ScreenState> _states() => [
  for (final variant in BarVariant.values)
    for (final admin in [false, true])
      ScreenState(
        '${variant.label} · ${admin ? '임원 3탭' : '부원 2탭'}',
        overrides: [
          _variantProvider.overrideWithValue(variant),
          _adminProvider.overrideWithValue(admin),
        ],
        hint: '탭을 눌러 선택이 바뀌는지, 위쪽 조건 패널로 폭, 글자 크기, 키보드 올라온 모양을 바꿔 보세요',
      ),
];

final bottomBarCompareScreenEntry = ScreenEntry(
  name: '하단 막대 비교 (S3a 후속)',
  description:
      '같은 가짜 본문 위에 하단 막대만 바꿔 끼워 보는 비교 화면 (현재 / 안 1 중앙 묶음 / 안 2 큰 칸 / 안 3 떠 있는 막대 × 부원 2탭, 임원 3탭)',
  path: '/home',
  builder: (_) => const _BarCompareScreen(),
  states: _states(),
);

class _BarCompareScreen extends ConsumerStatefulWidget {
  const _BarCompareScreen();

  @override
  ConsumerState<_BarCompareScreen> createState() => _BarCompareScreenState();
}

class _BarCompareScreenState extends ConsumerState<_BarCompareScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(_variantProvider);
    final admin = ref.watch(_adminProvider);
    final tabs = homeTabsFor(isAdmin: admin);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destinations = [for (final t in tabs) t.destination];

    return SmashScaffold(
      appBar: SmashAppBar(title: tabs[_selected].label),
      body: _FakeBody(title: tabs[_selected].label),
      // 키보드가 올라오면 막대를 숨긴다 (SmashTabShell과 같다)
      bottom: keyboardOpen
          ? null
          : CompareBar(
              variant: variant,
              destinations: destinations,
              selectedIndex: _selected,
              onSelected: (i) => setState(() => _selected = i),
            ),
    );
  }
}

/// 같은 가짜 본문: 카드 여러 장 + 맨 아래 카드 (막대에 가려지지 않는지 본다)
class _FakeBody extends StatelessWidget {
  const _FakeBody({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    compareBodyBottomPadding.value = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: const EdgeInsets.all(SmashSpacing.md),
      children: [
        for (var i = 1; i <= 9; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: SmashSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SmashColors.surface,
                borderRadius: SmashRadius.circular(SmashRadius.md),
                border: Border.all(color: SmashColors.line),
              ),
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.all(SmashSpacing.md),
                  child: SmashLabel('$title 본문 카드 $i', style: SmashText.body),
                ),
              ),
            ),
          ),
        const SmashLabel(
          '맨 아래 카드',
          key: ValueKey('compare-last-card'),
          style: SmashText.bodyStrong,
        ),
      ],
    );
  }
}

/// 변종에 맞는 하단 막대
class CompareBar extends StatelessWidget {
  const CompareBar({
    super.key,
    required this.variant,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final BarVariant variant;
  final List<SmashNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      BarVariant.current => KeyedSubtree(
        key: barOuterKey,
        child: SmashBottomNav(
          key: barVisibleKey,
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ),
      BarVariant.centered => _CenteredBar(this),
      BarVariant.bigCell => _BigCellBar(this),
      BarVariant.floating => _FloatingBar(this),
    };
  }
}

/// 막대 변종이 공유하는 칸 하나
class _Cell extends StatelessWidget {
  const _Cell({
    required this.destination,
    required this.selected,
    required this.position,
    required this.total,
    required this.onPressed,
    required this.height,
    required this.labelSize,
    this.iconSize = 24,
    this.fill = _Fill.pill,
    this.horizontalWhenFits = false,
  });

  final SmashNavDestination destination;
  final bool selected;
  final int position;
  final int total;
  final VoidCallback onPressed;
  final double height;
  final double labelSize;
  final double iconSize;
  final _Fill fill;
  final bool horizontalWhenFits;

  @override
  Widget build(BuildContext context) {
    final label = '${destination.label}, $position/$total';
    final color = selected ? SmashColors.brand : SmashColors.textSecondary;
    final style = (selected ? SmashText.bodyStrong : SmashText.body).copyWith(
      fontSize: labelSize,
      height: 1.2,
      color: color,
    );
    final icon = Icon(
      selected
          ? (destination.selectedIcon ?? destination.icon)
          : destination.icon,
      size: iconSize,
      color: color,
    );
    final text = SmashLabel(
      destination.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: style,
    );

    return Semantics(
      selected: selected,
      child: SmashPressable(
        onPressed: onPressed,
        semanticLabel: label,
        haptic: selected ? null : SmashHaptic.selection,
        borderRadius: SmashRadius.circular(SmashRadius.full),
        minSize: Size(SmashSpacing.minTouchTarget, height),
        builder: (context, states) {
          return LayoutBuilder(
            builder: (context, constraints) {
              Widget content;
              if (horizontalWhenFits &&
                  _fitsHorizontally(context, constraints.maxWidth, style)) {
                content = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: SmashSpacing.sm),
                    Flexible(child: text),
                  ],
                );
              } else {
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fill == _Fill.pill)
                      AnimatedContainer(
                        key: selected ? barHighlightKey : null,
                        duration: const Duration(milliseconds: 1),
                        width: 56,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? SmashColors.brandTint
                              : Colors.transparent,
                          borderRadius: SmashRadius.circular(SmashRadius.full),
                        ),
                        child: icon,
                      )
                    else
                      icon,
                    const SizedBox(height: SmashSpacing.xs),
                    text,
                  ],
                );
              }
              if (fill == _Fill.cell || fill == _Fill.cellRound) {
                return Container(
                  key: selected ? barHighlightKey : null,
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? SmashColors.brandTint
                        : Colors.transparent,
                    borderRadius: SmashRadius.circular(
                      fill == _Fill.cellRound
                          ? SmashRadius.full
                          : SmashRadius.md,
                    ),
                  ),
                  child: content,
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: SmashSpacing.sm,
                  ),
                  child: content,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 아이콘 + 간격 + 라벨이 칸 안(양옆 여백 포함)에 들어가는가 (글자 확대를 반영한다)
  bool _fitsHorizontally(
    BuildContext context,
    double maxWidth,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: destination.label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final need =
        iconSize + SmashSpacing.sm + painter.width + SmashSpacing.sm * 2;
    return need <= maxWidth;
  }
}

enum _Fill { pill, cell, cellRound }

Widget _scaled(Widget child) => MediaQuery.withClampedTextScaling(
  maxScaleFactor: SmashBottomNav.maxLabelScale,
  child: child,
);

class _CenteredBar extends StatelessWidget {
  const _CenteredBar(this.bar);

  final CompareBar bar;

  @override
  Widget build(BuildContext context) {
    final d = bar.destinations;
    return KeyedSubtree(
      key: barOuterKey,
      child: DecoratedBox(
        key: barVisibleKey,
        decoration: const BoxDecoration(
          color: SmashColors.surface,
          border: Border(top: BorderSide(color: SmashColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: _scaled(
            Center(
              heightFactor: 1,
              // 칸 폭은 112이지만 화면이 좁아 3칸이 안 들어가면 화면 폭을 칸 수로 나눈 값으로 줄인다
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < d.length; i++)
                      SizedBox(
                        width: math.min(
                          BarMetrics.centeredCell,
                          constraints.maxWidth / d.length,
                        ),
                        child: _Cell(
                          destination: d[i],
                          selected: i == bar.selectedIndex,
                          position: i + 1,
                          total: d.length,
                          onPressed: () => bar.onSelected(i),
                          height: BarMetrics.currentHeight,
                          labelSize: bar.variant.labelSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigCellBar extends StatelessWidget {
  const _BigCellBar(this.bar);

  final CompareBar bar;

  @override
  Widget build(BuildContext context) {
    final d = bar.destinations;
    return KeyedSubtree(
      key: barOuterKey,
      child: DecoratedBox(
        key: barVisibleKey,
        decoration: const BoxDecoration(
          color: SmashColors.surface,
          border: Border(top: BorderSide(color: SmashColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: _scaled(
            Padding(
              padding: const EdgeInsets.all(SmashSpacing.sm),
              child: Row(
                children: [
                  for (var i = 0; i < d.length; i++)
                    Expanded(
                      child: _Cell(
                        destination: d[i],
                        selected: i == bar.selectedIndex,
                        position: i + 1,
                        total: d.length,
                        onPressed: () => bar.onSelected(i),
                        height: BarMetrics.bigCellHeight - SmashSpacing.sm * 2,
                        labelSize: bar.variant.labelSize,
                        iconSize: 28,
                        fill: _Fill.cell,
                        horizontalWhenFits: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar(this.bar);

  final CompareBar bar;

  @override
  Widget build(BuildContext context) {
    final d = bar.destinations;
    return KeyedSubtree(
      key: barOuterKey,
      // 바깥은 투명하다. 막대 아래 안전 영역(홈 인디케이터)은 이 안의 SafeArea가 맡는다
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BarMetrics.floatingMargin,
            BarMetrics.floatingVerticalMargin,
            BarMetrics.floatingMargin,
            BarMetrics.floatingVerticalMargin,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(
                constraints.maxWidth,
                d.length * BarMetrics.floatingCellMax,
              );
              return Center(
                heightFactor: 1,
                child: SizedBox(
                  width: width,
                  height: BarMetrics.floatingHeight,
                  child: DecoratedBox(
                    key: barVisibleKey,
                    decoration: BoxDecoration(
                      color: SmashColors.surface,
                      borderRadius: SmashRadius.circular(SmashRadius.full),
                      border: Border.all(color: SmashColors.line),
                      boxShadow: SmashShadows.elevation2,
                    ),
                    child: _scaled(
                      Padding(
                        padding: const EdgeInsets.all(SmashSpacing.xs),
                        child: Row(
                          children: [
                            for (var i = 0; i < d.length; i++)
                              Expanded(
                                child: _Cell(
                                  destination: d[i],
                                  selected: i == bar.selectedIndex,
                                  position: i + 1,
                                  total: d.length,
                                  onPressed: () => bar.onSelected(i),
                                  height:
                                      BarMetrics.floatingHeight -
                                      SmashSpacing.xs * 2 -
                                      2,
                                  labelSize: bar.variant.labelSize,
                                  fill: _Fill.cellRound,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
