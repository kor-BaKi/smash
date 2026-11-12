import 'package:flutter/painting.dart';

/// SMASH 색상 토큰 (라이트 전용).
///
/// 브랜드 색은 [brand] 한 곳에서만 정한다. 눌림 색과 연한 배경 색은 거기서 계산하므로
/// [brand]만 바꾸면 전체가 따라 바뀐다. (대비는 test/core/design/colors_test.dart가 검사)
///
/// 상태(성공, 경고, 오류)는 색만으로 전달하지 않는다: 항상 아이콘과 문구를 함께 쓴다.
abstract final class SmashColors {
  // ---- 브랜드 ----
  static const Color brand = Color(0xFF1F4FD8);

  /// 눌림. 브랜드보다 어둡게
  static final Color brandPressed = _shade(brand, lightness: -0.08);

  /// 선택됨 배경, 안내 배경 (진한 쪽)
  static final Color brandTint = _tint(brand, lightness: 0.93);

  /// 선택됨 배경, 안내 배경 (연한 쪽)
  static final Color brandTintSoft = _tint(brand, lightness: 0.967);

  /// 브랜드 색 위의 글자와 아이콘
  static const Color onBrand = Color(0xFFFFFFFF);

  // ---- 중립 ----
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);

  /// 구분선 등 장식용 선. 입력창, 칩 같은 조작 요소의 테두리에는 쓰지 않는다 ([border] 사용)
  static const Color line = Color(0xFFE1E4E9);

  /// 조작 요소의 테두리 (비텍스트 대비 3:1 이상)
  static const Color border = Color(0xFF858D9D);

  static const Color text = Color(0xFF14171C);
  static const Color textSecondary = Color(0xFF5B6270);

  /// 비활성 글자 (비활성 요소는 대비 기준에서 제외되지만 구분은 되어야 한다)
  static const Color textDisabled = Color(0xFF9AA0AB);
  static const Color fillDisabled = Color(0xFFEEF0F3);

  // ---- 상태 ----
  static const Color success = Color(0xFF137A39);
  static const Color successBg = Color(0xFFE8F5EC);
  static const Color warning = Color(0xFFA15C07);
  static const Color warningBg = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFDECEC);

  // ---- 기타 ----
  /// 시트, 다이얼로그 뒤의 어두운 막 (약 48%)
  static const Color scrim = Color(0x7A14171C);

  // 같은 색조에서 밝기만 바꾼다
  static Color _shade(Color base, {required double lightness}) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
        .toColor();
  }

  // 같은 색조의 연한 배경: 채도를 높여 흐려 보이지 않게 하고 밝기를 고정한다
  static Color _tint(Color base, {required double lightness}) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withSaturation(1.0).withLightness(lightness).toColor();
  }
}
