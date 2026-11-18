import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/rules/deadline_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';
import '../../../support/segment_label.dart';

final _now = DateTime(2026, 11, 11, 14, 52, 10);
final _rules = DeadlineRules(_now);

Widget app(
  Widget child, {
  double textScale = 1.0,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: SmashTheme.light(),
  builder: (context, a) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: a!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      // 다시 그릴 때마다 새 State가 만들어지게 한다 (같은 위치의 State가 재사용되면 이전 값이 남는다)
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: KeyedSubtree(key: UniqueKey(), child: child),
      ),
    ),
  ),
);

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 1200)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 값을 들고 있다가 바뀌면 다시 그리는 틀
class _Host extends StatefulWidget {
  const _Host({required this.initial, required this.log, this.disabledHint});

  final DateTime initial;
  final List<DateTime> log;
  final String? disabledHint;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late DateTime value = widget.initial;

  @override
  Widget build(BuildContext context) => SmashTimeFieldPicker(
    value: value,
    isSelectable: _rules.isSelectable,
    disabledHint: widget.disabledHint ?? '지금보다 이전이라 선택할 수 없어요',
    onChanged: (next) {
      widget.log.add(next);
      setState(() => value = next);
    },
  );
}

DateTime today(int h, int m) => DateTime(2026, 11, 11, h, m);
DateTime tomorrow(int h, int m) => DateTime(2026, 11, 12, h, m);

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder f) =>
      tester.getSemantics(f).getSemanticsData();
  Finder hourCell() => find.byWidgetPredicate(
    (w) =>
        w is SmashPressable &&
        w.semanticLabel != null &&
        w.semanticLabel!.startsWith('시 선택'),
  );
  Finder minuteCell() => find.byWidgetPredicate(
    (w) =>
        w is SmashPressable &&
        w.semanticLabel != null &&
        w.semanticLabel!.startsWith('분 선택'),
  );
  Finder list() => find.byType(ListView);

  /// 팝업 바깥(왼쪽 위 구석)을 눌러 닫는다
  Future<void> closeByOutsideTap(WidgetTester tester) async {
    await tester.tapAt(const Offset(2, 2));
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        100,
        scrollable: find.descendant(
          of: list(),
          matching: find.byType(Scrollable),
        ),
      );
  Future<void> revealAbove(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        -100,
        scrollable: find.descendant(
          of: list(),
          matching: find.byType(Scrollable),
        ),
      );
  Finder row(String semanticLabel) => find.byWidgetPredicate(
    (w) => w is SmashPressable && w.semanticLabel == semanticLabel,
  );

  group('표시', () {
    testWidgets('오후 3:30: 오후 토글이 선택되고 칸에 "3시", "30분"이 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));

      expect(find.text('3시'), findsOneWidget);
      expect(find.text('30분'), findsOneWidget);
      final toggle = tester.widget<SmashSegmentedControl<bool>>(
        find.byType(SmashSegmentedControl<bool>),
      );
      expect(toggle.selected, isTrue);
    });

    testWidgets('분은 두 자리로 보인다 (오전 12:05 → 오전, "12시", "05분")', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(0, 5), log: [])));

      expect(find.text('12시'), findsOneWidget);
      expect(find.text('05분'), findsOneWidget);
      expect(
        tester
            .widget<SmashSegmentedControl<bool>>(
              find.byType(SmashSegmentedControl<bool>),
            )
            .selected,
        isFalse,
      );
    });

    testWidgets('12:00은 오후 12시, 23:59는 오후 11시 59분', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(12, 0), log: [])));
      expect(find.text('12시'), findsOneWidget);
      expect(
        tester
            .widget<SmashSegmentedControl<bool>>(
              find.byType(SmashSegmentedControl<bool>),
            )
            .selected,
        isTrue,
      );

      await tester.pumpWidget(app(_Host(initial: tomorrow(23, 59), log: [])));
      expect(find.text('11시'), findsOneWidget);
      expect(find.text('59분'), findsOneWidget);
    });

    testWidgets('처음에는 목록이 닫혀 있다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));

      expect(list(), findsNothing);
    });
  });

  group('목록 열기와 닫기', () {
    testWidgets('시 칸을 누르면 시 목록(12줄)이, 분 칸을 누르면 분 목록(60줄)이 열리고 한 번에 하나만 열린다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));

      await tester.tap(hourCell());
      await tester.pump();
      expect(list(), findsOneWidget);
      expect(
        tester.widget<ListView>(list()).childrenDelegate.estimatedChildCount,
        12,
      );

      // 팝업이 열려 있는 동안 다른 칸을 눌러도(바깥 누르기로 취급) 팝업만 닫히고 분 목록은 열리지 않는다
      await tester.tap(minuteCell(), warnIfMissed: false);
      await tester.pump();
      expect(list(), findsNothing);

      await tester.tap(minuteCell());
      await tester.pump();
      expect(list(), findsOneWidget, reason: '한 번에 하나만 열려 있다');
      expect(
        tester.widget<ListView>(list()).childrenDelegate.estimatedChildCount,
        60,
      );
    });

    testWidgets('같은 칸을 다시 누르면 닫힌다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(hourCell());
      await tester.pump();

      expect(list(), findsNothing);
    });

    testWidgets('열릴 때 높이를 애니메이션하지 않는다: 첫 프레임에 이미 5줄 높이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));

      await tester.tap(hourCell());
      await tester.pump();

      expect(tester.getRect(list()).height, 5 * 48);
    });

    testWidgets('목록은 150ms 동안 나타나고(투명도), 동작 줄이기가 켜져 있으면 바로 보인다', (
      tester,
    ) async {
      sizeScreen(tester);
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(of: list(), matching: find.byType(Opacity)).first,
          )
          .opacity;

      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));
      await tester.tap(hourCell());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(opacity(), lessThan(1));
      await tester.pumpAndSettle();
      expect(opacity(), 1);

      await tester.pumpWidget(
        app(_Host(initial: tomorrow(9, 10), log: []), disableAnimations: true),
      );
      await tester.tap(hourCell());
      await tester.pump();
      expect(opacity(), 1);
    });
  });

  group('값 고르기', () {
    testWidgets('시 줄을 누르면 그 시가 선택되고 목록이 닫히며 같은 날의 시각이 전달된다 (분은 그대로)', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <DateTime>[];
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: log)));

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(row('오전 11시'));
      await tester.pump();

      expect(log, [tomorrow(11, 10)]);
      expect(list(), findsNothing);
      expect(find.text('11시'), findsOneWidget);
    });

    testWidgets('분 줄을 누르면 그 분이 선택되고 목록이 닫힌다 (시는 그대로)', (tester) async {
      sizeScreen(tester);
      final log = <DateTime>[];
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: log)));

      await tester.tap(minuteCell());
      await tester.pump();
      await reveal(tester, row('45분'));
      await tester.tap(row('45분'));
      await tester.pump();

      expect(log, [tomorrow(9, 45)]);
      expect(list(), findsNothing);
      expect(find.text('45분'), findsOneWidget);
    });

    testWidgets(
      'E2: 지금 14:52에서 오후 3:30을 두고 오후 2시를 누르면 14:30은 지났으므로 분이 53으로 보정된다',
      (tester) async {
        sizeScreen(tester);
        final log = <DateTime>[];
        await tester.pumpWidget(app(_Host(initial: today(15, 30), log: log)));

        await tester.tap(hourCell());
        await tester.pump();
        await tester.tap(row('오후 2시'));
        await tester.pump();

        expect(log, [today(14, 53)]);
        expect(find.text('53분'), findsOneWidget);
      },
    );

    testWidgets('고를 수 없는 줄은 눌러도 아무 일도 없고 목록이 닫히지 않는다 (오늘 오후 1시, 오후 2시 40분)', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <DateTime>[];
      await tester.pumpWidget(app(_Host(initial: today(14, 55), log: log)));

      await tester.tap(hourCell());
      await tester.pump();
      await revealAbove(tester, row('오후 1시'));
      // 일부만 보이는 가장자리를 누르면 팝업 바깥을 누른 것이 되므로, 줄 전체가 보이게 한 뒤 누른다
      await tester.ensureVisible(row('오후 1시'));
      await tester.pump();
      await tester.tap(row('오후 1시'), warnIfMissed: false);
      await tester.pump();
      expect(log, isEmpty);
      expect(list(), findsOneWidget);

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(minuteCell());
      await tester.pump();
      await revealAbove(tester, row('40분'));
      // 일부만 보이는 가장자리를 누르면 팝업 바깥을 누른 것이 되므로, 줄 전체가 보이게 한 뒤 누른다
      await tester.ensureVisible(row('40분'));
      await tester.pump();
      await tester.tap(row('40분'), warnIfMissed: false);
      await tester.pump();
      expect(log, isEmpty);
      expect(list(), findsOneWidget);
    });

    testWidgets('오전/오후 토글: 오늘은 오전이 비활성이라 눌러도 바뀌지 않고, 내일은 오전/오후 모두 바뀐다', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <DateTime>[];
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: log)));

      await tester.tap(segmentLabel('오전'), warnIfMissed: false);
      await tester.pump();
      expect(log, isEmpty);

      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: log)));
      await tester.pumpAndSettle();
      await tester.tap(segmentLabel('오후'));
      await tester.pump();
      expect(log, [tomorrow(21, 10)]);
      await tester.tap(segmentLabel('오전'));
      await tester.pump();
      expect(log, [tomorrow(21, 10), tomorrow(9, 10)]);
    });

    testWidgets('날짜 부분이 규칙에 쓰인다: 같은 14:30도 오늘은 못 고르고 내일은 고를 수 있다', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <DateTime>[];
      await tester.pumpWidget(app(_Host(initial: tomorrow(15, 30), log: log)));

      await tester.tap(hourCell());
      await tester.pump();
      await tester.tap(row('오후 2시'));
      await tester.pump();

      expect(log, [tomorrow(14, 30)], reason: '내일 14:30은 보정 없이 고른다');
    });

    testWidgets('햅틱: 줄을 고르면 selectionClick, 비활성 줄은 울리지 않는다', (tester) async {
      sizeScreen(tester);
      final haptics = captureHaptics(tester);
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));

      await tester.tap(hourCell());
      await tester.pump();
      await revealAbove(tester, row('오후 1시'));
      await tester.tap(row('오후 1시'), warnIfMissed: false);
      await tester.pump();
      expect(haptics, isEmpty);
      await tester.tap(row('오후 4시'));
      await tester.pump();

      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });
  });

  group('열릴 때 위치', () {
    Rect listRect(WidgetTester tester) => tester.getRect(list());

    testWidgets('고른 값이 보이는 위치에서 열린다: 시 목록에서 9시, 분 목록에서 53분', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 53), log: [])));

      await tester.tap(hourCell());
      await tester.pump();
      expect(listRect(tester).contains(tester.getCenter(row('오전 9시'))), isTrue);

      await closeByOutsideTap(tester);
      await tester.tap(minuteCell());
      await tester.pump();
      expect(listRect(tester).contains(tester.getCenter(row('53분'))), isTrue);
    });

    testWidgets('고른 값이 아래쪽(12시)이어도 보이고 위쪽(1시)도 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(0, 10), log: [])));
      await tester.tap(hourCell());
      await tester.pump();
      expect(
        listRect(tester).contains(tester.getCenter(row('오전 12시'))),
        isTrue,
      );

      await tester.pumpWidget(app(_Host(initial: tomorrow(1, 10), log: [])));
      await tester.pumpAndSettle();
      await tester.tap(hourCell());
      await tester.pump();
      expect(listRect(tester).contains(tester.getCenter(row('오전 1시'))), isTrue);
    });

    testWidgets(
      '고른 값을 지금 고를 수 없으면 처음으로 고를 수 있는 값이 보인다 (오늘 오후 2시 30분 → 분 목록은 53분)',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app(_Host(initial: today(14, 30), log: [])));

        await tester.tap(minuteCell());
        await tester.pump();

        expect(listRect(tester).contains(tester.getCenter(row('53분'))), isTrue);
      },
    );

    testWidgets('고른 시가 지났다면(오늘 오후 1시) 시 목록은 처음 고를 수 있는 시(2시)가 보이게 열린다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: today(13, 0), log: [])));

      await tester.tap(hourCell());
      await tester.pump();

      expect(listRect(tester).contains(tester.getCenter(row('오후 2시'))), isTrue);
    });
  });

  group('모양과 크기', () {
    testWidgets('목록은 5줄 높이이고 한 줄은 48 이상이다. 줄과 칸의 터치 영역도 48 이상이다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: tomorrow(9, 10), log: [])));
      expect(tester.getSize(hourCell()).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(minuteCell()).height, greaterThanOrEqualTo(48));

      await tester.tap(hourCell());
      await tester.pump();
      expect(tester.getRect(list()).height, 5 * 48);
      expect(tester.getSize(row('오전 9시')).height, 48);
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets(
        '글자 $scale배: 줄이 줄어들지 않고 (2.0배는 높아지며), 목록 높이는 5줄이고, 넘치지 않는다 (폭 320)',
        (tester) async {
          sizeScreen(tester, size: const Size(320, 1400));
          await tester.pumpWidget(
            app(
              _Host(initial: tomorrow(9, 10), log: []),
              textScale: scale,
            ),
          );
          await tester.tap(hourCell());
          await tester.pump();

          expect(tester.takeException(), isNull);
          final rowHeight = tester.getSize(row('오전 9시')).height;
          final expected = [
            48.0,
            16 * scale * 1.5 + 16,
          ].reduce((a, b) => a > b ? a : b);
          expect(
            rowHeight,
            closeTo(expected, 0.01),
            reason: '줄 높이 = max(48, 글자 줄 높이 + 위아래 여백)',
          );
          expect(rowHeight, greaterThanOrEqualTo(48));
          if (scale >= 2.0) {
            expect(rowHeight, greaterThan(48), reason: '글자가 커지면 줄이 높아진다');
          }
          expect(tester.getRect(list()).height, closeTo(5 * rowHeight, 0.01));
          // 줄의 글자가 줄 높이 안에 들어간다
          expect(
            tester
                .getSize(
                  find.descendant(of: row('오전 9시'), matching: find.text('9시')),
                )
                .height,
            lessThanOrEqualTo(rowHeight),
          );
        },
      );
    }

    testWidgets('글자 2.0배 + 폭 320에서는 토글이 시, 분 칸과 한 줄에 안 들어가 아래 줄로 내려간다', (
      tester,
    ) async {
      sizeScreen(tester, size: const Size(320, 1400));
      await tester.pumpWidget(
        app(_Host(initial: tomorrow(9, 10), log: []), textScale: 2.0),
      );

      final toggle = tester.getRect(find.byType(SmashSegmentedControl<bool>));
      final cell = tester.getRect(hourCell());
      expect(toggle.top, isNot(closeTo(cell.top, 1)), reason: '같은 줄이 아니다');
      expect(tester.takeException(), isNull);
    });
  });

  group('목록 스크롤', () {
    testWidgets('목록을 드래그하면 목록이 스크롤되고 열린 채로 있다. 바깥 화면은 움직이지 않는다', (
      tester,
    ) async {
      sizeScreen(tester, size: const Size(400, 600));
      await tester.pumpWidget(
        app(
          Column(
            children: [
              _Host(initial: tomorrow(9, 10), log: []),
              const SizedBox(height: 1500),
            ],
          ),
        ),
      );
      await tester.tap(minuteCell());
      await tester.pump();
      final outer = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final inner = tester.state<ScrollableState>(
        find.descendant(of: list(), matching: find.byType(Scrollable)),
      );
      final innerBefore = inner.position.pixels;

      await tester.drag(list(), const Offset(0, -150));
      await tester.pump();

      expect(inner.position.pixels, greaterThan(innerBefore));
      expect(outer.position.pixels, 0, reason: '바깥 화면은 그대로');
      expect(list(), findsOneWidget);
    });

    testWidgets(
      '목록 끝에서는 튕기지 않는다 (Clamping): 맨 위에서 아래로 끌어도 위치가 0보다 작아지지 않고 바깥 화면도 움직이지 않는다',
      (tester) async {
        sizeScreen(tester, size: const Size(400, 600));
        await tester.pumpWidget(
          app(
            Column(
              children: [
                _Host(initial: tomorrow(1, 0), log: []),
                const SizedBox(height: 1500),
              ],
            ),
          ),
        );
        await tester.tap(hourCell());
        await tester.pump();
        final inner = tester.state<ScrollableState>(
          find.descendant(of: list(), matching: find.byType(Scrollable)),
        );
        expect(inner.position.physics, isA<ClampingScrollPhysics>());
        final outer = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );

        await tester.drag(list(), const Offset(0, 300));
        await tester.pump();

        expect(inner.position.pixels, 0);
        expect(outer.position.pixels, 0);
      },
    );
  });

  group('접근성', () {
    testWidgets('칸은 "시 선택, 현재 오후 3시", "분 선택, 현재 30분"으로 읽히고 열림 상태를 알린다', (
      tester,
    ) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));

      expect(find.bySemanticsLabel('시 선택, 현재 오후 3시'), findsOneWidget);
      expect(find.bySemanticsLabel('분 선택, 현재 30분'), findsOneWidget);
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시 선택, 현재 오후 3시'),
        ).flagsCollection.isButton,
        isTrue,
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시 선택, 현재 오후 3시'),
        ).flagsCollection.isExpanded,
        Tristate.isFalse,
      );

      await tester.tap(hourCell());
      await tester.pump();
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('시 선택, 현재 오후 3시'),
        ).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets(
      '줄은 "오후 3시", "30분"처럼 읽히고 고른 줄은 selected, 고를 수 없는 줄은 비활성과 이유를 읽는다',
      (tester) async {
        sizeScreen(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          app(
            _Host(
              initial: today(15, 30),
              log: [],
              disabledHint: '지금보다 이전이라 선택할 수 없어요',
            ),
          ),
        );

        await tester.tap(hourCell());
        await tester.pump();
        final selected = semanticsOf(tester, find.bySemanticsLabel('오후 3시'));
        expect(selected.flagsCollection.isSelected, Tristate.isTrue);
        expect(selected.flagsCollection.isEnabled, Tristate.isTrue);

        await revealAbove(tester, find.bySemanticsLabel('오후 1시'));
        final disabled = semanticsOf(tester, find.bySemanticsLabel('오후 1시'));
        expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
        expect(disabled.hint, '지금보다 이전이라 선택할 수 없어요');
        expect(
          semanticsOf(tester, find.bySemanticsLabel('오후 4시')).hint,
          isEmpty,
        );

        await closeByOutsideTap(tester);
        await tester.tap(minuteCell());
        await tester.pump();
        expect(find.bySemanticsLabel('30분'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('목록이 열린 직후(나타나는 150ms 동안, 투명도 0)에도 줄이 스크린리더에 잡힌다', (
      tester,
    ) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));

      await tester.tap(hourCell());
      await tester.pump(); // 애니메이션이 막 시작한 첫 프레임: 투명도 0
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: list(), matching: find.byType(Opacity)).first,
            )
            .opacity,
        lessThan(1),
      );

      expect(find.bySemanticsLabel('오후 3시'), findsOneWidget);
      expect(find.bySemanticsLabel('오후 4시'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('오전 토글이 비활성일 때(오늘 오후) 스크린리더에도 비활성으로 읽힌다', (tester) async {
      sizeScreen(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));

      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('오전'),
        ).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('색에만 의존하지 않는다: 고른 줄은 체크 아이콘과 굵은 글자, 고를 수 없는 줄은 흐린 글자다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(_Host(initial: today(15, 30), log: [])));
      await tester.tap(hourCell());
      await tester.pump();

      expect(
        find.descendant(of: row('오후 3시'), matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row('오후 4시'), matching: find.byIcon(Icons.check)),
        findsNothing,
      );
      final selectedText = tester.widget<Text>(
        find.descendant(of: row('오후 3시'), matching: find.text('3시')),
      );
      final plainText = tester.widget<Text>(
        find.descendant(of: row('오후 4시'), matching: find.text('4시')),
      );
      expect(
        selectedText.style!.fontWeight,
        isNot(plainText.style!.fontWeight),
      );
      await revealAbove(tester, row('오후 1시'));
      final disabledText = tester.widget<Text>(
        find.descendant(of: row('오후 1시'), matching: find.text('1시')),
      );
      expect(disabledText.style!.color, SmashColors.textDisabled);
    });
  });
}
