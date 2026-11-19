import 'package:flutter/material.dart';

import '../../format/hour12.dart';
import '../../format/ko_date_format.dart';
import '../../rules/deadline_rules.dart';
import '../../rules/time_slots.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';
import 'smash_calendar.dart';
import 'smash_chip.dart';
import 'smash_date_picker.dart';
import 'smash_label.dart';
import 'smash_sheet.dart';
import 'smash_time_field_picker.dart';

/// 날짜+시간 시트의 결과: 고른 시각이거나, "수동으로 종료" 선택 ([isManual])
class SmashDateTimeChoice {
  const SmashDateTimeChoice.value(DateTime this.value);
  const SmashDateTimeChoice.manual() : value = null;

  final DateTime? value;
  bool get isManual => value == null;

  @override
  bool operator ==(Object other) =>
      other is SmashDateTimeChoice && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// 날짜+시간 시트가 열리는 순간에 정해지는 제약. 오래 열어 둔 화면에서도 "지금"이 정확하도록 열 때마다 새로 만든다.
class SmashDateTimeConstraints {
  const SmashDateTimeConstraints({
    required this.firstDate,
    required this.lastDate,
    required this.isSelectable,
    this.initialValue,
    this.presets = const [],
  });

  /// [DeadlineRules]에서 만든다: 첫 선택 날짜, 고를 수 있는 시각 판정, 처음 값(5분 올림), 프리셋 칩
  factory SmashDateTimeConstraints.fromDeadlineRules(
    DeadlineRules rules, {
    required DateTime lastDate,
  }) => SmashDateTimeConstraints(
    firstDate: rules.firstSelectableDate,
    lastDate: lastDate,
    isSelectable: rules.isSelectable,
    initialValue: rules.initialValue,
    presets: rules.presets(),
  );

  /// 고를 수 있는 날짜의 범위 (양 끝 포함)
  final DateTime firstDate;
  final DateTime lastDate;

  /// 이 시각을 고를 수 있는가 (날짜별로 시간 목록의 활성이 정해지고, 고를 시각이 하나도 없는 날은 달력에서 막힌다)
  final SelectablePredicate isSelectable;

  /// 시트를 처음 열 때 골라져 있는 값. 없거나 고를 수 없으면 처음으로 고를 수 있는 날의 오전 9시(그날 9시가 지났으면 첫 시각)
  final DateTime? initialValue;

  /// 위쪽 칩. 없으면 칩 줄이 없다
  final List<DeadlinePreset> presets;
}

/// 날짜와 시간을 함께 고르는 시트를 연다. 닫으면 null이고, 고르면 [SmashDateTimeChoice]다.
/// 시트 구성: 프리셋 칩 → 달력 → 시간(오전/오후, 시, 분) → 고른 시각 요약 → "수동으로 종료"(선택) / 확인
///
/// - 바깥을 눌러도, 아래로 끌어도 닫히지 않는다 (입력 중인 값이 실수로 사라지지 않게. 끌기는 안쪽 시간 목록의 드래그와도 겹친다). 시간 목록은 시트 안에서 늘어나지 않고 칸에 붙은 팝업으로 열리므로 시트 높이는 변하지 않는다. 팝업은 바깥 누르기로 닫혀도 되는데, 그때도 값은 그대로이고 시트는 닫히지 않는다
///   닫기 버튼과 뒤로 가기로 닫는다
/// - 날짜를 바꿨을 때 고른 시간이 그날 고를 수 없는 시각이 되면 고를 수 있는 가까운 시각으로 맞추고 그 사실을 알린다
/// - 값을 직접 바꾸면 프리셋 칩 선택이 풀린다 (칩과 시각이 정확히 같을 때만 칩이 선택돼 보인다)
/// - 제출 직전 재검증은 호출하는 화면이 [DeadlineRules.revalidate]로 한다 (시트를 연 동안 시간이 흐르므로)
Future<SmashDateTimeChoice?> showSmashDateTimePicker({
  required BuildContext context,
  required SmashDateTimeConstraints constraints,
  bool allowManualClose = false,
  String manualCloseLabel = '수동으로 종료할래요',
  String title = '날짜와 시간 선택',
  String confirmLabel = '확인',
  DateTime? today,
}) {
  return showSmashSheet<SmashDateTimeChoice>(
    context: context,
    title: title,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => _DateTimeSheetBody(
      constraints: constraints,
      allowManualClose: allowManualClose,
      manualCloseLabel: manualCloseLabel,
      confirmLabel: confirmLabel,
      today: today,
    ),
  );
}

class _DateTimeSheetBody extends StatefulWidget {
  const _DateTimeSheetBody({
    required this.constraints,
    required this.allowManualClose,
    required this.manualCloseLabel,
    required this.confirmLabel,
    required this.today,
  });

  final SmashDateTimeConstraints constraints;
  final bool allowManualClose;
  final String manualCloseLabel;
  final String confirmLabel;
  final DateTime? today;

