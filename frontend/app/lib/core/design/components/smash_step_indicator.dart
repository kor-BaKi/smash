import 'package:flutter/material.dart';

import '../colors.dart';
import '../no_char_break.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 여러 단계로 나뉜 흐름(가입 3단계 등)의 진행 표시. 누르는 요소가 아니라 지금 어디인지 보여 주는 표시다.
///
/// - **색에만 의존하지 않는다**: 현재 단계는 브랜드 색으로 채운 동그라미 + 숫자, 완료한 단계는 체크 아이콘 + 굵은 테두리,
///   남은 단계는 빈 동그라미 + 숫자다. 단계 사이 선은 완료한 구간만 브랜드 색이다
/// - **스크린리더는 한 번에 읽는다**: "3단계 중 2단계, 이름 입력, 1단계 약관 동의 완료" (완료한 단계에는 "완료"가 붙는다)
/// - 단계는 2~5개다. 단계 이름은 짧은 낱말로 쓴다
/// - **한 줄(가로)에 놓이다가 좁아지면 세로로 바뀐다**: 칸마다 단계 이름의 가장 긴 낱말이 들어가야 가로로 놓고, 들어가지 않으면
///   동그라미 옆에 이름이 한 줄씩 놓이는 세로 배치로 바꾼다. 어느 쪽이든 낱말 중간에서 줄바꿈되지 않는다.
///   가로에서 이름은 동그라미 아래에서 낱말 단위로 줄바꿈된다
/// - **현재 단계가 바뀌어도 크기가 변하지 않는다**: 동그라미 크기, 선 굵기, 글자 굵기가 단계와 상관없이 같고,
///   가로/세로 판단도 어느 단계가 현재인지와 무관하다. 글자 크기를 키우면 동그라미도 함께 커진다 (최대 44)
///
/// 폭에 따라 배치를 바꾸려고 `LayoutBuilder`를 쓰므로 **고유 크기를 지원하지 않는다**: `SmashAdaptiveRow`, `IntrinsicHeight`,
/// `IntrinsicWidth` 안에 두지 않는다 (폭이 정해진 곳에 둔다).
class SmashStepIndicator extends StatelessWidget {
  const SmashStepIndicator({
    super.key,
    required this.steps,
    required this.current,
  }) : assert(steps.length >= 2 && steps.length <= 5, '단계는 2~5개'),
       assert(
         current >= 0 && current < steps.length,
         'current는 0부터 단계 수 - 1까지',
       );

  /// 단계 이름 (예: 약관 동의, 이름 입력, 비밀번호)
  final List<String> steps;

  /// 현재 단계 (0부터). 이보다 앞은 완료, 뒤는 남은 단계다
  final int current;

  static const double markerBase = 28;
  static const double markerMax = 44;
  static const double lineThickness = 2;

  /// 가로 배치에서 칸 안쪽 좌우 여백 (이름이 칸 가장자리에 붙지 않게)
  static const double columnPadding = SmashSpacing.xs;

  /// 세로 배치에서 동그라미와 이름 사이, 단계와 단계 사이
  static const double _rowGap = SmashSpacing.md;
  static const double _stepGap = SmashSpacing.md;

  /// 스크린리더가 읽는 말
  String get reading {
    final text = StringBuffer(
      '${steps.length}단계 중 ${current + 1}단계, ${steps[current]}',
    );
    for (var i = 0; i < current; i++) {
      text.write(', ${i + 1}단계 ${steps[i]} 완료');
    }
    return text.toString();
  }

  TextStyle _labelStyle(int index) => SmashText.caption.copyWith(
    fontWeight: FontWeight.w600,
    color: index > current ? SmashColors.textSecondary : SmashColors.text,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: reading,
      excludeSemantics: true,
      child: LayoutBuilder(builder: _layout),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final scaler = MediaQuery.textScalerOf(context);
    final marker = scaler
        .scale(markerBase)
        .clamp(markerBase, markerMax)
        .toDouble();
    final direction = Directionality.of(context);

    // 단계 이름의 가장 긴 낱말 (그려지는 글자와 같은 기준: SmashLabel이 그리는 문자열)
    var longestWord = 0.0;
    for (var i = 0; i < steps.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: noCharBreak(steps[i]), style: _labelStyle(i)),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      if (painter.minIntrinsicWidth > longestWord) {
        longestWord = painter.minIntrinsicWidth;
      }
      painter.dispose();
    }
    final column = constraints.maxWidth / steps.length;
    final horizontal = longestWord <= column - 2 * columnPadding;
    return horizontal ? _horizontal(marker) : _vertical(marker);
  }

  Widget _horizontal(double marker) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: marker,
                  child: Row(
                    children: [
                      Expanded(
                        child: _line(
                          key: ValueKey('step-line-$i-start'),
                          visible: i > 0,
                          done: i - 1 < current,
                        ),
                      ),
                      _marker(i, marker),
                      Expanded(
                        child: _line(
                          key: ValueKey('step-line-$i-end'),
                          visible: i < steps.length - 1,
                          done: i < current,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SmashSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: columnPadding,
                  ),
                  child: SmashLabel(
                    steps[i],
                    textAlign: TextAlign.center,
                    style: _labelStyle(i),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _vertical(double marker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: marker,
                  child: Column(
                    children: [
                      _marker(i, marker),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Center(
                            child: Container(
                              key: ValueKey('step-line-$i-down'),
                              width: lineThickness,
                              color: i < current
                                  ? SmashColors.brand
                                  : SmashColors.line,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: _rowGap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < steps.length - 1 ? _stepGap : 0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: marker),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SmashLabel(steps[i], style: _labelStyle(i)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _line({required Key key, required bool visible, required bool done}) {
    return Center(
      child: Container(
        key: key,
        height: lineThickness,
        color: !visible
            ? Colors.transparent
            : (done ? SmashColors.brand : SmashColors.line),
      ),
    );
  }

  Widget _marker(int index, double size) {
    final style = SmashText.caption.copyWith(fontWeight: FontWeight.w600);
    final Widget face;
    final Color fill;
    final Color? border;
    if (index < current) {
      fill = SmashColors.brandTint;
      border = SmashColors.brand;
      face = Icon(Icons.check, size: size * 0.6, color: SmashColors.brand);
    } else if (index == current) {
      fill = SmashColors.brand;
      border = null;
      face = SmashLabel(
        '${index + 1}',
        style: style.copyWith(color: SmashColors.onBrand),
      );
    } else {
      fill = SmashColors.surface;
      border = SmashColors.border;
      face = SmashLabel(
        '${index + 1}',
        style: style.copyWith(color: SmashColors.textSecondary),
      );
    }
    return SizedBox(
      key: ValueKey('step-marker-$index'),
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: border == null
              ? null
              : Border.all(color: border, width: lineThickness),
        ),
        child: Center(child: face),
      ),
    );
  }
}
