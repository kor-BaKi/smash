import 'package:flutter/animation.dart';

/// 모션 토큰. 모든 길이는 150~300ms 안이다.
///
/// 하루에도 여러 번 쓰는 행동(참여 응답 등)에는 장식 모션을 쓰지 않는다.
/// 모션 줄이기 설정 대응과 실제 적용은 컴포넌트 단계에서 한다.
abstract final class SmashMotion {
  /// 눌림, 칩과 스위치 전환, 목록 열기
  static const Duration fast = Duration(milliseconds: 150);

  /// 상태 변경, 스켈레톤 → 내용 전환, 스낵바 등장
  static const Duration base = Duration(milliseconds: 200);

  /// 시트 올라오기
  static const Duration slow = Duration(milliseconds: 280);

  /// 사라질 때는 나타날 때보다 빠르게
  static const Duration exit = Duration(milliseconds: 200);

  /// 나타나는 모션의 기본 곡선 (시작이 빠르고 끝이 부드럽다)
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// 화면 안에서 위치가 바뀔 때
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// 누르는 동안 줄어드는 비율
  static const double pressedScale = 0.97;

  static const List<Duration> durations = [fast, base, slow, exit];
}
