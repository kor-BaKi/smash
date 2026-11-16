import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'color_vision.dart';

// 팔레트 검증 도구가 믿을 만한지 확인한다. 기준값은 Sharma, Wu, Dalal (2005)의 CIEDE2000 검증 데이터다.
void main() {
  group('deltaE2000', () {
    test('Sharma 기준 데이터와 일치한다', () {
      expect(deltaE2000([50, 2.6772, -79.7751], [50, 0, -82.7485]), closeTo(2.0425, 0.0001));
      expect(deltaE2000([50, 3.1571, -77.2803], [50, 0, -82.7485]), closeTo(2.8615, 0.0001));
      expect(deltaE2000([50, 2.5, 0], [73, 25, -18]), closeTo(27.1492, 0.0001));
      expect(deltaE2000([50, 2.5, 0], [50, 0, -2.5]), closeTo(4.3065, 0.0001));
    });

    test('같은 색은 0이고 순서를 바꿔도 같다', () {
      expect(deltaE2000([40, 20, -30], [40, 20, -30]), 0);
      expect(deltaE2000([30, 10, 5], [60, -20, 40]), closeTo(deltaE2000([60, -20, 40], [30, 10, 5]), 1e-9));
    });
  });

  group('toLab', () {
    test('흰색과 검정', () {
      final white = toLab([255, 255, 255]);
      expect(white[0], closeTo(100, 0.01));
      expect(white[1].abs(), lessThan(0.01));
      expect(toLab([0, 0, 0])[0], closeTo(0, 0.01));
    });
  });

  group('색각 이상 시뮬레이션', () {
    test('정상 시각은 그대로, 회색은 어떤 유형에서도 거의 그대로다', () {
      const gray = Color(0xFF808080);
      for (final v in ColorVision.values) {
        for (final c in simulate(gray, v)) {
          expect(c, closeTo(128, 1.5), reason: '$v');
        }
      }
    });

    test('적색맹, 녹색맹에서는 빨강과 초록이 가까워진다 (정상 시각보다 훨씬)', () {
      const red = Color(0xFFC00000);
      const green = Color(0xFF008000);
      final normal = visionDelta(red, green, ColorVision.normal);
      expect(visionDelta(red, green, ColorVision.protanopia), lessThan(normal * 0.6));
      expect(visionDelta(red, green, ColorVision.deuteranopia), lessThan(normal * 0.6));
    });

    test('청황색맹에서는 파랑과 초록이 가까워진다', () {
      const blue = Color(0xFF0000C0);
      const teal = Color(0xFF008080);
      expect(visionDelta(blue, teal, ColorVision.tritanopia), lessThan(visionDelta(blue, teal, ColorVision.normal) * 0.6));
    });

    test('worstDelta는 네 유형 중 가장 작은 값이다', () {
      const a = Color(0xFFC00000);
      const b = Color(0xFF008000);
      expect(worstDelta(a, b), lessThanOrEqualTo(visionDelta(a, b, ColorVision.normal)));
      expect(worstDelta(a, b), lessThanOrEqualTo(visionDelta(a, b, ColorVision.deuteranopia)));
    });
  });
}
