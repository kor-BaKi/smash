import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/format/ko_date_format.dart';
import 'package:app/core/rules/deadline_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime(2026, 11, 11, 14, 52, 10);
final _today = DateTime(2026, 11, 11);
final _last = DateTime(2027, 12, 31);

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

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 2000)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

SmashDateTimeConstraints constraintsAt(
  DateTime now, {
  DateTime? initial,
  bool withInitial = true,
  DateTime? notBefore,
}) {
  final rules = DeadlineRules(now, notBefore: notBefore);
  return SmashDateTimeConstraints(
    firstDate: rules.firstSelectableDate,
    lastDate: _last,
    isSelectable: rules.isSelectable,
    initialValue: withInitial ? (initial ?? rules.initialValue) : null,
    presets: rules.presets(),
  );
}

String fmt(DateTime v) => KoDateFormat.dateTime(v, now: _today);
DateTime d(int month, int day, int h, int m) =>
    DateTime(2026, month, day, h, m);

void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  SemanticsData semanticsOf(WidgetTester tester, Finder f) =>
      tester.getSemantics(f).getSemanticsData();
  Finder day(String n) => find.widgetWithText(SmashPressable, n);
  Finder chip(String label) => find.widgetWithText(SmashChip, label);
  Finder confirm() => find.widgetWithText(SmashButton, '확인');
  Finder summary(DateTime v) => find.text('선택한 시각: ${fmt(v)}');
  Finder hourCell() => find.byWidgetPredicate(
    (w) => w is SmashPressable && (w.semanticLabel ?? '').startsWith('시 선택'),
  );
  Finder minuteCell() => find.byWidgetPredicate(
    (w) => w is SmashPressable && (w.semanticLabel ?? '').startsWith('분 선택'),
  );
  Finder hourRow(String label) => find.byWidgetPredicate(
    (w) => w is SmashPressable && w.semanticLabel == label,
  );

  group('showSmashDateTimePicker', () {
    late BuildContext ctx;
    Future<void> pump(
      WidgetTester tester, {
      double textScale = 1.0,
      Size? size,
    }) async {
      sizeScreen(tester, size: size ?? const Size(400, 2000));
      await tester.pumpWidget(
        app((c) {
          ctx = c;
          return const SizedBox();
        }, textScale: textScale),
      );
    }

    Future<SmashDateTimeChoice?> open(
      SmashDateTimeConstraints c, {
      bool manual = false,
      String title = '마감 시각',
    }) => showSmashDateTimePicker(
      context: ctx,
      constraints: c,
      allowManualClose: manual,
      title: title,
      today: _today,
    );

    testWidgets('열리면 제목, 프리셋 칩, 달력, 시간, 요약이 보이고 처음 값은 지금을 5분 올린 14:55다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);

      expect(find.text('마감 시각'), findsOneWidget);
      expect(chip('오늘 밤'), findsOneWidget);
      expect(chip('내일 오후'), findsOneWidget);
      expect(chip('3일 뒤'), findsOneWidget);
      expect(chip('1주일 뒤'), findsOneWidget);
      expect(find.text('2026년 11월'), findsOneWidget);
      expect(find.text('2시'), findsOneWidget);
      expect(find.text('55분'), findsOneWidget);
      expect(summary(d(11, 11, 14, 55)), findsOneWidget);
      expect(
        tester
            .widget<SmashSegmentedControl<bool>>(
              find.byType(SmashSegmentedControl<bool>),
            )
            .selected,
        isTrue,
      );
      expect(confirm(), findsOneWidget);
    });

    testWidgets('프리셋 칩을 누르면 날짜와 시간과 요약이 그 값으로 바뀌고 그 칩만 선택돼 보인다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);

      await tester.tap(chip('내일 오후'));
      await tester.pump();

      expect(summary(d(11, 12, 18, 0)), findsOneWidget);
      expect(find.text('6시'), findsOneWidget);
      expect(find.text('00분'), findsOneWidget);
      expect(tester.widget<SmashChip>(chip('내일 오후')).selected, isTrue);
      expect(tester.widget<SmashChip>(chip('오늘 밤')).selected, isFalse);
      expect(tester.widget<SmashChip>(chip('3일 뒤')).selected, isFalse);

      await tester.tap(chip('3일 뒤'));
      await tester.pump();
      expect(summary(d(11, 14, 18, 0)), findsOneWidget);
      expect(tester.widget<SmashChip>(chip('3일 뒤')).selected, isTrue);
      expect(tester.widget<SmashChip>(chip('내일 오후')).selected, isFalse);
    });

    testWidgets('직접 바꾸면 칩 선택이 풀린다: 내일 오후 6:00에서 분을 1분만 바꿔도 칩은 선택되지 않는다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);
      await tester.tap(chip('내일 오후'));
      await tester.pump();

      await tester.tap(minuteCell());
      await tester.pump();
      await tester.scrollUntilVisible(
        hourRow('1분'),
        100,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(hourRow('1분'));
      await tester.pump();

      expect(summary(d(11, 12, 18, 1)), findsOneWidget);
      expect(tester.widget<SmashChip>(chip('내일 오후')).selected, isFalse);
    });

    testWidgets('초기값이 프리셋과 같으면 처음부터 그 칩이 선택돼 있다', (tester) async {
      await pump(tester);
      open(constraintsAt(_now, initial: d(11, 12, 18, 0)));
      await settle(tester);

      expect(tester.widget<SmashChip>(chip('내일 오후')).selected, isTrue);
    });

    testWidgets('오늘 밤 칩은 21:30 이후에는 보이지 않는다 (경계)', (tester) async {
      await pump(tester);
      open(constraintsAt(DateTime(2026, 11, 11, 21, 29, 59, 999)));
      await settle(tester);
      expect(chip('오늘 밤'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      open(constraintsAt(DateTime(2026, 11, 11, 21, 30)));
      await settle(tester);
      expect(chip('오늘 밤'), findsNothing);
      expect(chip('내일 오후'), findsOneWidget);
    });

    testWidgets('프리셋이 없으면 칩 줄이 없다', (tester) async {
      await pump(tester);
      final c = constraintsAt(_now);
      open(
        SmashDateTimeConstraints(
          firstDate: c.firstDate,
          lastDate: c.lastDate,
          isSelectable: c.isSelectable,
          initialValue: c.initialValue,
        ),
      );
      await settle(tester);

      expect(find.byType(SmashChip), findsNothing);
    });

    testWidgets('날짜를 바꾸면 시간은 그대로이고 보정 안내가 없다 (내일 14:55)', (tester) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);

      await tester.tap(day('12'));
      await tester.pump();

      expect(summary(d(11, 12, 14, 55)), findsOneWidget);
      expect(find.textContaining('맞췄어요'), findsNothing);
    });

    testWidgets(
      'E1: 내일 오후 3:10을 골랐다가 날짜를 오늘로 바꾸면(지금 15:20) 15:21로 맞추고 그 사실을 알린다',
      (tester) async {
        await pump(tester);
        open(
          constraintsAt(
            DateTime(2026, 11, 11, 15, 20),
            initial: d(11, 12, 15, 10),
          ),
        );
        await settle(tester);
        expect(summary(d(11, 12, 15, 10)), findsOneWidget);

        await tester.tap(day('11'));
        await tester.pump();

        expect(summary(d(11, 11, 15, 21)), findsOneWidget);
        expect(
          find.text(
            '그날은 지난 시간이라 ${KoDateFormat.time(d(11, 11, 15, 21))}으로 맞췄어요',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('보정 안내는 시간을 직접 바꾸면 사라진다', (tester) async {
      await pump(tester);
      open(
        constraintsAt(
          DateTime(2026, 11, 11, 15, 20),
          initial: d(11, 12, 15, 10),
        ),
      );
      await settle(tester);
      await tester.tap(day('11'));
      await tester.pump();
      expect(find.textContaining('맞췄어요'), findsOneWidget);

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(hourRow('오후 5시'));
      await tester.pump();

      expect(find.textContaining('맞췄어요'), findsNothing);
      expect(summary(d(11, 11, 17, 21)), findsOneWidget);
    });

    testWidgets('날짜를 오전 시간대에서 오늘로 바꾸면(오늘 오전은 모두 지남) 오후의 처음 고를 수 있는 시각으로 간다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now, initial: d(11, 12, 9, 10)));
      await settle(tester);

      await tester.tap(day('11'));
      await tester.pump();

      expect(summary(d(11, 11, 14, 53)), findsOneWidget);
      expect(find.textContaining('맞췄어요'), findsOneWidget);
    });

    testWidgets('D10: 오늘 하루 전체가 지났으면 달력에서 오늘을 못 고르고 첫 날짜는 내일이다 (지금 23:59:10)', (
      tester,
    ) async {
      await pump(tester);
      open(
        constraintsAt(DateTime(2026, 11, 11, 23, 59, 10), withInitial: false),
      );
      await settle(tester);

      expect(
        summary(d(11, 12, 9, 0)),
        findsOneWidget,
        reason: '처음 값 = 내일 오전 9시',
      );
      final before = find.textContaining('선택한 시각').evaluate().length;
      await tester.tap(day('11'), warnIfMissed: false);
      await tester.pump();
      expect(
        summary(d(11, 12, 9, 0)),
        findsOneWidget,
        reason: '오늘을 눌러도 바뀌지 않는다',
      );
      expect(find.textContaining('선택한 시각').evaluate().length, before);
    });

    testWidgets(
      '범위 중간에 고를 수 없는 날(13일)이 있으면 달력에서 눌러도 선택되지 않는다 (날짜별 비활성은 제약의 판정을 따른다)',
      (tester) async {
        await pump(tester);
        open(
          SmashDateTimeConstraints(
            firstDate: _today,
            lastDate: _last,
            isSelectable: (t) => t.day != 13 && !t.isBefore(_now),
            initialValue: d(11, 12, 18, 0),
          ),
        );
        await settle(tester);

        await tester.tap(day('13'), warnIfMissed: false);
        await tester.pump();
        expect(summary(d(11, 12, 18, 0)), findsOneWidget);

        await tester.tap(day('14'));
        await tester.pump();
        expect(summary(d(11, 14, 18, 0)), findsOneWidget);
      },
    );

    testWidgets('날짜를 바꿔도 오전 12시(00:30)와 오후 12시(12:30)는 그대로다', (tester) async {
      await pump(tester);
      open(constraintsAt(_now, initial: d(11, 12, 0, 30)));
      await settle(tester);
      await tester.tap(day('13'));
      await tester.pump();
      expect(summary(d(11, 13, 0, 30)), findsOneWidget);
      expect(find.textContaining('맞췄어요'), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      open(constraintsAt(_now, initial: d(11, 12, 12, 30)));
      await settle(tester);
      await tester.tap(day('13'));
      await tester.pump();
      expect(summary(d(11, 13, 12, 30)), findsOneWidget);
      expect(find.textContaining('맞췄어요'), findsNothing);
    });

    testWidgets(
      '보정 경계: 지금 15:20:30이면 내일 15:21은 오늘로 바꿔도 그대로(안내 없음), 15:20은 15:21로 맞추고 안내한다',
      (tester) async {
        await pump(tester);
        final now = DateTime(2026, 11, 11, 15, 20, 30);
        open(constraintsAt(now, initial: d(11, 12, 15, 21)));
        await settle(tester);
        await tester.tap(day('11'));
        await tester.pump();
        expect(summary(d(11, 11, 15, 21)), findsOneWidget);
        expect(find.textContaining('맞췄어요'), findsNothing);
        await tester.tap(find.byIcon(Icons.close));
        await settle(tester);

        open(constraintsAt(now, initial: d(11, 12, 15, 20)));
        await settle(tester);
        await tester.tap(day('11'));
        await tester.pump();
        expect(summary(d(11, 11, 15, 21)), findsOneWidget);
        expect(find.textContaining('맞췄어요'), findsOneWidget);
      },
    );

    testWidgets(
      '초기값이 없으면 처음으로 고를 수 있는 날의 오전 9시, 오늘 오전이 지났으면 그날 처음으로 고를 수 있는 시각이다',
      (tester) async {
        await pump(tester);
        open(constraintsAt(DateTime(2026, 11, 11, 7, 30), withInitial: false));
        await settle(tester);
        expect(summary(d(11, 11, 9, 0)), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await settle(tester);

        open(constraintsAt(_now, withInitial: false));
        await settle(tester);
        expect(
          summary(d(11, 11, 14, 53)),
          findsOneWidget,
          reason: '지금 14:52이면 오늘 오전은 모두 지났다',
        );
      },
    );

    testWidgets('초기값이 지금보다 이르면(고를 수 없으면) 무시하고 처음 값으로 시작한다', (tester) async {
      await pump(tester);
      open(constraintsAt(_now, initial: d(11, 10, 9, 0)));
      await settle(tester);

      expect(summary(d(11, 11, 14, 53)), findsOneWidget);
    });

    testWidgets('시간 칸에서 시를 고르면 요약이 바뀐다', (tester) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(hourRow('오후 4시'));
      await tester.pump();

      expect(summary(d(11, 11, 16, 55)), findsOneWidget);
    });

    testWidgets('확인을 누르면 날짜와 시각(초 0)이 돌아온다', (tester) async {
      await pump(tester);
      final result = open(constraintsAt(_now));
      await settle(tester);

      await tester.tap(day('13'));
      await tester.pump();
      await tester.tap(confirm());
      await settle(tester);

      expect(
        find.byType(SmashSheetFrame),
        findsNothing,
        reason: '닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다',
      );
      final choice = await result;
      expect(choice, SmashDateTimeChoice.value(d(11, 13, 14, 55)));
      expect(choice!.value!.second, 0);
      expect(choice.isManual, isFalse);
    });

    testWidgets('닫기 버튼으로 닫으면 null이다', (tester) async {
      await pump(tester);
      final result = open(constraintsAt(_now));
      await settle(tester);
      await tester.tap(day('13'));

      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('바깥(배경)을 눌러도 닫히지 않는다 (C10/C13과 같은 규칙)', (tester) async {
      await pump(tester);
      var done = false;
      open(constraintsAt(_now)).then((_) => done = true);
      await settle(tester);

      await tester.tapAt(const Offset(200, 20));
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsOneWidget);
      expect(done, isFalse);
    });

    testWidgets('아래로 끌어서는 닫히지 않는다 (안쪽 시간 목록의 드래그와 겹치지 않게)', (tester) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);

      await tester.fling(find.text('2026년 11월'), const Offset(0, 600), 2500);
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsOneWidget);
    });

    testWidgets('시간 목록을 드래그해도 시트는 닫히지 않고 목록만 스크롤된다', (tester) async {
      await pump(tester, size: const Size(400, 1200));
      open(constraintsAt(_now, initial: d(11, 12, 9, 10)));
      await settle(tester);
      await tester.tap(minuteCell());
      await tester.pump();
      final inner = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      final before = inner.position.pixels;

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsOneWidget);
      expect(inner.position.pixels, greaterThan(before));
    });

    testWidgets('수동 종료: 허용하면 버튼이 보이고 누르면 manual이 돌아온다. 허용하지 않으면 버튼이 없다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now));
      await settle(tester);
      expect(find.text('수동으로 종료할래요'), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      final result = open(constraintsAt(_now), manual: true);
      await settle(tester);
      expect(find.text('수동으로 종료할래요'), findsOneWidget);
      await tester.tap(find.widgetWithText(SmashButton, '수동으로 종료할래요'));
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      final choice = await result;
      expect(choice!.isManual, isTrue);
      expect(choice.value, isNull);
    });

    testWidgets('모집 종료처럼 notBefore가 있으면 그 이전 날짜와 시각은 고를 수 없고 처음 값은 그 이후다', (
      tester,
    ) async {
      await pump(tester);
      open(constraintsAt(_now, notBefore: d(11, 20, 9, 1), withInitial: true));
      await settle(tester);

      expect(summary(d(11, 20, 9, 5)), findsOneWidget);
      await tester.tap(day('19'), warnIfMissed: false);
      await tester.pump();
      expect(summary(d(11, 20, 9, 5)), findsOneWidget, reason: '19일은 막혀 있다');
      await tester.tap(day('21'));
      await tester.pump();
      expect(summary(d(11, 21, 9, 5)), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('폭 320 + 글자 $scale배: 넘치지 않고 시트 안을 스크롤하면 확인까지 닿는다', (
        tester,
      ) async {
        await pump(tester, textScale: scale, size: const Size(320, 760));
        final result = open(constraintsAt(_now), manual: true);
        await settle(tester);

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          confirm(),
          300,
          scrollable: find
              .descendant(
                of: find.byType(SmashSheetFrame),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(confirm());
        await settle(tester);

        expect(find.byType(SmashSheetFrame), findsNothing);
        expect(await result, SmashDateTimeChoice.value(d(11, 11, 14, 55)));
      });
    }

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        '프리셋 칩 4개: 폭 320 + 글자 $scale배에서 넘치지 않고 모두 화면 안에 있으며 서로 겹치지 않고 눌린다',
        (tester) async {
          await pump(tester, textScale: scale, size: const Size(320, 1400));
          open(constraintsAt(_now));
          await settle(tester);

          expect(tester.takeException(), isNull);
          final labels = ['오늘 밤', '내일 오후', '3일 뒤', '1주일 뒤'];
          final rects = [for (final l in labels) tester.getRect(chip(l))];
          for (var k = 0; k < rects.length; k++) {
            expect(rects[k].left, greaterThanOrEqualTo(0), reason: labels[k]);
            expect(rects[k].right, lessThanOrEqualTo(320), reason: labels[k]);
            expect(
              rects[k].height,
              greaterThanOrEqualTo(40),
              reason: '터치 높이 ${labels[k]}',
            );
            for (var m = k + 1; m < rects.length; m++) {
              expect(
                rects[k].overlaps(rects[m]),
                isFalse,
                reason: '${labels[k]} / ${labels[m]}',
              );
            }
          }
          await tester.tap(chip('1주일 뒤'));
          await tester.pump();
          expect(summary(d(11, 18, 18, 0)), findsOneWidget);
          expect(tester.widget<SmashChip>(chip('1주일 뒤')).selected, isTrue);
        },
      );
    }

    testWidgets('스크린리더: 선택한 시각 요약은 바로 읽히고(liveRegion), 칩은 선택 여부를 알린다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      open(
        constraintsAt(
          DateTime(2026, 11, 11, 15, 20),
          initial: d(11, 12, 18, 0),
        ),
      );
      await settle(tester);

      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('선택한 시각: ${fmt(d(11, 12, 18, 0))}'),
        ).flagsCollection.isLiveRegion,
        isTrue,
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('내일 오후'),
        ).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('3일 뒤'),
        ).flagsCollection.isSelected,
        Tristate.isFalse,
      );

      handle.dispose();
    });

    testWidgets(
      '스크린리더: 보정 안내("그날은 지난 시간이라 오후 3:21으로 맞췄어요")는 바로 읽히고, 요약도 보정된 값으로 바뀐다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester);
        open(
          constraintsAt(
            DateTime(2026, 11, 11, 15, 20),
            initial: d(11, 12, 15, 10),
          ),
        );
        await settle(tester);

        await tester.tap(day('11'));
        await settle(tester);

        final notice = find.bySemanticsLabel(
          '그날은 지난 시간이라 ${KoDateFormat.time(d(11, 11, 15, 21))}으로 맞췄어요',
        );
        expect(
          semanticsOf(tester, notice).flagsCollection.isLiveRegion,
          isTrue,
        );
        expect(
          find.bySemanticsLabel('선택한 시각: ${fmt(d(11, 11, 15, 21))}'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );
  });

  group('SmashDateTimeField', () {
    var built = 0;
    Widget field({
      DateTime? value,
      ValueChanged<SmashDateTimeChoice>? onChanged,
      bool manual = false,
      bool isManual = false,
      String? error,
      String? helper,
      bool enabled = true,
      DateTime? now,
    }) => SmashDateTimeField(
      label: '마감 시각',
      value: value,
      isManual: isManual,
      allowManualClose: manual,
      onChanged: onChanged ?? (_) {},
      constraints: () {
        built++;
        return constraintsAt(now ?? _now);
      },
      errorText: error,
      helper: helper,
      enabled: enabled,
      today: _today,
    );

    Finder box() => find.byType(SmashPressable).first;
    setUp(() => built = 0);

    testWidgets(
      '값이 없으면 안내 문구, 있으면 "11월 11일 (수) 오후 3:30", 수동 종료면 "수동으로 종료"가 보인다',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app((_) => field()));
        expect(find.text('날짜와 시간을 선택해 주세요'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('날짜와 시간을 선택해 주세요')).style!.color,
          SmashColors.textSecondary,
        );

        await tester.pumpWidget(app((_) => field(value: d(11, 11, 15, 30))));
        expect(find.text(fmt(d(11, 11, 15, 30))), findsOneWidget);
        expect(find.text('11월 11일 (수) 오후 3:30'), findsOneWidget);

        await tester.pumpWidget(app((_) => field(isManual: true)));
        expect(find.text('수동으로 종료'), findsOneWidget);
      },
    );

    testWidgets('제약은 시트를 여는 순간에만, 열 때마다 새로 만들어진다 (그려질 때는 만들지 않는다)', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app((_) => field()));
      expect(built, 0);

      await tester.tap(box());
      await settle(tester);
      expect(built, 1);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);
      await tester.tap(box());
      await settle(tester);
      expect(built, 2);
    });

    testWidgets(
      '누르면 시트가 열리고 제목은 라벨이다. 확인하면 onChanged에 시각이 전달되고, 닫으면 전달되지 않는다',
      (tester) async {
        sizeScreen(tester);
        final changes = <SmashDateTimeChoice>[];
        await tester.pumpWidget(app((_) => field(onChanged: changes.add)));

        await tester.tap(box());
        await settle(tester);
        expect(
          find.descendant(
            of: find.byType(SmashSheetFrame),
            matching: find.text('마감 시각'),
          ),
          findsOneWidget,
        );
        await tester.tap(day('13'));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.close));
        await settle(tester);
        expect(changes, isEmpty);

        await tester.tap(box());
        await settle(tester);
        await tester.tap(day('13'));
        await tester.pump();
        await tester.tap(confirm());
        await settle(tester);

        expect(changes, [SmashDateTimeChoice.value(d(11, 13, 14, 55))]);
      },
    );

    testWidgets('수동 종료를 고르면 manual이 전달된다', (tester) async {
      sizeScreen(tester);
      final changes = <SmashDateTimeChoice>[];
      await tester.pumpWidget(
        app((_) => field(manual: true, onChanged: changes.add)),
      );

      await tester.tap(box());
      await settle(tester);
      await tester.tap(find.widgetWithText(SmashButton, '수동으로 종료할래요'));
      await settle(tester);

      expect(changes.single.isManual, isTrue);
    });

    testWidgets('비활성이면 눌러도 열리지 않는다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app((_) => field(enabled: false, value: d(11, 11, 15, 30))),
      );

      await tester.tap(box(), warnIfMissed: false);
      await settle(tester);

      expect(find.byType(SmashSheetFrame), findsNothing);
      expect(built, 0);
      expect(
        tester.widget<Text>(find.text(fmt(d(11, 11, 15, 30)))).style!.color,
        SmashColors.textDisabled,
      );
    });

    testWidgets('오류: 칸 아래에 아이콘과 문구, 빨간 두꺼운 테두리. 오류가 있으면 도움말은 사라진다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app((_) => field(helper: '지금보다 이후여야 해요', error: '마감 시각을 골라 주세요')),
      );

      expect(find.text('마감 시각을 골라 주세요'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('지금보다 이후여야 해요'), findsNothing);
      final border =
          (tester
                          .widget<Container>(
                            find
                                .descendant(
                                  of: box(),
                                  matching: find.byType(Container),
                                )
                                .first,
                          )
                          .decoration
                      as BoxDecoration)
                  .border
              as Border;
      expect(border.top.color, SmashColors.danger);
      expect(border.top.width, 2);
    });

    testWidgets(
      '스크린리더: "라벨, 값"(없으면 "선택 안 함", 수동 종료면 "수동으로 종료")을 버튼으로 읽고 오류는 바로 읽는다',
      (tester) async {
        sizeScreen(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app((_) => field()));
        expect(find.bySemanticsLabel('마감 시각, 선택 안 함'), findsOneWidget);
        expect(
          semanticsOf(
            tester,
            find.bySemanticsLabel('마감 시각, 선택 안 함'),
          ).flagsCollection.isButton,
          isTrue,
        );
        expect(
          semanticsOf(tester, find.bySemanticsLabel('마감 시각, 선택 안 함')).hint,
          '눌러서 날짜와 시간을 선택해요',
        );

        await tester.pumpWidget(app((_) => field(isManual: true)));
        expect(find.bySemanticsLabel('마감 시각, 수동으로 종료'), findsOneWidget);

        await tester.pumpWidget(
          app((_) => field(value: d(11, 11, 15, 30), error: '마감 시각을 골라 주세요')),
        );
        expect(
          find.bySemanticsLabel('마감 시각, ${fmt(d(11, 11, 15, 30))}'),
          findsOneWidget,
        );
        expect(
          semanticsOf(
            tester,
            find.bySemanticsLabel('오류: 마감 시각을 골라 주세요'),
          ).flagsCollection.isLiveRegion,
          isTrue,
        );
        handle.dispose();
      },
    );

    testWidgets('칸 높이는 52 이상이고, 폭 320 + 글자 2.0배 + 긴 값에서도 넘치지 않는다', (
      tester,
    ) async {
      sizeScreen(tester, size: const Size(320, 900));
      await tester.pumpWidget(
        app(
          (_) => field(
            value: DateTime(2027, 12, 31, 23, 59),
            error: '마감 시각은 지금보다 이후로 설정해 주세요',
          ),
          textScale: 2.0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(box()).height, greaterThanOrEqualTo(52));
    });
  });
}
