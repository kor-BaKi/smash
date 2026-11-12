import 'package:app/core/design/colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

String hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

void main() {
  group('브랜드 색은 한 곳에서 정해진다', () {
    test('브랜드 기준값', () {
      expect(SmashColors.brand, const Color(0xFF1F4FD8));
    });

    test('눌림 색은 브랜드보다 어둡고 같은 색조다', () {
      final base = HSLColor.fromColor(SmashColors.brand);
      final pressed = HSLColor.fromColor(SmashColors.brandPressed);

      expect(pressed.lightness, lessThan(base.lightness));
      expect((pressed.hue - base.hue).abs(), lessThan(2));
    });

    test('연한 배경 두 가지는 브랜드와 같은 색조이고 서로 다르며 흰색보다 어둡다', () {
      final base = HSLColor.fromColor(SmashColors.brand);
      final tint = HSLColor.fromColor(SmashColors.brandTint);
      final soft = HSLColor.fromColor(SmashColors.brandTintSoft);

      // 거의 흰색에 가까운 색은 8비트 반올림 때문에 색조가 몇 도 흔들리므로 허용 오차를 둔다
      expect((tint.hue - base.hue).abs(), lessThan(4));
      expect((soft.hue - base.hue).abs(), lessThan(4));
      expect(tint.lightness, lessThan(soft.lightness));
      expect(soft.lightness, lessThan(1.0));
    });
  });

  group('글자 대비 (WCAG AA 4.5:1)', () {
    void expectText(String name, Color fg, Color bg) {
      test(name, () {
        expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5),
            reason: '${hex(fg)} on ${hex(bg)} = ${contrastRatio(fg, bg).toStringAsFixed(2)}');
      });
    }

    final backgrounds = <String, Color>{
      '화면 배경': SmashColors.background,
      '표면': SmashColors.surface,
      '브랜드 연한 배경(진)': SmashColors.brandTint,
      '브랜드 연한 배경(연)': SmashColors.brandTintSoft,
    };
    backgrounds.forEach((name, bg) {
      expectText('본문 글자 / $name', SmashColors.text, bg);
      expectText('브랜드 글자 / $name', SmashColors.brand, bg);
    });
    expectText('보조 글자 / 화면 배경', SmashColors.textSecondary, SmashColors.background);
    expectText('보조 글자 / 표면', SmashColors.textSecondary, SmashColors.surface);
    expectText('보조 글자 / 비활성 배경', SmashColors.textSecondary, SmashColors.fillDisabled);

    expectText('브랜드 위 글자', SmashColors.onBrand, SmashColors.brand);
    expectText('눌린 브랜드 위 글자', SmashColors.onBrand, SmashColors.brandPressed);

    expectText('성공 글자 / 표면', SmashColors.success, SmashColors.surface);
    expectText('성공 글자 / 성공 배경', SmashColors.success, SmashColors.successBg);
    expectText('경고 글자 / 표면', SmashColors.warning, SmashColors.surface);
    expectText('경고 글자 / 경고 배경', SmashColors.warning, SmashColors.warningBg);
    expectText('오류 글자 / 표면', SmashColors.danger, SmashColors.surface);
    expectText('오류 글자 / 오류 배경', SmashColors.danger, SmashColors.dangerBg);

    expectText('상태색 채움 위 글자 / 성공', SmashColors.onBrand, SmashColors.success);
    expectText('상태색 채움 위 글자 / 경고', SmashColors.onBrand, SmashColors.warning);
    expectText('상태색 채움 위 글자 / 오류', SmashColors.onBrand, SmashColors.danger);
  });

  group('비텍스트 대비 (조작 요소 3:1)', () {
    test('입력창, 칩 테두리는 표면과 화면 배경 위에서 3:1 이상', () {
      expect(contrastRatio(SmashColors.border, SmashColors.surface), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(SmashColors.border, SmashColors.background), greaterThanOrEqualTo(3.0));
    });

    test('포커스, 선택 표시(브랜드)는 표면과 화면 배경 위에서 3:1 이상', () {
      expect(contrastRatio(SmashColors.brand, SmashColors.surface), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(SmashColors.brand, SmashColors.background), greaterThanOrEqualTo(3.0));
    });

    test('장식용 구분선(line)은 조작 요소 테두리가 아니므로 테두리보다 연하다', () {
      expect(contrastRatio(SmashColors.line, SmashColors.surface),
          lessThan(contrastRatio(SmashColors.border, SmashColors.surface)));
    });
  });

  group('비활성', () {
    test('비활성 글자는 보조 글자보다 흐리지만 배경과는 구분된다', () {
      final disabled = contrastRatio(SmashColors.textDisabled, SmashColors.surface);
      final secondary = contrastRatio(SmashColors.textSecondary, SmashColors.surface);

      expect(disabled, lessThan(secondary));
      expect(disabled, greaterThan(2.0));
    });
  });
}
