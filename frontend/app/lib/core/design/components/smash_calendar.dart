import 'package:flutter/material.dart';

import '../colors.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_icon_button.dart';
import 'smash_label.dart';
import 'smash_pressable.dart';

/// 시작일과 끝일이 모두 있는 기간 (예: 투표가 열려 있는 기간). 양 끝 날짜를 포함한다.
/// 끝이 시작보다 앞서는 기간은 무시한다. 시각은 무시하고 날짜만 본다.
///
/// 이미 계산된 기간만 받는다. 투표의 생성일, 마감일을 기간으로 바꾸는 일(마감일이 없으면 생성일 하루로 보는 규칙 등)과
/// 끝이 정해지지 않은 기간을 보여줄지는 화면이 정한다.
class SmashCalendarPeriod {
  const SmashCalendarPeriod({
    required this.start,
    required this.end,
    required this.title,
    this.colorIndex = 0,
    this.endIsDeadline = true,
  });

  final DateTime start;
  final DateTime end;

  /// 띠 안에 보이고 스크린리더가 읽는 제목 (예: 투표 제목)
  final String title;

  /// [SmashColors.pollBand]에 넘기는 번호. 같은 투표는 항상 같은 번호여야 색이 바뀌지 않는다
  /// (화면이 투표마다 안정적으로 정해서 넘긴다). 팔레트 크기를 넘으면 순환한다
  final int colorIndex;

  /// 끝일이 마감일인가. 마감일이 없어서 생성일 하루로 만든 기간이면 false로 넘긴다
  /// (그날을 스크린리더가 "마감일"이라고 읽지 않고 "진행 중"이라고 읽는다. 띠 모양은 같다)
  final bool endIsDeadline;
}

/// 한 주 안에서 기간 하나가 차지하는 구간 (띠 한 조각)
class SmashPeriodSegment {
  const SmashPeriodSegment({
    required this.periodIndex,
    required this.lane,
    required this.startColumn,
    required this.endColumn,
    required this.startsHere,
    required this.endsHere,
  });

  /// 입력 목록에서의 위치
  final int periodIndex;

  /// 0부터 세는 줄 번호. [SmashCalendarMath.maxPeriodLanes] 이상이면 그려지지 않고 "+N"으로만 알린다
  final int lane;

  /// 이 주 안에서 띠가 걸치는 칸 (0=일요일 ... 6=토요일, 양 끝 포함)
  final int startColumn;
  final int endColumn;

  /// 기간의 시작일이 이 주 안에 있는가 (false이면 앞 주나 앞 달에서 이어진 띠)
  final bool startsHere;

  /// 기간의 끝일(마감일)이 이 주 안에 있는가 (false이면 다음 주나 다음 달로 이어지는 띠)
  final bool endsHere;

  bool covers(int column) => column >= startColumn && column <= endColumn;
}

/// 날짜 계산 도구 (화면 없이 테스트할 수 있게 분리했다)
class SmashCalendarMath {
  const SmashCalendarMath._();

  static const weekdayNames = ['일', '월', '화', '수', '목', '금', '토'];

  /// 한 칸에 겹쳐 그리는 띠의 최대 줄 수. 더 겹치면 "+N"으로 알린다
  static const int maxPeriodLanes = 2;

  /// 시각을 지운 날짜. 하루를 더할 때 Duration이 아니라 날짜 생성자를 써서 시간대, 서머타임에 흔들리지 않는다
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int compareMonth(DateTime a, DateTime b) =>
      (a.year * 12 + a.month) - (b.year * 12 + b.month);

