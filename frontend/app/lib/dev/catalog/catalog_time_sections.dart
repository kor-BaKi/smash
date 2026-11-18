import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/format/ko_date_format.dart';
import '../../core/rules/deadline_rules.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

/// 카탈로그에서 "지금"을 고정해야 모양이 매번 같다 (프리셋 칩, 비활성 시각이 그 시각 기준으로 나온다)
final _fixedNow = DateTime(2026, 11, 11, 14, 52, 10);
final _fixedToday = DateTime(2026, 11, 11);
final _lastDate = DateTime(2030, 12, 31);

String _text(DateTime? value) =>
    value == null ? '고르지 않았어요' : KoDateFormat.dateTime(value, now: _fixedToday);

SmashDateTimeConstraints _deadline(
  DateTime now, {
  DateTime? initial,
  bool withInitial = true,
  DateTime? notBefore,
}) {
  final rules = DeadlineRules(now, notBefore: notBefore);
  return SmashDateTimeConstraints(
    firstDate: rules.firstSelectableDate,
    lastDate: _lastDate,
    isSelectable: rules.isSelectable,
    initialValue: withInitial ? (initial ?? rules.initialValue) : null,
    presets: rules.presets(),
  );
}

/// 규칙 없이 어떤 시각이든 고를 수 있다 (예: 모집 시작은 과거도 괜찮다)
SmashDateTimeConstraints _anyTime({DateTime? initial}) =>
    SmashDateTimeConstraints(
      firstDate: DateTime(2020),
      lastDate: _lastDate,
      isSelectable: (_) => true,
      initialValue: initial,
    );

SmashDateTimeField _field({
  String label = '마감 시각',
  DateTime? value,
  bool isManual = false,
  bool manual = false,
  ValueChanged<SmashDateTimeChoice>? onChanged,
  SmashDateTimeConstraints Function()? constraints,
  String? error,
  String? helper,
  bool enabled = true,
  DateTime? today,
}) => SmashDateTimeField(
  label: label,
  value: value,
  isManual: isManual,
  allowManualClose: manual,
  onChanged: onChanged ?? (_) {},
  constraints: constraints ?? () => _deadline(_fixedNow),
  errorText: error,
  helper: helper,
  enabled: enabled,
  today: today ?? _fixedToday,
);

