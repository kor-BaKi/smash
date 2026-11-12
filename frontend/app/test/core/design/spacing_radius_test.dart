import 'package:app/core/design/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('간격 (8pt 격자)', () {
    test('값: 4, 8, 16, 24, 32, 48', () {
      expect(SmashSpacing.all, [4, 8, 16, 24, 32, 48]);
    });

    test('모두 4의 배수이고, 가장 작은 단계를 뺀 나머지는 8의 배수다', () {
      for (final value in SmashSpacing.all) {
        expect(value % 4, 0, reason: '$value');
      }
      for (final value in SmashSpacing.all.skip(1)) {
        expect(value % 8, 0, reason: '$value');
      }
    });

    test('오름차순이다', () {
      final sorted = [...SmashSpacing.all]..sort();

      expect(SmashSpacing.all, sorted);
    });

    test('화면 좌우 여백은 16, 터치 영역 최소는 48', () {
      expect(SmashSpacing.screenMargin, 16);
      expect(SmashSpacing.minTouchTarget, 48);
    });
  });

  group('라운드', () {
    test('값: 8, 12, 16, 24 (오름차순)', () {
      expect(SmashRadius.all, [8, 12, 16, 24]);
    });

    test('시트는 위쪽 모서리만 둥글다', () {
      expect(SmashRadius.sheetTop.topLeft.x, SmashRadius.xl);
      expect(SmashRadius.sheetTop.topRight.x, SmashRadius.xl);
      expect(SmashRadius.sheetTop.bottomLeft.x, 0);
      expect(SmashRadius.sheetTop.bottomRight.x, 0);
    });

    test('알약형은 충분히 큰 값이다', () {
      expect(SmashRadius.full, greaterThanOrEqualTo(999));
    });
  });
}
