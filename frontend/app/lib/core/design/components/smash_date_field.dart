import 'package:flutter/material.dart';

import '../../format/ko_date_format.dart';
import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_date_picker.dart';
import 'smash_pressable.dart';

/// 날짜를 고르는 입력칸. 누르면 날짜 시트가 열리고, "선택"으로 확정하면 [onChanged]가 불린다.
/// 모양은 [SmashTextField]와 같다 (라벨은 칸 위, 오류는 칸 아래 아이콘과 함께).
///
/// - 값이 없으면 [hint]를 보여주고, 있으면 "11월 20일 (금)"처럼 보여준다 (올해가 아니면 연도가 붙는다)
/// - 고른 날짜는 시각 없는 날짜다. 시트를 닫으면 [onChanged]는 불리지 않는다
/// - [firstDate]~[lastDate] 밖과 [isDayEnabled]가 막은 날은 고를 수 없다.
///   시작일 뒤에 끝일을 고르는 식의 제약은 끝일 칸의 [firstDate]에 시작일을 넘겨서 만든다
/// - 스크린리더는 "라벨, 값(또는 선택 안 함)"을 읽고 버튼으로 읽는다
class SmashDateField extends StatelessWidget {
  const SmashDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.isDayEnabled,
    this.hint = '날짜를 선택해 주세요',
    this.helper,
    this.errorText,
    this.enabled = true,
    this.pickerTitle,
    this.today,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// 값이 없을 때 시트가 처음 보여줄 날짜 (예: 내일). 값이 있으면 값이 우선한다
  final DateTime? initialDate;
  final bool Function(DateTime day)? isDayEnabled;
  final String hint;
  final String? helper;
  final String? errorText;
  final bool enabled;

  /// 시트 제목. 기본은 라벨이다
  final String? pickerTitle;

  /// 오늘. 테스트에서 고정할 때만 넘긴다
  final DateTime? today;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  Future<void> _open(BuildContext context) async {
    final picked = await showSmashDatePicker(
      context: context,
      title: pickerTitle ?? label,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: value ?? initialDate,
      isDayEnabled: isDayEnabled,
      today: today,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    final valueText = current == null
        ? null
        : KoDateFormat.date(current, now: today);
    final borderColor = !enabled
        ? SmashColors.line
        : (_hasError ? SmashColors.danger : SmashColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨은 칸과 하나로 묶어 읽으므로 따로 읽지 않는다
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
          hint: helper ?? '눌러서 날짜를 선택해요',
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
                      Icons.calendar_today_outlined,
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
