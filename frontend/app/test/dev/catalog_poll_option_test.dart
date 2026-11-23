import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// C15b-2: SmashPollOptionRow 카탈로그 항목
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const name = 'SmashPollOptionRow';
  const narrow = '좁은 폭 전환 (폭 200, 글자 2.0배)';

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

  test('필요한 상태가 모두 있고 이름이 중복되지 않는다', () {
    final labels = catalogEntries
        .firstWhere((e) => e.name == name)
        .states
        .map((s) => s.label)
        .toList();
    expect(
      labels,
      containsAll([
        '투표 전 (선택 가능)',
        '눌림 (투표 전)',
        '처리 중 (보내는 중)',
        '결과: 내가 고른 선택지 (익명)',
        '결과: 기명 (투표한 사람)',
        '결과: 0표',
        '마감: 결과만 (누를 수 없음)',
        '긴 이름 (여러 줄)',
        narrow,
        interactiveStateLabel,
      ]),
    );
    expect(labels.toSet().length, labels.length);
  });

  testWidgets('눌림 상태는 배경이 연한 브랜드 색이다 (투표 전 상태는 흰 배경)', (tester) async {
    await open(tester);
    Color? background(String state) => tester
        .widgetList<Container>(
          find.descendant(
            of: block(1.0, state),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .whereType<Color>()
        .firstOrNull;
    expect(background('투표 전 (선택 가능)'), SmashColors.surface);
    expect(background('눌림 (투표 전)'), SmashColors.brandTintSoft);
  });

  testWidgets('좁은 폭 전환 상태는 글자 배율 블록(1.0/1.3/2.0)과 무관하게 결과가 이름 아래에 있다', (
    tester,
  ) async {
    await open(tester);
    for (final scale in [1.0, 1.3, 2.0]) {
      final inBlock = block(scale, narrow);
      expect(
        tester
            .getSize(
              find.descendant(
                of: inBlock,
                matching: find.byType(SmashPollOptionRow),
              ),
            )
            .width,
        200,
        reason: '폭 200 (배율 $scale)',
      );
      final labelRect = tester.getRect(
        find.descendant(of: inBlock, matching: find.text('목요일 저녁 7시')),
      );
      final percentTop = tester
          .getTopLeft(find.descendant(of: inBlock, matching: find.text('60%')))
          .dy;
      expect(
        percentTop,
        greaterThanOrEqualTo(labelRect.bottom - 0.5),
        reason: '결과가 이름 아래 (배율 $scale)',
      );
    }
  });

  testWidgets('직접 눌러 보기: 고르면 보내는 중 → 결과와 내 선택 → 다시 투표로 돌아온다', (tester) async {
    await open(tester);
    Finder inBlock(Finder f) =>
        find.descendant(of: block(1.0, interactiveStateLabel), matching: f);
    expect(inBlock(find.text('현재 값: 아직 투표하지 않았어요')), findsOneWidget);
    expect(
      inBlock(find.byIcon(Icons.radio_button_unchecked)),
      findsNWidgets(3),
    );

    await tester.tap(inBlock(find.text('토요일 오전 10시')));
    await tester.pump();
    expect(inBlock(find.byType(CircularProgressIndicator)), findsOneWidget);
    await tester.tap(inBlock(find.text('둘 다 어려워요')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      inBlock(find.byType(CircularProgressIndicator)),
      findsOneWidget,
      reason: '0.5초 뒤에도 보내는 중이다 (끝나려면 1초)',
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      inBlock(find.text('현재 값: 토요일 오전 10시에 투표')),
      findsOneWidget,
      reason: '보내는 중에 다른 선택지를 눌러도 무시된다',
    );
    expect(inBlock(find.byIcon(Icons.check_circle)), findsOneWidget);
    expect(
      inBlock(find.text('43%')),
      findsNWidgets(2),
      reason: '토요일 3/7과 목요일 3/7',
    );
    expect(inBlock(find.text('14%')), findsOneWidget, reason: '1/7');

    await tester.tap(inBlock(find.text('다시 투표')));
    await tester.pump();
    expect(inBlock(find.text('현재 값: 아직 투표하지 않았어요')), findsOneWidget);
    expect(
      inBlock(find.byIcon(Icons.radio_button_unchecked)),
      findsNWidgets(3),
    );

    // 다시 투표하면 이전 표는 빠지고 새 표가 더해진다: 목요일에 투표하면 4/7 = 57%
    await tester.tap(inBlock(find.text('목요일 저녁 7시')));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(
      inBlock(find.text('57%')),
      findsOneWidget,
      reason: '[4, 2, 1] → 4/7',
    );
  });

  testWidgets('보내는 중에 다른 항목으로 나가도 오류가 없다', (tester) async {
    await open(tester);
    await tester.tap(
      find.descendant(
        of: block(1.0, interactiveStateLabel),
        matching: find.text('목요일 저녁 7시'),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });
}
