import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/semantics_tree.dart';

/// C15b-3: SmashPhotoTile 카탈로그 항목
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const name = 'SmashPhotoTile';
  const grid = '2열 격자 (성공, 불러오는 중, 실패, 빈 자리: 같은 크기)';
  const bigText = '실패 (폭 168, 글자 2.0배)';

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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
    }
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
        '성공 (가로 사진)',
        '성공 (세로 사진)',
        '성공 + 날짜 + 눌러서 크게 보기',
        '눌림',
        '불러오는 중',
        '실패 (다시 시도)',
        '빈 사진 자리',
        grid,
        bigText,
        interactiveStateLabel,
      ]),
    );
    expect(labels.toSet().length, labels.length);
  });

  testWidgets('불러오는 중, 실패, 빈 자리 상태가 각각 맞는 모양이다', (tester) async {
    await open(tester);
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(
        of: block(1.0, '불러오는 중'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: block(1.0, '실패 (다시 시도)'),
        matching: find.text('다시 시도'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: block(1.0, '빈 사진 자리'),
        matching: find.byIcon(Icons.image_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('2열 격자: 서로 다른 상태의 네 칸이 모두 같은 크기다', (tester) async {
    await open(tester);
    await tester.pump();
    await tester.pump();
    final sizes = tester
        .widgetList(
          find.descendant(
            of: block(1.0, grid),
            matching: find.byType(SmashPhotoTile),
          ),
        )
        .map((w) => tester.getSize(find.byWidget(w)))
        .toSet();
    expect(sizes.length, 1, reason: '$sizes');
  });

  testWidgets('2열 격자의 네 번째(빈 자리)는 "사진 없음"으로 읽히고 다시 시도 버튼이 없다. 세 번째(실패)에는 있다', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await tester.pump();
    await tester.pump();
    Finder tileOf(String label) => find.descendant(
      of: block(1.0, grid),
      matching: find.byWidgetPredicate(
        (w) => w is SmashPhotoTile && w.semanticLabel == label,
      ),
    );
    expect(
      find.descendant(
        of: tileOf('활동 사진 4장 중 4번째'),
        matching: find.text('다시 시도'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: tileOf('활동 사진 4장 중 4번째'),
        matching: find.byIcon(Icons.image_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tileOf('활동 사진 4장 중 3번째'),
        matching: find.text('다시 시도'),
      ),
      findsOneWidget,
    );
    expect(
      semanticsNode(tester, (d) => d.label == '활동 사진 4장 중 4번째, 사진 없음'),
      isNotNull,
    );
    expect(
      semanticsNode(tester, (d) => d.label == '활동 사진 4장 중 3번째, 불러오지 못했어요'),
      isNotNull,
    );
    handle.dispose();
  });

  testWidgets('글자 2.0배 실패 상태는 글자 배율 블록(1.0/1.3/2.0)과 무관하게 폭 168이고 넘침이 없다', (
    tester,
  ) async {
    await open(tester);
    await tester.pump();
    await tester.pump();
    for (final scale in [1.0, 1.3, 2.0]) {
      final tile = find.descendant(
        of: block(scale, bigText),
        matching: find.byType(SmashPhotoTile),
      );
      expect(tester.getSize(tile).width, 168, reason: '배율 $scale');
      // 아이콘도 RichText라서(배율 고정) 글자 "다시 시도"의 RichText를 찾는다
      final label = find
          .descendant(
            of: find.descendant(of: tile, matching: find.text('다시 시도')),
            matching: find.byType(RichText),
          )
          .first;
      expect(
        tester.widget<RichText>(label).textScaler.scale(10),
        20,
        reason: '이 상태는 블록의 글자 배율과 상관없이 글자 2.0배다 (배율 $scale)',
      );
      final button = tester.getRect(
        find.descendant(
          of: block(scale, bigText),
          matching: find.text('다시 시도'),
        ),
      );
      final box = tester.getRect(tile);
      expect(button.right, lessThanOrEqualTo(box.right + 0.001));
      expect(button.bottom, lessThanOrEqualTo(box.bottom + 0.001));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('직접 눌러 보기: 두 번 실패하고 세 번째에 성공하며, 성공하면 크게 보기를 누를 수 있다', (
    tester,
  ) async {
    await open(tester);
    Finder inBlock(Finder f) =>
        find.descendant(of: block(1.0, interactiveStateLabel), matching: f);
    await tester.pump();
    expect(inBlock(find.textContaining('불러오기 시도 1번')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(inBlock(find.text('다시 시도')), findsOneWidget, reason: '첫 시도 실패');

    await tester.tap(inBlock(find.text('다시 시도')));
    await tester.pump();
    await tester.pump();
    expect(inBlock(find.textContaining('불러오기 시도 2번')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(inBlock(find.text('다시 시도')), findsOneWidget, reason: '두 번째 시도 실패');

    await tester.tap(inBlock(find.text('다시 시도')));
    await tester.pump();
    await tester.pump();
    expect(inBlock(find.textContaining('불러오기 시도 3번')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await settle(tester);
    expect(inBlock(find.byType(Image)), findsOneWidget, reason: '세 번째에 성공');
    expect(inBlock(find.text('2026-11-11')), findsOneWidget);

    await tester.tap(inBlock(find.byType(SmashPhotoTile)));
    await tester.pump();
    expect(inBlock(find.textContaining('크게 보기 1번')), findsOneWidget);
  });

  testWidgets('다른 항목으로 나가면 진행 중인 요청이 취소되고 오류나 대기 중인 타이머가 없다', (tester) async {
    await open(tester);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
