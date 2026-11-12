import 'package:app/core/format/hour12.dart';
import 'package:app/core/format/ko_date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const nbsp = ' ';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  // 2026-11-11 은 수요일
  final now = DateTime(2026, 11, 11, 9, 0);

  group('날짜', () {
    test('올해 날짜는 연도 없이 "11월 11일 (수)"', () {
      expect(KoDateFormat.date(DateTime(2026, 11, 11), now: now),
          '11월${nbsp}11일$nbsp(수)');
    });

    test('올해가 아니면 연도를 붙인다 (2027-01-05는 화요일)', () {
      expect(KoDateFormat.date(DateTime(2027, 1, 5), now: now),
          '2027년${nbsp}1월${nbsp}5일$nbsp(화)');
    });

    test('월과 일은 0을 채우지 않는다', () {
      expect(KoDateFormat.date(DateTime(2026, 3, 4), now: now),
          '3월${nbsp}4일$nbsp(수)');
    });

    test('요일 이름: 월화수목금토일', () {
      // 2026-11-09(월) ~ 2026-11-15(일)
      final days = [for (var d = 9; d <= 15; d++) DateTime(2026, 11, d)];
      final names = days
          .map((d) => KoDateFormat.date(d, now: now))
          .map((s) => s.substring(s.indexOf('(') + 1, s.indexOf(')')))
          .toList();

      expect(names, ['월', '화', '수', '목', '금', '토', '일']);
    });

    test('공백은 모두 NBSP이고 일반 공백이 남지 않는다', () {
      final text = KoDateFormat.date(DateTime(2027, 1, 5), now: now);

      expect(text.contains(' '), isFalse);
      expect(text.contains(nbsp), isTrue);
    });
  });

  group('시간 (오전/오후)', () {
    String t(int h, int m) => KoDateFormat.time(DateTime(2026, 11, 11, h, m));

    test('오전 12시 = 0시: 0:00 → "오전 12:00", 0:05 → "오전 12:05"', () {
      expect(t(0, 0), '오전${nbsp}12:00');
      expect(t(0, 5), '오전${nbsp}12:05');
    });

    test('오전 경계: 1:00, 9:05, 11:59', () {
      expect(t(1, 0), '오전${nbsp}1:00');
      expect(t(9, 5), '오전${nbsp}9:05');
      expect(t(11, 59), '오전${nbsp}11:59');
    });

    test('오후 12시 = 12시: 12:00 → "오후 12:00", 12:30 → "오후 12:30"', () {
      expect(t(12, 0), '오후${nbsp}12:00');
      expect(t(12, 30), '오후${nbsp}12:30');
    });

    test('오후: 13:00, 15:00, 23:59', () {
      expect(t(13, 0), '오후${nbsp}1:00');
      expect(t(15, 0), '오후${nbsp}3:00');
      expect(t(23, 59), '오후${nbsp}11:59');
    });

    test('분은 항상 두 자리', () {
      expect(t(15, 0), endsWith(':00'));
      expect(t(15, 7), endsWith(':07'));
    });
  });

  group('날짜 + 시간', () {
    test('"11월 11일 (수) 오후 3:00" 전체가 NBSP로 연결된다', () {
      final text = KoDateFormat.dateTime(DateTime(2026, 11, 11, 15, 0), now: now);

      expect(text, ['11월', '11일', '(수)', '오후', '3:00'].join(nbsp));
      expect(text.contains(' '), isFalse);
    });

    test('다른 해의 자정: "2027년 1월 5일 (화) 오전 12:00"', () {
      final text = KoDateFormat.dateTime(DateTime(2027, 1, 5, 0, 0), now: now);

      expect(text, ['2027년', '1월', '5일', '(화)', '오전', '12:00'].join(nbsp));
    });
  });

  // 표시(KoDateFormat.time)와 시간 휠 변환(hour12.dart)이 같은 경계를 쓰는지 확인한다
  test('표시와 12시간제 변환이 24시간 모두에서 같은 오전/오후와 시를 쓴다', () {
    for (var h = 0; h < 24; h++) {
      final twelve = toHour12(h);
      final shown = KoDateFormat.time(DateTime(2026, 11, 11, h, 0));
      final label = twelve.isPm ? '오후' : '오전';

      expect(shown, '$label$nbsp${twelve.hour12}:00', reason: '$h시');
    }
  });
}
