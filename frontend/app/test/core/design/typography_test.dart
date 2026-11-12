import 'package:app/core/design/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 글자 스타일은 Pretendard를 쓴다', () {
    for (final style in SmashText.all) {
      expect(style.fontFamily, 'Pretendard');
    }
  });

  test('굵기는 400과 600 두 가지뿐이다 (번들 글꼴 정리 후에도 유지되는 조합)', () {
    final weights = SmashText.all.map((s) => s.fontWeight).toSet();

    expect(weights, {FontWeight.w400, FontWeight.w600});
  });

  test('크기 단계: 28, 22, 18, 16, 16, 13', () {
    expect(SmashText.all.map((s) => s.fontSize), [28, 22, 18, 16, 16, 13]);
  });

  test('가장 작은 글자도 13sp 이상, 본문은 16sp 이상', () {
    for (final style in SmashText.all) {
      expect(style.fontSize, greaterThanOrEqualTo(13));
    }
    expect(SmashText.body.fontSize, greaterThanOrEqualTo(16));
    expect(SmashText.bodyStrong.fontSize, greaterThanOrEqualTo(16));
  });

  test('행간: 본문은 1.5배, 나머지도 1.25배 이상', () {
    expect(SmashText.body.height, closeTo(1.5, 0.001));
    expect(SmashText.bodyStrong.height, closeTo(1.5, 0.001));
    for (final style in SmashText.all) {
      expect(style.height, greaterThanOrEqualTo(1.25));
    }
  });

  test('줄 높이(px)가 8의 배수에 가깝게 맞는다: 36, 30, 26, 24, 24, 18', () {
    final lineHeights = SmashText.all.map((s) => (s.fontSize! * s.height!).round());

    expect(lineHeights, [36, 30, 26, 24, 24, 18]);
  });

  test('기본 글자색은 본문색, 보조 설명(caption)만 보조색이다', () {
    expect(SmashText.body.color, SmashColors.text);
    expect(SmashText.caption.color, SmashColors.textSecondary);
  });

  test('숫자용 스타일은 자릿수 폭을 같게 맞추고 원본은 바꾸지 않는다', () {
    final numeric = SmashText.tabular(SmashText.body);

    expect(numeric.fontFeatures, SmashText.tabularFigures);
    expect(SmashText.body.fontFeatures, isNull);
    expect(numeric.fontSize, SmashText.body.fontSize);
  });
}
