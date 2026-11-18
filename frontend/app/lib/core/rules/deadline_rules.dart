import 'time_slots.dart';

/// 마감 시각 프리셋 칩의 종류
enum DeadlinePresetKind {
  tonight,
  tomorrowAfternoon,
  threeDaysLater,
  weekLater,
}

/// 마감 시각 프리셋 칩 하나: 칩에 쓰는 글자와 눌렀을 때의 시각
class DeadlinePreset {
  const DeadlinePreset(this.kind, this.label, this.value);

  final DeadlinePresetKind kind;
  final String label;
  final DateTime value;
}

/// 모집 기간(시작, 종료)의 오류 종류
enum PeriodError {
  /// 종료가 시작보다 이후가 아니다 (서버 INVALID_PERIOD와 같은 기준)
  endNotAfterStart,

  /// 종료가 지금보다 이후가 아니다 (서버는 검사하지 않는 클라이언트 전용 규칙)
  endNotAfterNow,
}

/// 시각을 규칙에 맞게 바꾼 결과. [adjusted]가 true이면 사용자가 고른 값에서 바뀐 것이다 (안내 문구를 보여줄 때 쓴다)
class DeadlineAdjustment {
  const DeadlineAdjustment(this.value, {required this.adjusted});

  final DateTime value;
  final bool adjusted;
}

/// 제출 직전 재검증 결과. 유효하지 않으면 [suggestion]이 지금 시점에서 고를 수 있는 가장 이른 시각이다
class DeadlineRevalidation {
  const DeadlineRevalidation.valid() : valid = true, suggestion = null;
  const DeadlineRevalidation.invalid(DateTime this.suggestion) : valid = false;

  final bool valid;
  final DateTime? suggestion;
}

/// 마감 시각 규칙 (투표 마감, 모집 종료). 순수 계산이며 시각은 [now]로 받아 테스트에서 고정한다.
///
/// - 고를 수 있는 가장 이른 시각([minSelectable])은 현재 시각의 **다음 분**이다 (초, 밀리초는 0).
///   서버는 `closedAt > 지금`만 검사하므로 항상 그 규칙을 만족한다
/// - 처음 보여주는 값([initialValue])은 [minSelectable]을 **5분 단위로 올린** 값이다. 5분 단위는 초기값에만 쓰고
///   분은 1분 단위로 고른다
/// - [notBefore]를 주면 그 시각(분 단위로 올림) 이후만 고를 수 있다 (예: 모집 종료는 시작 + 1분 이후)
/// - 서버 시계는 한국 시간(JVM Asia/Seoul)이므로 기기도 한국 시간이라는 전제다
class DeadlineRules {
  DeadlineRules(this.now, {DateTime? notBefore})
    : minSelectable = _minOf(now, notBefore);

  final DateTime now;

  /// 고를 수 있는 가장 이른 시각 (이 시각 포함)
  final DateTime minSelectable;

  static const invalidCloseTimeMessage = '마감 시각은 지금보다 이후로 설정해 주세요.';
  static const endNotAfterStartMessage = '모집 종료 시각은 시작 시각보다 이후로 설정해 주세요.';
  static const endNotAfterNowMessage = '모집 종료 시각은 지금보다 이후로 설정해 주세요.';

  /// 칩 하나를 보이려면 [minSelectable]에서 이만큼의 여유가 있어야 한다 (오늘 밤 칩이 곧 지나 버리지 않게)
  static const tonightLead = Duration(minutes: 30);
  static const tonightHour = 22;
  static const afternoonHour = 18;

  static DateTime _nextMinute(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute + 1);

  static DateTime _ceilToMinute(DateTime t) {
    final floored = DateTime(t.year, t.month, t.day, t.hour, t.minute);
    return floored.isBefore(t)
        ? DateTime(t.year, t.month, t.day, t.hour, t.minute + 1)
        : floored;
  }

  static DateTime _minOf(DateTime now, DateTime? notBefore) {
    final next = _nextMinute(now);
    if (notBefore == null) return next;
    final floor = _ceilToMinute(notBefore);
    return floor.isAfter(next) ? floor : next;
  }

  /// 달력에서 고를 수 있는 첫 날짜 ([minSelectable]이 속한 날)
  DateTime get firstSelectableDate =>
      DateTime(minSelectable.year, minSelectable.month, minSelectable.day);

  /// 처음 보여주는 값: [minSelectable]을 5분 단위로 올린 값
  DateTime get initialValue {
    final add = (5 - minSelectable.minute % 5) % 5;
    return DateTime(
      minSelectable.year,
      minSelectable.month,
      minSelectable.day,
      minSelectable.hour,
      minSelectable.minute + add,
    );
  }

  bool isSelectable(DateTime candidate) => !candidate.isBefore(minSelectable);

  /// [candidate]가 [minSelectable]보다 이르면 [minSelectable]로 올린다
  DeadlineAdjustment adjust(DateTime candidate) =>
      candidate.isBefore(minSelectable)
      ? DeadlineAdjustment(minSelectable, adjusted: true)
      : DeadlineAdjustment(candidate, adjusted: false);

  static DateTime compose(DateTime date, int hour12, bool isPm, int minute) =>
      TimeSlots.compose(date, hour12, isPm, minute);

