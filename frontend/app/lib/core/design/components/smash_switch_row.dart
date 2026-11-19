import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 켜고 끄는 설정 한 줄 (알림 설정 등). 줄 어디를 눌러도 바뀌고, 높이는 56dp 이상이다.
/// 스크린리더는 "라벨, 설명, 켜짐/꺼짐"을 한 번에 읽는다.
class SmashSwitchRow extends StatelessWidget {
  const SmashSwitchRow({
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
        toggled: value,
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
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SmashSpacing.sm),
                child: Row(
                  children: [
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
                    const SizedBox(width: SmashSpacing.md),
                    Switch(
                      value: value,
                      onChanged: onChanged,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return SmashColors.textDisabled;
                        }
                        return states.contains(WidgetState.selected)
                            ? SmashColors.onBrand
                            : SmashColors.border;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return SmashColors.fillDisabled;
                        }
                        return states.contains(WidgetState.selected)
                            ? SmashColors.brand
                            : SmashColors.surface;
                      }),
                      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) return SmashColors.line;
                        return states.contains(WidgetState.selected)
                            ? Colors.transparent
                            : SmashColors.border;
                      }),
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