  @override
  State<_DateTimeSheetBody> createState() => _DateTimeSheetBodyState();
}

class _DateTimeSheetBodyState extends State<_DateTimeSheetBody> {
  late DateTime _value = _start();
  String? _notice;

  SelectablePredicate get _selectable => widget.constraints.isSelectable;

  DateTime _start() {
    final initial = widget.constraints.initialValue;
    if (initial != null && _selectable(initial)) return initial;
    return _firstValue();
  }

  /// 처음으로 고를 수 있는 날의 오전 9시 (그날 9시가 지났으면 그날의 첫 시각)
  DateTime _firstValue() {
    var day = SmashCalendarMath.dateOnly(widget.constraints.firstDate);
    final last = SmashCalendarMath.dateOnly(widget.constraints.lastDate);
    while (!day.isAfter(last)) {
      if (TimeSlots.isDayEnabled(day, _selectable)) {
        // 오전 9시를 고를 수 있으면 그 시각, 오전이 이미 지났으면 그날 처음으로 고를 수 있는 시각
        return TimeSlots.resolve(day, 9, false, 0, _selectable) ??
            _firstValueOn(day)!;
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    // 고를 수 있는 날이 범위 안에 하나도 없다 (제약이 잘못된 경우): 첫 날 오전 9시를 보여주되 확인해도 고를 수 없는 값이다
    return TimeSlots.compose(
      SmashCalendarMath.dateOnly(widget.constraints.firstDate),
      9,
      false,
      0,
    );
  }

  void _pickDay(DateTime day) {
    final h = toHour12(_value.hour);
    final requested = TimeSlots.compose(day, h.hour12, h.isPm, _value.minute);
    final resolved = TimeSlots.resolve(
      day,
      h.hour12,
      h.isPm,
      _value.minute,
      _selectable,
    );
    final next = resolved ?? _firstValueOn(day) ?? requested;
    setState(() {
      _value = next;
      _notice = next == requested
          ? null
          : '그날은 지난 시간이라 ${KoDateFormat.time(next)}으로 맞췄어요';
    });
  }

  /// [day]에서 고를 수 있는 가장 이른 시각 (오전부터 찾는다). 하나도 없으면 null
  DateTime? _firstValueOn(DateTime day) {
    for (final isPm in [false, true]) {
      final hour = TimeSlots.firstEnabledHour(day, isPm, _selectable);
      if (hour != null) {
        return TimeSlots.compose(
          day,
          hour,
          isPm,
          TimeSlots.firstEnabledMinute(day, hour, isPm, _selectable)!,
        );
      }
    }
    return null;
  }

  void _pickTime(DateTime next) => setState(() {
    _value = next;
    _notice = null;
  });

  void _pickPreset(DeadlinePreset preset) => setState(() {
    _value = preset.value;
    _notice = null;
  });

  bool _isPresetSelected(DeadlinePreset preset) =>
      preset.value.isAtSameMomentAs(_value);

  @override
  Widget build(BuildContext context) {
    final c = widget.constraints;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.presets.isNotEmpty) ...[
          Wrap(
            spacing: SmashSpacing.sm,
            runSpacing: SmashSpacing.xs,
            children: [
              for (final preset in c.presets)
                SmashChip(
                  label: preset.label,
                  selected: _isPresetSelected(preset),
                  onPressed: () => _pickPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: SmashSpacing.sm),
        ],
        SmashDayPicker(
          firstDate: c.firstDate,
          lastDate: c.lastDate,
          selectedDay: SmashCalendarMath.dateOnly(_value),
          isDayEnabled: (day) => TimeSlots.isDayEnabled(day, _selectable),
          today: widget.today,
          onChanged: _pickDay,
        ),
        const SizedBox(height: SmashSpacing.md),
        SmashTimeFieldPicker(
          value: _value,
          isSelectable: _selectable,
          onChanged: _pickTime,
        ),
        if (_notice != null) ...[
          const SizedBox(height: SmashSpacing.sm),
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: SmashColors.brand,
                  ),
                ),
                const SizedBox(width: SmashSpacing.xs),
                Expanded(
                  child: SmashLabel(
                    _notice!,
                    style: SmashText.caption.copyWith(color: SmashColors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: SmashSpacing.md),
        Semantics(
          liveRegion: true,
          container: true,
          child: SmashLabel(
            '선택한 시각: ${KoDateFormat.dateTime(_value, now: widget.today)}',
            textAlign: TextAlign.center,
            style: SmashText.bodyStrong,
          ),
        ),
        const SizedBox(height: SmashSpacing.md),
        SmashButton(
          label: widget.confirmLabel,
          onPressed: () =>
              Navigator.of(context).pop(SmashDateTimeChoice.value(_value)),
        ),
        if (widget.allowManualClose) ...[
          const SizedBox(height: SmashSpacing.sm),
          SmashButton(
            label: widget.manualCloseLabel,
            variant: SmashButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(context).pop(const SmashDateTimeChoice.manual()),
          ),
        ],
      ],
    );
  }
}
