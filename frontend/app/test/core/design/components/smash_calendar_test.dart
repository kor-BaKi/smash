import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';

final _today = DateTime(2026, 11, 16);

Widget host(Widget child, {double width = 360, double textScale = 1.0}) => MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, a) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: a!,
      ),
      home: Scaffold(body: Align(alignment: Alignment.topCenter, child: SizedBox(width: width, child: SingleChildScrollView(child: child)))),
    );

SmashCalendar calendar({
  DateTime? month,
  DateTime? selected,
  ValueChanged<DateTime>? onDay,
  ValueChanged<DateTime>? onMonth,
  bool Function(DateTime)? hasEventOn,
  bool Function(DateTime)? isDayEnabled,
  List<DateTimeRange> ranges = const [],
  String rangeLabel = '',
  List<SmashCalendarPeriod>? periods,
  DateTime? first,
  DateTime? last,
}) =>
    SmashCalendar(
      month: month ?? DateTime(2026, 11),
      selectedDay: selected,
      today: _today,
      onDaySelected: onDay ?? (_) {},
      onMonthChanged: onMonth ?? (_) {},
      hasEventOn: hasEventOn,
      isDayEnabled: isDayEnabled,
      highlightRanges: ranges,
      highlightLabel: rangeLabel,
      periods: periods,
      firstMonth: first,
      lastMonth: last,
    );

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder f) => tester.getSemantics(f).getSemanticsData();
  Finder cell(String day) => find.widgetWithText(SmashPressable, day);

  group('SmashCalendarMath', () {
    test('weeksOf: 항상 7칸씩, 날짜가 요일 칸에 맞게 놓인다', () {
      for (final month in [DateTime(2026, 11), DateTime(2026, 8), DateTime(2026, 2), DateTime(2028, 2), DateTime(2026, 12), DateTime(2027, 1)]) {
        final weeks = SmashCalendarMath.weeksOf(month);
        final days = <DateTime>[];
        for (final week in weeks) {
          expect(week.length, 7, reason: '$month');
          for (var col = 0; col < 7; col++) {
            final day = week[col];
            if (day == null) continue;
            expect(day.weekday % 7, col, reason: '$day는 ${SmashCalendarMath.weekdayNames[col]}요일 칸이어야 한다');
            days.add(day);
          }
        }
        expect(days.first, DateTime(month.year, month.month, 1));
        expect(days.length, DateTime(month.year, month.month + 1, 0).day, reason: '$month의 날짜 수');
        for (var i = 1; i < days.length; i++) {
          expect(days[i].difference(days[i - 1]).inHours, inInclusiveRange(23, 25), reason: '날짜가 하루씩 이어진다');
        }
      }
    });

    test('weeksOf: 주 수는 4~6주 (2026년 2월 4주, 11월 5주, 8월 6주)', () {
      expect(SmashCalendarMath.weeksOf(DateTime(2026, 2)).length, 4);
      expect(SmashCalendarMath.weeksOf(DateTime(2026, 11)).length, 5);
      expect(SmashCalendarMath.weeksOf(DateTime(2026, 8)).length, 6);
    });

    test('weeksOf: 일요일로 시작하는 달은 앞 빈칸이 없고, 토요일로 시작하는 달은 6칸이다', () {
      expect(SmashCalendarMath.weeksOf(DateTime(2026, 11)).first.first, DateTime(2026, 11, 1)); // 일요일
      expect(SmashCalendarMath.weeksOf(DateTime(2026, 8)).first.where((d) => d == null).length, 6); // 토요일 시작
    });

    test('weeksOf: 윤년 2월은 29일까지', () {
      final days = SmashCalendarMath.weeksOf(DateTime(2028, 2)).expand((w) => w).whereType<DateTime>().toList();
      expect(days.last, DateTime(2028, 2, 29));
      final common = SmashCalendarMath.weeksOf(DateTime(2027, 2)).expand((w) => w).whereType<DateTime>().toList();
      expect(common.last, DateTime(2027, 2, 28));
    });

    test('dayLabel: "11월 16일 월요일", 일요일과 토요일', () {
      expect(SmashCalendarMath.dayLabel(DateTime(2026, 11, 16)), '11월 16일 월요일');
      expect(SmashCalendarMath.dayLabel(DateTime(2026, 11, 15)), '11월 15일 일요일');
      expect(SmashCalendarMath.dayLabel(DateTime(2026, 11, 21)), '11월 21일 토요일');
    });

    test('dateOnly는 시각을 지우고, compareMonth는 연도를 넘어서도 맞다', () {
      expect(SmashCalendarMath.dateOnly(DateTime(2026, 11, 16, 23, 59, 59)), DateTime(2026, 11, 16));
      expect(SmashCalendarMath.compareMonth(DateTime(2026, 1), DateTime(2025, 12)), 1);
      expect(SmashCalendarMath.compareMonth(DateTime(2025, 12), DateTime(2026, 1)), -1);
      expect(SmashCalendarMath.compareMonth(DateTime(2026, 5, 3), DateTime(2026, 5, 28)), 0);
    });
  });

  group('SmashCalendar 화면', () {
    testWidgets('제목, 요일 머리글(일~토), 그 달의 날짜만 보인다', (tester) async {
      await tester.pumpWidget(host(calendar()));

      expect(find.text('2026년 11월'), findsOneWidget);
      for (final name in SmashCalendarMath.weekdayNames) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('1'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsNothing);
    });

    testWidgets('날짜를 누르면 그 날짜(시각 없이)가 전달된다', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(host(calendar(onDay: (d) => picked = d)));

      await tester.tap(cell('18'));

      expect(picked, DateTime(2026, 11, 18));
    });

    testWidgets('이전, 다음 버튼: 그 달의 1일이 전달되고 연도를 넘어간다', (tester) async {
      final months = <DateTime>[];
      await tester.pumpWidget(host(calendar(month: DateTime(2026, 1), onMonth: months.add)));
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpWidget(host(calendar(month: DateTime(2026, 12), onMonth: months.add)));
      await tester.tap(find.byIcon(Icons.chevron_right));

      expect(months, [DateTime(2025, 12, 1), DateTime(2027, 1, 1)]);
    });

    testWidgets('달 범위: 첫 달이면 이전 버튼, 마지막 달이면 다음 버튼이 눌리지 않고, 한 달 앞뒤는 눌린다', (tester) async {
      final months = <DateTime>[];
      Future<void> pump(DateTime month, {DateTime? first, DateTime? last}) =>
          tester.pumpWidget(host(calendar(month: month, first: first, last: last, onMonth: months.add)));

      await pump(DateTime(2026, 11), first: DateTime(2026, 11), last: DateTime(2026, 11));
      await tester.tap(find.byIcon(Icons.chevron_left), warnIfMissed: false);
      await tester.tap(find.byIcon(Icons.chevron_right), warnIfMissed: false);
      expect(months, isEmpty);

      await pump(DateTime(2026, 11), first: DateTime(2026, 10), last: DateTime(2026, 12));
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(months, [DateTime(2026, 10, 1), DateTime(2026, 12, 1)]);
    });

    testWidgets('선택한 날은 채워진 원이고, 보이는 달 밖의 날짜를 선택해도 아무것도 선택돼 보이지 않는다', (tester) async {
      Color? circleColor(String day) {
        final box = tester.widget<DecoratedBox>(find.ancestor(of: find.text(day), matching: find.byType(DecoratedBox)).first);
        return (box.decoration as BoxDecoration).color;
      }

      await tester.pumpWidget(host(calendar(selected: DateTime(2026, 11, 18))));
      expect(circleColor('18'), SmashColors.brand);
      expect(circleColor('19'), Colors.transparent);

      await tester.pumpWidget(host(calendar(selected: DateTime(2026, 10, 18))));
      expect(circleColor('18'), Colors.transparent);
    });

    testWidgets('오늘은 테두리 원이고, 오늘이 선택되면 테두리 없이 채워진다', (tester) async {
      BoxDecoration decorationOf(String day) =>
          tester.widget<DecoratedBox>(find.ancestor(of: find.text(day), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;

      await tester.pumpWidget(host(calendar()));
      expect((decorationOf('16').border as Border).top.color, SmashColors.brand);
      expect(decorationOf('17').border, isNull);

      await tester.pumpWidget(host(calendar(selected: _today)));
      expect(decorationOf('16').color, SmashColors.brand);
      expect(decorationOf('16').border, isNull);
    });

    testWidgets('스크린리더: 날짜, 요일, 오늘, 일정 있음, 강조 기간, 선택할 수 없음을 한 번에 읽고 선택 여부를 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(calendar(
        selected: DateTime(2026, 11, 18),
        hasEventOn: (day) => day.day == 16 || day.day == 20,
        isDayEnabled: (day) => day.day != 20,
        ranges: [DateTimeRange(start: DateTime(2026, 11, 22), end: DateTime(2026, 11, 24))],
        rangeLabel: '자유 활동 기간',
      )));

      expect(find.bySemanticsLabel('11월 16일 월요일, 오늘, 일정 있음'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 17일 화요일'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 20일 금요일, 일정 있음, 선택할 수 없음'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 22일 일요일, 자유 활동 기간'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 25일 수요일'), findsOneWidget); // 범위 밖
      expect(semanticsOf(tester, find.bySemanticsLabel('11월 18일 수요일')).flagsCollection.isSelected, Tristate.isTrue);
      expect(semanticsOf(tester, find.bySemanticsLabel('11월 17일 화요일')).flagsCollection.isSelected, Tristate.isFalse);
      expect(semanticsOf(tester, find.bySemanticsLabel('11월 17일 화요일')).flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('스크린리더: 월 제목은 heading+liveRegion(달이 바뀌면 읽음), 요일 머리글과 빈 칸, 행사 점은 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(calendar(hasEventOn: (day) => true)));

      final title = semanticsOf(tester, find.bySemanticsLabel('2026년 11월'));
      expect(title.flagsCollection.isHeader, isTrue);
      expect(title.flagsCollection.isLiveRegion, isTrue);
      expect(find.bySemanticsLabel('일'), findsNothing);
      expect(find.bySemanticsLabel('월'), findsNothing);
      expect(find.bySemanticsLabel('이전 달'), findsOneWidget);
      expect(find.bySemanticsLabel('다음 달'), findsOneWidget);
      // 점은 따로 읽히지 않고 날짜 칸의 읽는 말("일정 있음")로만 전달된다
      for (final node in find.bySemanticsLabel(RegExp('일정 있음')).evaluate()) {
        expect(RegExp('월요일|화요일|수요일|목요일|금요일|토요일|일요일').hasMatch(tester.getSemantics(find.byElementPredicate((e) => e == node)).label), isTrue);
      }
      handle.dispose();
    });

    testWidgets('월 이동 버튼: 읽는 이름은 "이전 달"/"다음 달", 터치 영역은 48x48, 범위 끝에서는 비활성으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(calendar(first: DateTime(2026, 11), last: DateTime(2026, 12)), width: 320));

      final previous = find.bySemanticsLabel('이전 달');
      final next = find.bySemanticsLabel('다음 달');
      expect(previous, findsOneWidget);
      expect(next, findsOneWidget);
      expect(semanticsOf(tester, previous).flagsCollection.isButton, isTrue);
      expect(semanticsOf(tester, previous).flagsCollection.isEnabled, Tristate.isFalse, reason: '첫 달이므로 이전 달은 비활성');
      expect(semanticsOf(tester, next).flagsCollection.isEnabled, Tristate.isTrue);
      expect(tester.getSize(find.byType(SmashIconButton).first), const Size(48, 48));
      expect(tester.getSize(find.byType(SmashIconButton).last), const Size(48, 48));
      handle.dispose();
    });

    testWidgets('선택할 수 없는 날은 눌러도 전달되지 않고 숫자가 흐린 색이다', (tester) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(host(calendar(onDay: picked.add, isDayEnabled: (d) => d.day >= _today.day)));

      await tester.tap(cell('10'), warnIfMissed: false);
      await tester.tap(cell('20'));

      expect(picked, [DateTime(2026, 11, 20)]);
      expect(tester.widget<Text>(find.text('10')).style!.color, SmashColors.textDisabled);
      expect(tester.widget<Text>(find.text('20')).style!.color, SmashColors.text);
    });

    testWidgets('강조 기간은 양 끝 날짜를 포함해 배경이 칠해지고 바깥은 칠해지지 않는다', (tester) async {
      await tester.pumpWidget(host(calendar(ranges: [DateTimeRange(start: DateTime(2026, 11, 22, 23, 59), end: DateTime(2026, 11, 24, 1))])));

      Color? bg(String day) => tester.widget<ColoredBox>(find.ancestor(of: find.text(day), matching: find.byType(ColoredBox)).first).color;
      expect(bg('21'), Colors.transparent);
      expect(bg('22'), SmashColors.brandTintSoft);
      expect(bg('23'), SmashColors.brandTintSoft);
      expect(bg('24'), SmashColors.brandTintSoft);
      expect(bg('25'), Colors.transparent);
    });

    Finder dot(int day) => find.byKey(ValueKey('event-dot|2026-11-$day'));

    testWidgets('행사 점: hasEventOn이 true인 날에만 색 채운 점 하나가 찍힌다 (hasEventOn이 없으면 점이 없다)', (tester) async {
      await tester.pumpWidget(host(calendar()));
      expect(find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('event-dot')), findsNothing);

      await tester.pumpWidget(host(calendar(hasEventOn: (day) => day.day == 16 || day.day == 25)));
      expect(dot(16), findsOneWidget);
      expect(dot(25), findsOneWidget);
      expect(dot(17), findsNothing);
      final decoration = (tester.widget<DecoratedBox>(dot(16))).decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, SmashCalendar.eventDotColor);
      expect(tester.getSize(dot(16)), const Size.square(6));
    });

    testWidgets('행사 점은 일정이 몇 개든 하나이고 개수나 종류를 구분하지 않는다 (같은 모양, 같은 색)', (tester) async {
      await tester.pumpWidget(host(calendar(hasEventOn: (day) => day.day % 2 == 0)));

      final decorations = {
        for (var d = 2; d <= 30; d += 2) (tester.widget<DecoratedBox>(dot(d)).decoration as BoxDecoration).color,
      };
      expect(decorations, {SmashCalendar.eventDotColor});
      expect(find.descendant(of: cell('16'), matching: find.text('+')), findsNothing);
      expect(find.descendant(of: cell('16'), matching: find.byKey(const ValueKey('event-dot|2026-11-16'))), findsOneWidget);
    });

    testWidgets('행사 점은 숫자 원 바깥(아래)에 있어서 선택한 날의 원, 오늘의 테두리 원과 겹치지 않는다', (tester) async {
      await tester.pumpWidget(host(calendar(
        selected: DateTime(2026, 11, 18),
        hasEventOn: (day) => day.day == 16 || day.day == 18 || day.day == 20,
        ranges: [DateTimeRange(start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 20))],
      )));

      for (final d in [16, 18, 20]) {
        final circle = tester.getRect(find.ancestor(of: find.text('$d'), matching: find.byType(DecoratedBox)).first);
        final dotRect = tester.getRect(dot(d));
        expect(dotRect.top, greaterThanOrEqualTo(circle.bottom), reason: '$d일: 점은 숫자 원 아래');
        expect(circle.overlaps(dotRect), isFalse, reason: '$d일');
      }
    });

    testWidgets('행사 점은 띠와도 겹치지 않는다: 점 줄은 숫자 원과 띠 자리 사이다', (tester) async {
      await tester.pumpWidget(host(calendar(
        hasEventOn: (day) => day.day == 18,
        periods: [
          SmashCalendarPeriod(start: DateTime(2026, 11, 16), end: DateTime(2026, 11, 20), title: '뒤풀이'),
          SmashCalendarPeriod(start: DateTime(2026, 11, 17), end: DateTime(2026, 11, 19), title: '회식', colorIndex: 1),
        ],
      )));

      final dotRect = tester.getRect(dot(18));
      for (final lane in [0, 1]) {
        final band = tester.getRect(find.byKey(ValueKey('period-band|2026-11-${lane == 0 ? 16 : 17}|lane$lane')));
        expect(band.top, greaterThanOrEqualTo(dotRect.bottom), reason: '$lane번 줄 띠는 점 아래');
        expect(band.overlaps(dotRect), isFalse);
      }
      // 점은 숫자 원과 띠 사이
      final circle = tester.getRect(find.ancestor(of: find.text('18'), matching: find.byType(DecoratedBox)).first);
      expect(dotRect.top, greaterThanOrEqualTo(circle.bottom));
    });

    testWidgets('빈 목록(periods: [])이면 띠 자리가 점 아래에 확보돼 있다', (tester) async {
      await tester.pumpWidget(host(calendar(hasEventOn: (day) => day.day == 18, periods: const [])));

      final reserved = tester.getRect(cell('18')).bottom - tester.getRect(dot(18)).bottom;
      expect(reserved, greaterThanOrEqualTo(SmashCalendar.bandHeight * 2 + SmashCalendar.bandGap));
    });

    test('행사 점 색: 흰 배경, 강조 기간 배경, 화면 배경 위에서 3:1 이상이고, 선택한 날의 브랜드 색과 다르다', () {
      const dotColor = SmashCalendar.eventDotColor;
      expect(contrastRatio(dotColor, SmashColors.surface), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(dotColor, SmashColors.brandTintSoft), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(dotColor, SmashColors.background), greaterThanOrEqualTo(3.0));
      expect(dotColor, isNot(SmashColors.brand));
    });

    testWidgets('행사 점은 선택한 날, 오늘, 강조 기간 안, 선택 불가인 날에서도 같은 색이고 가려지지 않는다', (tester) async {
      await tester.pumpWidget(host(calendar(
        selected: DateTime(2026, 11, 18),
        hasEventOn: (day) => const [16, 18, 21, 22].contains(day.day),
        isDayEnabled: (day) => day.day != 22,
        ranges: [DateTimeRange(start: DateTime(2026, 11, 21), end: DateTime(2026, 11, 22))],
      )));

      for (final d in [16, 18, 21, 22]) {
        final box = tester.widget<DecoratedBox>(dot(d));
        expect((box.decoration as BoxDecoration).color, SmashCalendar.eventDotColor, reason: '$d일');
        expect(dot(d).hitTestable(at: Alignment.center), findsOneWidget, reason: '$d일 점이 다른 위젯에 가려지지 않는다');
      }
    });

    testWidgets('읽는 말은 "일정 있음"으로 통일된다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(calendar(hasEventOn: (day) => day.day == 17)));

      expect(SmashCalendar.eventLabel, '일정 있음');
      expect(find.bySemanticsLabel('11월 17일 화요일, 일정 있음'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 18일 수요일'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('칸 높이는 48 이상이고, 폭 320에서도 칸 너비가 44 이상이다', (tester) async {
      await tester.pumpWidget(host(calendar(), width: 320));

      for (var d = 1; d <= 30; d++) {
        final size = tester.getSize(cell('$d'));
        expect(size.height, greaterThanOrEqualTo(48), reason: '$d일 높이');
        expect(size.width, greaterThanOrEqualTo(44), reason: '$d일 너비');
      }
    });

    testWidgets('주가 6줄인 달도 폭 320 + 글자 2.0배에서 넘치지 않고 모든 날짜가 보인다', (tester) async {
      await tester.pumpWidget(host(calendar(month: DateTime(2026, 8)), width: 320, textScale: 2.0));

      expect(tester.takeException(), isNull);
      for (var d = 1; d <= 31; d++) {
        expect(find.text('$d'), findsOneWidget, reason: '$d일');
      }
      expect(tester.getSize(cell('15')).height, greaterThanOrEqualTo(48));
    });

    testWidgets('글자 확대 시 칸이 커지고 같은 주의 칸 높이는 같다', (tester) async {
      await tester.pumpWidget(host(calendar(), width: 320, textScale: 2.0));

      final a = tester.getSize(cell('16')).height;
      final b = tester.getSize(cell('18')).height;
      expect(a, b);
    });
  });
}
