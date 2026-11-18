import 'package:app/core/rules/deadline_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-11-11(수) 기준 시각
DateTime at(int hour, int minute, [int second = 0, int ms = 0]) =>
    DateTime(2026, 11, 11, hour, minute, second, ms);

DeadlineRules rules(DateTime now, {DateTime? notBefore}) =>
    DeadlineRules(now, notBefore: notBefore);

void main() {
  group('A. 최소 선택 = 현재 시각의 다음 분', () {
    test('A1~A3: 초나 밀리초가 어떻든 다음 분 정각', () {
      expect(rules(at(14, 52, 10)).minSelectable, at(14, 53));
      expect(
        rules(at(14, 52, 0, 0)).minSelectable,
        at(14, 53),
        reason: '초가 0이어도 현재 분은 고를 수 없다',
      );
      expect(rules(at(14, 52, 59, 999)).minSelectable, at(14, 53));
    });

    test('A4: 시 경계, A5: 오전에서 오후로', () {
      expect(rules(at(14, 59, 30)).minSelectable, at(15, 0));
      expect(rules(at(11, 59, 30)).minSelectable, at(12, 0));
    });

    test('A6: 날짜 경계는 첫 선택 날짜도 내일이 된다', () {
      final r = rules(at(23, 59, 10));
      expect(r.minSelectable, DateTime(2026, 11, 12, 0, 0));
      expect(r.firstSelectableDate, DateTime(2026, 11, 12));
    });

    test('A7: 연말', () {
      expect(
        rules(DateTime(2026, 12, 31, 23, 59, 20)).minSelectable,
        DateTime(2027, 1, 1, 0, 0),
      );
    });

    test('A8: 하루 모든 분과 초 값에서 초, 밀리초는 0이고 minSelectable은 now보다 엄격히 뒤다', () {
      for (var h = 0; h < 24; h++) {
        for (var m = 0; m < 60; m++) {
          for (final (s, ms) in [(0, 0), (30, 0), (59, 999)]) {
            final now = at(h, m, s, ms);
            final min = rules(now).minSelectable;
            expect(min.second, 0);
            expect(min.millisecond, 0);
            expect(min.isAfter(now), isTrue, reason: '$now');
            expect(
              min.difference(now),
              lessThanOrEqualTo(const Duration(minutes: 1)),
              reason: '$now: 다음 분이지 그 이후가 아니다',
            );
          }
        }
      }
    });

    test('firstSelectableDate는 minSelectable이 속한 날이다', () {
      expect(rules(at(9, 0)).firstSelectableDate, DateTime(2026, 11, 11));
    });
  });

  group('B. 초기값 = 최소 선택을 5분 단위로 올린 값', () {
    final cases = <String, (DateTime, DateTime)>{
      'B1 14:52:10 → 14:55': (at(14, 52, 10), at(14, 55)),
      'B2 14:54:30 → 14:55': (at(14, 54, 30), at(14, 55)),
      'B3 14:54:59.999 → 14:55': (at(14, 54, 59, 999), at(14, 55)),
      'B4 14:55:00.000 → 15:00 (같은 5분 지점이면 다음 지점)': (
        at(14, 55, 0, 0),
        at(15, 0),
      ),
      'B5 14:55:30 → 15:00': (at(14, 55, 30), at(15, 0)),
      'B6 14:00:00 → 14:05': (at(14, 0), at(14, 5)),
      'B7 14:57:00 → 15:00 (시 넘김)': (at(14, 57), at(15, 0)),
      'B8 11:56:00 → 12:00 (오전→오후)': (at(11, 56), at(12, 0)),
      'B9 23:56:00 → 내일 00:00 (날짜 넘김)': (
        at(23, 56),
        DateTime(2026, 11, 12, 0, 0),
      ),
    };
    cases.forEach((name, c) {
      test(name, () => expect(rules(c.$1).initialValue, c.$2));
    });

    test(
      'B10: 하루 모든 분과 초 값에서 항상 최소 이상이고, 분이 5의 배수이고, 초는 0이며, now보다 엄격히 뒤다',
      () {
        for (var h = 0; h < 24; h++) {
          for (var m = 0; m < 60; m++) {
            for (final (s, ms) in [(0, 0), (30, 0), (59, 999)]) {
              final now = at(h, m, s, ms);
              final r = rules(now);
              final initial = r.initialValue;
              expect(
                initial.isBefore(r.minSelectable),
                isFalse,
                reason: '$now',
              );
              expect(initial.minute % 5, 0, reason: '$now');
              expect(initial.second, 0);
              expect(initial.millisecond, 0);
              expect(initial.isAfter(now), isTrue, reason: '$now');
              expect(
                initial.difference(r.minSelectable),
                lessThan(const Duration(minutes: 5)),
                reason: '$now: 5분 이상 올리지 않는다',
              );
              expect(r.isSelectable(initial), isTrue);
            }
          }
        }
      },
    );
  });

  group('C. 선택 가능 판정', () {
    final r = rules(at(14, 52, 10));
    test('C1~C5', () {
      expect(r.isSelectable(at(14, 53)), isTrue, reason: '최소 포함');
      expect(r.isSelectable(at(14, 52)), isFalse, reason: '현재 분');
      expect(r.isSelectable(at(14, 51)), isFalse);
      expect(
        r.isSelectable(DateTime(2026, 11, 10, 14, 53)),
        isFalse,
        reason: '어제 같은 시각',
      );
      expect(r.isSelectable(DateTime(2026, 11, 12, 0, 0)), isTrue);
    });
    test('C6~C7: clampToMin 대신 adjust', () {
      expect(r.adjust(at(14, 30)).value, at(14, 53));
      expect(r.adjust(at(15, 10)).value, at(15, 10));
    });
  });

  group('D. 시간 목록 활성 상태', () {
    test('D1~D4: 오늘 14:52:10', () {
      final r = rules(at(14, 52, 10));
      final today = DateTime(2026, 11, 11);
      expect(r.isAmEnabled(today), isFalse);
      expect(r.isPmEnabled(today), isTrue);
      expect(
        r.isHourEnabled(today, 12, true),
        isFalse,
        reason: '오후 12시 = 12:xx',
      );
      expect(r.isHourEnabled(today, 1, true), isFalse, reason: '오후 1시 = 13:xx');
      for (final hour in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) {
        expect(r.isHourEnabled(today, hour, true), isTrue, reason: '오후 $hour시');
      }
      for (var minute = 0; minute < 60; minute++) {
        expect(
          r.isMinuteEnabled(today, 2, true, minute),
          minute >= 53,
          reason: '오후 2시 $minute분',
        );
        expect(
          r.isMinuteEnabled(today, 3, true, minute),
          isTrue,
          reason: '오후 3시 $minute분',
        );
      }
      expect(r.firstEnabledMinute(today, 2, true), 53);
      expect(r.firstEnabledMinute(today, 3, true), 0);
    });

    test('D5: 내일은 전부 활성', () {
      final r = rules(at(14, 52, 10));
      final tomorrow = DateTime(2026, 11, 12);
      expect(r.isAmEnabled(tomorrow), isTrue);
      expect(r.isPmEnabled(tomorrow), isTrue);
      for (final isPm in [false, true]) {
        for (var hour = 1; hour <= 12; hour++) {
          expect(r.isHourEnabled(tomorrow, hour, isPm), isTrue);
        }
      }
      expect(r.firstEnabledHour(tomorrow, false), 1);
      expect(r.firstEnabledMinute(tomorrow, 1, false), 0);
    });

    test('D6: 09:10 오전 - 12시(0시대)와 1~8시는 비활성, 9시는 11분부터', () {
      final r = rules(at(9, 10));
      final today = DateTime(2026, 11, 11);
      for (final hour in [12, 1, 2, 3, 4, 5, 6, 7, 8]) {
        expect(
          r.isHourEnabled(today, hour, false),
          isFalse,
          reason: '오전 $hour시',
        );
      }
      expect(r.isHourEnabled(today, 9, false), isTrue);
      expect(r.firstEnabledMinute(today, 9, false), 11);
      expect(r.isMinuteEnabled(today, 9, false, 10), isFalse);
      expect(r.isMinuteEnabled(today, 9, false, 11), isTrue);
      expect(r.isHourEnabled(today, 10, false), isTrue);
      expect(r.firstEnabledHour(today, false), 9);
    });

    test('D7: 00:10 오전 12시 - 분 00~10은 비활성, 11부터 활성 (0시 경계)', () {
      final r = rules(at(0, 10));
      final today = DateTime(2026, 11, 11);
      for (var minute = 0; minute <= 10; minute++) {
        expect(r.isMinuteEnabled(today, 12, false, minute), isFalse);
      }
      expect(r.isMinuteEnabled(today, 12, false, 11), isTrue);
      expect(r.firstEnabledMinute(today, 12, false), 11);
    });

    test('D8: 12:20 - 오전은 전체 비활성, 오후 12시는 21분부터, 오후 1시부터는 전체 활성 (12시 경계)', () {
      final r = rules(at(12, 20));
      final today = DateTime(2026, 11, 11);
      expect(r.isAmEnabled(today), isFalse);
      expect(r.firstEnabledMinute(today, 12, true), 21);
      expect(r.isMinuteEnabled(today, 12, true, 20), isFalse);
      expect(r.isMinuteEnabled(today, 12, true, 21), isTrue);
      expect(r.firstEnabledMinute(today, 1, true), 0);
    });

    test('D9: 11:59:30 - 오전은 전체 비활성, 오후 12시 00분부터 활성', () {
      final r = rules(at(11, 59, 30));
      final today = DateTime(2026, 11, 11);
      expect(r.isAmEnabled(today), isFalse);
      expect(r.isMinuteEnabled(today, 12, true, 0), isTrue);
      expect(r.firstEnabledMinute(today, 12, true), 0);
    });

    test('D10: 23:59:10 - 오늘은 오전, 오후 모두 비활성이고 내일부터 선택할 수 있다', () {
      final r = rules(at(23, 59, 10));
      final today = DateTime(2026, 11, 11);
      expect(r.isAmEnabled(today), isFalse);
      expect(r.isPmEnabled(today), isFalse);
      expect(r.isDayEnabled(today), isFalse);
      expect(r.firstEnabledHour(today, true), isNull);
      expect(r.isDayEnabled(DateTime(2026, 11, 12)), isTrue);
      expect(r.firstSelectableDate, DateTime(2026, 11, 12));
    });

    test(
      'D11: 독립 기준과 일치 - 시 활성은 그 시의 마지막 분이 최소 이후인지, 오전/오후 활성은 그 반나절의 마지막 분이 최소 이후인지와 같다',
      () {
        for (var minuteOfDay = 0; minuteOfDay < 24 * 60; minuteOfDay += 7) {
          final now = at(minuteOfDay ~/ 60, minuteOfDay % 60, 11);
          final r = rules(now);
          for (final date in [
            DateTime(2026, 11, 10),
            DateTime(2026, 11, 11),
            DateTime(2026, 11, 12),
          ]) {
            for (final isPm in [false, true]) {
              final lastOfHalf = DateTime(
                date.year,
                date.month,
                date.day,
                isPm ? 23 : 11,
                59,
              );
              expect(
                isPm ? r.isPmEnabled(date) : r.isAmEnabled(date),
                !lastOfHalf.isBefore(r.minSelectable),
                reason: '$now $date pm=$isPm',
              );
              for (var hour = 1; hour <= 12; hour++) {
                final hour24 = hour % 12 + (isPm ? 12 : 0);
                final lastOfHour = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  hour24,
                  59,
                );
                expect(
                  r.isHourEnabled(date, hour, isPm),
                  !lastOfHour.isBefore(r.minSelectable),
                  reason: '$now $date $hour pm=$isPm',
                );
                for (var minute = 0; minute < 60; minute += 11) {
                  expect(
                    r.isMinuteEnabled(date, hour, isPm, minute),
                    !DateTime(
                      date.year,
                      date.month,
                      date.day,
                      hour24,
                      minute,
                    ).isBefore(r.minSelectable),
                  );
                }
              }
            }
          }
        }
      },
    );

    test(
      'D12: 12시간제 합성 - 오전 12시는 00:00, 오후 12시는 12:00, 오후 1시는 13:00, 오전 11시는 11:00',
      () {
        final d = DateTime(2026, 11, 11);
        expect(
          DeadlineRules.compose(d, 12, false, 0),
          DateTime(2026, 11, 11, 0, 0),
        );
        expect(
          DeadlineRules.compose(d, 12, true, 0),
          DateTime(2026, 11, 11, 12, 0),
        );
        expect(
          DeadlineRules.compose(d, 1, true, 5),
          DateTime(2026, 11, 11, 13, 5),
        );
        expect(
          DeadlineRules.compose(d, 11, false, 59),
          DateTime(2026, 11, 11, 11, 59),
        );
        expect(
          DeadlineRules.compose(d, 11, true, 59),
          DateTime(2026, 11, 11, 23, 59),
        );
      },
    );
  });

  group('E. 자동 보정', () {
    test('E1: 내일 오후 3:10을 골랐다가 날짜를 오늘로 바꿨다 (now 15:20) - 최소로 올리고 보정됨 표시', () {
      final r = rules(at(15, 20));
      final adjusted = r.adjust(at(15, 10));
      expect(adjusted.value, at(15, 21));
      expect(adjusted.adjusted, isTrue);
    });

    test('E4: 값이 바뀌지 않으면 adjusted는 false (경계: 최소와 같은 값도 false)', () {
      final r = rules(at(15, 20));
      expect(r.adjust(at(15, 21)).adjusted, isFalse);
      expect(r.adjust(at(18, 0)).adjusted, isFalse);
      expect(r.adjust(at(15, 20)).adjusted, isTrue);
    });
  });

  group('F. 프리셋 칩', () {
    List<String> labels(DateTime now) =>
        rules(now).presets().map((p) => p.label).toList();

    test(
      'F1: 08:00 - 오늘 밤(오늘 22:00), 내일 오후(내일 18:00), 3일 뒤(3일 뒤 18:00), 1주일 뒤(7일 뒤 18:00)',
      () {
        final presets = rules(at(8, 0)).presets();
        expect(presets.map((p) => p.label), ['오늘 밤', '내일 오후', '3일 뒤', '1주일 뒤']);
        expect(presets.map((p) => p.value), [
          at(22, 0),
          DateTime(2026, 11, 12, 18, 0),
          DateTime(2026, 11, 14, 18, 0),
          DateTime(2026, 11, 18, 18, 0),
        ]);
        expect(presets.map((p) => p.kind), DeadlinePresetKind.values);
      },
    );

    test(
      'F2~F3: 21:29:59.999에는 오늘 밤이 보이고 21:30:00에는 숨는다 (최소 + 30분 > 22:00)',
      () {
        expect(labels(at(21, 29, 59, 999)), contains('오늘 밤'));
        expect(labels(at(21, 30, 0, 0)), isNot(contains('오늘 밤')));
      },
    );

    test('F4: 22:00과 23:59:30에는 오늘 밤이 숨고 나머지 셋은 항상 보인다', () {
      for (final now in [at(22, 0), at(23, 59, 30)]) {
        expect(labels(now), ['내일 오후', '3일 뒤', '1주일 뒤'], reason: '$now');
      }
    });

    test('F5: 23:59:30 - 내일 오후는 11-12 18:00 (날짜는 now 기준)', () {
      expect(
        rules(at(23, 59, 30)).presets().first.value,
        DateTime(2026, 11, 12, 18, 0),
      );
    });

    test('F6~F8: 3일 뒤의 월, 연, 윤년 경계', () {
      DateTime threeDays(DateTime now) =>
          rules(now).presets().firstWhere((p) => p.label == '3일 뒤').value;
      expect(
        threeDays(DateTime(2026, 11, 29, 8, 0)),
        DateTime(2026, 12, 2, 18, 0),
      );
      expect(
        threeDays(DateTime(2026, 12, 30, 8, 0)),
        DateTime(2027, 1, 2, 18, 0),
      );
      expect(
        threeDays(DateTime(2028, 2, 27, 8, 0)),
        DateTime(2028, 3, 1, 18, 0),
      );
    });

    test('F6b: 1주일 뒤는 정확히 7일 뒤 18:00이고 월, 연, 윤년 경계를 넘는다', () {
      DateTime week(DateTime now) =>
          rules(now).presets().firstWhere((p) => p.label == '1주일 뒤').value;
      expect(week(DateTime(2026, 11, 11, 8, 0)), DateTime(2026, 11, 18, 18, 0));
      expect(week(DateTime(2026, 11, 29, 8, 0)), DateTime(2026, 12, 6, 18, 0));
      expect(week(DateTime(2026, 12, 30, 8, 0)), DateTime(2027, 1, 6, 18, 0));
      expect(week(DateTime(2028, 2, 27, 8, 0)), DateTime(2028, 3, 5, 18, 0));
      expect(week(DateTime(2027, 2, 27, 8, 0)), DateTime(2027, 3, 6, 18, 0));
    });

    test(
      'F9: 하루 모든 시각에서 보이는 프리셋은 분 00, 초 0이고 선택 가능하며 순서는 오늘 밤, 내일 오후, 3일 뒤, 1주일 뒤다',
      () {
        for (var minuteOfDay = 0; minuteOfDay < 24 * 60; minuteOfDay++) {
          for (final second in [0, 59]) {
            final now = at(minuteOfDay ~/ 60, minuteOfDay % 60, second);
            final r = rules(now);
            final presets = r.presets();
            var lastKind = -1;
            for (final preset in presets) {
              expect(preset.value.minute, 0);
              expect(preset.value.second, 0);
              expect(
                r.isSelectable(preset.value),
                isTrue,
                reason: '$now ${preset.label}',
              );
              expect(preset.kind.index, greaterThan(lastKind));
              lastKind = preset.kind.index;
            }
            expect(presets.length, inInclusiveRange(3, 4));
          }
        }
      },
    );

    test('F10: presetFor는 시각이 정확히 같을 때만 칩을 돌려준다 (1분이라도 다르면 null)', () {
      final r = rules(at(8, 0));
      expect(r.presetFor(at(22, 0))?.label, '오늘 밤');
      expect(r.presetFor(DateTime(2026, 11, 12, 18, 0))?.label, '내일 오후');
      expect(r.presetFor(DateTime(2026, 11, 14, 18, 0))?.label, '3일 뒤');
      expect(r.presetFor(DateTime(2026, 11, 18, 18, 0))?.label, '1주일 뒤');
      expect(r.presetFor(at(22, 1)), isNull);
      expect(r.presetFor(at(21, 59)), isNull);
      expect(r.presetFor(null), isNull);
    });

    test('숨은 프리셋 값은 presetFor에도 잡히지 않는다 (21:30 이후 22:00)', () {
      expect(rules(at(21, 40)).presetFor(at(22, 0)), isNull);
    });

    test('notBefore가 있으면 그보다 이른 프리셋은 숨는다', () {
      final r = rules(at(8, 0), notBefore: DateTime(2026, 11, 12, 19, 0));
      expect(r.presets().map((p) => p.label), ['3일 뒤', '1주일 뒤']);
    });
  });

  group('G. 모집 기간 (종료 > 시작)', () {
    final r = rules(DateTime(2026, 1, 1, 9, 0));
    DateTime d(int day, int h, int m) => DateTime(2026, 3, day, h, m);

    test('G1~G2: 하나라도 비어 있으면 유효 (서버와 같음)', () {
      expect(r.validatePeriod(null, d(2, 9, 0)), isNull);
      expect(r.validatePeriod(d(2, 9, 0), null), isNull);
      expect(r.validatePeriod(null, null), isNull);
    });

    test('G3: 시작이 과거여도 종료가 미래면 유효 (바로 시작)', () {
      expect(rules(d(5, 12, 0)).validatePeriod(d(1, 9, 0), d(9, 9, 0)), isNull);
    });

    test('G4~G6: 같으면 오류, 1분 뒤면 유효, 이르면 오류', () {
      expect(
        r.validatePeriod(d(2, 9, 0), d(2, 9, 0)),
        PeriodError.endNotAfterStart,
      );
      expect(r.validatePeriod(d(2, 9, 0), d(2, 9, 1)), isNull);
      expect(
        r.validatePeriod(d(2, 9, 0), d(2, 8, 59)),
        PeriodError.endNotAfterStart,
      );
    });

    test('G7~G10: 오전 12시/오후 12시, 11:59 → 12:00, 날짜 경계', () {
      expect(r.validatePeriod(d(2, 0, 0), d(2, 12, 0)), isNull);
      expect(
        r.validatePeriod(d(2, 12, 0), d(2, 0, 0)),
        PeriodError.endNotAfterStart,
      );
      expect(r.validatePeriod(d(2, 11, 59), d(2, 12, 0)), isNull);
      expect(r.validatePeriod(d(2, 23, 59), d(3, 0, 0)), isNull);
    });

    test('G11: 종료가 지금보다 이후가 아니면 오류 (서버보다 엄격한 클라이언트 규칙)', () {
      final now = DateTime(2026, 3, 5, 14, 52, 30);
      final rr = rules(now);
      expect(
        rr.validatePeriod(null, DateTime(2026, 3, 5, 14, 52)),
        PeriodError.endNotAfterNow,
      );
      expect(
        rr.validatePeriod(null, DateTime(2026, 3, 5, 14, 52, 45)),
        PeriodError.endNotAfterNow,
        reason: '아직 최소(14:53)보다 이르다',
      );
      expect(
        rr.validatePeriod(null, DateTime(2026, 3, 5, 14, 53)),
        isNull,
        reason: '최소와 같으면 유효',
      );
    });

    test('G12: 시작 규칙이 먼저다 - 종료가 시작보다도 지금보다도 이르면 "시작보다 이후" 오류', () {
      final rr = rules(DateTime(2026, 3, 5, 14, 52));
      expect(
        rr.validatePeriod(
          DateTime(2026, 3, 9, 9, 0),
          DateTime(2026, 3, 7, 9, 0),
        ),
        PeriodError.endNotAfterStart,
      );
      expect(
        rr.validatePeriod(
          DateTime(2026, 3, 1, 9, 0),
          DateTime(2026, 3, 1, 8, 0),
        ),
        PeriodError.endNotAfterStart,
      );
    });

    test('G13: 오류 문구는 서버와 같은 존댓말 문구다', () {
      expect(
        DeadlineRules.periodErrorMessage(PeriodError.endNotAfterStart),
        '모집 종료 시각은 시작 시각보다 이후로 설정해 주세요.',
      );
      expect(
        DeadlineRules.periodErrorMessage(PeriodError.endNotAfterNow),
        '모집 종료 시각은 지금보다 이후로 설정해 주세요.',
      );
      expect(DeadlineRules.invalidCloseTimeMessage, '마감 시각은 지금보다 이후로 설정해 주세요.');
    });

    test('validateOrder는 지금을 보지 않는 정적 규칙이다', () {
      expect(
        DeadlineRules.validateOrder(d(2, 9, 0), d(2, 9, 0)),
        PeriodError.endNotAfterStart,
      );
      expect(
        DeadlineRules.validateOrder(DateTime(2000), DateTime(2001)),
        isNull,
      );
    });
  });

  group('H. 제출 직전 재검증', () {
    test('H1: 14:52:30에 14:53을 골랐다면 14:52:59까지는 유효', () {
      expect(
        DeadlineRules.revalidate(at(14, 53), at(14, 52, 59)).valid,
        isTrue,
      );
    });

    test('H2: 14:53:00에는 오류 (서버의 closedAt > 지금과 같은 기준), 제안은 다음 분', () {
      final result = DeadlineRules.revalidate(at(14, 53), at(14, 53, 0, 0));
      expect(result.valid, isFalse);
      expect(result.suggestion, at(14, 54));
    });

    test(
      'H3: 시트를 14:52:50에 열어 14:53을 골랐는데 제출이 14:53:05 - 오류와 보정 제안값 14:54',
      () {
        final result = DeadlineRules.revalidate(at(14, 53), at(14, 53, 5));
        expect(result.valid, isFalse);
        expect(result.suggestion, at(14, 54));
      },
    );

    test('H4: 수동 종료(null)는 언제나 유효하고 제안이 없다', () {
      final result = DeadlineRules.revalidate(null, at(23, 59, 59));
      expect(result.valid, isTrue);
      expect(result.suggestion, isNull);
    });

    test('제안값은 항상 그 시점에서 고를 수 있고 현재보다 뒤다', () {
      for (final nowAtSubmit in [at(14, 53, 5), at(23, 59, 30), at(0, 0, 0)]) {
        final result = DeadlineRules.revalidate(at(0, 0), nowAtSubmit);
        expect(result.valid, isFalse);
        expect(result.suggestion!.isAfter(nowAtSubmit), isTrue);
        expect(
          DeadlineRules(nowAtSubmit).isSelectable(result.suggestion!),
          isTrue,
        );
      }
    });
  });

  group('notBefore (모집 종료 = 시작 + 1분 이후)', () {
    test('notBefore가 다음 분보다 이르면 다음 분이 최소다', () {
      expect(
        rules(at(14, 52, 10), notBefore: at(9, 0)).minSelectable,
        at(14, 53),
      );
    });

    test('notBefore가 더 늦으면 그 시각이 최소다 (시작 + 1분)', () {
      final start = DateTime(2026, 11, 20, 9, 0);
      final r = rules(
        at(14, 52, 10),
        notBefore: start.add(const Duration(minutes: 1)),
      );
      expect(r.minSelectable, DateTime(2026, 11, 20, 9, 1));
      expect(r.isSelectable(DateTime(2026, 11, 20, 9, 0)), isFalse);
      expect(r.isSelectable(DateTime(2026, 11, 20, 9, 1)), isTrue);
      expect(r.firstSelectableDate, DateTime(2026, 11, 20));
    });

    test('notBefore에 초가 있으면 분 단위로 올림한다', () {
      final r = rules(at(8, 0), notBefore: DateTime(2026, 11, 20, 9, 0, 30));
      expect(r.minSelectable, DateTime(2026, 11, 20, 9, 1));
    });

    test('초기값은 그 최소를 5분 단위로 올린 값이다', () {
      final r = rules(at(8, 0), notBefore: DateTime(2026, 11, 20, 9, 1));
      expect(r.initialValue, DateTime(2026, 11, 20, 9, 5));
    });
  });
}
