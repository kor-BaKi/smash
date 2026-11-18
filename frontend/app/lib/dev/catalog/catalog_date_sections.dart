import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/format/ko_date_format.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

/// 카탈로그에서 "오늘"을 고정해야 모양이 매번 같다
final _today = DateTime(2026, 11, 16);
final _first = DateTime(2026, 11, 1);
final _last = DateTime(2027, 2, 28);

String _text(DateTime? day) =>
    day == null ? '고르지 않았어요' : KoDateFormat.date(day, now: _today);

SmashDateField _field({
  String label = '시작일',
  DateTime? value,
  ValueChanged<DateTime>? onChanged,
  DateTime? first,
  DateTime? last,
  DateTime? initial,
  bool Function(DateTime)? enabled,
  String? error,
  String? helper,
  bool isEnabled = true,
}) => SmashDateField(
  label: label,
  value: value,
  onChanged: onChanged ?? (_) {},
  firstDate: first ?? _first,
  lastDate: last ?? _last,
  initialDate: initial,
  isDayEnabled: enabled,
  errorText: error,
  helper: helper,
  enabled: isEnabled,
  today: _today,
);

final dayPickerEntry = CatalogEntry(
  name: 'SmashDayPicker',
  description:
      '날짜 하나를 고르는 달력 본체 (시트 껍데기 없음). 범위(양 끝 포함) 밖과 막은 날은 못 고르고, 그 밖의 달로는 못 넘어간다. 날짜와 시간을 함께 고르는 시트도 이 본체를 쓴다.',
  states: [
    CatalogState(
      '기본 (범위 2026년 11월 ~ 2027년 2월)',
      (_) => SmashDayPicker(
        firstDate: _first,
        lastDate: _last,
        today: _today,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '고른 날 (11월 20일)',
      (_) => SmashDayPicker(
        firstDate: _first,
        lastDate: _last,
        selectedDay: DateTime(2026, 11, 20),
        today: _today,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '범위 제한 (11월 18일 ~ 25일만 선택 가능)',
      (_) => SmashDayPicker(
        firstDate: DateTime(2026, 11, 18),
        lastDate: DateTime(2026, 11, 25),
        today: _today,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '일요일은 막음',
      (_) => SmashDayPicker(
        firstDate: _first,
        lastDate: _last,
        isDayEnabled: (d) => d.weekday != DateTime.sunday,
        today: _today,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<DateTime?>(
        initial: null,
        describe: _text,
        builder: (context, value, onChanged) => SmashDayPicker(
          firstDate: _first,
          lastDate: _last,
          selectedDay: value,
          today: _today,
          onChanged: onChanged,
        ),
      ),
    ),
  ],
);

final dateFieldEntry = CatalogEntry(
  name: 'SmashDateField',
  description:
      '날짜를 고르는 입력칸. 누르면 날짜 시트가 열리고 "선택"으로 확정하면 값이 바뀐다. 모양은 SmashTextField와 같다.',
  states: [
    CatalogState('빈 값', (_) => _field()),
    CatalogState('값 있음', (_) => _field(value: DateTime(2026, 11, 20))),
    CatalogState(
      '다른 해의 값 (연도가 붙음)',
      (_) => _field(value: DateTime(2027, 1, 5)),
    ),
    CatalogState('도움말', (_) => _field(helper: '신청서를 받기 시작하는 날이에요')),
    CatalogState('오류', (_) => _field(error: '시작일을 골라 주세요')),
    CatalogState(
      '비활성',
      (_) => _field(isEnabled: false, value: DateTime(2026, 11, 20)),
    ),
    CatalogState(
      '긴 라벨과 긴 오류',
      (_) => _field(
        label: '신청서를 받기 시작하는 날짜와 마감 전 안내를 보낼 날짜',
        value: DateTime(2027, 1, 5),
        error: '시작일은 마감일보다 앞이어야 해요',
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<DateTime?>(
        initial: null,
        describe: _text,
        builder: (context, value, onChanged) => _field(
          value: value,
          onChanged: onChanged,
          initial: DateTime(2026, 11, 17),
        ),
      ),
    ),
    CatalogState(
      '지난 날짜 불가 (오늘 11월 16일부터)',
      (_) => CatalogStateHost<DateTime?>(
        initial: null,
        describe: _text,
        builder: (context, value, onChanged) => _field(
          label: '마감일',
          value: value,
          onChanged: onChanged,
          first: _today,
        ),
      ),
    ),
    CatalogState(
      '시작일과 끝일 (끝일은 시작일 이후만 고를 수 있음)',
      (_) => CatalogStateHost<({DateTime? start, DateTime? end})>(
        initial: (start: null, end: null),
        describe: (v) => '${_text(v.start)} ~ ${_text(v.end)}',
        builder: (context, v, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              label: '시작일',
              value: v.start,
              // 시작일을 끝일보다 늦게 바꾸면 끝일을 비운다
              onChanged: (start) => onChanged((
                start: start,
                end: v.end != null && v.end!.isBefore(start) ? null : v.end,
              )),
            ),
            const SizedBox(height: SmashSpacing.md),
            _field(
              label: '끝일',
              value: v.end,
              first: v.start ?? _first,
              onChanged: (end) => onChanged((start: v.start, end: end)),
            ),
          ],
        ),
      ),
    ),
  ],
);

final datePickerEntry = CatalogEntry(
  name: 'showSmashDatePicker',
  description:
      '날짜 시트. "선택"을 눌러야 확정되고 닫으면 값이 안 바뀐다. 바깥을 누르거나 끌어내려도 닫히지 않는다. 눌러서 열어 보세요.',
  states: [
    for (final scenario
        in <
          ({
            String label,
            String button,
            DateTime? initial,
            DateTime? first,
            DateTime? last,
            bool Function(DateTime)? enabled,
          })
        >[
          (
            label: '초기값 없음 ("선택"이 비활성)',
            button: '날짜 시트 열기',
            initial: null,
            first: null,
            last: null,
            enabled: null,
          ),
          (
            label: '초기값 있음 (11월 20일이 골라져 있음)',
            button: '초기값 있는 시트 열기',
            initial: DateTime(2026, 11, 20),
            first: null,
            last: null,
            enabled: null,
          ),
          (
            label: '지난 날짜 불가 (오늘 11월 16일부터)',
            button: '지난 날짜 불가 시트 열기',
            initial: null,
            first: _today,
            last: null,
            enabled: null,
          ),
          (
            label: '범위 제한 (11월 18일 ~ 25일)',
            button: '범위 제한 시트 열기',
            initial: DateTime(2026, 11, 20),
            first: DateTime(2026, 11, 18),
            last: DateTime(2026, 11, 25),
            enabled: null,
          ),
          (
            label: '일요일 막음',
            button: '일요일 막은 시트 열기',
            initial: null,
            first: null,
            last: null,
            enabled: (DateTime d) => d.weekday != DateTime.sunday,
          ),
        ])
      CatalogState(
        scenario.label,
        (_) => CatalogStateHost<String>(
          initial: '아직 열지 않았어요',
          describe: (value) => value,
          builder: (context, value, onChanged) => SmashButton(
            label: scenario.button,
            variant: SmashButtonVariant.secondary,
            onPressed: () async {
              final picked = await showSmashDatePicker(
                context: context,
                firstDate: scenario.first ?? _first,
                lastDate: scenario.last ?? _last,
                initialDate: scenario.initial,
                isDayEnabled: scenario.enabled,
                today: _today,
              );
              onChanged(
                picked == null ? '닫았어요 (바뀐 값 없음)' : '고른 날짜: ${_text(picked)}',
              );
            },
          ),
        ),
      ),
    CatalogState(
      '값 확인 (닫으면 값이 안 바뀌는지)',
      (_) => CatalogStateHost<DateTime?>(
        initial: DateTime(2026, 11, 20),
        describe: (value) => '현재 값은 ${_text(value)}',
        builder: (context, value, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(label: '날짜', value: value, onChanged: onChanged),
            Padding(
              padding: const EdgeInsets.only(top: SmashSpacing.sm),
              child: Text(
                '시트에서 다른 날을 골라도 "닫기"를 누르면 값이 그대로다',
                style: SmashText.caption,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);
