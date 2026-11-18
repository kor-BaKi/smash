import 'package:flutter/material.dart';

import '../../format/ko_date_format.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';
import 'smash_calendar.dart';
import 'smash_sheet.dart';

/// 날짜 하나를 고르는 달력 본체 (시트 껍데기 없음). [showSmashDatePicker]가 시트 안에 넣어 쓰고,
/// 날짜와 시간을 함께 고르는 시트도 이 본체를 그대로 쓴다.
///
/// - 고른 날짜는 시각이 없는 날짜(자정)로 돌려준다
/// - [firstDate]부터 [lastDate]까지(양 끝 포함)만 고를 수 있고, 그 밖의 달로는 넘어갈 수 없다.
///   [isDayEnabled]로 더 좁힐 수 있다 (예: 지난 날짜 막기, 시작일보다 앞선 날 막기)
/// - 어느 달을 보여줄지는 이 위젯이 들고 있다. 처음에는 [selectedDay], 없으면 [initialMonth], 없으면 오늘이 있는 달이고
///   범위 밖이면 가장 가까운 달이다
class SmashDayPicker extends StatefulWidget {
  const SmashDayPicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.selectedDay,
    this.initialMonth,
    this.isDayEnabled,
    this.today,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onChanged;
  final DateTime? initialMonth;
  final bool Function(DateTime day)? isDayEnabled;

  /// 오늘. 테스트에서 고정할 때만 넘긴다
  final DateTime? today;

  /// [day]를 고를 수 있는가 (범위 안이고 [isDayEnabled]가 허용)
  static bool isSelectable(
    DateTime day, {
    required DateTime firstDate,
    required DateTime lastDate,
    bool Function(DateTime day)? isDayEnabled,
  }) {
    final d = SmashCalendarMath.dateOnly(day);
    if (d.isBefore(SmashCalendarMath.dateOnly(firstDate))) return false;
    if (d.isAfter(SmashCalendarMath.dateOnly(lastDate))) return false;
    return isDayEnabled?.call(d) ?? true;
  }

  /// 처음에 보여줄 달: [preferred]가 속한 달을 [firstDate]~[lastDate]의 달 안으로 맞춘 것
  static DateTime clampMonth(
    DateTime preferred,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    final first = DateTime(firstDate.year, firstDate.month);
    final last = DateTime(lastDate.year, lastDate.month);
    final month = DateTime(preferred.year, preferred.month);
    if (SmashCalendarMath.compareMonth(month, first) < 0) return first;
    if (SmashCalendarMath.compareMonth(month, last) > 0) return last;
    return month;
  }

  @override
  State<SmashDayPicker> createState() => _SmashDayPickerState();
}

class _SmashDayPickerState extends State<SmashDayPicker> {
  late DateTime _month = SmashDayPicker.clampMonth(
    widget.selectedDay ?? widget.initialMonth ?? widget.today ?? DateTime.now(),
    widget.firstDate,
    widget.lastDate,
  );

  @override
  Widget build(BuildContext context) {
    return SmashCalendar(
      month: _month,
      selectedDay: widget.selectedDay,
      today: widget.today,
      firstMonth: DateTime(widget.firstDate.year, widget.firstDate.month),
      lastMonth: DateTime(widget.lastDate.year, widget.lastDate.month),
      isDayEnabled: (day) => SmashDayPicker.isSelectable(
        day,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        isDayEnabled: widget.isDayEnabled,
      ),
      // SmashCalendar는 시각 없는 날짜만 전달하므로 그대로 넘긴다 (테스트가 이 약속을 지킨다)
      onDaySelected: widget.onChanged,
      onMonthChanged: (month) => setState(() => _month = month),
    );
  }
}

/// 날짜를 고르는 시트를 연다. "선택"을 눌러야 확정되고, 닫으면 null이다. 고른 날짜는 시각 없는 날짜다.
///
/// - 시트는 바깥을 눌러도, 아래로 끌어도 닫히지 않는다 (고르던 날짜를 실수로 잃지 않게). 닫기 버튼으로만 닫는다
/// - [initialDate]가 범위 안이고 선택 가능하면 처음부터 골라져 있고, 아니면 아무것도 골라지지 않아 "선택"이 비활성이다
/// - 날짜 범위는 [firstDate]~[lastDate] (양 끝 포함), [isDayEnabled]로 더 좁힌다
Future<DateTime?> showSmashDatePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  bool Function(DateTime day)? isDayEnabled,
  String title = '날짜 선택',
  String confirmLabel = '선택',
  DateTime? today,
}) {
  return showSmashSheet<DateTime>(
    context: context,
    title: title,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => _DatePickerSheetBody(
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      isDayEnabled: isDayEnabled,
      confirmLabel: confirmLabel,
      today: today,
    ),
  );
}

class _DatePickerSheetBody extends StatefulWidget {
  const _DatePickerSheetBody({
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.isDayEnabled,
    required this.confirmLabel,
    required this.today,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final bool Function(DateTime day)? isDayEnabled;
  final String confirmLabel;
  final DateTime? today;

  @override
  State<_DatePickerSheetBody> createState() => _DatePickerSheetBodyState();
}

class _DatePickerSheetBodyState extends State<_DatePickerSheetBody> {
  late DateTime? _selected = _initialSelection();

  DateTime? _initialSelection() {
    final initial = widget.initialDate;
    if (initial == null) return null;
    final ok = SmashDayPicker.isSelectable(
      initial,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      isDayEnabled: widget.isDayEnabled,
    );
    return ok ? SmashCalendarMath.dateOnly(initial) : null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SmashDayPicker(
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectedDay: selected,
          initialMonth: widget.initialDate,
          isDayEnabled: widget.isDayEnabled,
          today: widget.today,
          onChanged: (day) => setState(() => _selected = day),
        ),
        const SizedBox(height: SmashSpacing.md),
        Semantics(
          liveRegion: true,
          container: true,
          child: Text(
            selected == null
                ? '날짜를 선택해 주세요'
                : '선택한 날짜: ${KoDateFormat.date(selected, now: widget.today)}',
            textAlign: TextAlign.center,
            style: selected == null
                ? SmashText.body.copyWith(color: SmashColors.textSecondary)
                : SmashText.bodyStrong,
          ),
        ),
        const SizedBox(height: SmashSpacing.md),
        SmashButton(
          label: widget.confirmLabel,
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
        ),
      ],
    );
  }
}