  /// 일요일 시작 달력의 주 목록. 그 달이 아닌 칸은 null이다. 항상 7칸씩이고, 4~6주가 나온다
  static List<List<DateTime?>> weeksOf(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7; // 일요일(7)이 0
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  /// "11월 16일 월요일"
  static String dayLabel(DateTime day) =>
      '${day.month}월 ${day.day}일 ${weekdayNames[day.weekday % 7]}요일';

  /// 가로로 민 결과가 달을 넘기는지: 1이면 다음 달(왼쪽으로 밂), -1이면 이전 달(오른쪽으로 밂), 0이면 넘기지 않는다.
  ///
  /// - [dx], [dy]는 손가락이 움직인 거리, [velocity]는 놓는 순간의 가로 속도(dp/초)이다
  /// - 가로로 [SmashCalendar.swipeDistance] 이상 밀었거나, 거리가 짧아도 [SmashCalendar.swipeFlingVelocity] 이상의
  ///   속도로 [SmashCalendar.swipeMinFlingDistance] 이상 움직였으면 넘긴다
  /// - 가로 이동이 세로 이동보다 크지 않으면 넘기지 않는다 (거의 세로로 민 대각선)
  /// - 방향은 속도가 아니라 움직인 거리(dx)의 부호로 정한다
  static int swipeDirection({
    required double dx,
    required double dy,
    required double velocity,
  }) {
    final far = dx.abs() >= SmashCalendar.swipeDistance;
    final fast =
        velocity.abs() >= SmashCalendar.swipeFlingVelocity &&
        dx.abs() >= SmashCalendar.swipeMinFlingDistance;
    if (!far && !fast) return 0;
    if (dx.abs() <= dy.abs()) return 0;
    if (dx < 0) return 1;
    if (dx > 0) return -1;
    return 0;
  }

  /// 그날 걸쳐 있는 기간들을 스크린리더가 읽는 문구로 만든다 (입력 순서대로).
  /// 예: "투표 '뒤풀이 장소' 진행 중", "투표 '뒤풀이 장소' 마감일". 제목이 비어 있으면 제목 없이 "투표 진행 중"이다.
  /// 끝일이라도 [SmashCalendarPeriod.endIsDeadline]이 false이면 "마감일"이 아니라 "진행 중"이라고 읽는다.
  static List<String> periodPhrasesOn(
    DateTime day,
    List<SmashCalendarPeriod> periods, {
    required String noun,
  }) {
    final target = dateOnly(day);
    final phrases = <String>[];
    for (final period in periods) {
      final start = dateOnly(period.start);
      final end = dateOnly(period.end);
      // 끝이 시작보다 앞선 기간은 이 검사가 모든 날을 걸러내서 따로 처리할 필요가 없다
      if (target.isBefore(start) || target.isAfter(end)) continue;
      final status = isSameDay(target, end) && period.endIsDeadline
          ? '마감일'
          : '진행 중';
      final title = period.title.trim();
      phrases.add(title.isEmpty ? '$noun $status' : "$noun '$title' $status");
    }
    return phrases;
  }

  /// 한 주(7칸, 그 달이 아닌 칸은 null)에 그릴 띠 조각들과 그 줄 번호.
  ///
  /// - 줄은 시작일이 이른 기간부터 차례로 배정한다. 시작일이 같으면 더 길게 이어지는 기간, 그다음 입력 순서가
  ///   위쪽 줄을 받는다 (앞 주에서 이어진 띠가 같은 줄을 유지하기 쉽다)
  /// - 앞 기간이 끝난 줄은 다음 기간이 다시 쓴다 (겹치지 않는 기간은 같은 줄)
  /// - 그 달이 아닌 칸(null)에는 걸치지 않는다. 그래서 달 경계에서 띠는 그 달의 첫날, 마지막 날에서 끊긴다
  static List<SmashPeriodSegment> periodSegmentsOfWeek(
    List<DateTime?> week,
    List<SmashCalendarPeriod> periods,
  ) {
    final found =
        <({int index, DateTime start, DateTime end, int first, int last})>[];
    for (var i = 0; i < periods.length; i++) {
      final start = dateOnly(periods[i].start);
      final end = dateOnly(periods[i].end);
      if (end.isBefore(start)) continue;
      int? first;
      int? last;
      for (var col = 0; col < week.length; col++) {
        final day = week[col];
        if (day == null) continue;
        if (day.isBefore(start) || day.isAfter(end)) continue;
        first ??= col;
        last = col;
      }
      if (first == null || last == null) continue;
      found.add((index: i, start: start, end: end, first: first, last: last));
    }

    // 시작일이 이른 기간이 위 줄을 받는다. 이번 주 안에서 시작 칸이 빠른 순서와 같고, 앞 주에서 이어진 기간(시작일이 더 이름)이
    // 이번 주 첫 칸에서 새로 시작하는 기간보다 위 줄을 유지하게 된다. 시작일이 같으면 더 길게 이어지는 기간, 그다음 입력 순서다
    found.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      final byEnd = b.end.compareTo(a.end);
      if (byEnd != 0) return byEnd;
      return a.index.compareTo(b.index);
    });

