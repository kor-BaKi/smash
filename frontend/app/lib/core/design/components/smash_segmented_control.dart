import 'package:flutter/material.dart';

import '../colors.dart';
import '../no_char_break.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_adaptive_row.dart';
import 'smash_label.dart';
import 'smash_pressable.dart';

class SmashSegment<T> {
  const SmashSegment({required this.value, required this.label, this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// 둘 중 하나, 여럿 중 하나를 고르는 조각 선택 (이동 방식: 같이 가요 | 따로 가요).
///
/// - 선택된 조각은 색뿐 아니라 체크 아이콘과 굵은 글자로도 구분한다
/// - 조각은 같은 너비이고 터치 영역은 48dp 이상. 글자가 길면 공백에서 줄바꿈되어 높이가 늘어난다
/// - 한글 라벨은 낱말 중간에서 줄바꿈되지 않는다 ([SmashLabel]: "같이/가요")
/// - **조각이 가장 긴 낱말(선택 표시 포함)을 담지 못할 만큼 좁아지면 세로로 쌓인다** ([SmashAdaptiveRow]: 4개는 4열 → 2열 → 1열).
///   글자를 키우거나 폭이 좁을 때 낱말이 쪼개지는 대신 조각이 한 줄씩 늘어난다. 판단은 어느 조각이 선택됐는지와 무관하다
///   (선택된 조각의 체크 아이콘과 굵은 글자 폭을 모든 조각에 미리 반영한다. 선택을 바꿔도 배치가 바뀌지 않는다)
/// - 스크린리더는 라벨 원문에 "N개 중 M번째"를 덧붙여 읽는다. 가로든 세로든 목록 순서로 정해지고 화면 위치에 의존하지 않는다.
///   선택 여부는 위치가 아니라 선택 상태(`selected`)와 체크 아이콘, 굵은 글자로 표시한다
/// - 선택된 조각을 다시 눌러도 [onChanged]는 불리지 않는다
class SmashSegmentedControl<T> extends StatelessWidget {
  const SmashSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<SmashSegment<T>> segments;
  final T selected;

  /// null이면 전체 비활성
  final ValueChanged<T>? onChanged;

  /// 이 선택 그룹이 무엇을 고르는 것인지 (스크린리더가 먼저 읽는다)
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2 && segments.length <= 4, '조각은 2~4개');
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(SmashSpacing.xs),
        decoration: BoxDecoration(
          color: SmashColors.surface,
          borderRadius: SmashRadius.circular(SmashRadius.md),
          border: Border.all(color: SmashColors.border),
        ),
        child: SmashAdaptiveRow(
          spacing: 0,
          runSpacing: SmashSpacing.xs,
          minCellWidth: _selectedCellWidth(context),
          children: [
            for (var i = 0; i < segments.length; i++)
              _buildSegment(segments[i], i),
          ],
        ),
      ),
    );
  }

  static const double _checkWidth = 18 + SmashSpacing.xs;
  static const double _segmentPadding = SmashSpacing.sm * 2;

  /// 모든 조각이 "선택된 모습"(체크 아이콘 + 굵은 글자)일 때 필요한 칸 폭의 최대값.
  /// 선택이 바뀌어도 열 수가 바뀌지 않게 이 값을 칸 폭의 하한으로 쓴다.
  /// 글자 폭은 화면에 그리는 글자([SmashLabel]이 그리는 문자열)와 같은 기준으로 잰다 (가장 긴 낱말)
  double _selectedCellWidth(BuildContext context) {
    var widest = 0.0;
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: noCharBreak(segment.label), style: SmashText.bodyStrong),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      widest = widest < painter.minIntrinsicWidth ? painter.minIntrinsicWidth : widest;
      painter.dispose();
    }
    return widest + _checkWidth + _segmentPadding;
  }

  Widget _buildSegment(SmashSegment<T> segment, int index) {
    final isSelected = segment.value == selected;
    final enabled = onChanged != null && segment.enabled;

    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      hint: '${segments.length}개 중 ${index + 1}번째',
      child: SmashPressable(
        onPressed: enabled
            ? () {
                if (!isSelected) onChanged!(segment.value);
              }
            : null,
        borderRadius: SmashRadius.circular(SmashRadius.sm),
        minSize: const Size(SmashSpacing.minTouchTarget, SmashSpacing.minTouchTarget),
        builder: (context, states) {
          final disabled = states.contains(WidgetState.disabled);
          final pressed = states.contains(WidgetState.pressed);
          final foreground = disabled
              ? SmashColors.textDisabled
              : isSelected
                  ? SmashColors.brand
                  : SmashColors.text;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SmashSpacing.sm,
              vertical: SmashSpacing.sm,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? SmashColors.brandTint
                  : pressed
                      ? SmashColors.background
                      : Colors.transparent,
              borderRadius: SmashRadius.circular(SmashRadius.sm),
              border: states.contains(WidgetState.focused)
                  ? Border.all(color: SmashColors.brand, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check, size: 18, color: foreground),
                  const SizedBox(width: SmashSpacing.xs),
                ],
                Flexible(
                  child: SmashLabel(
                    segment.label,
                    textAlign: TextAlign.center,
                    style: (isSelected ? SmashText.bodyStrong : SmashText.body)
                        .copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
