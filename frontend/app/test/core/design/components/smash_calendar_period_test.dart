import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/finders.dart';

SmashCalendarPeriod p(
  int sm,
  int sd,
  int em,
  int ed, {
  int sy = 2026,
  int ey = 2026,
  String title = '뒤풀이',
  int color = 0,
  bool deadline = true,
}) =>
    SmashCalendarPeriod(
      start: DateTime(sy, sm, sd),
      end: DateTime(ey, em, ed),
      title: title,
      colorIndex: color,
      endIsDeadline: deadline,
    );

/// 2026년 11월의 주들: 0주 1~7일, 1주 8~14일, 2주 15~21일, 3주 22~28일, 4주 29~30일(+빈칸 5개)
List<List<DateTime?>> nov() => SmashCalendarMath.weeksOf(DateTime(2026, 11));

/// 2026년 8월: 0주는 앞 빈칸 6개 + 1일(토), 5주는 30, 31일(+빈칸 5개)
List<List<DateTime?>> aug() => SmashCalendarMath.weeksOf(DateTime(2026, 8));

List<SmashPeriodSegment> seg(List<DateTime?> week, List<SmashCalendarPeriod> periods) =>
    SmashCalendarMath.periodSegmentsOfWeek(week, periods);

void main() {
  group('periodPhrasesOn: 읽는 말', () {
    List<String> phrases(int day, List<SmashCalendarPeriod> periods, {int month = 11, String noun = '투표'}) =>
        SmashCalendarMath.periodPhrasesOn(DateTime(2026, month, day), periods, noun: noun);

    test('기간이 없거나 그날이 기간 밖이면 비어 있다', () {
      expect(phrases(12, const []), isEmpty);
      expect(phrases(9, [p(11, 10, 11, 14)]), isEmpty);
      expect(phrases(15, [p(11, 10, 11, 14)]), isEmpty);
    });

    test("진행 중인 날은 \"투표 '제목' 진행 중\", 끝일은 \"투표 '제목' 마감일\"", () {
      final periods = [p(11, 10, 11, 14, title: '뒤풀이 장소')];
      expect(phrases(10, periods), ["투표 '뒤풀이 장소' 진행 중"]);
      expect(phrases(12, periods), ["투표 '뒤풀이 장소' 진행 중"]);
      expect(phrases(14, periods), ["투표 '뒤풀이 장소' 마감일"]);
    });

    test('하루짜리 기간은 마감일로 읽는다', () {
      expect(phrases(12, [p(11, 12, 11, 12, title: '오늘 투표')]), ["투표 '오늘 투표' 마감일"]);
    });

    test('끝일이 마감일이 아니면(endIsDeadline false: 마감 없는 투표의 생성일 하루) "진행 중"으로 읽는다', () {
      expect(phrases(12, [p(11, 12, 11, 12, title: '마감 없는 투표', deadline: false)]), ["투표 '마감 없는 투표' 진행 중"]);
      expect(phrases(14, [p(11, 10, 11, 14, title: '가', deadline: false)]), ["투표 '가' 진행 중"]);
    });

    test('겹치면 제목을 입력 순서대로 모두 읽는다', () {
      final periods = [p(11, 10, 11, 14, title: '가'), p(11, 12, 11, 16, title: '나'), p(11, 14, 11, 14, title: '다')];
      expect(phrases(12, periods), ["투표 '가' 진행 중", "투표 '나' 진행 중"]);
      expect(phrases(14, periods), ["투표 '가' 마감일", "투표 '나' 진행 중", "투표 '다' 마감일"]);
      expect(phrases(16, periods), ["투표 '나' 마감일"]);
    });

    test('줄 수를 넘어 화면에 안 보이는 투표도 읽는 말에는 모두 들어간다 (정보 손실이 없다)', () {
      final periods = [for (var i = 0; i < 5; i++) p(11, 10, 11, 14, title: '투표${'가나다라마'[i]}')];
      expect(phrases(12, periods), hasLength(5));
    });

    test('제목이 비어 있거나 공백뿐이면 제목 없이 읽는다', () {
      expect(phrases(12, [p(11, 10, 11, 14, title: '')]), ['투표 진행 중']);
      expect(phrases(14, [p(11, 10, 11, 14, title: '   ')]), ['투표 마감일']);
    });

    test('제목 앞뒤 공백은 지운다', () {
      expect(phrases(12, [p(11, 10, 11, 14, title: '  가나  ')]), ["투표 '가나' 진행 중"]);
    });

    test('noun을 바꿀 수 있다', () {
      expect(phrases(12, [p(11, 10, 11, 14, title: '신입')], noun: '모집'), ["모집 '신입' 진행 중"]);
    });

    test('시각은 무시하고 날짜만 본다, 끝이 앞선 기간은 무시한다', () {
      final withTime = [SmashCalendarPeriod(start: DateTime(2026, 11, 10, 23, 59), end: DateTime(2026, 11, 14, 0, 1), title: '가')];
      expect(phrases(10, withTime), ["투표 '가' 진행 중"]);
      expect(phrases(14, withTime), ["투표 '가' 마감일"]);
      expect(phrases(12, [p(11, 14, 11, 10)]), isEmpty);
    });

    test('달을 넘는 기간: 10월 28일~11월 3일', () {
      final periods = [p(10, 28, 11, 3, title: '가')];
      expect(phrases(1, periods), ["투표 '가' 진행 중"]);
      expect(phrases(3, periods), ["투표 '가' 마감일"]);
      expect(phrases(4, periods), isEmpty);
    });
  });

  group('periodSegmentsOfWeek: 한 주 안의 구간', () {
    test('한 주 안에 있는 기간: 시작과 끝이 모두 이 주', () {
      final s = seg(nov()[2], [p(11, 17, 11, 19)]); // 화~목
      expect(s, hasLength(1));
      expect([s[0].startColumn, s[0].endColumn, s[0].startsHere, s[0].endsHere, s[0].lane], [2, 4, true, true, 0]);
    });

    test('주 경계: 11월 20일(금)~24일(화)은 앞 주에서 토요일까지, 다음 주에서 화요일까지 이어진다', () {
      final periods = [p(11, 20, 11, 24)];
      final first = seg(nov()[2], periods).single;
      expect([first.startColumn, first.endColumn, first.startsHere, first.endsHere], [5, 6, true, false]);
      final second = seg(nov()[3], periods).single;
      expect([second.startColumn, second.endColumn, second.startsHere, second.endsHere], [0, 2, false, true]);
    });

    test('달 경계(앞): 10월 28일~11월 3일은 11월 첫 주에서 1일부터 이어진 띠다', () {
      final s = seg(nov()[0], [p(10, 28, 11, 3)]).single;
      expect([s.startColumn, s.endColumn, s.startsHere, s.endsHere], [0, 2, false, true]);
    });

    test('달 경계(뒤): 11월 28일~12월 4일은 마지막 날(30일)에서 끊기고 마감일은 이 달에 없다', () {
      final periods = [p(11, 28, 12, 4)];
      final week3 = seg(nov()[3], periods).single;
      expect([week3.startColumn, week3.endColumn, week3.startsHere, week3.endsHere], [6, 6, true, false]);
      final week4 = seg(nov()[4], periods).single;
      expect([week4.startColumn, week4.endColumn, week4.startsHere, week4.endsHere], [0, 1, false, false]);
    });

    test('빈 칸(그 달이 아닌 칸)에는 걸치지 않는다: 11월 마지막 주(29, 30일 + 빈칸 5개)', () {
      final s = seg(nov()[4], [p(11, 30, 12, 2)]).single;
      expect([s.startColumn, s.endColumn, s.startsHere, s.endsHere], [1, 1, true, false]);
    });

    test('앞 빈칸: 8월 첫 주(토요일 1일만 있음)에서 7월 30일~8월 3일은 토요일 한 칸에서 시작해 이어진다', () {
      final periods = [p(7, 30, 8, 3)];
      final first = seg(aug()[0], periods).single;
      expect([first.startColumn, first.endColumn, first.startsHere, first.endsHere], [6, 6, false, false]);
      final second = seg(aug()[1], periods).single;
      expect([second.startColumn, second.endColumn, second.startsHere, second.endsHere], [0, 1, false, true]);
    });

    test('그 주와 겹치지 않는 기간, 그 달과 전혀 겹치지 않는 기간은 구간이 없다', () {
      expect(seg(nov()[1], [p(11, 17, 11, 19)]), isEmpty);
      for (final week in nov()) {
        expect(seg(week, [p(10, 1, 10, 31), p(12, 1, 12, 31)]), isEmpty);
      }
    });

    test('시각은 무시하고, 끝이 앞선 기간은 무시한다', () {
      final withTime = [SmashCalendarPeriod(start: DateTime(2026, 11, 17, 23, 59), end: DateTime(2026, 11, 19, 0, 1), title: '가')];
      final s = seg(nov()[2], withTime).single;
      expect([s.startColumn, s.endColumn, s.startsHere, s.endsHere], [2, 4, true, true]);
      expect(seg(nov()[2], [p(11, 19, 11, 17)]), isEmpty);
    });

    test('구간은 입력 목록의 위치(periodIndex)를 가진다', () {
      final s = seg(nov()[2], [p(11, 1, 11, 2), p(11, 17, 11, 19), p(11, 18, 11, 18)]);
      expect(s.map((e) => e.periodIndex).toList()..sort(), [1, 2]);
    });
  });

  group('periodSegmentsOfWeek: 줄 배정', () {
    int laneOf(List<SmashPeriodSegment> s, int index) => s.firstWhere((e) => e.periodIndex == index).lane;

    test('겹치지 않는 기간은 같은 줄(0)', () {
      final s = seg(nov()[2], [p(11, 15, 11, 16), p(11, 18, 11, 19)]);
      expect(s.map((e) => e.lane), [0, 0]);
    });

    test('겹치면 줄이 쌓인다 (먼저 시작한 쪽이 위)', () {
      final s = seg(nov()[2], [p(11, 17, 11, 21), p(11, 15, 11, 19)]);
      expect(laneOf(s, 1), 0); // 15일에 시작
      expect(laneOf(s, 0), 1); // 17일에 시작
    });

    test('세 개가 겹치면 세 번째는 2번 줄이고 그려지지 않는 줄이다', () {
      final s = seg(nov()[2], [p(11, 15, 11, 21), p(11, 15, 11, 20), p(11, 15, 11, 19)]);
      expect([laneOf(s, 0), laneOf(s, 1), laneOf(s, 2)], [0, 1, 2]);
      expect(SmashCalendarMath.maxPeriodLanes, 2);
      expect(SmashCalendarMath.hiddenPeriodColumns(s), {0, 1, 2, 3, 4}); // 2번 줄 기간이 걸친 칸(15~19일)
    });

    test('끝난 줄은 다음 기간이 다시 쓴다', () {
      final s = seg(nov()[2], [p(11, 15, 11, 21), p(11, 15, 11, 16), p(11, 18, 11, 19)]);
      expect([laneOf(s, 0), laneOf(s, 1), laneOf(s, 2)], [0, 1, 1]);
      expect(SmashCalendarMath.hiddenPeriodColumns(s), isEmpty);
    });

    test('시작일이 같으면 더 길게 이어지는 기간이 위, 모두 같으면 입력 순서', () {
      final longer = seg(nov()[2], [p(11, 15, 11, 16), p(11, 15, 11, 19)]);
      expect([laneOf(longer, 1), laneOf(longer, 0)], [0, 1]);
      final same = seg(nov()[2], [p(11, 15, 11, 16), p(11, 15, 11, 16)]);
      expect([laneOf(same, 0), laneOf(same, 1)], [0, 1]);
    });

    test('앞 주에서 이어진 기간이 같은 줄을 유지한다 (새로 시작한 기간보다 위)', () {
      final s = seg(nov()[2], [p(11, 15, 11, 16), p(11, 12, 11, 20)]);
      expect(laneOf(s, 1), 0);
      expect(laneOf(s, 0), 1);
    });

    test('앞 주에서 이어진 짧은 기간이, 이번 주 첫 칸에서 새로 시작하는 더 긴 기간보다 위 줄을 유지한다', () {
      final s = seg(nov()[2], [p(11, 12, 11, 16), p(11, 15, 11, 21)]);
      expect(laneOf(s, 0), 0, reason: '앞 주에서 이어진 A가 위');
      expect(laneOf(s, 1), 1);
    });

    test('줄 번호는 칸별이 아니라 구간별이라 한 구간은 끝까지 같은 줄이다', () {
      final s = seg(nov()[2], [p(11, 15, 11, 21), p(11, 17, 11, 18)]);
      expect([s[0].lane, s[0].startColumn, s[0].endColumn], [0, 0, 6]);
      expect([s[1].lane, s[1].startColumn, s[1].endColumn], [1, 2, 3]);
    });
  });

  group('hiddenPeriodCounts: 가려진 기간 수 ("+N")', () {
    test('2개 이하로만 겹치면 없다', () {
      final s = seg(nov()[2], [p(11, 15, 11, 21), p(11, 17, 11, 19)]);
      expect(SmashCalendarMath.hiddenPeriodCounts(s), isEmpty);
      expect(SmashCalendarMath.hiddenPeriodColumns(s), isEmpty);
    });

    test('3개가 겹치면 겹친 칸마다 1, 4개가 겹치면 2', () {
      final three = seg(nov()[2], [p(11, 15, 11, 21), p(11, 15, 11, 20), p(11, 17, 11, 19)]);
      expect(SmashCalendarMath.hiddenPeriodCounts(three), {2: 1, 3: 1, 4: 1});
      final four = seg(nov()[2], [p(11, 15, 11, 21), p(11, 15, 11, 21), p(11, 16, 11, 18), p(11, 17, 11, 17)]);
      expect(SmashCalendarMath.hiddenPeriodCounts(four), {1: 1, 2: 2, 3: 1});
    });

    test('2개 겹침에서도 가려진 기간이 남는 경우를 알린다 (숨은 기간을 조용히 빠뜨리지 않는다)', () {
      // A 15~21, B 15~16, C 16~21: 16일에 셋이 겹쳐 C가 2번 줄이 되고, 17일부터는 A, C 둘만 겹치지만 C는 계속 가려져 있다
      final s = seg(nov()[2], [p(11, 15, 11, 21), p(11, 15, 11, 16), p(11, 16, 11, 21)]);
      expect(s.firstWhere((e) => e.periodIndex == 2).lane, 2);
      expect(SmashCalendarMath.hiddenPeriodCounts(s), {1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1});
      expect(SmashCalendarMath.hiddenPeriodColumns(s), {1, 2, 3, 4, 5, 6});
    });

    test('가려진 기간이 없으면 빈 맵', () {
      expect(SmashCalendarMath.hiddenPeriodCounts(const []), isEmpty);
    });
  });

  group('SmashCalendar 띠 화면', () {
    Widget host(Widget child, {double width = 360, double textScale = 1.0}) => MaterialApp(
          theme: SmashTheme.light(),
          builder: (context, a) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: a!,
          ),
          home: Scaffold(
            body: Align(alignment: Alignment.topCenter, child: SizedBox(width: width, child: SingleChildScrollView(child: child))),
          ),
        );

    SmashCalendar calendar({
      DateTime? month,
      List<SmashCalendarPeriod>? periods = const [],
      bool Function(DateTime)? hasEventOn,
      ValueChanged<DateTime>? onDay,
      List<DateTimeRange> ranges = const [],
      DateTime? today,
      String noun = '투표',
    }) =>
        SmashCalendar(
          month: month ?? DateTime(2026, 11),
          today: today ?? DateTime(2026, 11, 16),
          onDaySelected: onDay ?? (_) {},
          onMonthChanged: (_) {},
          periods: periods,
          periodNoun: noun,
          hasEventOn: hasEventOn,
          highlightRanges: ranges,
          highlightLabel: '강조 기간',
        );

    /// 띠 조각의 키: 조각이 시작하는 칸의 날짜(기간의 시작일, 이어진 띠는 그 주의 첫 칸)와 줄 번호
    Finder band(int day, int lane, {int month = 11}) => find.byKey(ValueKey('period-band|2026-$month-$day|lane$lane'));
    Finder more(int day) => find.byKey(ValueKey('period-more|2026-11-$day'));
    Finder cell(String day) => find.widgetWithText(SmashPressable, day);
    Finder anyBand() => find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('period-band'));
    BoxDecoration decorationOf(WidgetTester tester, Finder f) => tester.widget<DecoratedBox>(f).decoration as BoxDecoration;

    testWidgets('띠는 기간 전체에 하나로 이어진다: 시작일 칸의 안쪽부터 마감일 칸의 안쪽까지', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18)])));

      final rect = tester.getRect(band(16, 0));
      expect(rect.left - tester.getRect(cell('16')).left, closeTo(3, 0.01), reason: '시작일은 왼쪽이 3 띄워진다');
      expect(tester.getRect(cell('18')).right - rect.right, closeTo(3, 0.01), reason: '마감일은 오른쪽이 3 띄워진다');
      expect(rect.height, SmashCalendar.bandHeight);
      expect(rect.width, greaterThan(tester.getSize(cell('17')).width * 2), reason: '세 칸에 걸친 하나의 띠');
      expect(anyBand(), findsOneWidget, reason: '조각이 하나');
      expect(band(17, 0), findsNothing);
    });

    testWidgets('모양: 마감일 쪽 끝만 둥글고 시작 쪽은 평평하다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18)])));

      final deco = decorationOf(tester, band(16, 0));
      final radius = deco.borderRadius as BorderRadius;
      expect(radius.topRight, const Radius.circular(SmashCalendar.bandHeight / 2));
      expect(radius.bottomRight, const Radius.circular(SmashCalendar.bandHeight / 2));
      expect(radius.topLeft, Radius.zero);
      expect(radius.bottomLeft, Radius.zero);
    });

    testWidgets('주 경계: 앞 주 조각은 토요일 칸 오른쪽 끝까지 붙고(둥글지 않음), 다음 주 조각은 일요일 칸 왼쪽 끝부터 이어진다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(11, 20, 11, 24)])));

      final first = tester.getRect(band(20, 0));
      expect(first.right, closeTo(tester.getRect(cell('21')).right, 0.01));
      expect(first.left - tester.getRect(cell('20')).left, closeTo(3, 0.01));
      expect(decorationOf(tester, band(20, 0)).borderRadius, isNull, reason: '마감일이 아니라 다음 주로 이어지므로 둥글지 않다');

      final second = tester.getRect(band(22, 0));
      expect(second.left, closeTo(tester.getRect(cell('22')).left, 0.01));
      expect(tester.getRect(cell('24')).right - second.right, closeTo(3, 0.01));
      expect(decorationOf(tester, band(22, 0)).borderRadius, isNotNull);
      expect(second.top, greaterThan(first.top), reason: '다음 줄(주)에 있다');
    });

    testWidgets('달 경계: 10월 28일~11월 3일은 11월 1일 칸 왼쪽 끝부터, 11월 28일~12월 4일은 30일 칸 오른쪽 끝까지 이어진다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(10, 28, 11, 3), p(11, 28, 12, 4, ey: 2026)])));

      final early = tester.getRect(band(1, 0));
      expect(early.left, closeTo(tester.getRect(cell('1')).left, 0.01), reason: '앞 달에서 이어짐');
      expect(tester.getRect(cell('3')).right - early.right, closeTo(3, 0.01), reason: '11월 3일이 마감일');

      final lateWeek3 = tester.getRect(band(28, 0));
      expect(lateWeek3.left - tester.getRect(cell('28')).left, closeTo(3, 0.01), reason: '11월 28일이 시작일');
      expect(lateWeek3.right, closeTo(tester.getRect(cell('28')).right, 0.01));
      final lateWeek4 = tester.getRect(band(29, 0));
      expect(lateWeek4.left, closeTo(tester.getRect(cell('29')).left, 0.01));
      expect(lateWeek4.right, closeTo(tester.getRect(cell('30')).right, 0.01), reason: '다음 달로 이어짐: 30일 오른쪽 끝까지');
      expect(decorationOf(tester, band(29, 0)).borderRadius, isNull);
    });

    testWidgets('겹치는 기간은 위아래로 쌓이고(줄 사이 2), 줄 높이는 17이다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 20, title: '가'), p(11, 16, 11, 20, title: '나', color: 1)])));

      final lane0 = tester.getRect(band(16, 0));
      final lane1 = tester.getRect(band(16, 1));
      expect(lane0.height, 17);
      expect(lane1.height, 17);
      expect(lane1.top - lane0.bottom, closeTo(SmashCalendar.bandGap, 0.01));
      expect(tester.getRect(cell('16')).bottom - lane1.bottom, closeTo(4, 0.01), reason: '칸 아래 여백 4');
    });

    testWidgets('띠 자리(두 줄)는 칸 높이에 포함된다: 띠가 없으면 자리만 있고, 있어도 높이가 같다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: null)));
      final without = tester.getSize(cell('16')).height;
      expect(anyBand(), findsNothing);

      await tester.pumpWidget(host(calendar(periods: const [])));
      final withEmpty = tester.getSize(cell('16')).height;
      expect(withEmpty - without, closeTo(38, 0.5), reason: '띠 두 줄(17+2+17)과 위 간격 2');

      await tester.pumpWidget(host(calendar(periods: [p(11, 1, 11, 30, title: '긴 투표'), p(11, 1, 11, 30, title: '둘째', color: 1)])));
      expect(tester.getSize(cell('16')).height, withEmpty, reason: '띠가 2줄이어도 높이는 같다');
    });

    testWidgets('달을 넘겨도 칸 높이가 같다 (띠를 쓰는 화면이 항상 목록을 넘기는 전제)', (tester) async {
      await tester.pumpWidget(host(calendar(month: DateTime(2026, 11), periods: [p(11, 16, 11, 18)])));
      final november = tester.getSize(cell('16')).height;
      await tester.pumpWidget(host(calendar(month: DateTime(2026, 12), periods: const [])));
      await tester.pumpAndSettle();

      expect(tester.getSize(cell('16')).height, november);
    });

    group('띠 안의 제목', () {
      Finder titleIn(Finder band) => find.descendant(of: band, matching: anyText());

      testWidgets('제목은 띠 안에 한 줄로 보이고 넘치면 말줄임이다 (글자 11, 흰색)', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '뒤풀이 장소')])));

        final text = tester.widget<Text>(titleIn(band(16, 0)));
        expect(text.data, '뒤풀이 장소');
        expect(text.maxLines, 1);
        expect(text.softWrap, isFalse);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.style!.fontSize, 11);
        expect(text.style!.color, SmashColors.onBrand);
      });

      testWidgets('제목은 시작일 칸에서 시작한다 (시작일은 띠 왼쪽 안쪽 6, 이어진 띠는 첫 칸에서 4)', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [p(11, 20, 11, 24, title: '송년회')])));

        // 시작일(20일) 조각: 띠 왼쪽 + 6
        expect(tester.getTopLeft(titleIn(band(20, 0))).dx - tester.getRect(band(20, 0)).left, closeTo(6, 0.01));
        expect(tester.getTopLeft(titleIn(band(20, 0))).dx, greaterThanOrEqualTo(tester.getRect(cell('20')).left));
        // 이어진 조각(22일 첫 칸): 띠 왼쪽 + 4
        expect(tester.getTopLeft(titleIn(band(22, 0))).dx - tester.getRect(band(22, 0)).left, closeTo(4, 0.01));
      });

      testWidgets('제목은 조각마다 한 번만 나온다 (두 주에 걸치면 두 번)', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [p(11, 20, 11, 24, title: '송년회')])));

        expect(find.text('송년회'), findsNWidgets(2));
        expect(find.descendant(of: band(20, 0), matching: find.text('송년회')), findsOneWidget);
        expect(find.descendant(of: band(22, 0), matching: find.text('송년회')), findsOneWidget);
      });

      testWidgets('제목이 비면 띠에 글자가 없다', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '')])));

        expect(band(16, 0), findsOneWidget);
        expect(titleIn(band(16, 0)), findsNothing);
      });

      testWidgets('제목이 길면 띠 폭 안에서 말줄임되고 칸 밖으로 나가지 않는다', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 16, title: '이 제목은 하루짜리 좁은 띠에 들어가기에는 훨씬 깁니다')]), width: 320));

        expect(tester.takeException(), isNull);
        final bandRect = tester.getRect(band(16, 0));
        final textRect = tester.getRect(titleIn(band(16, 0)));
        expect(textRect.left, greaterThanOrEqualTo(bandRect.left));
        expect(textRect.right, lessThanOrEqualTo(bandRect.right + 0.01));
        expect(bandRect.width, lessThanOrEqualTo(tester.getSize(cell('16')).width));
      });

      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('글자 확대 $scale배: 띠 안 글자는 1.2배까지만 커지고 띠 높이(17) 안에 들어간다', (tester) async {
          await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 20, title: '뒤풀이 장소')]), textScale: scale));

          final applied = MediaQuery.textScalerOf(tester.element(titleIn(band(16, 0)))).scale(10) / 10;
          expect(applied, closeTo(scale > 1.2 ? 1.2 : scale, 0.001));
          expect(tester.getSize(titleIn(band(16, 0))).height, lessThanOrEqualTo(SmashCalendar.bandHeight));
          expect(tester.getSize(band(16, 0)).height, SmashCalendar.bandHeight, reason: '띠 높이는 글자가 커져도 그대로');
        });
      }

      testWidgets('글자 크기를 제한해도 읽는 말에는 제목 전체가 들어 있다 (정보 손실 없음)', (tester) async {
        final handle = tester.ensureSemantics();
        const long = '다음 달 정기 활동 장소와 시간대 그리고 준비물을 정하는 투표';
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 16, title: long)]), textScale: 2.0, width: 320));

        // 보이는 글자는 좁은 띠에서 말줄임이 되고 글자 확대도 1.2배로 제한되지만
        expect(MediaQuery.textScalerOf(tester.element(titleIn(band(16, 0)))).scale(10) / 10, closeTo(1.2, 0.001));
        // 스크린리더는 제목 전체를 읽는다
        expect(find.bySemanticsLabel(RegExp(long)), findsOneWidget);
        expect(find.bySemanticsLabel("11월 16일 월요일, 오늘, 투표 '$long' 마감일"), findsOneWidget);
        handle.dispose();
      });
    });

    group('색', () {
      testWidgets('띠 색은 colorIndex로 정해지고 SmashColors.pollBand와 같다 (같은 번호는 같은 색, 다른 번호는 다른 색)', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [
          p(11, 1, 11, 3, color: 0),
          p(11, 5, 11, 7, color: 1),
          p(11, 8, 11, 10, color: 1),
          p(11, 12, 11, 14, color: 2),
        ])));

        Color colorOf(int day) => decorationOf(tester, band(day, 0)).color!;
        expect(colorOf(1), SmashColors.pollBand(0));
        expect(colorOf(5), SmashColors.pollBand(1));
        expect(colorOf(8), SmashColors.pollBand(1));
        expect(colorOf(12), SmashColors.pollBand(2));
        expect(colorOf(5), colorOf(8));
        expect({colorOf(1), colorOf(5), colorOf(12)}, hasLength(3));
      });

      testWidgets('colorIndex가 팔레트 크기(6)를 넘으면 순환해서 같은 색을 쓴다', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [
          p(11, 1, 11, 2, color: 0),
          p(11, 4, 11, 5, color: 6),
          p(11, 7, 11, 8, color: 13),
          p(11, 10, 11, 11, color: 1),
          p(11, 13, 11, 14, color: -1),
        ])));

        Color colorOf(int day) => decorationOf(tester, band(day, 0)).color!;
        expect(colorOf(4), colorOf(1), reason: '6은 0과 같다');
        expect(colorOf(7), colorOf(10), reason: '13은 1과 같다');
        expect(colorOf(13), SmashColors.pollBand(5), reason: '-1은 마지막 색');
      });

      testWidgets('팔레트 6색이 모두 서로 다른 띠로 그려지고 띠 안 흰 글자는 모두 4.5:1 이상이다', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [
          for (var i = 0; i < 6; i++) p(11, 1 + i * 4, 11, 3 + i * 4, title: '색${'가나다라마바'[i]}', color: i),
        ])));

        final colors = <Color>{};
        for (var i = 0; i < 6; i++) {
          final bandFinder = band(1 + i * 4, 0);
          final color = decorationOf(tester, bandFinder).color!;
          colors.add(color);
          final text = tester.widget<Text>(find.descendant(of: bandFinder, matching: anyText()));
          expect(contrastRatio(text.style!.color!, color), greaterThanOrEqualTo(4.5), reason: '$i번 색 위 흰 글자');
          expect(contrastRatio(color, SmashColors.surface), greaterThanOrEqualTo(3.0));
          expect(contrastRatio(color, SmashColors.brandTintSoft), greaterThanOrEqualTo(3.0));
        }
        expect(colors, hasLength(6));
      });

      testWidgets('강조 기간 배경 위에서도 띠는 보이고 색은 그대로다', (tester) async {
        await tester.pumpWidget(host(calendar(
          periods: [p(11, 22, 11, 25, color: 3)],
          ranges: [DateTimeRange(start: DateTime(2026, 11, 22), end: DateTime(2026, 11, 25))],
        )));

        expect(decorationOf(tester, band(22, 0)).color, SmashColors.pollBand(3));
        expect(contrastRatio(SmashColors.pollBand(3), SmashColors.brandTintSoft), greaterThanOrEqualTo(3.0));
      });
    });

    group('겹침과 "+N"', () {
      testWidgets('겹치는 기간은 줄이 쌓여 최대 2줄까지만 그려진다', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [
          p(11, 16, 11, 20, title: '가', color: 0),
          p(11, 16, 11, 20, title: '나', color: 1),
          p(11, 16, 11, 20, title: '다', color: 2),
        ])));

        expect(band(16, 0), findsOneWidget);
        expect(band(16, 1), findsOneWidget);
        expect(band(16, 2), findsNothing);
        expect(find.text('다'), findsNothing, reason: '세 번째 투표는 그려지지 않는다');
      });

      testWidgets('가려진 투표가 있는 칸에는 "+N"이 붙는다 (3개 겹침이면 +1, 4개 겹침이면 +2)', (tester) async {
        await tester.pumpWidget(host(calendar(periods: [
          p(11, 15, 11, 21, title: '가'),
          p(11, 16, 11, 20, title: '나', color: 1),
          p(11, 17, 11, 19, title: '다', color: 2),
          p(11, 18, 11, 18, title: '라', color: 3),
        ])));

        expect(more(16), findsNothing, reason: '16일은 둘만 겹친다');
        expect(tester.widget<Text>(more(17)).data, '+1');
        expect(tester.widget<Text>(more(18)).data, '+2');
        expect(tester.widget<Text>(more(19)).data, '+1');
        expect(more(20), findsNothing);
      });

      testWidgets('"+N"은 점 줄(숫자 원과 띠 사이)에서 행사 점 옆에 있어서 점과 띠를 가리지 않는다 (글꼴과 상관없이 겹치지 않음)', (tester) async {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(host(
            calendar(
              hasEventOn: (day) => day.day == 18,
              periods: [p(11, 16, 11, 20, title: '가'), p(11, 16, 11, 20, title: '나', color: 1), p(11, 16, 11, 20, title: '다', color: 2)],
            ),
            width: 320,
            textScale: scale,
          ));

          final plus = tester.getRect(more(18));
          final dot = tester.getRect(find.byKey(const ValueKey('event-dot|2026-11-18')));
          final circle = tester.getRect(find.ancestor(of: find.text('18'), matching: find.byType(DecoratedBox)).first);
          final cellRect = tester.getRect(cell('18'));
          expect(plus.overlaps(dot), isFalse, reason: '글자 $scale배');
          expect(plus.left, greaterThanOrEqualTo(dot.right), reason: '점의 오른쪽');
          // 점과 "+N" 사이에 간격이 있다 (폭이 모자라 줄어들면 간격도 같은 비율로 줄어든다)
          expect(plus.left - dot.right, greaterThanOrEqualTo(2.5), reason: '글자 $scale배: 점과 +N이 붙지 않는다');
          expect(plus.top, greaterThanOrEqualTo(circle.bottom), reason: '숫자 원 아래');
          expect(plus.bottom, lessThanOrEqualTo(tester.getRect(band(16, 0)).top + 0.01), reason: '띠 위');
          expect(plus.left, greaterThanOrEqualTo(cellRect.left));
          expect(plus.right, lessThanOrEqualTo(cellRect.right + 0.01), reason: '칸 밖으로 나가지 않는다');
        }
      });

      testWidgets('행사 점이 없으면 "+N"만 가운데에 있고, 점이 있으면 둘이 나란히 가운데에 모인다', (tester) async {
        final periods = [p(11, 16, 11, 20, title: '가'), p(11, 16, 11, 20, title: '나', color: 1), p(11, 16, 11, 20, title: '다', color: 2)];
        await tester.pumpWidget(host(calendar(periods: periods)));
        final cellRect = tester.getRect(cell('18'));
        expect(tester.getRect(more(18)).center.dx, closeTo(cellRect.center.dx, 0.5));

        await tester.pumpWidget(host(calendar(periods: periods, hasEventOn: (day) => day.day == 18)));
        final dot = tester.getRect(find.byKey(const ValueKey('event-dot|2026-11-18')));
        final plus = tester.getRect(more(18));
        final groupCenter = (dot.left + plus.right) / 2;
        expect(groupCenter, closeTo(cellRect.center.dx, 0.5));
      });
    });

    group('눌림과 읽기', () {
      testWidgets('띠는 눌러도 아무 일도 없고 그 칸의 날짜를 누른 것이 된다 (띠 한가운데를 눌러도 onDaySelected)', (tester) async {
        final taps = <DateTime>[];
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '뒤풀이')], onDay: taps.add)));

        await tester.tapAt(tester.getCenter(band(16, 0)));
        await tester.pump();

        expect(taps, [DateTime(2026, 11, 17)], reason: '띠 중앙은 17일 칸 위');
        await tester.tapAt(tester.getRect(band(16, 0)).centerLeft + const Offset(8, 0));
        expect(taps.last, DateTime(2026, 11, 16));
      });

      testWidgets('띠는 스크린리더에 따로 잡히지 않는다: 제목을 읽는 노드는 날짜 칸뿐이다', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '뒤풀이 장소')])));

        final nodes = find.bySemanticsLabel(RegExp('뒤풀이 장소')).evaluate();
        expect(nodes, hasLength(3), reason: '16, 17, 18일 칸');
        for (final node in nodes) {
          final label = tester.getSemantics(find.byElementPredicate((e) => e == node)).label;
          expect(RegExp('월요일|화요일|수요일').hasMatch(label), isTrue, reason: label);
        }
        handle.dispose();
      });

      testWidgets("스크린리더: 칸마다 \"투표 '제목' 진행 중\", 마감일 칸은 \"투표 '제목' 마감일\"을 읽는다", (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '뒤풀이 장소'), p(11, 17, 11, 17, title: '회식 메뉴', color: 1)])));

        expect(find.bySemanticsLabel("11월 16일 월요일, 오늘, 투표 '뒤풀이 장소' 진행 중"), findsOneWidget);
        expect(find.bySemanticsLabel("11월 17일 화요일, 투표 '뒤풀이 장소' 진행 중, 투표 '회식 메뉴' 마감일"), findsOneWidget);
        expect(find.bySemanticsLabel("11월 18일 수요일, 투표 '뒤풀이 장소' 마감일"), findsOneWidget);
        expect(find.bySemanticsLabel('11월 19일 목요일'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('읽는 말의 순서: 날짜, 오늘, 일정 있음, 투표, 강조 기간', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(
          hasEventOn: (day) => day.day == 16,
          periods: [p(11, 16, 11, 18, title: '가')],
          ranges: [DateTimeRange(start: DateTime(2026, 11, 16), end: DateTime(2026, 11, 16))],
        )));

        expect(find.bySemanticsLabel("11월 16일 월요일, 오늘, 일정 있음, 투표 '가' 진행 중, 강조 기간"), findsOneWidget);
        handle.dispose();
      });

      testWidgets('가려져 안 보이는 투표도 읽는 말에는 들어간다', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(periods: [
          p(11, 16, 11, 20, title: '가'),
          p(11, 16, 11, 20, title: '나', color: 1),
          p(11, 16, 11, 20, title: '다', color: 2),
        ])));

        expect(find.text('다'), findsNothing);
        expect(find.bySemanticsLabel("11월 17일 화요일, 투표 '가' 진행 중, 투표 '나' 진행 중, 투표 '다' 진행 중"), findsOneWidget);
        handle.dispose();
      });

      testWidgets('마감일이 없어 생성일 하루로 만든 투표(endIsDeadline false)는 "마감일"이 아니라 "진행 중"으로 읽는다', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(periods: [p(11, 18, 11, 18, title: '마감 없는 투표', deadline: false)])));

        expect(find.bySemanticsLabel("11월 18일 수요일, 투표 '마감 없는 투표' 진행 중"), findsOneWidget);
        expect(band(18, 0), findsOneWidget, reason: '띠 모양은 마감 있는 투표와 같다');
        expect(decorationOf(tester, band(18, 0)).borderRadius, isNotNull);
        handle.dispose();
      });

      testWidgets('periodNoun으로 읽는 말의 이름을 바꿀 수 있다', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(calendar(periods: [p(11, 16, 11, 18, title: '신입')], noun: '모집')));

        expect(find.bySemanticsLabel("11월 16일 월요일, 오늘, 모집 '신입' 진행 중"), findsOneWidget);
        handle.dispose();
      });
    });

    testWidgets('그 달과 겹치지 않는 기간, 끝이 앞선 기간은 그려지지 않는다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(10, 1, 10, 31), p(12, 1, 12, 31), p(11, 19, 11, 16)])));

      expect(anyBand(), findsNothing);
    });

    testWidgets('periods가 null이면 띠 자리도 띠도 없다', (tester) async {
      await tester.pumpWidget(host(calendar(periods: null)));

      expect(anyBand(), findsNothing);
    });

    testWidgets('띠는 칸 영역 안에 있다 (주의 왼쪽 끝, 오른쪽 끝을 넘지 않는다)', (tester) async {
      await tester.pumpWidget(host(calendar(periods: [p(10, 25, 12, 5), p(11, 3, 11, 25, color: 1)])));

      final calendarRect = tester.getRect(find.byType(SmashCalendar));
      for (final element in anyBand().evaluate()) {
        final rect = tester.getRect(find.byElementPredicate((e) => e == element));
        expect(rect.left, greaterThanOrEqualTo(calendarRect.left));
        expect(rect.right, lessThanOrEqualTo(calendarRect.right + 0.01));
      }
    });
  });

  group('레이아웃 점검: 폭 × 글자 크기 × 투표 상황 (2026년 8월, 6주 달)', () {
    Widget host(Widget child, {required double width, required double textScale}) => MaterialApp(
          theme: SmashTheme.light(),
          builder: (context, a) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: a!,
          ),
          home: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: SingleChildScrollView(child: child))),
          ),
        );

    // 제목에는 숫자를 쓰지 않는다 (날짜 숫자와 같은 글자를 찾는 검사와 섞이지 않게)
    final scenarios = <String, List<SmashCalendarPeriod>>{
      '투표 0개': const [],
      '투표 1개': [p(8, 10, 8, 14, title: '뒤풀이 장소')],
      '투표 2개 겹침': [p(8, 10, 8, 16, title: '뒤풀이 장소'), p(8, 12, 8, 20, title: '행사 날짜', color: 1)],
      '투표 3개 겹침(+1)': [p(8, 10, 8, 16, title: '뒤풀이 장소'), p(8, 12, 8, 20, title: '행사 날짜', color: 1), p(8, 13, 8, 15, title: '회식', color: 2)],
      '하루짜리 투표(긴 제목)': [p(8, 12, 8, 12, title: '오늘 저녁 메뉴를 고르는 투표', color: 3), p(8, 13, 8, 13, title: '하루', color: 4)],
      '주와 달을 넘는 긴 제목': [p(7, 28, 9, 3, title: '개강 총회와 신입 환영회 일정 그리고 장소를 한꺼번에 정하는 투표', color: 5)],
    };

    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final entry in scenarios.entries) {
          testWidgets('폭 ${width.toInt()}, 글자 $scale배, ${entry.key}: 넘치지 않고 모든 칸이 눌릴 만큼 크며 띠 글자 대비가 충분하다', (tester) async {
            await tester.pumpWidget(host(
              SmashCalendar(
                month: DateTime(2026, 8),
                today: DateTime(2026, 8, 12),
                onDaySelected: (_) {},
                onMonthChanged: (_) {},
                periods: entry.value,
                hasEventOn: (day) => day.day == 6 || day.day == 12 || day.day == 25,
              ),
              width: width,
              textScale: scale,
            ));

            expect(tester.takeException(), isNull, reason: '오버플로 없음');
            for (var d = 1; d <= 31; d++) {
              final cell = find.widgetWithText(SmashPressable, '$d');
              expect(cell, findsOneWidget, reason: '$d일');
              final size = tester.getSize(cell);
              expect(size.height, greaterThanOrEqualTo(48), reason: '$d일 높이');
              expect(size.width, greaterThanOrEqualTo(44), reason: '$d일 너비');
              // 날짜 숫자는 접히지 않고 한 줄이다
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: find.text('$d'), matching: find.byType(RichText)),
              );
              expect(paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: '$d'.length)), hasLength(1), reason: '$d일 숫자가 두 줄로 접히지 않는다 (접히면 줄마다 상자가 생긴다)');
              expect(tester.getRect(find.text('$d')).right, lessThanOrEqualTo(tester.getRect(cell).right + 0.01), reason: '$d일 숫자가 칸 밖으로 나가지 않는다');
            }
            final calendarRect = tester.getRect(find.byType(SmashCalendar));
            for (final element in find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('period-band')).evaluate()) {
              final finder = find.byElementPredicate((e) => e == element);
              final rect = tester.getRect(finder);
              expect(rect.left, greaterThanOrEqualTo(calendarRect.left - 0.01));
              expect(rect.right, lessThanOrEqualTo(calendarRect.right + 0.01));
              expect(rect.height, SmashCalendar.bandHeight);
              final color = (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration).color!;
              for (final text in tester.widgetList<Text>(find.descendant(of: finder, matching: anyText()))) {
                expect(contrastRatio(text.style!.color!, color), greaterThanOrEqualTo(4.5));
                expect(tester.getSize(find.descendant(of: finder, matching: anyText())).height, lessThanOrEqualTo(SmashCalendar.bandHeight));
              }
            }
          });
        }
      }
    }
  });
}
