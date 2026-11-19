import 'package:flutter/material.dart';

import '../colors.dart';
import '../no_char_break.dart';
import '../spacing.dart';
import '../typography.dart';

/// [SmashTabBar]의 탭 하나. 개수를 보이려면 [badgeCount]를 넘긴다 (0도 보인다, null이면 없음).
/// 개수는 라벨 오른쪽에 **숫자만** 보인다 (배경 모양 없음). 라벨과 8의 간격을 두고, 굵기는 고정이며(선택이 바뀌어도 폭이 변하지 않는다)
/// 자릿수 폭이 같은 숫자(tabular figures)를 쓴다. 숫자 색은 탭 글자 색(선택은 브랜드 색, 나머지는 보조색)을 따르고 배경(흰색) 대비 4.5:1 이상이다.
class SmashTab {
  const SmashTab({required this.label, this.badgeCount, this.semanticLabel});

  final String label;
  final int? badgeCount;

  /// 스크린리더가 읽는 말. 기본은 "라벨" 또는 "라벨, 12건"이다
  final String? semanticLabel;

  String get readAs =>
      semanticLabel ?? (badgeCount == null ? label : '$label, $badgeCount건');
}

/// 화면 안의 탭 줄 (미처리 | 합격 | 불합격 등). `TabController`와 `TabBarView`와 함께 쓴다.
///
/// - 높이 48, 선택된 탭은 브랜드 색 글자와 **밑줄**로 구분한다 (색만으로 구분하지 않는다). 글자 굵기는 같아서 선택이 바뀌어도 폭이 변하지 않는다
/// - 탭 글자는 항상 한 줄이다. 폭이 모자라 모든 탭이 같은 폭으로 안 들어가면 **자동으로 스크롤형**으로 바뀌고,
///   선택된 탭이 항상 화면에 보이게 스크롤한다. [isScrollable]로 강제할 수도 있다
/// - 스크린리더는 탭 위치("3개 중 1번째")와 선택 상태를 읽고, 개수는 "12건"으로 읽는다
/// - 키보드: Tab과 방향키(왼쪽/오른쪽)로 탭 사이를 옮기고 Enter(스페이스)로 고른다 (Flutter 기본 포커스 이동)
/// - 동작 줄이기: 탭을 바꿀 때 밑줄이 움직이는 시간은 [TabController.animationDuration]이 정한다.
///   컨트롤러를 만들 때 `animationDuration: SmashTabBar.animationDurationOf(context)`를 넘기면 동작 줄이기에서 즉시 바뀐다
class SmashTabBar extends StatelessWidget {
  const SmashTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable,
  });

  final TabController controller;
  final List<SmashTab> tabs;

  /// null이면 폭에 따라 자동 (모든 탭이 같은 폭으로 들어가면 고정, 아니면 스크롤)
  final bool? isScrollable;

  static const double height = 48;
  static const double _indicatorHeight = 3;
  static const double _fixedPadding = SmashSpacing.sm;
  static const double _scrollPadding = SmashSpacing.md;

  /// 라벨과 개수 숫자 사이 간격 (숫자가 라벨의 일부로 붙어 보이지 않게)
  static const double _badgeGap = SmashSpacing.sm;

  /// 탭 전환 애니메이션 길이. 동작 줄이기가 켜져 있으면 0
  static Duration animationDurationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : kTabScrollDuration;

  /// 탭 글자. **자간을 0으로 명시한다**: 명시하지 않으면 Material의 기본 글자 스타일(자간 0.1)이 섞여 실제 폭이
  /// [TextPainter]로 잰 폭보다 글자당 0.1px 커지고, 그러면 고정 모드에서 폭이 모자라 글자가 잘릴 수 있다
  static final TextStyle _labelStyle = SmashText.bodyStrong.copyWith(
    letterSpacing: 0,
  );

  /// 개수 숫자: 굵기는 항상 w600(선택이 바뀌어도 폭이 변하지 않는다), 자릿수 폭이 같은 숫자.
  /// 색은 정하지 않는다 (탭 글자 색을 따라 선택은 브랜드 색, 나머지는 보조색이 된다)
  static final TextStyle _countStyle = SmashText.tabular(
    const TextStyle(
      fontFamily: SmashText.family,
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
  );

  /// 탭 내용(글자 + 개수)이 한 줄로 차지하는 폭
  static double contentWidth(SmashTab tab, TextScaler scaler) {
    var width = _measure(tab.label, _labelStyle, scaler);
    final count = tab.badgeCount;
    if (count != null) {
      width += _badgeGap + _badgeWidth(count, scaler);
    }
    return width;
  }

  /// 개수 숫자의 폭 (배경 모양이 없으므로 숫자 폭 그대로다)
  static double _badgeWidth(int count, TextScaler scaler) =>
      _measure('$count', _countStyle, scaler);

  /// 실제로 그려지는 글자와 같은 기준으로 잰다: `SmashLabel`이 그리는 문자열([noCharBreak])을 같은 스타일로 한 줄에 놓았을 때의 폭
  static double _measure(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: noCharBreak(text), style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// 모든 탭이 같은 폭으로 한 줄에 들어가는가 (각 탭의 좌우 여백 포함)
  static bool fitsFixed({
    required List<double> contentWidths,
    required double available,
  }) {
    if (contentWidths.isEmpty) return true;
    final slot = available / contentWidths.length;
    for (final width in contentWidths) {
      // 소수 픽셀 오차로 경계에서 글자가 잘리지 않게 1px 여유를 둔다
      if (width + 2 * _fixedPadding + 1 > slot) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(tabs.isNotEmpty, '탭은 하나 이상');
    assert(
      tabs.length == controller.length,
      'tabs 수(${tabs.length})와 컨트롤러 length(${controller.length})가 달라요',
    );
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollable =
            isScrollable ??
            !fitsFixed(
              contentWidths: [for (final t in tabs) contentWidth(t, scaler)],
              available: constraints.maxWidth,
            );
        return DecoratedBox(
          decoration: const BoxDecoration(color: SmashColors.surface),
          child: TabBar(
            controller: controller,
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
            padding: scrollable
                ? const EdgeInsets.symmetric(horizontal: SmashSpacing.sm)
                : EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(
              horizontal: scrollable ? _scrollPadding : _fixedPadding,
            ),
            labelStyle: _labelStyle,
            unselectedLabelStyle: _labelStyle,
            labelColor: SmashColors.brand,
            unselectedLabelColor: SmashColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                color: SmashColors.brand,
                width: _indicatorHeight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_indicatorHeight),
              ),
            ),
            dividerColor: SmashColors.line,
            dividerHeight: 1,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? SmashColors.brandTintSoft
                  : Colors.transparent,
            ),
            physics: const ClampingScrollPhysics(),
            tabs: [for (final tab in tabs) _buildTab(tab)],
          ),
        );
      },
    );
  }

  Widget _buildTab(SmashTab tab) {
    final count = tab.badgeCount;
    return Tab(
      height: height,
      child: Semantics(
        label: tab.readAs,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 강제로 고정 폭(isScrollable: false)인데 폭이 모자라면 넘침 오류 대신 한 줄 안에서 잘린다
            Flexible(child: _text(tab.label)),
            if (count != null) ...[
              const SizedBox(width: _badgeGap),
              _text('$count', style: _countStyle),
            ],
          ],
        ),
      ),
    );
  }
}

/// 탭 글자는 한 줄이다 (줄바꿈하지 않는다). 글자 위젯은 여기서만 만든다 (라벨과 개수 숫자 두 곳)
Widget _text(String data, {TextStyle? style}) => Text(
  data,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.clip,
  style: style,
);