final timeFieldPickerEntry = CatalogEntry(
  name: 'SmashTimeFieldPicker',
  description:
      '시간을 고르는 입력: [오전|오후] 토글 + [시]:[분] 두 칸. 칸을 누르면 그 칸에 붙은 팝업에 세로 목록(5줄)이 열린다 (화면 높이가 변하지 않고, 아래 공간이 모자라면 위로, 그래도 모자라면 줄 수를 줄여 연다). 항목을 누르면 고르고 닫히며, 바깥 누르기와 뒤로 가기는 값 변경 없이 팝업만 닫는다. 지금보다 이른 시각은 비활성이다.',
  states: [
    CatalogState(
      '내일 오전 9:10 (모든 시각 활성)',
      (_) => CatalogStateHost<DateTime>(
        initial: DateTime(2026, 11, 12, 9, 10),
        describe: _text,
        builder: (context, value, onChanged) => SmashTimeFieldPicker(
          value: value,
          isSelectable: (_) => true,
          onChanged: onChanged,
        ),
      ),
    ),
    CatalogState('오늘 오후 3:30, 지금 14:52:10 (오전과 14:52 이전 시각은 비활성)', (_) {
      final rules = DeadlineRules(_fixedNow);
      return CatalogStateHost<DateTime>(
        initial: DateTime(2026, 11, 11, 15, 30),
        describe: _text,
        builder: (context, value, onChanged) => SmashTimeFieldPicker(
          value: value,
          isSelectable: rules.isSelectable,
          onChanged: onChanged,
        ),
      );
    }),
    CatalogState('고른 시각이 지났을 때 (오늘 오후 2:30 → 분 목록은 53분이 보이게 열림)', (_) {
      final rules = DeadlineRules(_fixedNow);
      return CatalogStateHost<DateTime>(
        initial: DateTime(2026, 11, 11, 14, 30),
        describe: _text,
        builder: (context, value, onChanged) => SmashTimeFieldPicker(
          value: value,
          isSelectable: rules.isSelectable,
          onChanged: onChanged,
        ),
      );
    }),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<({bool tomorrow, DateTime value})>(
        initial: (tomorrow: true, value: DateTime(2026, 11, 12, 15, 30)),
        describe: (v) => _text(v.value),
        builder: (context, v, onChanged) {
          final rules = DeadlineRules(_fixedNow);
          DateTime onDay(bool tomorrow) =>
              DateTime(2026, 11, tomorrow ? 12 : 11);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: SmashSpacing.sm,
                children: [
                  SmashChip(
                    label: '오늘 (지금 14:52)',
                    selected: !v.tomorrow,
                    onPressed: () {
                      final day = onDay(false);
                      final next = rules.adjust(
                        DateTime(
                          day.year,
                          day.month,
                          day.day,
                          v.value.hour,
                          v.value.minute,
                        ),
                      );
                      onChanged((tomorrow: false, value: next.value));
                    },
                  ),
                  SmashChip(
                    label: '내일',
                    selected: v.tomorrow,
                    onPressed: () => onChanged((
                      tomorrow: true,
                      value: DateTime(
                        2026,
                        11,
                        12,
                        v.value.hour,
                        v.value.minute,
                      ),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: SmashSpacing.md),
              SmashTimeFieldPicker(
                value: v.value,
                isSelectable: rules.isSelectable,
                onChanged: (next) =>
                    onChanged((tomorrow: v.tomorrow, value: next)),
              ),
            ],
          );
        },
      ),
    ),
  ],
);

final dateTimeFieldEntry = CatalogEntry(
  name: 'SmashDateTimeField',
  description:
      '날짜와 시간을 고르는 입력칸. 누르면 날짜+시간 시트가 열리고 확인하면 값이 바뀐다. 시트의 제약(지금 기준)은 여는 순간에 만들어진다.',
  states: [
    CatalogState('빈 값', (_) => _field()),
    CatalogState('값 있음', (_) => _field(value: DateTime(2026, 11, 11, 15, 30))),
    CatalogState('수동으로 종료 선택', (_) => _field(isManual: true, manual: true)),
    CatalogState('도움말', (_) => _field(helper: '지금보다 이후 시각만 고를 수 있어요')),
    CatalogState('오류', (_) => _field(error: '마감 시각은 지금보다 이후로 설정해 주세요')),
    CatalogState(
      '비활성',
      (_) => _field(enabled: false, value: DateTime(2026, 11, 11, 15, 30)),
    ),
    CatalogState(
      '투표 마감 (실제 지금 기준: 프리셋 칩, 수동 종료까지) — 눌러 보세요',
      (_) => CatalogStateHost<SmashDateTimeChoice?>(
        initial: null,
        describe: (v) => v == null
            ? '고르지 않았어요'
            : (v.isManual ? '수동으로 종료' : KoDateFormat.dateTime(v.value!)),
        builder: (context, v, onChanged) => _field(
          value: v?.value,
          isManual: v?.isManual ?? false,
          manual: true,
          today: DateTime.now(),
          constraints: () => _deadline(DateTime.now()),
          onChanged: onChanged,
        ),
      ),
    ),
    CatalogState(
      '모집 시작과 종료 (종료는 시작보다 1분 이상 뒤: 오류 문구는 DeadlineRules가 정함)',
      (_) => CatalogStateHost<({DateTime? start, DateTime? end})>(
        initial: (start: DateTime(2026, 11, 20, 9, 0), end: null),
        describe: (v) => '${_text(v.start)} ~ ${_text(v.end)}',
        builder: (context, v, onChanged) {
          final rules = DeadlineRules(_fixedNow);
          final error = rules.validatePeriod(v.start, v.end);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                label: '모집 시작',
                value: v.start,
                constraints: () => _anyTime(initial: v.start),
                onChanged: (c) => onChanged((start: c.value, end: v.end)),
              ),
              const SizedBox(height: SmashSpacing.md),
              _field(
                label: '모집 종료',
                value: v.end,
                error: error == null
                    ? null
                    : DeadlineRules.periodErrorMessage(error),
                constraints: () => _deadline(
                  _fixedNow,
                  notBefore: v.start?.add(const Duration(minutes: 1)),
                ),
                onChanged: (c) => onChanged((start: v.start, end: c.value)),
              ),
            ],
          );
        },
      ),
    ),
  ],
);

