import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {bool disableAnimations = false}) => MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, a) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
        child: a!,
      ),
      home: Scaffold(body: child),
    );

SmashCalendar calendar({
  DateTime? month,
  List<DateTime>? changes,
  DateTime? first,
  DateTime? last,
  List<DateTime>? taps,
}) =>
    SmashCalendar(
      month: month ?? DateTime(2026, 11),
      today: DateTime(2026, 11, 16),
      firstMonth: first,
      lastMonth: last,
      onDaySelected: (d) => taps?.add(d),
      onMonthChanged: (m) => changes?.add(m),
    );

void main() {
  group('swipeDirection (판정 규칙: 숫자로 직접 확인)', () {
    int dir(double dx, {double dy = 0, double v = 0}) => SmashCalendarMath.swipeDirection(dx: dx, dy: dy, velocity: v);

    test('충분히 멀리 밀면 방향대로: 왼쪽(음수)은 다음 달(1), 오른쪽(양수)은 이전 달(-1)', () {
      expect(dir(-64), 1);
      expect(dir(-200), 1);
      expect(dir(64), -1);
      expect(dir(200), -1);
    });

    test('거리가 모자라고 느리면 넘기지 않는다', () {
      expect(dir(-63.9), 0);
      expect(dir(40, v: 799), 0);
      expect(dir(0), 0);
    });

    test('거리가 짧아도 빠르면 넘긴다: 속도 800 이상, 거리 24 이상', () {
      expect(dir(-40, v: -2000), 1);
      expect(dir(40, v: 2000), -1);
      expect(dir(-24, v: -800), 1);
      expect(dir(-40, v: -800), 1);
      expect(dir(-40, v: -799), 0, reason: '속도 모자람');
      expect(dir(-23.9, v: -5000), 0, reason: '거리 모자람');
      expect(dir(-10, v: -5000), 0);
    });

    test('방향은 속도가 아니라 움직인 거리의 부호로 정한다', () {
      expect(dir(-100, v: 900), 1);
      expect(dir(100, v: -900), -1);
    });

    test('가로 이동이 세로 이동보다 크지 않으면 넘기지 않는다 (거의 세로인 대각선)', () {
      expect(dir(-100, dy: 400), 0);
      expect(dir(-100, dy: 100), 0, reason: '같으면 가로가 우세하지 않다');
      expect(dir(-100, dy: 99), 1);
      expect(dir(-120, dy: -20), 1, reason: '세로 방향은 위아래 상관없이 크기만 본다');
      expect(dir(-40, dy: 400, v: -2000), 0, reason: '빨라도 세로가 우세하면 넘기지 않는다');
    });

    test('임계값 상수', () {
      expect(SmashCalendar.swipeDistance, 64);
      expect(SmashCalendar.swipeFlingVelocity, 800);
      expect(SmashCalendar.swipeMinFlingDistance, 24);
    });
  });

  Finder cell(String day) => find.widgetWithText(SmashPressable, day);

  group('가로 스와이프', () {
    testWidgets('왼쪽으로 충분히 밀면 다음 달, 오른쪽으로 밀면 이전 달 (그 달의 1일이 전달된다)', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.drag(cell('16'), const Offset(-120, 0));
      await tester.pump();
      await tester.drag(cell('16'), const Offset(120, 0));
      await tester.pump();

      expect(changes, [DateTime(2026, 12, 1), DateTime(2026, 10, 1)]);
    });

    testWidgets('연도를 넘어간다: 12월에서 다음 달은 다음 해 1월, 1월에서 이전 달은 지난해 12월', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(month: DateTime(2026, 12), changes: changes)));
      await tester.drag(cell('16'), const Offset(-120, 0));
      await tester.pumpWidget(app(calendar(month: DateTime(2026, 1), changes: changes)));
      await tester.pumpAndSettle(); // 달이 바뀌는 전환이 끝나야 칸이 하나만 남는다
      await tester.drag(cell('16'), const Offset(120, 0));

      expect(changes, [DateTime(2027, 1, 1), DateTime(2025, 12, 1)]);
    });

    testWidgets('거리가 모자라고 느리면 넘어가지 않는다 (40만큼 천천히)', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.timedDrag(cell('16'), const Offset(-40, 0), const Duration(seconds: 1));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('너무 짧게(10) 밀면 넘어가지 않는다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.drag(cell('16'), const Offset(-10, 0));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('범위 끝에서는 막힌다: 마지막 달에서 왼쪽, 첫 달에서 오른쪽으로 밀어도 안 넘어가고 반대쪽은 넘어간다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes, first: DateTime(2026, 11), last: DateTime(2026, 11))));
      await tester.drag(cell('16'), const Offset(-120, 0));
      await tester.drag(cell('16'), const Offset(120, 0));
      expect(changes, isEmpty);

      await tester.pumpWidget(app(calendar(changes: changes, last: DateTime(2026, 11))));
      await tester.drag(cell('16'), const Offset(-120, 0));
      expect(changes, isEmpty, reason: '마지막 달에서 다음 달 방향');
      await tester.drag(cell('16'), const Offset(120, 0));
      expect(changes, [DateTime(2026, 10, 1)], reason: '마지막 달에서 이전 달 방향은 된다');

      changes.clear();
      await tester.pumpWidget(app(calendar(changes: changes, first: DateTime(2026, 11))));
      await tester.drag(cell('16'), const Offset(120, 0));
      expect(changes, isEmpty, reason: '첫 달에서 이전 달 방향');
      await tester.drag(cell('16'), const Offset(-120, 0));
      expect(changes, [DateTime(2026, 12, 1)]);
    });

    testWidgets('날짜가 없는 빈 칸에서 시작해도 넘어간다 (2026년 8월 첫 주의 앞 빈칸)', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(month: DateTime(2026, 8), changes: changes)));

      final first = tester.getRect(cell('1'));
      await tester.dragFrom(Offset(20, first.center.dy), const Offset(-120, 0));
      await tester.pump();

      expect(changes, [DateTime(2026, 9, 1)]);
    });

    testWidgets('스와이프를 넣어도 날짜를 누르는 동작은 그대로다', (tester) async {
      final taps = <DateTime>[];
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(taps: taps, changes: changes)));

      await tester.tap(cell('18'));

      expect(taps, [DateTime(2026, 11, 18)]);
      expect(changes, isEmpty);
    });
  });

  group('손가락이 둘 이상 닿을 때', () {
    testWidgets('스와이프하는 손가락이 먼저 닿았다면, 나중에 가만히 닿은 손가락(손바닥 등)이 있어도 넘어간다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      final first = await tester.startGesture(tester.getCenter(cell('16')), pointer: 1);
      final resting = await tester.startGesture(tester.getCenter(cell('25')), pointer: 2);
      await first.moveBy(const Offset(-120, 0));
      await first.up();
      await resting.up();
      await tester.pump();

      expect(changes, [DateTime(2026, 12, 1)]);
    });

    testWidgets('나중에 닿은 손가락만 움직이면 넘어가지 않는다 (처음 닿은 손가락의 움직임으로만 판단한다)', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      final first = await tester.startGesture(tester.getCenter(cell('16')), pointer: 1);
      final second = await tester.startGesture(tester.getCenter(cell('25')), pointer: 2);
      await second.moveBy(const Offset(-120, 0));
      await second.up();
      await first.up();
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('터치가 취소돼도(시스템이 가로챔 등) 다음 스와이프는 정상으로 동작한다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      final cancelled = await tester.startGesture(tester.getCenter(cell('16')), pointer: 1);
      await cancelled.moveBy(const Offset(-20, 0));
      await cancelled.cancel();
      await tester.pump();
      expect(changes, isEmpty);

      await tester.drag(cell('16'), const Offset(-120, 0));
      await tester.pump();

      expect(changes, [DateTime(2026, 12, 1)]);
    });

    testWidgets('한 번의 터치가 끝나면 다음 터치는 새로 시작한다 (이전 거리가 남지 않는다)', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.drag(cell('16'), const Offset(-30, 0)); // 모자란 거리
      await tester.drag(cell('16'), const Offset(-30, 0)); // 합치면 60이지만 새 터치이므로 따로 센다
      await tester.pump();

      expect(changes, isEmpty);
    });
  });

  group('세로 드래그와의 충돌', () {
    testWidgets('세로로만 밀면 달이 넘어가지 않는다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.drag(cell('16'), const Offset(0, 300));
      await tester.fling(cell('16'), const Offset(0, -300), 2000);
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('거의 세로인 대각선(가로 100, 세로 400)은 달을 넘기지 않지만 거의 가로인 대각선(가로 120, 세로 20)은 넘긴다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(calendar(changes: changes)));

      await tester.drag(cell('16'), const Offset(-100, 400));
      await tester.pump();
      expect(changes, isEmpty);

      await tester.drag(cell('16'), const Offset(-120, 20));
      await tester.pump();
      expect(changes, [DateTime(2026, 12, 1)]);
    });

    Widget scrollScreen(List<DateTime> changes) => SizedBox(
          height: 300,
          child: SingleChildScrollView(
            child: Column(children: [calendar(changes: changes), const SizedBox(height: 600)]),
          ),
        );

    testWidgets('스크롤 화면 안에서 세로로 밀면 화면이 스크롤되고 달은 넘어가지 않는다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(scrollScreen(changes)));
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scrollable.position.pixels, 0);

      await tester.drag(cell('16'), const Offset(0, -200));
      await tester.pump();

      expect(scrollable.position.pixels, greaterThan(100));
      expect(changes, isEmpty);
    });

    testWidgets('스크롤 화면 안에서 대각선으로 밀어도(가로 -30, 세로 -200) 스크롤되고 달은 넘어가지 않는다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(scrollScreen(changes)));
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);

      await tester.drag(cell('16'), const Offset(-30, -200));
      await tester.pump();

      expect(scrollable.position.pixels, greaterThan(100));
      expect(changes, isEmpty);
    });

    testWidgets('스크롤 화면 안에서 가로로 밀면 달이 넘어가고 화면은 스크롤되지 않는다', (tester) async {
      final changes = <DateTime>[];
      await tester.pumpWidget(app(scrollScreen(changes)));
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);

      await tester.drag(cell('16'), const Offset(-120, 0));
      await tester.pump();

      expect(changes, [DateTime(2026, 12, 1)]);
      expect(scrollable.position.pixels, 0);
    });
  });

  group('달이 바뀔 때의 전환', () {
    Widget host(DateTime month) => app(calendar(month: month));
    Widget hostReduced(DateTime month) => app(calendar(month: month), disableAnimations: true);

    testWidgets('전환 중에는 이전 달과 새 달이 함께 있다가 끝나면 새 달만 남는다', (tester) async {
      await tester.pumpWidget(host(DateTime(2026, 11)));
      await tester.pumpWidget(host(DateTime(2026, 12)));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('1'), findsNWidgets(2), reason: '전환 중: 11월 1일과 12월 1일');
      expect(find.text('31'), findsOneWidget, reason: '12월에만 있는 31일');

      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('동작 줄이기가 켜져 있으면 바로 바뀐다 (전환 중인 상태가 없다)', (tester) async {
      await tester.pumpWidget(hostReduced(DateTime(2026, 11)));
      await tester.pumpWidget(hostReduced(DateTime(2026, 12)));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('방향: 다음 달이면 새 달이 오른쪽에서, 이전 달이면 왼쪽에서 들어온다', (tester) async {
      double incomingDx() {
        final slide = find.ancestor(of: find.text('31'), matching: find.byType(SlideTransition)).first;
        return tester.widget<SlideTransition>(slide).position.value.dx;
      }

      await tester.pumpWidget(host(DateTime(2026, 11)));
      await tester.pumpWidget(host(DateTime(2026, 12))); // 앞으로: 12월에만 31일이 있다
      await tester.pump(const Duration(milliseconds: 40));
      expect(incomingDx(), greaterThan(0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(host(DateTime(2026, 11)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(DateTime(2026, 10))); // 뒤로: 10월에만 31일이 있다
      await tester.pump(const Duration(milliseconds: 40));
      expect(incomingDx(), lessThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('방향: 나가는 달은 들어오는 달의 반대쪽으로 빠진다 (앞으로 가면 왼쪽, 뒤로 가면 오른쪽)', (tester) async {
      double outgoingDx() {
        final slide = find.ancestor(of: find.text('31'), matching: find.byType(SlideTransition)).first;
        return tester.widget<SlideTransition>(slide).position.value.dx;
      }

      // 앞으로: 10월(31일 있음)에서 11월(31일 없음)로 가면 '31'은 나가는 10월 칸이다
      await tester.pumpWidget(host(DateTime(2026, 10)));
      await tester.pumpWidget(host(DateTime(2026, 11)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('31'), findsOneWidget);
      expect(outgoingDx(), lessThan(0));
      await tester.pumpAndSettle();

      // 뒤로: 12월에서 11월로 가면 '31'은 나가는 12월 칸이다
      await tester.pumpWidget(host(DateTime(2026, 12)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(DateTime(2026, 11)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('31'), findsOneWidget);
      expect(outgoingDx(), greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('전환이 끝나면 칸을 누를 수 있다 (전환 중 이전 달 칸이 입력을 가로채지 않는다)', (tester) async {
      final taps = <DateTime>[];
      await tester.pumpWidget(app(SmashCalendar(month: DateTime(2026, 11), today: DateTime(2026, 11, 16), onDaySelected: taps.add, onMonthChanged: (_) {})));
      await tester.pumpWidget(app(SmashCalendar(month: DateTime(2026, 12), today: DateTime(2026, 11, 16), onDaySelected: taps.add, onMonthChanged: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(cell('20'));

      expect(taps, [DateTime(2026, 12, 20)]);
    });
  });
}
