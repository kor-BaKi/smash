import '../format/hour12.dart';

/// 후보 시각을 고를 수 있는지 판정하는 함수
typedef SelectablePredicate = bool Function(DateTime candidate);

/// 12시간제 시간 목록(오전/오후, 시 1~12, 분 0~59)의 활성 판정. 순수 계산이다.
///
/// 규칙은 [SelectablePredicate] 하나로 받는다 (예: `DeadlineRules.isSelectable`). 목록의 모든 줄은
/// "그 시각을 고를 수 있는가"의 답이므로, 위젯과 단위 테스트가 같은 계산을 쓴다.
/// 시 목록은 화면에 1, 2, ... 12 순서로 놓인다 ([hourList]). "첫 활성 값"은 이 목록 순서에서 맨 위에 있는 값이다.
abstract final class TimeSlots {
  static const hourList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  /// [date]의 날짜에 12시간제 시각을 합쳐 시각을 만든다 (초, 밀리초는 0).
  /// 오전 12시는 0시, 오후 12시는 12시, 오후 1시는 13시다.
  static DateTime compose(DateTime date, int hour12, bool isPm, int minute) =>
      DateTime(
        date.year,
        date.month,
        date.day,
        toHour24(hour12, isPm: isPm),
        minute,
      );

  static bool isMinuteEnabled(
    DateTime date,
    int hour12,
    bool isPm,
    int minute,
    SelectablePredicate selectable,
  ) => selectable(compose(date, hour12, isPm, minute));

  /// 그 시에 고를 수 있는 분이 하나라도 있는가
  static bool isHourEnabled(
    DateTime date,
    int hour12,
    bool isPm,
    SelectablePredicate selectable,
  ) => firstEnabledMinute(date, hour12, isPm, selectable) != null;

  /// 그 오전/오후에 고를 수 있는 시각이 하나라도 있는가
  static bool isHalfEnabled(
    DateTime date,
    bool isPm,
    SelectablePredicate selectable,
  ) => firstEnabledHour(date, isPm, selectable) != null;

  /// 그 날짜에 고를 수 있는 시각이 하나라도 있는가 (달력에서 날짜를 막을지 정할 때 쓴다)
  static bool isDayEnabled(DateTime date, SelectablePredicate selectable) =>
      isHalfEnabled(date, false, selectable) ||
      isHalfEnabled(date, true, selectable);

  /// 시 목록 순서(1~12)에서 처음으로 고를 수 있는 시. 없으면 null
  static int? firstEnabledHour(
    DateTime date,
    bool isPm,
    SelectablePredicate selectable,
  ) {
    for (final hour in hourList) {
      if (firstEnabledMinute(date, hour, isPm, selectable) != null) return hour;
    }
    return null;
  }

  /// 그 시에서 처음으로 고를 수 있는 분(0~59). 없으면 null
  static int? firstEnabledMinute(
    DateTime date,
    int hour12,
    bool isPm,
    SelectablePredicate selectable,
  ) {
    for (var minute = 0; minute < 60; minute++) {
      if (isMinuteEnabled(date, hour12, isPm, minute, selectable)) {
        return minute;
      }
    }
    return null;
  }

  /// 사용자가 시, 분, 오전/오후 중 하나를 바꿔서 요청한 시각을 실제로 고를 수 있는 시각으로 맞춘다.
  /// 1. 요청한 시각을 고를 수 있으면 그대로
  /// 2. 아니면 같은 시에서 처음으로 고를 수 있는 분으로 (예: 지금이 14:52일 때 오후 2시를 누르면 14:53)
  /// 3. 그 시에 고를 분이 없으면 같은 오전/오후에서 목록 순서로 처음 고를 수 있는 시의 첫 분
  /// 4. 그 오전/오후에 고를 시각이 없으면 null (오전/오후 토글이 비활성이어야 하는 경우)
  static DateTime? resolve(
    DateTime date,
    int hour12,
    bool isPm,
    int minute,
    SelectablePredicate selectable,
  ) {
    final requested = compose(date, hour12, isPm, minute);
    if (selectable(requested)) return requested;
    final sameHourMinute = firstEnabledMinute(date, hour12, isPm, selectable);
    if (sameHourMinute != null) {
      return compose(date, hour12, isPm, sameHourMinute);
    }
    final hour = firstEnabledHour(date, isPm, selectable);
    if (hour == null) return null;
    return compose(
      date,
      hour,
      isPm,
      firstEnabledMinute(date, hour, isPm, selectable)!,
    );
  }
}