final dateTimePickerEntry = CatalogEntry(
  name: 'showSmashDateTimePicker',
  description:
      '날짜+시간 시트. 프리셋 칩, 달력, 시간, 요약, (수동 종료), 확인. 바깥을 눌러도 끌어도 닫히지 않고 ✕나 뒤로 가기로 닫는다. 눌러서 열어 보세요.',
  states: [
    for (final s
        in <
          ({
            String label,
            String button,
            SmashDateTimeConstraints Function() constraints,
            bool manual,
          })
        >[
          (
            label: '투표 마감 (지금 11/11 14:52 고정): 칩 4개 + 수동 종료',
            button: '마감 시트 열기',
            constraints: () => _deadline(_fixedNow),
            manual: true,
          ),
          (
            label: '저녁 늦게 (지금 21:40: 오늘 밤 칩이 숨음)',
            button: '21:40 시트 열기',
            constraints: () => _deadline(DateTime(2026, 11, 11, 21, 40)),
            manual: true,
          ),
          (
            label: '자정 직전 (지금 23:59:10: 오늘은 못 고르고 내일부터)',
            button: '23:59 시트 열기',
            constraints: () => _deadline(
              DateTime(2026, 11, 11, 23, 59, 10),
              withInitial: false,
            ),
            manual: true,
          ),
          (
            label: '모집 종료 (시작 11/20 09:00 + 1분 이후만)',
            button: '모집 종료 시트 열기',
            constraints: () =>
                _deadline(_fixedNow, notBefore: DateTime(2026, 11, 20, 9, 1)),
            manual: false,
          ),
          (
            label: '규칙 없음 (과거도 가능, 모집 시작 용도)',
            button: '모집 시작 시트 열기',
            constraints: () => _anyTime(initial: DateTime(2026, 11, 11, 9, 0)),
            manual: false,
          ),
        ])
      CatalogState(
        s.label,
        (_) => CatalogStateHost<String>(
          initial: '아직 열지 않았어요',
          describe: (value) => value,
          builder: (context, value, onChanged) => SmashButton(
            label: s.button,
            variant: SmashButtonVariant.secondary,
            onPressed: () async {
              final choice = await showSmashDateTimePicker(
                context: context,
                title: '시각 선택',
                constraints: s.constraints(),
                allowManualClose: s.manual,
                today: _fixedToday,
              );
              onChanged(
                choice == null
                    ? '닫았어요 (바뀐 값 없음)'
                    : (choice.isManual
                          ? '수동으로 종료를 골랐어요'
                          : '고른 시각: ${_text(choice.value)}'),
              );
            },
          ),
        ),
      ),
    CatalogState(
      '값 확인 (닫으면 값이 안 바뀌는지)',
      (_) => CatalogStateHost<DateTime?>(
        initial: DateTime(2026, 11, 12, 18, 0),
        describe: (value) => '현재 값은 ${_text(value)}',
        builder: (context, value, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              label: '시각',
              value: value,
              onChanged: (c) => onChanged(c.value),
            ),
            Padding(
              padding: const EdgeInsets.only(top: SmashSpacing.sm),
              child: Text(
                '시트에서 다른 값을 골라도 ✕로 닫으면 값이 그대로다',
                style: SmashText.caption,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);