    final laneLastColumn = <int>[];
    final segments = <SmashPeriodSegment>[];
    for (final item in found) {
      var lane = laneLastColumn.indexWhere((last) => last < item.first);
      if (lane == -1) {
        lane = laneLastColumn.length;
        laneLastColumn.add(item.last);
      } else {
        laneLastColumn[lane] = item.last;
      }
      segments.add(
        SmashPeriodSegment(
          periodIndex: item.index,
          lane: lane,
          startColumn: item.first,
          endColumn: item.last,
          startsHere: isSameDay(week[item.first]!, item.start),
          endsHere: isSameDay(week[item.last]!, item.end),
        ),
      );
    }
    return segments;
  }

  /// 그려지지 않는 줄(maxPeriodLanes 이상)의 기간이 걸친 칸별 개수. 이 칸에는 "+N"을 붙인다.
  /// 3개 이상 겹치는 날을 모두 포함한다. 숨겨진 기간이 하나라도 걸친 날이면 겹친 수가 2개여도 붙는다
  /// (숨은 기간을 조용히 빠뜨리지 않기 위해서다). 키는 칸 번호(0=일요일 ... 6=토요일)다.
  static Map<int, int> hiddenPeriodCounts(List<SmashPeriodSegment> segments) {
    final counts = <int, int>{};
    for (final segment in segments) {
      if (segment.lane < maxPeriodLanes) continue;
      for (var col = segment.startColumn; col <= segment.endColumn; col++) {
        counts[col] = (counts[col] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// [hiddenPeriodCounts]의 칸 번호들
  static Set<int> hiddenPeriodColumns(List<SmashPeriodSegment> segments) =>
      hiddenPeriodCounts(segments).keys.toSet();
}

/// 한 달 달력.
///
/// - 일요일 시작이고 그 달의 날짜만 보여준다. 칸 높이는 48 이상이고 글자가 커지면 칸이 커진다
/// - 선택, 오늘, 선택할 수 없는 날, 강조 기간(예: 지난 날짜 안내)은 색뿐 아니라 모양, 읽는 말로도 구분한다
/// - **행사**: [hasEventOn]이 true인 날에는 숫자 아래에 색 채운 점 하나가 찍힌다. 일정이 있는지 없는지만 알리고
///   개수와 종류는 구분하지 않는다. 스크린리더는 "일정 있음"이라고 읽는다
/// - **기간 띠**: [periods]의 기간 전체가 두꺼운 띠로 이어지고 띠 안에 제목이 한 줄로 보인다. 아래 [periods] 참고
/// - 어느 날이 선택됐는지와 어느 달을 보여줄지는 화면이 정한다 ([onDaySelected], [onMonthChanged]로 알려 주기만 한다).
///   날짜를 누르면 [onDaySelected]만 부른다. 그날의 상세는 화면이 열어 준다 (이 컴포넌트에는 상세 화면이 없다)
/// - 달 이동은 이전/다음 버튼과 가로로 밀기 둘 다 된다. 가로로 [swipeDistance] 이상 밀거나
///   [swipeFlingVelocity] 이상의 속도로 짧게 튕기면 넘어가고, 범위 끝에서는 막힌다.
///   세로로 밀면 달이 넘어가지 않고 위쪽 스크롤 화면이 스크롤된다
/// - 달이 바뀔 때는 살짝 미끄러지며 바뀌고, 시스템의 "동작 줄이기"가 켜져 있으면 바로 바뀐다
/// - 가로 폭 전체에 놓아 쓴다 (폭 320에서도 칸 너비가 44 이상이 되도록)
class SmashCalendar extends StatefulWidget {
  const SmashCalendar({
    super.key,
    required this.month,
    required this.onDaySelected,
    required this.onMonthChanged,
    this.selectedDay,
    this.hasEventOn,
    this.isDayEnabled,
    this.highlightRanges = const [],
    this.highlightLabel = '',
    this.periods,
    this.periodNoun = '투표',
    this.firstMonth,
    this.lastMonth,
    this.today,
  });

  /// 보여줄 달 (그 달 안의 아무 날짜)
  final DateTime month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// 이전 달, 다음 달 버튼을 누르거나 가로로 밀면 그 달의 1일을 알려 준다
  final ValueChanged<DateTime> onMonthChanged;

  /// true를 돌려주는 날에 행사 점을 찍는다. 날짜 집합(`Set<DateTime>`)이 아니라 함수로 받는 이유:
  /// 집합은 시각이 지워진 날짜로 키를 맞춰야 하는데 그 실수가 조용히 점이 안 찍히는 버그가 되고,
  /// 함수는 화면이 가진 목록으로 바로 계산할 수 있고 보이는 한 달 날짜에만 불린다 ([isDayEnabled]와 같은 방식)
  final bool Function(DateTime day)? hasEventOn;

  /// false를 돌려주는 날은 누를 수 없다 (예: 지난 날짜). null이면 모두 누를 수 있다
  final bool Function(DateTime day)? isDayEnabled;

  /// 배경으로 강조할 기간 (양 끝 날짜 포함). 스크린리더에는 [highlightLabel]로 알린다
  final List<DateTimeRange> highlightRanges;
  final String highlightLabel;

  /// 기간 전체를 날짜 아래의 두꺼운 띠로 보여준다 (예: 투표가 열려 있는 기간).
  ///
  /// - null이면 띠 자리를 만들지 않는다. 빈 목록이면 자리는 잡아 두고 띠만 없다
  ///   (달을 넘길 때 칸 높이가 달라지지 않게, 띠를 쓰는 화면은 항상 목록을 넘긴다)
  /// - 띠 안에 제목이 한 줄로 보이고 넘치면 말줄임이다. 제목은 띠의 각 주 조각이 시작하는 칸
  ///   (기간의 시작일, 이어진 띠는 그 주의 첫 칸)에서 시작한다. 글자 확대는 1.2배까지만 따른다
  /// - 색은 [SmashCalendarPeriod.colorIndex]로 정하고([SmashColors.pollBand]), 색은 추가 단서일 뿐이다.
  ///   모양으로도 구분한다: 마감일 칸은 띠 끝이 둥글고, 시작일 칸은 띠가 왼쪽 가장자리에서 띄워져 평평하게 시작하며,
  ///   앞뒤로 이어지는 칸(주, 달 경계 포함)은 가장자리까지 붙어 이어진다
  /// - 겹치면 줄을 쌓아 최대 [SmashCalendarMath.maxPeriodLanes]줄까지 그리고, 더 겹쳐 가려진 기간이 있는 칸에는
  ///   "+N"(가려진 기간 수)을 붙인다
  /// - 띠는 누를 수 없다 (눌러도 그 칸의 날짜를 누른 것이다). 읽는 말은 칸에 합쳐서 붙고 띠 자체는 읽지 않는다:
  ///   "[periodNoun] '제목' 진행 중", "[periodNoun] '제목' 마감일"
  /// - 시작일과 끝일이 모두 있는 기간만 받는다 (마감 없는 투표를 어떻게 보여줄지는 화면이 정한다)
  final List<SmashCalendarPeriod>? periods;

  /// 읽는 말에 쓰는 기간의 이름
  final String periodNoun;

  /// 이 달보다 앞, 뒤로는 이동할 수 없다 (null이면 제한 없음)
  final DateTime? firstMonth;
  final DateTime? lastMonth;

  /// 오늘. 테스트에서 고정할 때만 넘긴다
  final DateTime? today;

  static const double minCellHeight = 48;

  /// 가로로 이만큼(dp) 이상 밀면 달이 넘어간다
  static const double swipeDistance = 64;

  /// 이 속도(dp/초) 이상으로 튕기면 [swipeMinFlingDistance]만 움직여도 넘어간다
  static const double swipeFlingVelocity = 800;
  static const double swipeMinFlingDistance = 24;

  /// 행사 점 색. 흰 배경(5.2:1)과 강조 기간 배경(4.7:1) 위에서 3:1 이상이다.
  /// 점은 숫자 원 바깥(아래)에 찍히므로 선택한 날의 채운 원, 오늘의 테두리 원과 겹치지 않는다
  static const Color eventDotColor = SmashColors.warning;

  /// 일정이 있는 날을 스크린리더가 읽는 말
  static const String eventLabel = '일정 있음';

  /// 띠 한 줄의 높이. 두 줄이 쌓이면 줄 사이 [bandGap]이 들어간다
  static const double bandHeight = 17;
  static const double bandGap = 2;

  /// 띠 안 제목의 글자 크기. 글자 확대는 [bandMaxTextScale]배까지만 따른다 (띠 높이가 고정이라서)
  static const double bandFontSize = 11;
  static const double bandMaxTextScale = 1.2;

  @override
  State<SmashCalendar> createState() => _SmashCalendarState();
}

class _SmashCalendarState extends State<SmashCalendar> {
  int _direction = 1; // 1: 앞(다음 달) 방향으로 넘어옴, -1: 뒤

  // 손가락이 처음 닿은 곳에서 지금까지 움직인 거리. 가로 드래그 인식기와 경쟁하지 않는 Listener로 잰다
  // (인식기는 가로 이동만 알려 줘서, 거의 세로인 대각선 드래그를 걸러낼 수 없기 때문이다)
  // 드래그 인식기는 처음 닿은 손가락을 따르므로 여기서도 처음 닿은 손가락의 움직임만 센다
  // (두 번째 손가락이나 손바닥이 닿아도 스와이프가 조용히 실패하지 않게)
  final Set<int> _activePointers = {};
  int? _pointer;
  double _moveDx = 0;
  double _moveDy = 0;

  @override
  void didUpdateWidget(SmashCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final change = SmashCalendarMath.compareMonth(
      widget.month,
      oldWidget.month,
    );
    if (change != 0) _direction = change > 0 ? 1 : -1;
  }

  bool get _canGoPrevious =>
      widget.firstMonth == null ||
      SmashCalendarMath.compareMonth(widget.month, widget.firstMonth!) > 0;
  bool get _canGoNext =>
      widget.lastMonth == null ||
      SmashCalendarMath.compareMonth(widget.month, widget.lastMonth!) < 0;

  void _goPrevious() => widget.onMonthChanged(
    DateTime(widget.month.year, widget.month.month - 1, 1),
  );
  void _goNext() => widget.onMonthChanged(
    DateTime(widget.month.year, widget.month.month + 1, 1),
  );

  void _onDragEnd(DragEndDetails details) {
    final direction = SmashCalendarMath.swipeDirection(
      dx: _moveDx,
      dy: _moveDy,
      velocity: details.primaryVelocity ?? 0,
    );
    if (direction > 0 && _canGoNext) _goNext();
    if (direction < 0 && _canGoPrevious) _goPrevious();
  }

  bool _inHighlight(DateTime day) {
    for (final range in widget.highlightRanges) {
      final start = SmashCalendarMath.dateOnly(range.start);
      final end = SmashCalendarMath.dateOnly(range.end);
      if (!day.isBefore(start) && !day.isAfter(end)) return true;
    }
    return false;
  }

  Widget _grid(DateTime now) {
    final weeks = SmashCalendarMath.weeksOf(widget.month);
    final periods = widget.periods;

    return Column(
      key: ValueKey(widget.month.year * 12 + widget.month.month),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final week in weeks) _weekRow(week, now, periods)],
    );
  }

  Widget _weekRow(
    List<DateTime?> week,
    DateTime now,
    List<SmashCalendarPeriod>? periods,
  ) {
    final segments = periods == null
        ? const <SmashPeriodSegment>[]
        : SmashCalendarMath.periodSegmentsOfWeek(week, periods);
    final hiddenCounts = SmashCalendarMath.hiddenPeriodCounts(segments);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < week.length; col++)
          Expanded(
            child: week[col] == null
                ? const SizedBox(height: SmashCalendar.minCellHeight)
                : _DayCell(
                    day: week[col]!,
                    isToday: SmashCalendarMath.isSameDay(week[col]!, now),
                    isSelected:
                        widget.selectedDay != null &&
                        SmashCalendarMath.isSameDay(
                          week[col]!,
                          widget.selectedDay!,
                        ),
                    enabled: widget.isDayEnabled?.call(week[col]!) ?? true,
                    highlighted: _inHighlight(week[col]!),
                    highlightLabel: widget.highlightLabel,
                    hasEvent: widget.hasEventOn?.call(week[col]!) ?? false,
                    reservePeriodLanes: periods != null,
                    hiddenPeriodCount: hiddenCounts[col] ?? 0,
                    periodPhrases: periods == null
                        ? const []
                        : SmashCalendarMath.periodPhrasesOn(
                            week[col]!,
                            periods,
                            noun: widget.periodNoun,
                          ),
                    onTap: () => widget.onDaySelected(week[col]!),
                  ),
          ),
      ],
    );

    final visible = [
      for (final s in segments)
        if (s.lane < SmashCalendarMath.maxPeriodLanes) s,
    ];
    if (periods == null || visible.isEmpty) return row;

    // 띠는 제목이 여러 칸에 걸쳐 한 줄로 보이도록 한 주 단위로 칸 위에 얹는다 (누를 수 없고 읽히지도 않는다)
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / week.length;
        return Stack(
          children: [
            row,
            for (final segment in visible)
              _band(segment, periods[segment.periodIndex], week, cellWidth),
          ],
        );
      },
    );
  }

  Widget _band(
    SmashPeriodSegment segment,
    SmashCalendarPeriod period,
    List<DateTime?> week,
    double cellWidth,
  ) {
    final left =
        segment.startColumn * cellWidth +
        (segment.startsHere ? _DayCell.capInset : 0);
    final right =
        (segment.endColumn + 1) * cellWidth -
        (segment.endsHere ? _DayCell.capInset : 0);
    final bottomOfLane =
        _DayCell.cellVerticalPadding +
        (SmashCalendarMath.maxPeriodLanes - 1 - segment.lane) *
            (SmashCalendar.bandHeight + SmashCalendar.bandGap);
    final firstDay = week[segment.startColumn]!;
    final title = period.title.trim();

    return Positioned(
      left: left,
      width: right - left,
      bottom: bottomOfLane,
      height: SmashCalendar.bandHeight,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: DecoratedBox(
            key: ValueKey(
              'period-band|${_DayCell.keyOf(firstDay)}|lane${segment.lane}',
            ),
            decoration: BoxDecoration(
              color: SmashColors.pollBand(period.colorIndex),
              // 마감일 칸은 띠 끝이 둥글다
              borderRadius: segment.endsHere
                  ? const BorderRadius.horizontal(
                      right: Radius.circular(SmashCalendar.bandHeight / 2),
                    )
                  : null,
            ),
            child: title.isEmpty
                ? null
                : Padding(
                    padding: EdgeInsets.only(
                      left: segment.startsHere ? 6 : 4,
                      right: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: SmashCalendar.bandMaxTextScale,
                        child: SmashLabel(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: SmashText.caption.copyWith(
                            fontSize: SmashCalendar.bandFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: SmashColors.onBrand,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = SmashCalendarMath.dateOnly(widget.today ?? DateTime.now());
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SmashIconButton(
              icon: Icons.chevron_left,
              semanticLabel: '이전 달',
              onPressed: _canGoPrevious ? _goPrevious : null,
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: SmashLabel(
                  '${widget.month.year}년 ${widget.month.month}월',
                  textAlign: TextAlign.center,
                  style: SmashText.heading,
                ),
              ),
            ),
            SmashIconButton(
              icon: Icons.chevron_right,
              semanticLabel: '다음 달',
              onPressed: _canGoNext ? _goNext : null,
            ),
          ],
        ),
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (_activePointers.isEmpty) {
              _pointer = event.pointer;
              _moveDx = 0;
              _moveDy = 0;
            }
            _activePointers.add(event.pointer);
          },
          onPointerUp: (event) => _activePointers.remove(event.pointer),
          onPointerCancel: (event) => _activePointers.remove(event.pointer),
          onPointerMove: (event) {
            if (event.pointer != _pointer) return;
            _moveDx += event.delta.dx;
            _moveDy += event.delta.dy;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final name in SmashCalendarMath.weekdayNames)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: SmashSpacing.sm,
                            ),
                            child: SmashLabel(
                              name,
                              textAlign: TextAlign.center,
                              style: SmashText.caption.copyWith(
                                color: SmashColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ClipRect(
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : SmashMotion.base,
                    switchInCurve: SmashMotion.easeOut,
                    switchOutCurve: SmashMotion.easeOut,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) {
                      final isIncoming =
                          child.key ==
                          ValueKey(widget.month.year * 12 + widget.month.month);
                      // 들어오는 달은 진행 방향 쪽에서 오고, 나가는 달은 반대쪽으로 빠진다
                      final from = Offset(
                        _direction * (isIncoming ? 0.08 : -0.08),
                        0,
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: from,
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _grid(now),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.enabled,
    required this.highlighted,
    required this.highlightLabel,
    required this.hasEvent,
    required this.reservePeriodLanes,
    required this.hiddenPeriodCount,
    required this.periodPhrases,
    required this.onTap,
  });

  /// 시작일 칸에서 띠가 왼쪽 가장자리에서 띄워지는 거리, 마감일 칸에서 오른쪽에서 띄워지는 거리
  static const double capInset = 3;

  /// 칸 안쪽 위아래 여백. 띠를 칸 아래에서부터 얹을 때 같은 값을 쓴다
  static const double cellVerticalPadding = SmashSpacing.xs;

  static const double _dotSize = 6;
  static const double _dotRowHeight = 10;

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool enabled;
  final bool highlighted;
  final String highlightLabel;
  final bool hasEvent;
  final bool reservePeriodLanes;

  /// 줄 수를 넘어 가려진 기간 수 (0이면 "+N"이 없다)
  final int hiddenPeriodCount;
  final List<String> periodPhrases;
  final VoidCallback onTap;

  static String keyOf(DateTime day) => '${day.year}-${day.month}-${day.day}';

  String get _semanticLabel {
    final parts = <String>[
      SmashCalendarMath.dayLabel(day),
      if (isToday) '오늘',
      if (hasEvent) SmashCalendar.eventLabel,
      ...periodPhrases,
      if (highlighted && highlightLabel.isNotEmpty) highlightLabel,
      if (!enabled) '선택할 수 없음',
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final numberColor = isSelected
        ? SmashColors.onBrand
        : (enabled ? SmashColors.text : SmashColors.textDisabled);

    return Semantics(
      selected: isSelected,
      child: SmashPressable(
        onPressed: enabled ? onTap : null,
        semanticLabel: _semanticLabel,
        borderRadius: SmashRadius.circular(SmashRadius.md),
        minSize: const Size(0, SmashCalendar.minCellHeight),
        builder: (context, states) {
          return ColoredBox(
            color: highlighted ? SmashColors.brandTintSoft : Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: SmashCalendar.minCellHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: cellVerticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 숫자는 접히지 않는다: 글자가 커져서 칸 폭을 넘으면 칸 폭에 맞춰 줄인다 (예: 폭 320 + 글자 2.0배)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? SmashColors.brand
                              : Colors.transparent,
                          border: isToday && !isSelected
                              ? Border.all(color: SmashColors.brand, width: 2)
                              : (states.contains(WidgetState.focused)
                                    ? Border.all(
                                        color: SmashColors.text,
                                        width: 2,
                                      )
                                    : null),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: SmashLabel(
                            '${day.day}',
                            style:
                                (isSelected || isToday
                                        ? SmashText.bodyStrong
                                        : SmashText.body)
                                    .copyWith(color: numberColor, height: 1.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 점 줄: 행사 점과 가려진 기간 수 "+N"을 가운데 한 줄로 묶는다. 숫자 원과 띠 사이라서 가려지지 않고,
                    // 한 줄(Row)이라 글꼴이나 글자 크기와 상관없이 서로 겹치지 않는다. 폭이 모자라면 줄여서 넣는다
                    ExcludeSemantics(
                      child: SizedBox(
                        height: _dotRowHeight,
                        width: double.infinity,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasEvent)
                                  DecoratedBox(
                                    key: ValueKey('event-dot|${keyOf(day)}'),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SmashCalendar.eventDotColor,
                                    ),
                                    child: const SizedBox.square(
                                      dimension: _dotSize,
                                    ),
                                  ),
                                if (hasEvent && hiddenPeriodCount > 0)
                                  const SizedBox(width: 4),
                                if (hiddenPeriodCount > 0)
                                  MediaQuery.withClampedTextScaling(
                                    maxScaleFactor:
                                        SmashCalendar.bandMaxTextScale,
                                    child: SmashLabel(
                                      '+$hiddenPeriodCount',
                                      key: ValueKey(
                                        'period-more|${keyOf(day)}',
                                      ),
                                      style: SmashText.caption.copyWith(
                                        fontSize: 10,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                        color: SmashColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (reservePeriodLanes) ...[
                      const SizedBox(height: 2),
                      // 띠가 앉는 자리 (띠는 주 단위로 칸 위에 얹힌다)
                      const SizedBox(
                        height:
                            SmashCalendar.bandHeight *
                                SmashCalendarMath.maxPeriodLanes +
                            SmashCalendar.bandGap,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
