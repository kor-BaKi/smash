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

  // ---- 투표 띠 팔레트 ----
  /// 달력에서 투표 기간을 구분하는 띠 색. 투표마다 [pollBand]로 번호를 넘겨 쓴다.
  ///
  /// 띠 안에 흰 글자(투표 제목)를 쓰므로 모두 어둡다: 흰 글자 대비 4.5:1, 흰 배경과 연한 브랜드 배경([brandTintSoft])
  /// 위에서도 3:1 이상이다. 색각 이상(적색맹, 녹색맹, 청황색맹) 시뮬레이션 후에도 서로 CIEDE2000 색차 15 이상으로
  /// 구분되고, 브랜드 색(선택한 날의 원), 행사 점 색([warning])과도 정상 시각에서 20 이상 떨어져 있다.
  /// 색은 추가 단서일 뿐이다 (띠의 모양과 읽는 말이 정보를 전한다).
  /// 값을 바꿀 때는 test/core/design/poll_band_palette_test.dart의 기준을 다시 통과해야 한다.
  /// 번호가 이어지는 색끼리(0-1, 1-2 ... 5-0)가 가장 멀도록 순서를 정했다.
  static const List<Color> pollBandColors = [
    Color(0xFF581030), // 와인
    Color(0xFFD03070), // 분홍
    Color(0xFF005000), // 초록
    Color(0xFFB030D0), // 보라
    Color(0xFF501870), // 남보라
    Color(0xFF508010), // 올리브
  ];

  /// [index]번째 투표 띠 색. 팔레트 크기를 넘으면 처음부터 다시 쓴다 (음수도 안전하다)
  static Color pollBand(int index) => pollBandColors[index % pollBandColors.length];

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
