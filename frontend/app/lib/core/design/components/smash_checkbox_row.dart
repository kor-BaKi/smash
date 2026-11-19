import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 체크박스 한 줄 (동의 항목 등). 줄 어디를 눌러도 바뀌고, 높이는 48dp 이상이다.
/// 스크린리더는 "라벨, 선택됨/선택 안 됨"을 한 번에 읽는다.
class SmashCheckboxRow extends StatelessWidget {
  const SmashCheckboxRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;

  /// null이면 비활성
  final ValueChanged<bool>? onChanged;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final textColor = _enabled ? SmashColors.text : SmashColors.textDisabled;
    return MergeSemantics(
      child: Semantics(
        checked: value,
        enabled: _enabled,
        label: label,
        hint: description,
        onTap: _enabled ? () => onChanged!(!value) : null,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: _enabled ? () => onChanged!(!value) : null,
            splashFactory: NoSplash.splashFactory,
            highlightColor: SmashColors.fillDisabled,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: SmashSpacing.minTouchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SmashSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: value,
                      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return states.contains(WidgetState.selected)
                              ? SmashColors.textDisabled
                              : Colors.transparent;
                        }
                        return states.contains(WidgetState.selected)
                            ? SmashColors.brand
                            : Colors.transparent;
                      }),
                      checkColor: SmashColors.onBrand,
                      side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
                            color: states.contains(WidgetState.disabled)
                                ? SmashColors.line
                                : SmashColors.border,
                            width: 2,
                          )),
                    ),
                    const SizedBox(width: SmashSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SmashLabel(label, style: SmashText.body.copyWith(color: textColor)),
                          if (description != null)
                            SmashLabel(
                              description!,
                              style: SmashText.caption.copyWith(
                                color: _enabled
                                    ? SmashColors.textSecondary
                                    : SmashColors.textDisabled,
                              ),
                            ),
                        ],
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
