import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/text_lines.dart';

/// SmashLabel의 카탈로그 항목: 상자 폭을 바꿔 가며 일반 Text와 SmashLabel을 비교하는 "직접 눌러 보기"
void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  Finder block(double scale) =>
      find.byKey(ValueKey('SmashLabel|$scale|$interactiveStateLabel'));
  Finder inBlock(double scale, Finder f) =>
      find.descendant(of: block(scale), matching: f);

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 40000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CatalogApp(entries: catalogEntries));
    await tester.tap(find.text('SmashLabel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('SmashLabel은 목록에 있고 직접 눌러 보기 상태가 있으며 상태 이름이 중복되지 않는다 (이후 단계의 항목은 그 뒤에 붙는다)', () {
    final entry = catalogEntries.firstWhere((e) => e.name == 'SmashLabel');
    final labels = entry.states.map((s) => s.label).toList();
    expect(labels, contains(interactiveStateLabel));
    expect(labels.toSet().length, labels.length);
  });

  testWidgets('직접 눌러 보기: 슬라이더로 상자 폭을 바꾸면 현재 값과 두 상자의 폭이 따라 바뀐다', (
    tester,
  ) async {
    await open(tester);
    expect(inBlock(1.0, find.text('현재 값: 상자 폭 150')), findsOneWidget);

    final slider = tester.widget<Slider>(inBlock(1.0, find.byType(Slider)));
    slider.onChanged!(90);
    await tester.pump();

    expect(inBlock(1.0, find.text('현재 값: 상자 폭 90')), findsOneWidget);
    expect(
      inBlock(1.3, find.text('현재 값: 상자 폭 150')),
      findsOneWidget,
      reason: '다른 배율 블록은 그대로',
    );
    final boxes = inBlock(
      1.0,
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 90),
    );
    expect(
      boxes,
      findsNWidgets(2),
      reason: '일반 Text 상자와 SmashLabel 상자 둘 다 글자 영역 폭 90',
    );
  });

  testWidgets('좁은 상자(폭 150) 상태에서 SmashLabel은 낱말 중간에서 끊기지 않고 일반 Text는 끊긴다', (
    tester,
  ) async {
    await open(tester);
    const sentence = '같이 이동하고 싶어요 오늘도 함께 가요';
    final staticBlock = find.byKey(
      const ValueKey('SmashLabel|1.0|좁은 상자 (폭 150)'),
    );
    // 캡션도 일반 Text이므로 같은 문장을 가진 것만 고른다 (SmashLabel도 Text라서 하위 클래스는 제외)
    final plain = find.descendant(
      of: staticBlock,
      matching: find.byWidgetPredicate(
        (w) => w is Text && w is! SmashLabel && w.data == sentence,
      ),
    );
    final label = find.descendant(
      of: staticBlock,
      matching: find.byType(SmashLabel),
    );

    expect(plain, findsOneWidget);
    expect(label, findsOneWidget);
    expect(midWordBreaks(tester, plain), greaterThan(0), reason: '일반 Text');
    expect(midWordBreaks(tester, label), 0, reason: 'SmashLabel');
  });
}
