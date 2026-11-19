import 'package:flutter/painting.dart';

import 'colors.dart';

/// SMASH 글자 스타일 토큰. 글꼴은 Pretendard, 굵기는 400과 600 두 가지만 쓴다.
///
/// - 본문은 16sp 이상, 가장 작은 글자(caption)도 13sp 이상이다.
/// - 행간은 한글 가독성을 위해 본문 1.5배 이상으로 둔다.
/// - 시스템 글자 크기 확대를 막지 않는다. 줄 높이와 레이아웃이 확대에 맞춰 늘어나야 한다.
/// - **자간(`letterSpacing`)은 모든 토큰에 명시한다.** 명시하지 않으면 Flutter가 테마의 기본 글자 스타일
///   (Material 3: `bodyMedium` 0.25, `bodyLarge` 0.5, `labelLarge` 0.1 등)의 자간을 섞어서, 같은 토큰이 놓인 자리마다
///   다른 자간으로 그려지고 `TextPainter`로 잰 폭과도 어긋난다. 본문, 강조 본문, 캡션은 0이고, 제목 토큰은 글자 크기에
///   비례해 조인다 (heading −0.2, title −0.3, display −0.4).
/// - 새 글자 스타일을 만들 때는 토큰에서 파생하거나(`SmashText.body.copyWith(fontSize: …)`는 자간을 물려받는다) 자간을
///   직접 명시한다. 자간 없이 `TextStyle(...)`을 새로 만들면 주변 글자 스타일(위젯마다 다르다)의 자간이 섞일 수 있다.
///   그려진 모든 글자의 자간이 토큰 값인지는 `letter_spacing_guard_test`가 카탈로그 전체와 오버레이에서 검사한다.
abstract final class SmashText {
  static const String family = 'Pretendard';

  /// 오늘 활동 카드의 시간대처럼 가장 크게 보여주는 글자
  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: SmashColors.text,
  );

  /// 화면 제목
  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: SmashColors.text,
  );

  /// 섹션 제목
  static const TextStyle heading = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: SmashColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: SmashColors.text,
  );

  /// 강조 본문, 버튼 글자
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: SmashColors.text,
  );

  /// 보조 설명, 배지
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: SmashColors.textSecondary,
  );

  /// 금액, 인원, 시각처럼 숫자를 비교하는 곳에서 자릿수 폭을 같게 맞춘다
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: tabularFigures);

  /// 토큰에 정의된 모든 스타일 (테스트와 테마 구성용)
  static const List<TextStyle> all = [display, title, heading, body, bodyStrong, caption];
}
