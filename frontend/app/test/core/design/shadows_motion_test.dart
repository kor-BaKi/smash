import 'package:app/core/design/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('그림자', () {
    test('elevation1은 번지지 않는 1px 위쪽 선이다', () {
      final shadow = SmashShadows.elevation1.single;

      expect(shadow.blurRadius, 0);
      expect(shadow.offset.dy, -1);
      expect(shadow.color, SmashColors.line);
    });

    test('elevation2는 아래로 8, 번짐 24, 투명도 12%', () {
      final shadow = SmashShadows.elevation2.single;

      expect(shadow.offset.dy, 8);
      expect(shadow.blurRadius, 24);
      expect(shadow.color.a, closeTo(0.12, 0.01));
    });
  });

  group('모션', () {
    test('모든 길이가 150~300ms 안이다', () {
      for (final duration in SmashMotion.durations) {
        expect(duration.inMilliseconds, inInclusiveRange(150, 300));
      }
    });

    test('값: fast 150, base 200, slow 280, exit 200', () {
      expect(SmashMotion.fast.inMilliseconds, 150);
      expect(SmashMotion.base.inMilliseconds, 200);
      expect(SmashMotion.slow.inMilliseconds, 280);
      expect(SmashMotion.exit.inMilliseconds, 200);
    });

    test('사라지는 모션은 가장 오래 걸리는 나타나기(시트)보다 빠르다', () {
      expect(SmashMotion.exit, lessThan(SmashMotion.slow));
    });

    test('easeOut은 끝점이 0과 1이고 시작이 빠르다 (같은 시간에 선형보다 더 진행)', () {
      expect(SmashMotion.easeOut.transform(0), 0);
      expect(SmashMotion.easeOut.transform(1), 1);
      expect(SmashMotion.easeOut.transform(0.2), greaterThan(0.2));
      expect(SmashMotion.easeOut.transform(0.5), greaterThan(0.5));
    });

    test('easeOut은 한 번도 뒤로 가지 않는다 (단조 증가)', () {
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final value = SmashMotion.easeOut.transform(i / 100);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('눌림 비율은 0.97 (0.95~0.98 권장 범위 안)', () {
      expect(SmashMotion.pressedScale, inInclusiveRange(0.95, 0.98));
    });
  });

  test('햅틱 지점은 선택, 가벼운 성공, 확정 세 가지', () {
    expect(SmashHaptic.values.map((h) => h.name), ['selection', 'light', 'medium']);
  });
}
