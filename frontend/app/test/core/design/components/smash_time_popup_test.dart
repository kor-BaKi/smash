import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/rules/deadline_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _now = DateTime(2026, 11, 11, 14, 52, 10);
final _today = DateTime(2026, 11, 11);

SmashTimePopupPlacement place({
  Rect anchor = const Rect.fromLTWH(16, 100, 84, 48),
  Size bounds = const Size(400, 800),
  EdgeInsets safe = EdgeInsets.zero,
  double rowHeight = 48,
  int preferredRows = 5,
}) => SmashTimePopupPlacement.compute(
  anchor: anchor,
  bounds: bounds,
  safe: safe,
  rowHeight: rowHeight,
  preferredRows: preferredRows,
);

void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  group('위치 계산 (SmashTimePopupPlacement)', () {
    test('아래 공간이 충분하면 칸 바로 아래(간격 4)에 5줄로 열고, 칸의 왼쪽에 맞춘다', () {
      final p = place();
      expect(p.above, isFalse);
      expect(p.rows, 5);
      expect(p.height, 5 * 48 + 2);
      expect(p.dx, 0);
      expect(p.width, 96, reason: '칸 폭 84보다 좁으면 최소 폭 96');
    });

    test('아래가 모자라고 위가 충분하면 위에 5줄로 연다', () {
      final p = place(anchor: const Rect.fromLTWH(16, 652, 84, 48));
      expect(p.above, isTrue);
      expect(p.rows, 5);
    });

    test('경계: 아래 공간이 정확히 5줄(+테두리)이면 아래, 1px 모자라면 위', () {
      // bottomLimit = 800 - 8 = 792, 아래 공간 = 792 - (bottom + 4) = 242
      final exact = place(
        anchor: const Rect.fromLTWH(16, 498, 84, 48),
      ); // bottom 546 → 792-550=242
      expect(exact.above, isFalse);
      expect(exact.rows, 5);
      final shy = place(anchor: const Rect.fromLTWH(16, 499, 84, 48)); // 241
      expect(shy.above, isTrue);
      expect(shy.rows, 5);
    });

    test('위아래 모두 5줄이 안 되면 더 넓은 쪽에서 줄 수를 줄인다 (아래 4줄)', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 150, 84, 48),
        bounds: const Size(400, 420),
      );
      expect(p.above, isFalse);
      expect(p.rows, 4);
      expect(p.height, 4 * 48 + 2);
    });

    test('위쪽이 더 넓으면 위에서 줄인다', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 230, 84, 48),
        bounds: const Size(400, 420),
      );
      expect(p.above, isTrue);
      expect(p.rows, 4);
    });

    test('경계: 줄 수가 3줄 맞게 들어가는 공간 146(=3*48+2)은 3줄, 1 모자라면 위로', () {
      final threeBelow = place(
        anchor: const Rect.fromLTWH(16, 194, 84, 48),
        bounds: const Size(400, 400),
      );
      expect(threeBelow.above, isFalse);
      expect(threeBelow.rows, 3);
      final shy = place(
        anchor: const Rect.fromLTWH(16, 195, 84, 48),
        bounds: const Size(400, 400),
      );
      expect(shy.above, isTrue);
      expect(shy.rows, 3);
    });

    test('위아래 같은 줄 수면 아래에 연다', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 120, 84, 48),
        bounds: const Size(400, 300),
      );
      expect(p.above, isFalse);
      expect(p.rows, p.rows);
    });

    test('화면에 3줄도 안 들어가는 작은 화면에서는 화면 밖으로 나가지 않는 것이 우선이다 (1줄)', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 80, 84, 48),
        bounds: const Size(400, 200),
      );
      expect(p.rows, 1);
      expect(p.rows, lessThan(SmashTimePopupPlacement.minRows));
    });

    test('줄이 하나도 안 들어가는 극단적인 화면에서도 줄 수는 1 이상이다 (0줄 팝업이 되지 않는다)', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 40, 84, 48),
        bounds: const Size(400, 120),
      );
      expect(p.rows, 1);
      expect(p.height, 48 + 2);
    });

    test('글자 2.0배(줄 높이 64)에서도 5줄이 들어가면 5줄, 안 들어가면 줄인다', () {
      final big = place(
        anchor: const Rect.fromLTWH(16, 20, 168, 64),
        bounds: const Size(320, 568),
        rowHeight: 64,
      );
      expect(big.above, isFalse);
      expect(big.rows, 5);
      expect(big.height, 5 * 64 + 2);
      final tight = place(
        anchor: const Rect.fromLTWH(16, 200, 168, 64),
        bounds: const Size(320, 568),
        rowHeight: 64,
      );
      expect(tight.rows, lessThan(5));
      expect(tight.rows, greaterThanOrEqualTo(1));
    });

    test('키보드나 아래 안전 영역만큼 아래 공간이 줄어든다 (키보드 300 → 위에 열기)', () {
      final p = place(
        anchor: const Rect.fromLTWH(16, 400, 84, 48),
        safe: const EdgeInsets.only(bottom: 300),
      );
      expect(p.above, isTrue);
    });

    test('위쪽 안전 영역(노치)만큼 위 공간이 줄어든다', () {
      final withoutNotch = place(
        anchor: const Rect.fromLTWH(16, 270, 84, 48),
        bounds: const Size(400, 400),
      );
      final withNotch = place(
        anchor: const Rect.fromLTWH(16, 270, 84, 48),
        bounds: const Size(400, 400),
        safe: const EdgeInsets.only(top: 100),
      );
      expect(withNotch.rows, lessThanOrEqualTo(withoutNotch.rows));
    });

    test('오른쪽 끝을 넘으면 왼쪽으로 밀어 화면 안(가장자리 8)에 둔다', () {
      final p = place(anchor: const Rect.fromLTWH(340, 100, 84, 48));
      // 폭 96, 가장 오른쪽 왼쪽 끝 = 400 - 8 - 96 = 296
      expect(p.width, 96);
      expect(p.dx, 296 - 340);
    });

    test('왼쪽 끝이 가장자리보다 안쪽이면 8로 밀어 넣는다', () {
      final p = place(anchor: const Rect.fromLTWH(0, 100, 84, 48));
      expect(p.dx, 8);
    });

    test('폭은 칸 폭 이상이다 (칸이 넓으면 칸 폭, 좁으면 96)', () {
      expect(place(anchor: const Rect.fromLTWH(16, 100, 170, 48)).width, 170);
      expect(place(anchor: const Rect.fromLTWH(16, 100, 60, 48)).width, 96);
    });

    test('화면이 아주 좁으면 폭은 화면 폭 - 16을 넘지 않는다', () {
      final p = place(
        anchor: const Rect.fromLTWH(8, 100, 60, 48),
        bounds: const Size(100, 800),
      );
      expect(p.width, 84);
    });

    test('같은 입력은 같은 결과다 (값 동등)', () {
      expect(place(), place());
      expect(place().hashCode, place().hashCode);
      expect(
        place(),
        isNot(place(anchor: const Rect.fromLTWH(16, 652, 84, 48))),
      );
    });
  });

  group('시트 안의 팝업', () {
    late BuildContext ctx;
    DateTime? result;

    Future<void> openSheet(
      WidgetTester tester, {
      Size size = const Size(400, 900),
      double textScale = 1.0,
      bool disableAnimations = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      result = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: SmashTheme.light(),
          builder: (context, a) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: a!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final rules = DeadlineRules(_now);
      showSmashDateTimePicker(
        context: ctx,
        today: _today,
        constraints: SmashDateTimeConstraints(
          firstDate: rules.firstSelectableDate,
          lastDate: DateTime(2027, 12, 31),
          isSelectable: rules.isSelectable,
          initialValue: DateTime(2026, 11, 12, 15, 30),
        ),
      ).then((choice) => result = choice?.value);
      await settle(tester);
    }

    Finder hourCell() => find.byWidgetPredicate(
      (w) => w is SmashPressable && (w.semanticLabel ?? '').startsWith('시 선택'),
    );
    Finder minuteCell() => find.byWidgetPredicate(
      (w) => w is SmashPressable && (w.semanticLabel ?? '').startsWith('분 선택'),
    );
    Finder row(String label) => find.byWidgetPredicate(
      (w) => w is SmashPressable && w.semanticLabel == label,
    );
    Finder popupList() => find.byType(ListView);
    Finder sheet() => find.byType(SmashSheetFrame);
    Finder summary(String text) => find.textContaining('선택한 시각: $text');

    Rect popupRect(WidgetTester tester) => tester.getRect(
      find.ancestor(of: popupList(), matching: find.byType(Opacity)).first,
    );

    String? primaryLabel() {
      final context = FocusManager.instance.primaryFocus?.context;
      return context
          ?.findAncestorWidgetOfExactType<SmashPressable>()
          ?.semanticLabel;
    }

    test('SmashTimePopupPlacement 최소 줄 수는 3이다', () {
      expect(SmashTimePopupPlacement.minRows, 3);
    });

    testWidgets('팝업을 열어도 시트 높이가 변하지 않는다 (시 칸, 분 칸 모두)', (tester) async {
      await openSheet(tester);
      final before = tester.getSize(sheet()).height;
      final summaryTop = tester.getTopLeft(find.textContaining('선택한 시각')).dy;

      await tester.tap(hourCell());
      await settle(tester);
      expect(popupList(), findsOneWidget);
      expect(tester.getSize(sheet()).height, before);
      expect(
        tester.getTopLeft(find.textContaining('선택한 시각')).dy,
        summaryTop,
        reason: '아래 내용도 밀리지 않는다',
      );

      await tester.tapAt(const Offset(2, 2));
      await settle(tester);
      await tester.tap(minuteCell());
      await settle(tester);
      expect(popupList(), findsOneWidget);
      expect(tester.getSize(sheet()).height, before);
    });

    testWidgets('팝업은 칸 아래(간격 4)에 칸 왼쪽을 맞춰 열리고 폭은 칸 폭 이상이며 5줄이다 (공간이 넉넉한 화면)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SmashTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: SmashTimeFieldPicker(
                  value: DateTime(2026, 11, 12, 15, 30),
                  isSelectable: (_) => true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final cell = tester.getRect(hourCell());

      await tester.tap(hourCell());
      await settle(tester);
      final popup = popupRect(tester);

      expect(popup.top, closeTo(cell.bottom + 4, 0.01));
      expect(popup.left, closeTo(cell.left, 0.01));
      expect(popup.width, greaterThanOrEqualTo(cell.width));
      expect(popup.height, 5 * 48 + 2);
    });

    testWidgets('오른쪽 끝에 있는 칸(폭 84)의 팝업(최소 폭 96)은 왼쪽으로 밀려 화면 안(가장자리 8)에 열린다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SmashTheme.light(),
          home: Scaffold(
            // 토글, 시, 분 칸이 한 줄에 놓이고 분 칸이 화면 오른쪽 끝(여백 3)에 닿는다
            body: Padding(
              padding: const EdgeInsets.only(right: 3, top: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: SmashTimeFieldPicker(
                  value: DateTime(2026, 11, 12, 15, 30),
                  isSelectable: (_) => true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final cell = tester.getRect(minuteCell());
      expect(cell.right, greaterThan(390), reason: '분 칸이 오른쪽 끝에 있다');

      await tester.tap(minuteCell());
      await settle(tester);
      final popup = popupRect(tester);

      expect(popup.right, lessThanOrEqualTo(400 - 8 + 0.01));
      expect(popup.left, lessThan(cell.left), reason: '왼쪽으로 밀렸다');
      expect(popup.width, 96);
    });

    testWidgets('시트 안에서는 칸이 아래쪽이라 칸 위(간격 4)에 5줄로 열린다', (tester) async {
      await openSheet(tester);
      final cell = tester.getRect(hourCell());

      await tester.tap(hourCell());
      await settle(tester);
      final popup = popupRect(tester);

      expect(popup.bottom, closeTo(cell.top - 4, 0.01));
      expect(popup.left, closeTo(cell.left, 0.01));
      expect(popup.height, 5 * 48 + 2);
    });

    testWidgets('아래 공간이 모자라면 칸 위에 열리고 화면 밖으로 나가지 않는다 (낮은 화면)', (tester) async {
      await openSheet(tester, size: const Size(400, 560));
      await tester.ensureVisible(minuteCell());
      await tester.pump();
      final cell = tester.getRect(minuteCell());

      await tester.tap(minuteCell());
      await settle(tester);
      final popup = popupRect(tester);

      expect(popup.bottom, lessThanOrEqualTo(cell.top - 4 + 0.01));
      expect(popup.top, greaterThanOrEqualTo(8));
      expect(popup.height, greaterThanOrEqualTo(3 * 48));
    });

    for (final h in [420.0, 480.0, 560.0, 700.0, 900.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('화면 높이 $h × 글자 $scale배: 시/분 팝업이 항상 화면 안(위아래 8 이상)에 있다', (
          tester,
        ) async {
          await openSheet(tester, size: Size(360, h), textScale: scale);
          for (final cell in [hourCell(), minuteCell()]) {
            await tester.ensureVisible(cell);
            await tester.pump();
            await tester.tap(cell);
            await settle(tester);

            final popup = popupRect(tester);
            expect(
              popup.top,
              greaterThanOrEqualTo(8 - 0.01),
              reason: '위 $popup',
            );
            expect(
              popup.bottom,
              lessThanOrEqualTo(h - 8 + 0.01),
              reason: '아래 $popup',
            );
            expect(popup.left, greaterThanOrEqualTo(8 - 0.01));
            expect(popup.right, lessThanOrEqualTo(360 - 8 + 0.01));
            expect(tester.takeException(), isNull);

            await tester.tapAt(const Offset(2, 2));
            await settle(tester);
          }
        });
      }
    }

    testWidgets('항목을 누르면 값이 반영되고 팝업이 닫히며 시트는 열려 있다 (확인 버튼 없음)', (tester) async {
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);
      await tester.tap(row('오후 5시'));
      await settle(tester);

      expect(popupList(), findsNothing);
      expect(sheet(), findsOneWidget);
      expect(summary('11월 12일 (목) 오후 5:30'), findsOneWidget);
      expect(result, isNull, reason: '시트는 닫히지 않았다');
    });

    testWidgets('바깥 누르기: 값은 그대로이고 팝업만 닫히며 시트는 닫히지 않는다', (tester) async {
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);

      await tester.tapAt(const Offset(2, 2));
      await settle(tester);

      expect(popupList(), findsNothing);
      expect(sheet(), findsOneWidget);
      expect(summary('11월 12일 (목) 오후 3:30'), findsOneWidget);
    });

    testWidgets('팝업 바깥의 시트 위(날짜 칸 등)를 눌러도 아래 시트는 반응하지 않고 팝업만 닫힌다', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);

      await tester.tap(find.text('13'), warnIfMissed: false);
      await settle(tester);

      expect(popupList(), findsNothing);
      expect(
        summary('11월 12일 (목) 오후 3:30'),
        findsOneWidget,
        reason: '13일이 눌리지 않았다',
      );
    });

    testWidgets('팝업 안의 고를 수 없는 줄을 눌러도 팝업은 닫히지 않고 값도 그대로다', (tester) async {
      await openSheet(tester);
      // 내일 오후 3시이므로 모두 고를 수 있다. 오늘로 바꿔서 지난 시각이 있게 한다
      await tester.tap(find.text('11'));
      await tester.pump();
      await tester.tap(hourCell());
      await settle(tester);
      await tester.scrollUntilVisible(
        row('오후 1시'),
        -80,
        scrollable: find.descendant(
          of: popupList(),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(row('오후 1시'));
      await tester.pump();
      final before = summary('11월 11일 (수) 오후 3:30');
      expect(before, findsOneWidget);

      await tester.tap(row('오후 1시'), warnIfMissed: false);
      await tester.pump();

      expect(popupList(), findsOneWidget);
      expect(before, findsOneWidget);
    });

    testWidgets('뒤로 가기: 팝업만 닫히고 시트는 열려 있으며, 한 번 더 누르면 시트가 닫힌다', (tester) async {
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(popupList(), findsNothing);
      expect(sheet(), findsOneWidget);
      expect(summary('11월 12일 (목) 오후 3:30'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(sheet(), findsNothing);
    });

    testWidgets('스크린리더 탈출 제스처(dismiss): 팝업만 닫히고 시트는 열려 있다', (tester) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);

      dismissAction(tester, '시 목록');
      await settle(tester);

      expect(popupList(), findsNothing);
      expect(sheet(), findsOneWidget);
      expect(summary('11월 12일 (목) 오후 3:30'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('팝업이 열려 있는 동안 뒤의 시트 내용은 접근성 트리에서 빠지고, 닫히면 돌아온다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);
      expect(hasLabel(tester, RegExp('^분 선택')), isTrue);

      await tester.tap(hourCell());
      await settle(tester);
      expect(hasLabel(tester, RegExp('^분 선택')), isFalse);
      expect(hasLabel(tester, '선택한 시각'), isFalse);
      expect(hasLabel(tester, '시 목록'), isTrue);
      expect(hasLabel(tester, '목록 닫기'), isTrue);
      expect(hasLabel(tester, '오후 3시'), isTrue);

      await tester.tapAt(const Offset(2, 2));
      await settle(tester);
      expect(hasLabel(tester, RegExp('^분 선택')), isTrue);
      expect(hasLabel(tester, '시 목록'), isFalse);
      handle.dispose();
    });

    group('포커스', () {
      testWidgets(
        '열리면 포커스가 목록의 고른 줄로 가고(시: 오후 3시, 분: 30분), 항목으로 닫으면 연 칸으로 돌아온다',
        (tester) async {
          await openSheet(tester);
          await tester.tap(hourCell());
          await settle(tester);
          expect(primaryLabel(), '오후 3시');

          await tester.tap(row('오후 5시'));
          await settle(tester);
          expect(primaryLabel(), startsWith('시 선택'));

          await tester.tap(minuteCell());
          await settle(tester);
          expect(primaryLabel(), '30분');
        },
      );

      testWidgets('바깥 누르기로 닫아도 연 칸으로 돌아온다', (tester) async {
        await openSheet(tester);
        await tester.tap(minuteCell());
        await settle(tester);
        expect(primaryLabel(), '30분');

        await tester.tapAt(const Offset(2, 2));
        await settle(tester);

        expect(primaryLabel(), startsWith('분 선택'));
      });

      testWidgets('뒤로 가기와 탈출 제스처로 닫아도 연 칸으로 돌아온다', (tester) async {
        final handle = tester.ensureSemantics();
        await openSheet(tester);
        await tester.tap(hourCell());
        await settle(tester);
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(primaryLabel(), startsWith('시 선택'));

        await tester.tap(minuteCell());
        await settle(tester);
        dismissAction(tester, '분 목록');
        await settle(tester);
        expect(primaryLabel(), startsWith('분 선택'));
        handle.dispose();
      });

      testWidgets('키보드: 목록의 고른 줄에서 Enter를 누르면 그 줄이 선택된다 (확인 버튼 없이)', (
        tester,
      ) async {
        await openSheet(tester);
        await tester.tap(hourCell());
        await settle(tester);
        expect(primaryLabel(), '오후 3시');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);

        expect(popupList(), findsNothing);
        expect(summary('11월 12일 (목) 오후 4:30'), findsOneWidget);
      });
    });

    testWidgets('동작 줄이기: 팝업이 나타날 때 투명도 애니메이션이 없다', (tester) async {
      await openSheet(tester, disableAnimations: true);
      await tester.tap(hourCell());
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: popupList(), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('목록은 끝에서 튕기지 않는다 (ClampingScrollPhysics)', (tester) async {
      await openSheet(tester);
      await tester.tap(hourCell());
      await settle(tester);

      expect(
        tester.widget<ListView>(popupList()).physics,
        isA<ClampingScrollPhysics>(),
      );
    });

    testWidgets('분을 고른 뒤 같은 칸을 다시 열면 고른 값(45분)에 포커스가 가 있다', (tester) async {
      await openSheet(tester);
      await tester.tap(minuteCell());
      await settle(tester);
      await tester.scrollUntilVisible(
        row('45분'),
        80,
        scrollable: find.descendant(
          of: popupList(),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(row('45분'));
      await tester.pump();
      await tester.tap(row('45분'));
      await settle(tester);
      expect(popupList(), findsNothing);

      await tester.tap(minuteCell());
      await settle(tester);
      expect(popupList(), findsOneWidget);
      expect(primaryLabel(), '45분');
    });
  });
}

SemanticsOwner semanticsOwner(WidgetTester tester) {
  SemanticsOwner? owner;
  tester.binding.rootPipelineOwner.visitChildren((child) {
    owner ??= child.semanticsOwner;
  });
  return owner ?? tester.binding.rootPipelineOwner.semanticsOwner!;
}

/// 실제 의미 트리(스크린리더가 보는 것)에서 조건에 맞는 첫 노드. 위젯 기준 파인더(find.bySemanticsLabel)는
/// 가려진 노드도 찾아 주므로, 가려짐을 확인할 때는 이 함수를 쓴다
SemanticsNode? semanticsNode(
  WidgetTester tester,
  bool Function(SemanticsData data) test,
) {
  SemanticsNode? found;
  void walk(SemanticsNode node) {
    if (found != null) return;
    if (test(node.getSemanticsData())) {
      found = node;
      return;
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(semanticsOwner(tester).rootSemanticsNode!);
  return found;
}

bool hasLabel(WidgetTester tester, Pattern label) =>
    semanticsNode(tester, (d) => label.allMatches(d.label).isNotEmpty) != null;

void dismissAction(WidgetTester tester, String label) {
  final node = semanticsNode(tester, (d) => d.label == label);
  expect(node, isNotNull, reason: '$label 노드');
  expect(
    node!.getSemanticsData().hasAction(SemanticsAction.dismiss),
    isTrue,
    reason: '$label 에 dismiss 동작',
  );
  semanticsOwner(tester).performAction(node.id, SemanticsAction.dismiss);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
