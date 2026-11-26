import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/components/components.dart';
import '../../core/design/haptics.dart';
import '../../core/design/motion.dart';
import '../../core/design/motion_context.dart';
import '../../core/design/radius.dart';
import '../../core/design/shadows.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'screen_entry.dart';

/// 하단 막대 모양 비교 (개발 전용). 탭 구조(부원 홈/일정, 임원 홈/일정/운영)는 그대로이고 막대 모양만 다르다.
/// `SmashBottomNav`는 건드리지 않고, 변종은 이 파일 안에서만 그린다. 한 안이 정해지면 그 안을 실제 컴포넌트에 반영한다.
enum BarVariant {
  /// 지금 쓰는 `SmashBottomNav` 그대로 (실제 컴포넌트. 선택 애니메이션은 컴포넌트 자체의 것: 알약 배경색만 150ms)
  current('현재'),

  /// 현재 막대와 같은 모양(전체 폭, 칸 균등, 알약 56×32, 높이 64)을 이 파일에서 다시 그린 것. 선택 애니메이션을 입힌다
  /// (실제 컴포넌트를 건드리지 않고 "현재 모양 + 애니메이션"을 비교하려는 것)
  currentLook('현재 막대'),

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

/// 탭 구성 (구조는 아직 확정이 아니라 갤러리에서만 비교한다)
enum TabSet {
  /// 예전 구성(S3a-1): 부원 홈/일정, 임원 홈/일정/운영 (이 비교 화면에서만 고정해 둔다)
  base(''),

  /// 구성 C: 부원 홈/일정/내 정보, 임원 홈/일정/운영/내 정보
  c('구성 C'),

  /// 구성 A': 부원 홈/일정/내 기록/내 정보, 임원 홈/일정/내 기록/운영/내 정보
  aRecord("구성 A'"),

  /// 구성 A'에서 "내 기록"을 "내 활동"으로 바꾼 라벨 대안
  aActivity("구성 A' (내 활동)");

  const TabSet(this.label);

  final String label;

  List<SmashNavDestination> destinations({required bool admin}) {
    const home = SmashNavDestination(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    );
    const schedule = SmashNavDestination(
      label: '일정',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    );
    const operate = SmashNavDestination(
      label: '운영',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
    );
    const me = SmashNavDestination(
      label: '내 정보',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    );
    const record = SmashNavDestination(
      label: '내 기록',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    );
    const activity = SmashNavDestination(
      label: '내 활동',
      icon: Icons.sports_tennis_outlined,
      selectedIcon: Icons.sports_tennis,
    );
    return switch (this) {
      // 갤러리 비교용 "예전 구성"(부원 홈/일정, 임원 홈/일정/운영)을 고정한다. 실제 홈 셸의 탭 구성(`homeTabsFor`)과 별개다
      TabSet.base => [home, schedule, if (admin) operate],
      TabSet.c => [home, schedule, if (admin) operate, me],
      TabSet.aRecord => [home, schedule, record, if (admin) operate, me],
      TabSet.aActivity => [home, schedule, activity, if (admin) operate, me],
    };
  }