  // ---- 시간 목록 활성 ----
  bool isDayEnabled(DateTime date) =>
      TimeSlots.isDayEnabled(date, isSelectable);
  bool isAmEnabled(DateTime date) =>
      TimeSlots.isHalfEnabled(date, false, isSelectable);
  bool isPmEnabled(DateTime date) =>
      TimeSlots.isHalfEnabled(date, true, isSelectable);
  bool isHourEnabled(DateTime date, int hour12, bool isPm) =>
      TimeSlots.isHourEnabled(date, hour12, isPm, isSelectable);
  bool isMinuteEnabled(DateTime date, int hour12, bool isPm, int minute) =>
      TimeSlots.isMinuteEnabled(date, hour12, isPm, minute, isSelectable);
  int? firstEnabledHour(DateTime date, bool isPm) =>
      TimeSlots.firstEnabledHour(date, isPm, isSelectable);
  int? firstEnabledMinute(DateTime date, int hour12, bool isPm) =>
      TimeSlots.firstEnabledMinute(date, hour12, isPm, isSelectable);

  // ---- 프리셋 ----
  /// 지금 보여줄 프리셋 칩들 (오늘 밤, 내일 오후, 3일 뒤, 1주일 뒤 순서).
  /// 오늘 밤은 오늘 22:00이고 [minSelectable] + 30분이 22:00을 넘으면 숨긴다. 내일 오후는 내일 18:00, 3일 뒤는 3일 뒤 18:00, 1주일 뒤는 7일 뒤 18:00이다.
  /// 보이는 칩은 항상 분이 00이고 [isSelectable]을 만족한다. 날짜는 [now] 기준이다
  List<DeadlinePreset> presets() {
    final today = DateTime(now.year, now.month, now.day);
    final tonight = DateTime(today.year, today.month, today.day, tonightHour);
    final tomorrow = DateTime(
      today.year,
      today.month,
      today.day + 1,
      afternoonHour,
    );
    final threeDays = DateTime(
      today.year,
      today.month,
      today.day + 3,
      afternoonHour,
    );
    final weekLater = DateTime(
      today.year,
      today.month,
      today.day + 7,
      afternoonHour,
    );
    final all = [
      DeadlinePreset(DeadlinePresetKind.tonight, '오늘 밤', tonight),
      DeadlinePreset(DeadlinePresetKind.tomorrowAfternoon, '내일 오후', tomorrow),
      DeadlinePreset(DeadlinePresetKind.threeDaysLater, '3일 뒤', threeDays),
      DeadlinePreset(DeadlinePresetKind.weekLater, '1주일 뒤', weekLater),
    ];
    return [
      for (final preset in all)
        if (isSelectable(preset.value) &&
            (preset.kind != DeadlinePresetKind.tonight ||
                !preset.value.isBefore(minSelectable.add(tonightLead))))
          preset,
    ];
  }

  /// [value]와 시각이 정확히 같은 프리셋 (칩 강조용). 1분이라도 다르면 null이라 직접 바꾸면 칩 선택이 풀린다
  DeadlinePreset? presetFor(DateTime? value) {
    if (value == null) return null;
    for (final preset in presets()) {
      if (preset.value.isAtSameMomentAs(value)) return preset;
    }
    return null;
  }

  // ---- 모집 기간 ----
  /// 시작과 종료가 모두 있으면 종료가 시작보다 이후여야 한다. 하나라도 비어 있으면 검증하지 않는다 (서버와 같음)
  static PeriodError? validateOrder(DateTime? start, DateTime? end) =>
      start != null && end != null && !end.isAfter(start)
      ? PeriodError.endNotAfterStart
      : null;

  /// [validateOrder]에 더해 종료가 [minSelectable]보다 이르면 오류다 (클라이언트 규칙, 서버보다 엄격).
  /// 시작 규칙이 먼저다. 시작이 과거여도 괜찮다 (바로 시작)
  PeriodError? validatePeriod(DateTime? start, DateTime? end) {
    final order = validateOrder(start, end);
    if (order != null) return order;
    if (end != null && end.isBefore(minSelectable)) {
      return PeriodError.endNotAfterNow;
    }
    return null;
  }

  static String periodErrorMessage(PeriodError error) => switch (error) {
    PeriodError.endNotAfterStart => endNotAfterStartMessage,
    PeriodError.endNotAfterNow => endNotAfterNowMessage,
  };

  // ---- 제출 직전 ----
  /// 제출하는 순간([nowAtSubmit]) 선택한 마감 시각이 아직 유효한가. 서버의 `closedAt > 지금`과 같은 기준이다.
  /// 마감 없음(수동 종료, null)은 항상 유효하다. 유효하지 않으면 지금 고를 수 있는 가장 이른 시각을 제안한다
  static DeadlineRevalidation revalidate(
    DateTime? selection,
    DateTime nowAtSubmit,
  ) {
    if (selection == null || selection.isAfter(nowAtSubmit)) {
      return const DeadlineRevalidation.valid();
    }
    return DeadlineRevalidation.invalid(
      DeadlineRules(nowAtSubmit).minSelectable,
    );
  }
}
