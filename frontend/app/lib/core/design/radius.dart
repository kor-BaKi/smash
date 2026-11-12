import 'package:flutter/painting.dart';

/// 라운드 토큰. 중첩 단계마다 다른 값을 쓴다 (바깥이 크고 안쪽이 작다).
abstract final class SmashRadius {
  /// 칩, 입력창 안쪽 요소
  static const double sm = 8;

  /// 버튼, 입력창
  static const double md = 12;

  /// 카드
  static const double lg = 16;

  /// 시트 위쪽 모서리
  static const double xl = 24;

  /// 배지, 알약형
  static const double full = 999;

  static const List<double> all = [sm, md, lg, xl];

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);

  /// 시트처럼 위쪽만 둥글게
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
}