  int tabCount({required bool admin}) => destinations(admin: admin).length;
}

final _variantProvider = Provider<BarVariant>((ref) => BarVariant.current);
final _adminProvider = Provider<bool>((ref) => false);
final _tabSetProvider = Provider<TabSet>((ref) => TabSet.base);

String _roleLabel(TabSet set, bool admin) =>
    '${admin ? '임원' : '부원'} ${set.tabCount(admin: admin)}탭';

ScreenState _state(TabSet set, BarVariant variant, bool admin) => ScreenState(
  // 기존 8개 상태는 이름을 그대로 둔다 (구성 이름이 없는 것이 "현재 구성")
  set == TabSet.base
      ? '${variant.label} · ${_roleLabel(set, admin)}'
      : '${set.label} · ${variant.label} · ${_roleLabel(set, admin)}',
  overrides: [
    _variantProvider.overrideWithValue(variant),
    _adminProvider.overrideWithValue(admin),
    _tabSetProvider.overrideWithValue(set),
  ],
  hint: '탭을 눌러 선택 표시가 부드럽게 옮겨 가는지, 위쪽 조건 패널로 폭, 글자 크기, 키보드 올라온 모양을 바꿔 보세요',
);

List<ScreenState> _states() => [
  // 1) 현재 구성: 기존 8개 상태 그대로
  for (final variant in [
    BarVariant.current,
    BarVariant.centered,
    BarVariant.bigCell,
    BarVariant.floating,
  ])
    for (final admin in [false, true]) _state(TabSet.base, variant, admin),
  // 2) 구성 C, A', A'(내 활동) × 현재 막대 / 안 2 / 안 3 (안 1은 칸이 늘면 의미가 없어서 뺀다)
  for (final set in [TabSet.c, TabSet.aRecord, TabSet.aActivity])
    for (final variant in [
      BarVariant.currentLook,
      BarVariant.bigCell,
      BarVariant.floating,
    ])
      for (final admin in [false, true]) _state(set, variant, admin),
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
    final set = ref.watch(_tabSetProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destinations = set.destinations(admin: admin);

    return SmashScaffold(
      appBar: SmashAppBar(title: destinations[_selected].label),
      body: _FakeBody(title: destinations[_selected].label),
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
      BarVariant.currentLook => _CenteredBar(this, fullWidthCells: true),
      BarVariant.bigCell => _BigCellBar(this),
      BarVariant.floating => _FloatingBar(this),
    };
  }
}

/// 선택 애니메이션의 길이와 곡선: 모션 토큰을 그대로 쓴다 (`SmashMotion.base` 200ms, 위치가 바뀌는 곡선 `easeInOut` 하나).
/// 시스템에서 동작 줄이기를 켜면 길이가 0이라 바로 바뀐다
Duration _selectDuration(BuildContext context) =>
    context.moveDuration(SmashMotion.base);
const Curve _selectCurve = SmashMotion.easeInOut;

enum _Fill { pill, cell, cellRound }

/// 칸의 내용(아이콘 + 라벨). 선택되면 색과 글자 굵기가 [_selectDuration] 동안 부드럽게 바뀌고,
/// 아이콘은 가운데쯤에서 채운 모양으로 바뀐다. 아이콘 크기는 바꾸지 않는다(칸 높이가 흔들리지 않게).
/// 터치 영역과 스크린리더 "선택됨"은 애니메이션과 상관없이 바로 바뀐다.
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
    this.horizontal = false,
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

  /// 아이콘과 라벨을 가로로 나란히 놓을지 (막대 전체가 같은 배치여야 해서 막대가 정해 준다)
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final label = '${destination.label}, $position/$total';

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
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: selected ? 1.0 : 0.0),
                duration: _selectDuration(context),
                curve: _selectCurve,
                builder: (context, t, _) {
                  final color = Color.lerp(
                    SmashColors.textSecondary,
                    SmashColors.brand,
                    t,
                  )!;
                  final icon = Icon(
                    t >= 0.5
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
                    style: SmashText.body.copyWith(
                      fontSize: labelSize,
                      height: 1.2,
                      color: color,
                      fontWeight: FontWeight.lerp(
                        FontWeight.w400,
                        FontWeight.w600,
                        t,
                      ),
                    ),
                  );
                  if (fill == _Fill.pill) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: SmashSpacing.sm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: _pillWidth,
                              height: _pillHeight,
                              child: Center(child: icon),
                            ),
                            const SizedBox(height: SmashSpacing.xs),
                            text,
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    height: height,
                    alignment: Alignment.center,
                    child: horizontal
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              icon,
                              const SizedBox(width: SmashSpacing.sm),
                              Flexible(child: text),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              icon,
                              const SizedBox(height: SmashSpacing.xs),
                              text,
                            ],
                          ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

const double _pillWidth = 56;
const double _pillHeight = 32;

Widget _scaled(Widget child) => MediaQuery.withClampedTextScaling(
  maxScaleFactor: SmashBottomNav.maxLabelScale,
  child: child,
);

