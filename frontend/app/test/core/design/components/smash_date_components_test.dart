import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/format/ko_date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _today = DateTime(2026, 11, 16);
final _first = DateTime(2026, 11, 1);
final _last = DateTime(2027, 2, 28);

/// 화면에 보이는 날짜 표기. 공백이 줄바꿈 없는 공백(NBSP)이라 일반 공백으로 쓴 글자와 같지 않다
String f(int y, int m, int d) =>
    KoDateFormat.date(DateTime(y, m, d), now: _today);

Widget app(Widget Function(BuildContext) builder, {double textScale = 1.0}) =>
    MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, a) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: a!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: Builder(builder: builder)),
      ),
    );

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 1200)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  SemanticsData semanticsOf(WidgetTester tester, Finder f) =>
      tester.getSemantics(f).getSemanticsData();
  Finder day(String d) => find.widgetWithText(SmashPressable, d);

  group('SmashDayPicker: 정적 규칙', () {
    test(
      'isSelectable: 양 끝을 포함하고 범위 밖은 안 되며, isDayEnabled가 더 좁힌다 (시각은 무시)',
      () {
        bool ok(DateTime d, {bool Function(DateTime)? p}) =>
            SmashDayPicker.isSelectable(
              d,
              firstDate: DateTime(2026, 11, 18),
              lastDate: DateTime(2026, 11, 25),
              isDayEnabled: p,
            );

        expect(ok(DateTime(2026, 11, 17)), isFalse);
        expect(ok(DateTime(2026, 11, 18)), isTrue);
        expect(ok(DateTime(2026, 11, 25)), isTrue);
        expect(ok(DateTime(2026, 11, 26)), isFalse);
        expect(ok(DateTime(2026, 11, 18, 0, 0, 1)), isTrue, reason: '시각은 무시');
        expect(
          ok(DateTime(2026, 11, 25, 23, 59)),
          isTrue,
          reason: '마지막 날은 하루 종일',
        );
        expect(
          ok(DateTime(2026, 11, 20), p: (d) => d.weekday != DateTime.friday),
          isFalse,
        );
        expect(
          ok(DateTime(2026, 11, 21), p: (d) => d.weekday != DateTime.friday),
          isTrue,
        );
      },
    );

    test(
      'isSelectable: firstDate에 시각이 있어도(예: 지금 시각) 그날은 고를 수 있다 (기존 투표 마감 선택이 firstDate에 지금을 넘겼다)',
      () {
        final firstWithTime = DateTime(2026, 11, 16, 14, 30);
        expect(
          SmashDayPicker.isSelectable(
            DateTime(2026, 11, 16),
            firstDate: firstWithTime,
            lastDate: DateTime(2026, 12, 31),
          ),
          isTrue,
        );
        expect(
          SmashDayPicker.isSelectable(
            DateTime(2026, 11, 15),
            firstDate: firstWithTime,
            lastDate: DateTime(2026, 12, 31),
          ),
          isFalse,
        );
        expect(
          SmashDayPicker.isSelectable(
            DateTime(2026, 12, 31),
            firstDate: firstWithTime,
            lastDate: DateTime(2026, 12, 31, 9),
          ),
          isTrue,
        );
      },
    );

    test('clampMonth: 범위 안이면 그대로, 앞이면 첫 달, 뒤면 마지막 달', () {
      final first = DateTime(2026, 11, 18);
      final last = DateTime(2027, 2, 5);
      expect(
        SmashDayPicker.clampMonth(DateTime(2026, 12, 31), first, last),
        DateTime(2026, 12),
      );
      expect(
        SmashDayPicker.clampMonth(DateTime(2020, 1, 1), first, last),
        DateTime(2026, 11),
      );
      expect(
        SmashDayPicker.clampMonth(DateTime(2030, 1, 1), first, last),
        DateTime(2027, 2),
      );
      expect(
        SmashDayPicker.clampMonth(DateTime(2026, 11, 1), first, last),
        DateTime(2026, 11),
        reason: '첫 달 안의 날짜',
      );
    });
  });

  group('SmashDayPicker 화면', () {
    Widget picker({
      DateTime? first,
      DateTime? last,
      DateTime? selected,
      DateTime? initialMonth,
      bool Function(DateTime)? enabled,
      ValueChanged<DateTime>? onChanged,
    }) => SmashDayPicker(
      firstDate: first ?? _first,
      lastDate: last ?? _last,
      selectedDay: selected,
      initialMonth: initialMonth,
      isDayEnabled: enabled,
      today: _today,
      onChanged: onChanged ?? (_) {},
    );

    testWidgets('처음 달: 선택한 날, 없으면 initialMonth, 없으면 오늘의 달, 범위 밖이면 가장 가까운 달', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app((_) => picker(selected: DateTime(2026, 12, 25))),
      );
      expect(find.text('2026년 12월'), findsOneWidget);

      await tester.pumpWidget(
        app(
          (_) => KeyedSubtree(
            key: const ValueKey('b'),
            child: picker(initialMonth: DateTime(2027, 1, 10)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2027년 1월'), findsOneWidget);

      await tester.pumpWidget(
        app((_) => KeyedSubtree(key: const ValueKey('c'), child: picker())),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026년 11월'), findsOneWidget);

      await tester.pumpWidget(
        app(
          (_) => KeyedSubtree(
            key: const ValueKey('d'),
            child: picker(
              selected: DateTime(2030, 6, 1),
              last: DateTime(2026, 12, 31),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('2026년 12월'),
        findsOneWidget,
        reason: '범위 뒤를 가리키면 마지막 달',
      );
    });

    testWidgets('선택한 날과 initialMonth가 모두 있으면 선택한 날의 달이 먼저 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          (_) => picker(
            selected: DateTime(2026, 12, 25),
            initialMonth: DateTime(2027, 1, 10),
          ),
        ),
      );

      expect(find.text('2026년 12월'), findsOneWidget);
    });

    testWidgets('날짜를 누르면 시각 없는 날짜가 전달된다', (tester) async {
      sizeScreen(tester);
      DateTime? picked;
      await tester.pumpWidget(app((_) => picker(onChanged: (d) => picked = d)));

      await tester.tap(day('20'));

      expect(picked, DateTime(2026, 11, 20));
      expect(picked!.hour, 0);
    });

    testWidgets('범위 밖 날짜는 누를 수 없고 "선택할 수 없음"으로 읽힌다 (양 끝은 선택 가능)', (
      tester,
    ) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      final picked = <DateTime>[];
      await tester.pumpWidget(
        app(
          (_) => picker(
            first: DateTime(2026, 11, 18),
            last: DateTime(2026, 11, 25),
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(day('17'), warnIfMissed: false);
      await tester.tap(day('26'), warnIfMissed: false);
      await tester.tap(day('18'));
      await tester.tap(day('25'));

      expect(picked, [DateTime(2026, 11, 18), DateTime(2026, 11, 25)]);
      expect(find.bySemanticsLabel('11월 17일 화요일, 선택할 수 없음'), findsOneWidget);
      expect(find.bySemanticsLabel('11월 26일 목요일, 선택할 수 없음'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('달 이동은 범위 안에서만 된다: 첫 달이면 이전, 마지막 달이면 다음이 비활성이고, 한 달 앞뒤는 넘어간다', (
      tester,
    ) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          (_) => picker(
            first: DateTime(2026, 11, 5),
            last: DateTime(2026, 11, 20),
          ),
        ),
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('이전 달'),
        ).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('다음 달'),
        ).flagsCollection.isEnabled,
        Tristate.isFalse,
      );

      await tester.pumpWidget(
        app(
          (_) => picker(
            first: DateTime(2026, 10, 5),
            last: DateTime(2026, 12, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('2026년 10월'), findsOneWidget);
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('이전 달'),
        ).flagsCollection.isEnabled,
        Tristate.isFalse,
        reason: '더는 앞으로 못 간다',
      );
      handle.dispose();
    });

    testWidgets('isDayEnabled가 더 좁힌다: 일요일은 누를 수 없다', (tester) async {
      sizeScreen(tester);
      final picked = <DateTime>[];
      await tester.pumpWidget(
        app(
          (_) => picker(
            enabled: (d) => d.weekday != DateTime.sunday,
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(day('22'), warnIfMissed: false); // 일요일
      await tester.tap(day('23'));

      expect(picked, [DateTime(2026, 11, 23)]);
    });

    testWidgets('보는 달을 넘겨도 고른 날은 그대로 표시된다', (tester) async {
      sizeScreen(tester);
      DateTime? selected = DateTime(2026, 11, 20);
      await tester.pumpWidget(
        app(
          (_) => StatefulBuilder(
            builder: (context, setState) => picker(
              selected: selected,
              onChanged: (d) => setState(() => selected = d),
            ),
          ),
        ),
      );

      Color? circle(String d) {
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(of: find.text(d), matching: find.byType(DecoratedBox))
              .first,
        );
        return (box.decoration as BoxDecoration).color;
      }

      expect(circle('20'), SmashColors.brand);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('2026년 12월'), findsOneWidget);
      expect(circle('20'), Colors.transparent, reason: '12월 20일은 선택된 날이 아니다');
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(circle('20'), SmashColors.brand);
    });
  });

  group('showSmashDatePicker', () {
    late BuildContext ctx;
    Future<void> pump(
      WidgetTester tester, {
      double textScale = 1.0,
      Size size = const Size(400, 1200),
    }) async {
      sizeScreen(tester, size: size);
      await tester.pumpWidget(
        app((c) {
          ctx = c;
          return const SizedBox();
        }, textScale: textScale),
      );
    }

    Future<DateTime?> open({
      DateTime? initial,
      DateTime? first,
      DateTime? last,
      bool Function(DateTime)? enabled,
      String? title,
      String? confirm,
    }) => showSmashDatePicker(
      context: ctx,
      firstDate: first ?? _first,
      lastDate: last ?? _last,
      initialDate: initial,
      isDayEnabled: enabled,
      today: _today,
      title: title ?? '날짜 선택',
      confirmLabel: confirm ?? '선택',
    );

    Finder confirmButton() => find.widgetWithText(SmashButton, '선택');
    bool confirmEnabled(WidgetTester tester) =>
        tester.widget<SmashButton>(confirmButton()).onPressed != null;

    testWidgets('열리면 제목과 달력이 보이고, 초기값이 없으면 안내 문구와 비활성 "선택"이 보인다', (
      tester,
    ) async {
      await pump(tester);
      open();
      await settle(tester);

      expect(find.text('날짜 선택'), findsOneWidget);
      expect(find.text('2026년 11월'), findsOneWidget);
      expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse);
    });

    testWidgets('초기값이 범위 안이면 처음부터 골라져 있고 "선택"이 활성이다 (선택한 날짜 문구 포함)', (
      tester,
    ) async {
      await pump(tester);
      open(initial: DateTime(2026, 11, 20));
      await settle(tester);

      expect(
        find.text(
          '선택한 날짜: ${KoDateFormat.date(DateTime(2026, 11, 20), now: _today)}',
        ),
        findsOneWidget,
      );
      expect(find.text('선택한 날짜: ${f(2026, 11, 20)}'), findsOneWidget);
      expect(confirmEnabled(tester), isTrue);
    });

    testWidgets('초기값이 범위 밖이거나 막힌 날이면 고르지 않은 상태로 열리고, 달은 가장 가까운 달이다', (
      tester,
    ) async {
      await pump(tester);
      open(initial: DateTime(2020, 1, 1));
      await settle(tester);
      expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse);
      expect(find.text('2026년 11월'), findsOneWidget, reason: '범위 앞이면 첫 달');
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      open(
        initial: DateTime(2026, 11, 22),
        enabled: (d) => d.weekday != DateTime.sunday,
      );
      await settle(tester);
      expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse, reason: '22일은 일요일이라 막혀 있다');
    });

    testWidgets('막힌 날을 초기값으로 주면 아무것도 고르지 않은 채 그 날이 속한 달이 먼저 보인다', (
      tester,
    ) async {
      await pump(tester);
      open(
        initial: DateTime(2026, 12, 22),
        enabled: (d) =>
            d.weekday != DateTime.tuesday && d.weekday != DateTime.sunday,
      );
      await settle(tester);

      expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
      expect(find.text('2026년 12월'), findsOneWidget);
    });

    testWidgets('firstDate에 시각이 있어도(지금 시각) 그날을 시트에서 고를 수 있고 돌아오는 값은 날짜뿐이다', (
      tester,
    ) async {
      await pump(tester);
      final result = showSmashDatePicker(
        context: ctx,
        firstDate: DateTime(2026, 11, 16, 14, 30),
        lastDate: _last,
        today: _today,
      );
      await settle(tester);

      await tester.tap(day('16'));
      await tester.pump();
      await tester.tap(confirmButton());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2026, 11, 16));
    });

    testWidgets(
      '날짜 표기는 today 기준으로 연도를 붙인다 (오늘이 2031년이면 2031년 날짜에는 연도가 없고 2030년에는 붙는다)',
      (tester) async {
        await pump(tester);
        final far = DateTime(2031, 5, 10);
        showSmashDatePicker(
          context: ctx,
          firstDate: DateTime(2030, 1, 1),
          lastDate: DateTime(2032, 1, 1),
          initialDate: DateTime(2031, 5, 20),
          today: far,
        );
        await settle(tester);
        expect(
          find.text(
            '선택한 날짜: ${KoDateFormat.date(DateTime(2031, 5, 20), now: far)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text('선택한 날짜: 5월\u00a020일\u00a0(화)'),
          findsOneWidget,
          reason: '연도 없음 (NBSP 표기)',
        );
        await tester.tap(find.byIcon(Icons.close));
        await settle(tester);

        showSmashDatePicker(
          context: ctx,
          firstDate: DateTime(2030, 1, 1),
          lastDate: DateTime(2032, 1, 1),
          initialDate: DateTime(2030, 5, 20),
          today: far,
        );
        await settle(tester);
        expect(find.textContaining('2030년'), findsWidgets);
      },
    );

    testWidgets('날짜를 고르고 "선택"을 누르면 시각 없는 날짜가 돌아온다', (tester) async {
      await pump(tester);
      final result = open();
      await settle(tester);

      await tester.tap(day('19'));
      await tester.pump();
      expect(find.text('선택한 날짜: ${f(2026, 11, 19)}'), findsOneWidget);
      expect(confirmEnabled(tester), isTrue);
      await tester.tap(confirmButton());
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2026, 11, 19));
    });

    testWidgets('초기값에 시각이 있어도 돌아오는 값은 날짜뿐이다', (tester) async {
      await pump(tester);
      final result = open(initial: DateTime(2026, 11, 20, 23, 59, 30));
      await settle(tester);

      await tester.tap(confirmButton());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2026, 11, 20));
    });

    testWidgets('여러 번 바꿔 고르면 마지막으로 고른 날짜가 돌아온다', (tester) async {
      await pump(tester);
      final result = open();
      await settle(tester);

      await tester.tap(day('18'));
      await tester.tap(day('24'));
      await tester.tap(day('21'));
      await tester.pump();
      await tester.tap(confirmButton());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2026, 11, 21));
    });

    testWidgets('달을 넘겨서 고른 날짜도 돌아온다 (다른 해 포함: 2027년 1월 5일은 연도가 붙는다)', (
      tester,
    ) async {
      await pump(tester);
      final result = open();
      await settle(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('2027년 1월'), findsOneWidget);
      await tester.tap(day('5'));
      await tester.pump();
      expect(find.text('선택한 날짜: ${f(2027, 1, 5)}'), findsOneWidget);
      await tester.tap(confirmButton());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2027, 1, 5));
    });

    testWidgets('닫기 버튼으로 닫으면 null이다. 날짜를 골랐어도 "선택"을 누르지 않았으면 null이다', (
      tester,
    ) async {
      await pump(tester);
      final result = open(initial: DateTime(2026, 11, 20));
      await settle(tester);
      await tester.tap(day('23'));

      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, isNull);
    });

    testWidgets('바깥을 눌러도, 아래로 끌어도 닫히지 않는다 (고르던 날짜를 잃지 않는다)', (tester) async {
      await pump(tester);
      open();
      await settle(tester);
      await tester.tap(day('20'));
      await tester.pump();

      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      expect(find.byType(SmashSheetFrame), findsOneWidget);

      await tester.fling(find.text('2026년 11월'), const Offset(0, 500), 2000);
      await settle(tester);
      expect(find.byType(SmashSheetFrame), findsOneWidget);
      expect(find.text('선택한 날짜: ${f(2026, 11, 20)}'), findsOneWidget);
    });

    testWidgets('제목과 확정 글자를 바꿀 수 있다', (tester) async {
      await pump(tester);
      open(title: '마감일', confirm: '정하기');
      await settle(tester);

      expect(find.text('마감일'), findsOneWidget);
      expect(find.widgetWithText(SmashButton, '정하기'), findsOneWidget);
    });

    testWidgets('범위 밖과 막힌 날은 시트 안에서도 고를 수 없다', (tester) async {
      await pump(tester);
      final result = open(
        first: DateTime(2026, 11, 18),
        last: DateTime(2026, 11, 25),
        enabled: (d) => d.weekday != DateTime.saturday,
      );
      await settle(tester);

      await tester.tap(day('17'), warnIfMissed: false);
      await tester.tap(day('21'), warnIfMissed: false); // 토요일
      await tester.pump();
      expect(confirmEnabled(tester), isFalse);
      await tester.tap(day('20'));
      await tester.pump();
      await tester.tap(confirmButton());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      expect(await result, DateTime(2026, 11, 20));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('폭 320 + 글자 $scale배: 넘치지 않고 시트 안에서 스크롤해 "선택"까지 닿는다', (
        tester,
      ) async {
        await pump(tester, textScale: scale, size: const Size(320, 700));
        final result = open(initial: DateTime(2026, 11, 20));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(SmashSheetFrame)).height,
          lessThanOrEqualTo(700 * 0.9 + 40),
        );
        await tester.scrollUntilVisible(
          confirmButton(),
          300,
          scrollable: find
              .descendant(
                of: find.byType(SmashSheetFrame),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(confirmButton());
        await settle(tester);

        expect(
          find.byType(SmashSheetFrame),
          findsNothing,
          reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
        );
        expect(await result, DateTime(2026, 11, 20));
      });
    }

    testWidgets(
      '스크린리더: 선택한 날짜 문구는 바로 읽히고(liveRegion), 닫기 버튼과 이전/다음 달 버튼에 이름이 있다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester);
        open(initial: DateTime(2026, 11, 20));
        await settle(tester);

        expect(
          semanticsOf(
            tester,
            find.bySemanticsLabel('선택한 날짜: ${f(2026, 11, 20)}'),
          ).flagsCollection.isLiveRegion,
          isTrue,
        );
        expect(find.bySemanticsLabel('닫기'), findsOneWidget);
        expect(find.bySemanticsLabel('이전 달'), findsOneWidget);
        expect(find.bySemanticsLabel('다음 달'), findsOneWidget);
        expect(
          semanticsOf(
            tester,
            find.bySemanticsLabel('11월 20일 금요일'),
          ).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        handle.dispose();
      },
    );
  });

  group('SmashDateField', () {
    Widget field({
      DateTime? value,
      ValueChanged<DateTime>? onChanged,
      DateTime? first,
      DateTime? last,
      DateTime? initial,
      bool Function(DateTime)? enabled,
      String label = '시작일',
      String? error,
      String? helper,
      bool isEnabled = true,
      String? pickerTitle,
    }) => SmashDateField(
      label: label,
      value: value,
      onChanged: onChanged ?? (_) {},
      firstDate: first ?? _first,
      lastDate: last ?? _last,
      initialDate: initial,
      isDayEnabled: enabled,
      errorText: error,
      helper: helper,
      enabled: isEnabled,
      pickerTitle: pickerTitle,
      today: _today,
    );

    Finder box() => find.byType(SmashPressable).first;

    testWidgets('값이 없으면 안내 문구, 있으면 "11월 20일 (금)", 올해가 아니면 연도가 붙는다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app((_) => field()));
      expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('날짜를 선택해 주세요')).style!.color,
        SmashColors.textSecondary,
      );

      await tester.pumpWidget(app((_) => field(value: DateTime(2026, 11, 20))));
      expect(
        find.text(KoDateFormat.date(DateTime(2026, 11, 20), now: _today)),
        findsOneWidget,
      );
      expect(find.text(f(2026, 11, 20)), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(f(2026, 11, 20))).style!.color,
        SmashColors.text,
      );

      await tester.pumpWidget(app((_) => field(value: DateTime(2027, 1, 5))));
      expect(find.text(f(2027, 1, 5)), findsOneWidget);
    });

    testWidgets(
      '값 표기는 today 기준으로 연도를 붙인다 (오늘이 2031년이면 2031년 값에는 연도가 없고 2030년 값에는 붙는다)',
      (tester) async {
        sizeScreen(tester);
        final far = DateTime(2031, 5, 10);
        Widget farField(DateTime value) => SmashDateField(
          label: '날짜',
          value: value,
          onChanged: (_) {},
          firstDate: DateTime(2030, 1, 1),
          lastDate: DateTime(2032, 1, 1),
          today: far,
        );

        await tester.pumpWidget(app((_) => farField(DateTime(2031, 5, 20))));
        expect(find.text('5월\u00a020일\u00a0(화)'), findsOneWidget);
        await tester.pumpWidget(app((_) => farField(DateTime(2030, 5, 20))));
        expect(find.text('2030년\u00a05월\u00a020일\u00a0(월)'), findsOneWidget);
      },
    );

    testWidgets('누르면 시트가 열리고 제목은 라벨(또는 pickerTitle)이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app((_) => field(label: '시작일')));
      await tester.tap(box());
      await settle(tester);
      expect(find.byType(SmashSheetFrame), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SmashSheetFrame),
          matching: find.text('시작일'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      await tester.pumpWidget(
        app((_) => field(label: '시작일', pickerTitle: '시작하는 날')),
      );
      await tester.tap(box());
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(SmashSheetFrame),
          matching: find.text('시작하는 날'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('고르고 "선택"을 누르면 onChanged에 시각 없는 날짜가 전달되고, 닫으면 전달되지 않는다', (
      tester,
    ) async {
      sizeScreen(tester);
      final changes = <DateTime>[];
      await tester.pumpWidget(app((_) => field(onChanged: changes.add)));

      await tester.tap(box());
      await settle(tester);
      await tester.tap(find.widgetWithText(SmashPressable, '20'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);
      expect(changes, isEmpty, reason: '닫으면 전달되지 않는다');

      await tester.tap(box());
      await settle(tester);
      await tester.tap(find.widgetWithText(SmashPressable, '20'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SmashButton, '선택'));
      await settle(tester);

      expect(changes, [DateTime(2026, 11, 20)]);
    });

    testWidgets('시트는 값이 있으면 그 값에서, 없으면 initialDate에서 시작한다 (값이 우선)', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          (_) => field(
            value: DateTime(2026, 12, 3),
            initial: DateTime(2026, 11, 25),
          ),
        ),
      );
      await tester.tap(box());
      await settle(tester);
      expect(find.text('선택한 날짜: ${f(2026, 12, 3)}'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      await tester.pumpWidget(
        app((_) => field(initial: DateTime(2026, 11, 25))),
      );
      await tester.tap(box());
      await settle(tester);
      expect(find.text('선택한 날짜: ${f(2026, 11, 25)}'), findsOneWidget);
    });

    testWidgets('끝일 칸의 firstDate에 시작일을 넘기면 그보다 앞선 날은 시트에서 고를 수 없다', (
      tester,
    ) async {
      sizeScreen(tester);
      final changes = <DateTime>[];
      await tester.pumpWidget(
        app(
          (_) => field(
            label: '끝일',
            first: DateTime(2026, 11, 18),
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(box());
      await settle(tester);

      await tester.tap(
        find.widgetWithText(SmashPressable, '17'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        tester
            .widget<SmashButton>(find.widgetWithText(SmashButton, '선택'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.widgetWithText(SmashPressable, '18'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SmashButton, '선택'));
      await settle(tester);

      expect(changes, [DateTime(2026, 11, 18)]);
    });

    testWidgets('lastDate가 시트까지 전달된다: 마지막 날 다음 날은 고를 수 없고 마지막 날은 고를 수 있다', (
      tester,
    ) async {
      sizeScreen(tester);
      final changes = <DateTime>[];
      await tester.pumpWidget(
        app((_) => field(last: DateTime(2026, 11, 25), onChanged: changes.add)),
      );
      await tester.tap(box());
      await settle(tester);

      await tester.tap(
        find.widgetWithText(SmashPressable, '26'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        tester
            .widget<SmashButton>(find.widgetWithText(SmashButton, '선택'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.widgetWithText(SmashPressable, '25'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SmashButton, '선택'));
      await settle(tester);

      expect(changes, [DateTime(2026, 11, 25)]);
    });

    testWidgets('isDayEnabled가 시트까지 전달된다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app((_) => field(enabled: (d) => d.weekday != DateTime.sunday)),
      );
      await tester.tap(box());
      await settle(tester);

      await tester.tap(
        find.widgetWithText(SmashPressable, '22'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        tester
            .widget<SmashButton>(find.widgetWithText(SmashButton, '선택'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('비활성이면 눌러도 시트가 열리지 않고 글자와 아이콘이 흐리다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app((_) => field(isEnabled: false, value: DateTime(2026, 11, 20))),
      );

      await tester.tap(box(), warnIfMissed: false);
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      expect(
        tester.widget<Text>(find.text(f(2026, 11, 20))).style!.color,
        SmashColors.textDisabled,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.calendar_today_outlined)).color,
        SmashColors.textDisabled,
      );
    });

    testWidgets('오류: 칸 아래에 아이콘과 문구가 붙고 테두리가 빨갛게 두꺼워진다. 도움말 문구는 오류가 있으면 사라진다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app((_) => field(helper: '마감 전에 정해 주세요')));
      expect(find.text('마감 전에 정해 주세요'), findsOneWidget);
      BoxDecoration deco() =>
          (tester
                  .widget<Container>(
                    find
                        .descendant(of: box(), matching: find.byType(Container))
                        .first,
                  )
                  .decoration
              as BoxDecoration);
      expect((deco().border as Border).top.color, SmashColors.border);
      expect((deco().border as Border).top.width, 1);

      await tester.pumpWidget(
        app((_) => field(helper: '마감 전에 정해 주세요', error: '시작일을 골라 주세요')),
      );
      expect(find.text('시작일을 골라 주세요'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('마감 전에 정해 주세요'), findsNothing);
      expect((deco().border as Border).top.color, SmashColors.danger);
      expect((deco().border as Border).top.width, 2);
    });

    testWidgets('스크린리더: "라벨, 값"(없으면 "선택 안 함")을 버튼으로 읽고, 오류는 바로 읽는다', (
      tester,
    ) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app((_) => field()));
      expect(find.bySemanticsLabel('시작일, 선택 안 함'), findsOneWidget);
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시작일, 선택 안 함'),
        ).flagsCollection.isButton,
        isTrue,
      );
      expect(
        semanticsOf(tester, find.bySemanticsLabel('시작일, 선택 안 함')).hint,
        '눌러서 날짜를 선택해요',
      );

      await tester.pumpWidget(
        app(
          (_) => field(
            value: DateTime(2026, 11, 20),
            error: '시작일을 골라 주세요',
            helper: '직접 쓴 도움말',
          ),
        ),
      );
      expect(find.bySemanticsLabel('시작일, ${f(2026, 11, 20)}'), findsOneWidget);
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시작일, ${f(2026, 11, 20)}'),
        ).hint,
        '직접 쓴 도움말',
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('오류: 시작일을 골라 주세요'),
        ).flagsCollection.isLiveRegion,
        isTrue,
      );

      await tester.pumpWidget(app((_) => field(isEnabled: false)));
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시작일, 선택 안 함'),
        ).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('칸 높이는 52 이상(터치 영역 48 이상)이고 가로 폭을 모두 쓴다', (tester) async {
      sizeScreen(tester, size: const Size(320, 800));
      await tester.pumpWidget(app((_) => field()));

      final size = tester.getSize(box());
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, 320);
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('폭 320 + 글자 $scale배 + 긴 라벨과 연도가 붙은 값: 넘치지 않는다', (
        tester,
      ) async {
        sizeScreen(tester, size: const Size(320, 800));
        await tester.pumpWidget(
          app(
            (_) => field(
              label: '신청서를 받기 시작하는 날짜',
              value: DateTime(2027, 1, 5),
              error: '시작일은 마감일보다 앞이어야 해요',
            ),
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(box()).height, greaterThanOrEqualTo(52));
      });
    }
  });
}
