import 'package:app/core/design/colors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_vision.dart';
import '../../support/contrast.dart';

void main() {
  const colors = SmashColors.pollBandColors;

  test('팔레트는 6색이고 값이 모두 다르다', () {
    expect(colors, hasLength(6));
    expect(colors.toSet(), hasLength(6));
  });

  test('팔레트 값 (바꿀 때 이 테스트의 기준을 모두 다시 통과해야 한다)', () {
    expect(colors.map((c) => c.toARGB32().toRadixString(16)).toList(), ['ff581030', 'ffd03070', 'ff005000', 'ffb030d0', 'ff501870', 'ff508010']);
  });

  group('대비', () {
    for (var i = 0; i < colors.length; i++) {
      test('$i번 색: 흰 글자 4.5:1 이상, 흰 배경과 연한 배경과 화면 배경 위에서 3:1 이상', () {
        expect(contrastRatio(SmashColors.onBrand, colors[i]), greaterThanOrEqualTo(4.5), reason: '띠 안 흰 글자');
        expect(contrastRatio(colors[i], SmashColors.surface), greaterThanOrEqualTo(3.0), reason: '흰 배경');
        expect(contrastRatio(colors[i], SmashColors.brandTintSoft), greaterThanOrEqualTo(3.0), reason: '강조 기간 배경');
        expect(contrastRatio(colors[i], SmashColors.background), greaterThanOrEqualTo(3.0), reason: '화면 배경');
      });
    }
  });

  group('색각 이상에서도 서로 구분된다 (CIEDE2000 색차)', () {
    for (final vision in ColorVision.values) {
      test('$vision: 어느 두 색이든 색차 15 이상', () {
        var closest = double.infinity;
        for (var i = 0; i < colors.length; i++) {
          for (var j = i + 1; j < colors.length; j++) {
            final d = visionDelta(colors[i], colors[j], vision);
            if (d < closest) closest = d;
            expect(d, greaterThanOrEqualTo(15.0), reason: '$i번과 $j번 ($vision)');
          }
        }
        expect(closest, greaterThanOrEqualTo(15.0));
      });
    }

    test('번호가 이어지는 색끼리(0-1, 1-2 ... 5-0)는 모든 시각 유형에서 18 이상 떨어져 있다', () {
      for (var i = 0; i < colors.length; i++) {
        final d = worstDelta(colors[i], colors[(i + 1) % colors.length]);
        expect(d, greaterThanOrEqualTo(18.0), reason: '$i번과 ${(i + 1) % colors.length}번');
      }
    });
  });

  test('선택한 날의 브랜드 색과 행사 점 색(warning)과는 정상 시각에서 색차 20 이상이다', () {
    for (var i = 0; i < colors.length; i++) {
      expect(visionDelta(colors[i], SmashColors.brand, ColorVision.normal), greaterThanOrEqualTo(20.0), reason: '$i번 / 브랜드');
      expect(visionDelta(colors[i], SmashColors.warning, ColorVision.normal), greaterThanOrEqualTo(20.0), reason: '$i번 / 행사 점');
    }
  });

  group('pollBand: 번호가 팔레트 크기를 넘으면 순환한다', () {
    test('0~5는 각 색, 6부터는 처음부터 다시', () {
      for (var i = 0; i < colors.length; i++) {
        expect(SmashColors.pollBand(i), colors[i]);
      }
      expect(SmashColors.pollBand(6), colors[0]);
      expect(SmashColors.pollBand(7), colors[1]);
      expect(SmashColors.pollBand(11), colors[5]);
      expect(SmashColors.pollBand(12), colors[0]);
      expect(SmashColors.pollBand(600), colors[0]);
      expect(SmashColors.pollBand(1000001), colors[1000001 % 6]);
    });

    test('음수도 안전하다', () {
      expect(SmashColors.pollBand(-1), colors[5]);
      expect(SmashColors.pollBand(-6), colors[0]);
      expect(SmashColors.pollBand(-7), colors[5]);
    });
  });
}