/// 칸 줄과 그 뒤에서 선택된 칸으로 옮겨 가는 선택 표시(알약 또는 칸 틴트)
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.bar,
    required this.cellWidth,
    required this.fill,
    required this.cellHeight,
    required this.iconSize,
    this.horizontalWhenFits = false,
  });

  final CompareBar bar;
  final double cellWidth;
  final _Fill fill;

  /// 칸 높이 (알약 방식은 칸이 내용에 맞춰 커지므로 최소 높이)
  final double cellHeight;
  final double iconSize;
  final bool horizontalWhenFits;

  @override
  Widget build(BuildContext context) {
    final d = bar.destinations;
    final i = bar.selectedIndex;
    final pill = fill == _Fill.pill;
    // 가로 배치는 모든 라벨이 칸 안에 들어갈 때만이고, 하나라도 안 들어가면 막대 전체가 세로다
    // (한 막대 안에 가로 칸과 세로 칸이 섞이지 않게). 가장 넓은 모습(굵은 글자, 글자 확대 반영)으로 정해서 애니메이션 중에 뒤바뀌지 않는다
    final horizontal =
        horizontalWhenFits &&
        d.every((dest) => _fitsHorizontally(context, dest.label, cellWidth));
    final radius = fill == _Fill.cell ? SmashRadius.md : SmashRadius.full;

    return SizedBox(
      width: cellWidth * d.length,
      child: Stack(
        children: [
          // 선택 표시: 같은 시간과 곡선으로 새 칸으로 옮겨 간다 (동작 줄이기에서는 바로 옮겨 간다)
          AnimatedPositioned(
            duration: _selectDuration(context),
            curve: _selectCurve,
            left: pill
                ? i * cellWidth + (cellWidth - _pillWidth) / 2
                : i * cellWidth,
            top: pill ? SmashSpacing.sm : 0,
            width: pill ? _pillWidth : cellWidth,
            height: pill ? _pillHeight : cellHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                key: barHighlightKey,
                decoration: BoxDecoration(
                  color: SmashColors.brandTint,
                  borderRadius: SmashRadius.circular(radius),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var n = 0; n < d.length; n++)
                SizedBox(
                  width: cellWidth,
                  child: _Cell(
                    destination: d[n],
                    selected: n == i,
                    position: n + 1,
                    total: d.length,
                    onPressed: () => bar.onSelected(n),
                    height: cellHeight,
                    labelSize: bar.variant.labelSize,
                    iconSize: iconSize,
                    fill: fill,
                    horizontal: horizontal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 아이콘 + 간격 + 라벨(선택된 굵은 글자)이 칸 안(양옆 여백 포함)에 들어가는가
  bool _fitsHorizontally(BuildContext context, String label, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: SmashText.bodyStrong.copyWith(
          fontSize: bar.variant.labelSize,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final need =
        iconSize + SmashSpacing.sm + painter.width + SmashSpacing.sm * 2;
    return need <= maxWidth;
  }
}

class _CenteredBar extends StatelessWidget {
  const _CenteredBar(this.bar, {this.fullWidthCells = false});

  final CompareBar bar;

  /// true면 현재 막대처럼 칸이 전체 폭을 균등하게 나눈다 (안 1은 칸 폭 상한 112)
  final bool fullWidthCells;

  @override
  Widget build(BuildContext context) {
    final n = bar.destinations.length;
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
              // 안 1: 칸 폭은 112이지만 화면이 좁아 칸이 안 들어가면 화면 폭을 칸 수로 나눈 값으로 줄인다
              child: LayoutBuilder(
                builder: (context, constraints) => _BarRow(
                  bar: bar,
                  cellWidth: fullWidthCells
                      ? constraints.maxWidth / n
                      : math.min(
                          BarMetrics.centeredCell,
                          constraints.maxWidth / n,
                        ),
                  fill: _Fill.pill,
                  cellHeight: BarMetrics.currentHeight,
                  iconSize: 24,
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
    final n = bar.destinations.length;
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
              child: LayoutBuilder(
                builder: (context, constraints) => _BarRow(
                  bar: bar,
                  cellWidth: constraints.maxWidth / n,
                  fill: _Fill.cell,
                  cellHeight: BarMetrics.bigCellHeight - SmashSpacing.sm * 2,
                  iconSize: 28,
                  horizontalWhenFits: true,
                ),
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
    final n = bar.destinations.length;
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
                n * BarMetrics.floatingCellMax,
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
                        child: LayoutBuilder(
                          builder: (context, inner) => _BarRow(
                            bar: bar,
                            cellWidth: inner.maxWidth / n,
                            fill: _Fill.cellRound,
                            cellHeight:
                                BarMetrics.floatingHeight -
                                SmashSpacing.xs * 2 -
                                2,
                            iconSize: 24,
                          ),
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
