import 'package:app/core/rules/deadline_rules.dart';
import 'package:app/core/rules/time_slots.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int hour, int minute, [int second = 0]) =>
    DateTime(2026, 11, 11, hour, minute, second);
final today = DateTime(2026, 11, 11);
final tomorrow = DateTime(2026, 11, 12);

void main() {
  group('resolve: 요청한 시각을 고를 수 있는 시각으로 맞춘다', () {
    test('E2: 지금 14:52, 오후 2시를 눌렀을 때 분이 30이면 53분으로 보정된다', () {
      final rules = DeadlineRules(at(14, 52, 10));
      final resolved = TimeSlots.resolve(
        today,
        2,
        true,
        30,
        rules.isSelectable,
      );
      expect(resolved, at(14, 53));
    });

    test('요청한 시각을 고를 수 있으면 그대로다', () {
      final rules = DeadlineRules(at(14, 52, 10));
      expect(
        TimeSlots.resolve(today, 3, true, 30, rules.isSelectable),
        at(15, 30),
      );
      expect(
        TimeSlots.resolve(tomorrow, 9, false, 10, rules.isSelectable),
        DateTime(2026, 11, 12, 9, 10),
      );
    });

    test('E3: 내일 오전 9:10을 오후로 바꾸면 오후 9:10이 그대로 유지된다 (고를 수 있으면 보정하지 않는다)', () {
      final rules = DeadlineRules(at(14, 52, 10));
      expect(
        TimeSlots.resolve(tomorrow, 9, true, 10, rules.isSelectable),
        DateTime(2026, 11, 12, 21, 10),
      );
    });

    test('같은 시에 고를 분이 없으면 같은 오전/오후에서 목록 순서로 처음 고를 수 있는 시의 첫 분으로 간다', () {
      final rules = DeadlineRules(at(14, 52, 10));
      // 오늘 오후 1시(13시)는 모두 지났다 → 오후에서 처음 고를 수 있는 시는 2시(14:53)
      expect(
        TimeSlots.resolve(today, 1, true, 20, rules.isSelectable),
        at(14, 53),
      );
    });

    test('오후 12시를 눌렀는데 오후 12시가 지났으면(14:52) 오후 2시 53분으로 간다', () {
      final rules = DeadlineRules(at(14, 52, 10));
      expect(
        TimeSlots.resolve(today, 12, true, 0, rules.isSelectable),
        at(14, 53),
      );
    });

    test('그 오전/오후에 고를 시각이 없으면 null (오전이 모두 지난 오늘)', () {
      final rules = DeadlineRules(at(14, 52, 10));
      expect(
        TimeSlots.resolve(today, 9, false, 10, rules.isSelectable),
        isNull,
      );
    });

    test('같은 시에 고를 수 있는 분이 있으면 다른 시로 가지 않고 그 시의 첫 분으로 간다 (규칙이 단조롭지 않아도)', () {
      // 오후 1시는 모두 허용, 오후 3시는 40분부터만 허용하는 규칙
      bool rule(DateTime t) => t.hour == 13 || (t.hour == 15 && t.minute >= 40);
      expect(TimeSlots.resolve(today, 3, true, 10, rule), at(15, 40));
      expect(TimeSlots.resolve(today, 3, true, 55, rule), at(15, 55));
    });

    test('규칙이 모두 허용하면 요청 그대로 (오전 12시 = 00:00 포함)', () {
      bool all(DateTime _) => true;
      expect(TimeSlots.resolve(today, 12, false, 0, all), at(0, 0));
      expect(TimeSlots.resolve(today, 12, true, 59, all), at(12, 59));
    });
  });

  group('목록 순서와 첫 활성 값', () {
    test('시 목록은 1부터 12까지 순서다', () {
      expect(TimeSlots.hourList, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    });

    test(
      '첫 활성 시는 시간 순서가 아니라 목록 순서의 맨 위다: 11:59:30 오후에는 12시(12:00)가 가장 이르지만 목록 순서로는 1시가 먼저다',
      () {
        final rules = DeadlineRules(at(11, 59, 30));
        expect(rules.firstEnabledHour(today, true), 1);
        expect(rules.isHourEnabled(today, 12, true), isTrue);
      },
    );

    test('그 오전/오후에 고를 시각이 없으면 첫 활성 시는 null이고 날짜 전체가 비활성이다', () {
      final rules = DeadlineRules(at(23, 59, 10));
      expect(rules.firstEnabledHour(today, false), isNull);
      expect(rules.firstEnabledHour(today, true), isNull);
      expect(TimeSlots.isDayEnabled(today, rules.isSelectable), isFalse);
    });

    test('임의의 규칙(평일 낮만)도 같은 계산으로 활성이 정해진다', () {
      bool workHours(DateTime d) => d.hour >= 9 && d.hour < 18;
      expect(TimeSlots.isHalfEnabled(today, false, workHours), isTrue);
      expect(TimeSlots.isHourEnabled(today, 8, false, workHours), isFalse);
      expect(TimeSlots.isHourEnabled(today, 9, false, workHours), isTrue);
      expect(
        TimeSlots.isHourEnabled(today, 6, true, workHours),
        isFalse,
        reason: '오후 6시 = 18시',
      );
      expect(TimeSlots.firstEnabledHour(today, true, workHours), 1);
      expect(
        TimeSlots.isHourEnabled(today, 12, true, workHours),
        isTrue,
        reason: '오후 12시 = 12시',
      );
    });
  });
}
