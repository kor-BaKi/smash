import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// C15b-1: SmashParticipationButtons 카탈로그 항목
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const name = 'SmashParticipationButtons';
  const grid = '2×2 전환 (폭 320, 글자 2.0배)';
  const vertical = '세로 전환 (폭 200, 글자 2.0배)';

  Finder block(double scale, String state) =>
      find.byKey(ValueKey('$name|$scale|$state'));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 40000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CatalogApp(entries: catalogEntries));
    await tester.tap(find.text(name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Offset pos(
    WidgetTester tester,
    double scale,
    String state,
    SmashParticipationAction action,
  ) => tester.getTopLeft(
    find.descendant(
      of: block(scale, state),
      matching: find.byKey(ValueKey(action)),
    ),
  );

  test('상태 이름이 중복되지 않고 필요한 상태가 모두 있다', () {
    final labels = catalogEntries
        .firstWhere((e) => e.name == name)
        .states
        .map((s) => s.label)
        .toList();
    expect(
      labels,
      containsAll([
        '기본 (4개)',
        '처리 중 (참여)',
        '비활성',
        grid,
        vertical,
        interactiveStateLabel,
      ]),
    );
    expect(labels.toSet().length, labels.length);
  });

  testWidgets(
    '2×2 전환 상태는 글자 배율 블록(1.0/1.3/2.0)과 무관하게 두 줄 두 칸이고, 세로 전환 상태는 한 줄씩이다',
    (tester) async {
      await open(tester);
      for (final scale in [1.0, 1.3, 2.0]) {
        final g = [
          for (final a in SmashParticipationAction.values)
            pos(tester, scale, grid, a),
        ];
        expect(
          {for (final o in g) o.dy}.length,
          2,
          reason: '2×2 줄 수 (배율 $scale)',
        );
        expect(
          {for (final o in g) o.dx}.length,
          2,
          reason: '2×2 열 수 (배율 $scale)',
        );
        final v = [
          for (final a in SmashParticipationAction.values)
            pos(tester, scale, vertical, a),
        ];
        expect({for (final o in v) o.dx}.length, 1, reason: '세로 (배율 $scale)');
        expect({for (final o in v) o.dy}.length, 4);
      }
    },
  );

  testWidgets('처리 중 상태는 참여 버튼에만 진행 표시가 있고, 비활성 상태는 모두 비활성이다', (tester) async {
    await open(tester);
    expect(
      find.descendant(
        of: block(1.0, '처리 중 (참여)'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.descendant(
          of: block(1.0, '처리 중 (참여)'),
          matching: find.byKey(const ValueKey(SmashParticipationAction.attend)),
        ),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
      reason: '진행 표시는 참여 버튼 안에 있다',
    );
    for (final w in tester.widgetList<SmashButton>(
      find.descendant(
        of: block(1.0, '비활성'),
        matching: find.byType(SmashButton),
      ),
    )) {
      expect(w.onPressed, isNull, reason: w.label);
    }
  });

  testWidgets('직접 눌러 보기: 누르면 처리 중이 되고 그동안 다른 누름은 무시되며, 끝나면 현재 값이 바뀐다', (
    tester,
  ) async {
    await open(tester);
    Finder inBlock(Finder f) =>
        find.descendant(of: block(1.0, interactiveStateLabel), matching: f);
    expect(
      inBlock(find.text('현재 값: 아직 누르지 않았어요 (받아들인 누름 0번)')),
      findsOneWidget,
    );

    await tester.tap(
      inBlock(find.byKey(const ValueKey(SmashParticipationAction.absent))),
    );
    await tester.pump();
    expect(inBlock(find.byType(CircularProgressIndicator)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(
      inBlock(find.byType(CircularProgressIndicator)),
      findsOneWidget,
      reason: '1초 뒤에도 처리 중이다 (끝나려면 1.5초)',
    );
    await tester.tap(
      inBlock(find.byKey(const ValueKey(SmashParticipationAction.absent))),
      warnIfMissed: false,
    );
    await tester.tap(
      inBlock(find.byKey(const ValueKey(SmashParticipationAction.attend))),
      warnIfMissed: false,
    );
    expect(
      inBlock(find.textContaining('받아들인 누름 1번')),
      findsOneWidget,
      reason: '연타는 무시된다',
    );

    await tester.pump(const Duration(milliseconds: 1600));
    expect(inBlock(find.text('현재 값: 불참 (받아들인 누름 1번)')), findsOneWidget);
    expect(inBlock(find.byType(CircularProgressIndicator)), findsNothing);

    await tester.tap(
      inBlock(find.byKey(const ValueKey(SmashParticipationAction.carryover))),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    expect(inBlock(find.text('현재 값: 이월 (받아들인 누름 2번)')), findsOneWidget);
  });

  testWidgets('처리 중에 다른 항목으로 나가도 오류가 없다', (tester) async {
    await open(tester);
    await tester.tap(
      find.descendant(
        of: block(1.0, interactiveStateLabel),
        matching: find.byKey(const ValueKey(SmashParticipationAction.attend)),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
  });
}
