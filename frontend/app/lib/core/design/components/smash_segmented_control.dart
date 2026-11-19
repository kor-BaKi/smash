import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
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
/// - 조각은 같은 너비이고 터치 영역은 48dp 이상. 글자가 길거나 확대되면 공백에서 줄바꿈되어 높이가 늘어난다
/// - 한글 라벨은 낱말 중간에서 줄바꿈되지 않는다 ([SmashLabel]: "같이/가요"). 다만 한 낱말이 조각 폭보다 길면 엔진이 글자 단위로 끊으므로,
///   쓰는 쪽이 낱말이 들어갈 폭을 잡아야 한다 (선택된 조각은 체크 아이콘이 폭을 차지한다. 조각 수가 많거나 라벨이 길면 폭을 넉넉히)
/// - 스크린리더는 라벨 원문을 읽는다
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final segment in segments)
                Expanded(child: _buildSegment(segment)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(SmashSegment<T> segment) {
    final isSelected = segment.value == selected;
    final enabled = onChanged != null && segment.enabled;

    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
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
