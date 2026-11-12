import 'package:app/core/format/hour12.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toHour12 (24시간제 → 12시간제)', () {
    test('0시 → 오전 12시, 12시 → 오후 12시', () {
      expect(toHour12(0), (hour12: 12, isPm: false));
      expect(toHour12(12), (hour12: 12, isPm: true));
    });

    test('오전 1~11시', () {
      expect(toHour12(1), (hour12: 1, isPm: false));
      expect(toHour12(11), (hour12: 11, isPm: false));
    });

    test('오후 1~11시', () {
      expect(toHour12(13), (hour12: 1, isPm: true));
      expect(toHour12(23), (hour12: 11, isPm: true));
    });

    test('범위를 벗어나면 RangeError', () {
      expect(() => toHour12(-1), throwsRangeError);
      expect(() => toHour12(24), throwsRangeError);
    });
  });

  group('toHour24 (12시간제 → 24시간제)', () {
    test('오전 12시 = 0시, 오후 12시 = 12시', () {
      expect(toHour24(12, isPm: false), 0);
      expect(toHour24(12, isPm: true), 12);
    });

    test('오전 1~11시는 그대로', () {
      expect(toHour24(1, isPm: false), 1);
      expect(toHour24(11, isPm: false), 11);
    });

    test('오후 1~11시는 12를 더한다', () {
      expect(toHour24(1, isPm: true), 13);
      expect(toHour24(11, isPm: true), 23);
    });

    test('범위를 벗어나면 RangeError', () {
      expect(() => toHour24(0, isPm: false), throwsRangeError);
      expect(() => toHour24(13, isPm: true), throwsRangeError);
    });
  });

  test('0~23시 모두 왕복 변환해도 같은 값', () {
    for (var h = 0; h < 24; h++) {
      final twelve = toHour12(h);

      expect(toHour24(twelve.hour12, isPm: twelve.isPm), h, reason: '$h시');
    }
  });

  test('24시간이 서로 다른 (시, 오전/오후) 조합 24가지로 변환된다', () {
    final seen = <(int, bool)>{
      for (var h = 0; h < 24; h++) (toHour12(h).hour12, toHour12(h).isPm),
    };

    expect(seen, hasLength(24));
  });
}
