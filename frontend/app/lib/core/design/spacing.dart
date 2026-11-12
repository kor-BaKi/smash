/// 간격 토큰 (8pt 격자, 가장 작은 단계만 4).
abstract final class SmashSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// 화면 좌우 여백
  static const double screenMargin = md;

  /// 터치 영역 최소 크기 (dp). 모든 조작 요소가 이 크기 이상이어야 한다
  static const double minTouchTarget = 48;

  static const List<double> all = [xs, sm, md, lg, xl, xxl];
}
