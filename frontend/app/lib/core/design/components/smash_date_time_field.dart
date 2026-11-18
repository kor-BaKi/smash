import 'package:flutter/material.dart';

import '../../format/ko_date_format.dart';
import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_date_time_picker.dart';
import 'smash_pressable.dart';

/// 날짜와 시간을 고르는 입력칸. 누르면 날짜+시간 시트가 열리고 확인하면 [onChanged]가 불린다.
/// 모양은 [SmashDateField], [SmashTextField]와 같다.
///
/// - 값은 "11월 11일 (수) 오후 3:30"처럼 보인다. 값이 없으면 [hint], "수동으로 종료"를 골랐으면([isManual]) [manualText]를 보인다
/// - 시트의 제약([constraints])은 시트를 여는 순간에 만들어진다 (오래 열어 둔 화면에서도 "지금"이 정확하도록)
/// - 닫으면 [onChanged]는 불리지 않는다
class SmashDateTimeField extends StatelessWidget {
  const SmashDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.constraints,
    this.allowManualClose = false,
    this.isManual = false,
    this.manualText = '수동으로 종료',
    this.manualCloseLabel = '수동으로 종료할래요',
    this.hint = '날짜와 시간을 선택해 주세요',
    this.helper,
    this.errorText,
    this.enabled = true,
    this.pickerTitle,
    this.today,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<SmashDateTimeChoice> onChanged;

  /// 시트를 여는 순간 불러서 제약을 만든다
  final SmashDateTimeConstraints Function() constraints;
  final bool allowManualClose;

  /// 수동 종료를 골라서 값이 없는 상태인가
  final bool isManual;
  final String manualText;
  final String manualCloseLabel;
  final String hint;
  final String? helper;
  final String? errorText;
  final bool enabled;
  final String? pickerTitle;

  /// 오늘. 테스트에서 고정할 때만 넘긴다
  final DateTime? today;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  Future<void> _open(BuildContext context) async {
    final choice = await showSmashDateTimePicker(
      context: context,
      title: pickerTitle ?? label,
      constraints: constraints(),
      allowManualClose: allowManualClose,
      manualCloseLabel: manualCloseLabel,
      today: today,
    );
    if (choice != null) onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    final valueText = current != null
        ? KoDateFormat.dateTime(current, now: today)
        : (isManual ? manualText : null);
    final borderColor = !enabled
        ? SmashColors.line
        : (_hasError ? SmashColors.danger : SmashColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: SmashText.caption.copyWith(
              color: SmashColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: SmashSpacing.xs),
        Semantics(
          hint: helper ?? '눌러서 날짜와 시간을 선택해요',
          child: SmashPressable(
            onPressed: enabled ? () => _open(context) : null,
            semanticLabel: '$label, ${valueText ?? '선택 안 함'}',
            borderRadius: SmashRadius.circular(SmashRadius.md),
            minSize: const Size(0, 52),
            builder: (context, states) {
              final focused = states.contains(WidgetState.focused);
              return Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: SmashSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: enabled
                      ? SmashColors.surface
                      : SmashColors.fillDisabled,
                  borderRadius: SmashRadius.circular(SmashRadius.md),
                  border: Border.all(
                    color: focused && !_hasError
                        ? SmashColors.brand
                        : borderColor,
                    width: focused || _hasError ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        valueText ?? hint,
                        style: SmashText.body.copyWith(
                          color: !enabled
                              ? SmashColors.textDisabled
                              : (valueText == null
                                    ? SmashColors.textSecondary
                                    : SmashColors.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: SmashSpacing.sm),
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: enabled
                          ? SmashColors.textSecondary
                          : SmashColors.textDisabled,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: Semantics(
              liveRegion: true,
              label: '오류: $errorText',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: SmashColors.danger,
                    ),
                  ),
                  const SizedBox(width: SmashSpacing.xs),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: SmashText.caption.copyWith(
                        color: SmashColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (helper != null && helper!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: ExcludeSemantics(
              child: Text(helper!, style: SmashText.caption),
            ),
          ),
      ],
    );
  }
}
