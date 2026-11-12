import 'package:flutter/painting.dart';

import 'colors.dart';

/// SMASH 글자 스타일 토큰. 글꼴은 Pretendard, 굵기는 400과 600 두 가지만 쓴다.
///
/// - 본문은 16sp 이상, 가장 작은 글자(caption)도 13sp 이상이다.
/// - 행간은 한글 가독성을 위해 본문 1.5배 이상으로 둔다.
/// - 시스템 글자 크기 확대를 막지 않는다. 줄 높이와 레이아웃이 확대에 맞춰 늘어나야 한다.
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
    color: SmashColors.text,
  );

  /// 강조 본문, 버튼 글자
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: SmashColors.text,
  );

  /// 보조 설명, 배지
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: SmashColors.textSecondary,
  );

  /// 금액, 인원, 시각처럼 숫자를 비교하는 곳에서 자릿수 폭을 같게 맞춘다
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: tabularFigures);

  /// 토큰에 정의된 모든 스타일 (테스트와 테마 구성용)
  static const List<TextStyle> all = [display, title, heading, body, bodyStrong, caption];
}
