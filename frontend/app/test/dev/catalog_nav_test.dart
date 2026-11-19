import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// C15a(SmashTabBar, SmashSelectField, showSmashActionSheet)의 카탈로그 항목.
/// 값이 바뀌는 컴포넌트이므로 "직접 눌러 보기" 상태에서 실제로 값이 바뀌어야 한다.
void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  const names = ['SmashTabBar', 'SmashSelectField', 'showSmashActionSheet'];

  CatalogEntry entryNamed(String name) =>
      catalogEntries.firstWhere((e) => e.name == name);

  Finder block(String entryName, double scale) =>
      find.byKey(ValueKey('$entryName|$scale|$interactiveStateLabel'));
  Finder inBlock(String entryName, double scale, Finder matching) =>
      find.descendant(of: block(entryName, scale), matching: matching);

  Future<void> open(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(400, 40000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CatalogApp(entries: catalogEntries));
    await tester.tap(find.text(name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('새 컴포넌트 세 개는 목록 맨 아래에 순서대로 붙어 있다', () {
    expect(
      catalogEntries
          .map((e) => e.name)
          .toList()
          .sublist(catalogEntries.length - 3),
      names,
    );
  });

  test('세 컴포넌트 모두 직접 눌러 보기 상태를 가지고, 상태 이름이 중복되지 않는다', () {
    for (final name in names) {
      final labels = entryNamed(name).states.map((s) => s.label).toList();
      expect(labels, contains(interactiveStateLabel), reason: name);
      expect(labels.toSet().length, labels.length, reason: '$name 상태 이름 중복');
    }
  });

  group('SmashTabBar', () {
    testWidgets('직접 눌러 보기: 탭을 누르면 현재 값과 본문이 바뀌고, 옆으로 밀어도 따라간다', (tester) async {
      await open(tester, 'SmashTabBar');

      expect(
        inBlock('SmashTabBar', 1.0, find.text('현재 값: 1번째 탭 (미처리)')),
        findsOneWidget,
      );
      await tester.tap(inBlock('SmashTabBar', 1.0, find.text('합격')));
      await tester.pumpAndSettle();
      expect(
        inBlock('SmashTabBar', 1.0, find.text('현재 값: 2번째 탭 (합격)')),
        findsOneWidget,
      );
      expect(
        inBlock('SmashTabBar', 1.0, find.textContaining('합격 화면')),
        findsOneWidget,
      );

      await tester.fling(
        inBlock('SmashTabBar', 1.0, find.byType(TabBarView)),
        const Offset(-300, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(
        inBlock('SmashTabBar', 1.0, find.text('현재 값: 3번째 탭 (불합격)')),
        findsOneWidget,
      );
    });

    testWidgets('글자 배율 블록마다 값이 독립이다 (1.0배에서 눌러도 1.3배는 그대로)', (tester) async {
      await open(tester, 'SmashTabBar');

      await tester.tap(inBlock('SmashTabBar', 1.0, find.text('합격')));
      await tester.pumpAndSettle();

      expect(
        inBlock('SmashTabBar', 1.0, find.text('현재 값: 2번째 탭 (합격)')),
        findsOneWidget,
      );
      expect(
        inBlock('SmashTabBar', 1.3, find.text('현재 값: 1번째 탭 (미처리)')),
        findsOneWidget,
      );
    });

    testWidgets('정적 상태의 탭은 눌러도 바뀌지 않는다 (모양 확인용)', (tester) async {
      await open(tester, 'SmashTabBar');
      final staticBlock = find.byKey(
        const ValueKey('SmashTabBar|1.0|고정 3탭 (같은 폭)'),
      );
      final controllerBefore = tester
          .widget<TabBar>(
            find.descendant(of: staticBlock, matching: find.byType(TabBar)),
          )
          .controller!;

      await tester.tap(
        find.descendant(of: staticBlock, matching: find.text('종료된 투표')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(controllerBefore.index, 0);
    });
  });

  group('SmashSelectField', () {
    testWidgets('직접 눌러 보기: 시트에서 조를 고르면 칸과 현재 값이 바뀌고 오류가 사라진다', (tester) async {
      await open(tester, 'SmashSelectField');
      expect(
        inBlock('SmashSelectField', 1.0, find.text('현재 값: 고르지 않았어요')),
        findsOneWidget,
      );
      expect(
        inBlock('SmashSelectField', 1.0, find.text('조를 골라 주세요')),
        findsOneWidget,
      );

      await tester.tap(
        inBlock('SmashSelectField', 1.0, find.byType(SmashPressable)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SmashSheetFrame),
          matching: find.text('2조'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        inBlock('SmashSelectField', 1.0, find.text('현재 값: 2조')),
        findsOneWidget,
      );
      expect(
        inBlock('SmashSelectField', 1.0, find.text('조를 골라 주세요')),
        findsNothing,
      );
      expect(
        inBlock('SmashSelectField', 1.3, find.text('현재 값: 고르지 않았어요')),
        findsOneWidget,
        reason: '다른 배율 블록은 그대로',
      );
    });

    testWidgets('직접 눌러 보기: 시트를 닫기만 하면 값이 그대로다', (tester) async {
      await open(tester, 'SmashSelectField');

      await tester.tap(
        inBlock('SmashSelectField', 1.0, find.byType(SmashPressable)),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        inBlock('SmashSelectField', 1.0, find.text('현재 값: 고르지 않았어요')),
        findsOneWidget,
      );
    });
  });

  group('showSmashActionSheet', () {
    testWidgets('직접 눌러 보기: 행동을 고르면 고른 행동이 현재 값에 나오고, 취소와 뒤로 가기는 "닫았어요"', (
      tester,
    ) async {
      await open(tester, 'showSmashActionSheet');
      final opener = inBlock('showSmashActionSheet', 1.0, find.text('행동 고르기'));
      expect(
        inBlock('showSmashActionSheet', 1.0, find.text('현재 값: 아직 열지 않았어요')),
        findsOneWidget,
      );

      await tester.tap(opener);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SmashSheetFrame),
          matching: find.text('이름 바꾸기'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        inBlock('showSmashActionSheet', 1.0, find.text('현재 값: 고른 행동: 이름 바꾸기')),
        findsOneWidget,
      );

      await tester.tap(opener);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SmashButton, '취소'));
      await tester.pumpAndSettle();
      expect(
        inBlock(
          'showSmashActionSheet',
          1.0,
          find.text('현재 값: 닫았어요 (고른 행동 없음)'),
        ),
        findsOneWidget,
      );

      await tester.tap(opener);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SmashSheetFrame),
          matching: find.text('조 삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        inBlock('showSmashActionSheet', 1.0, find.text('현재 값: 고른 행동: 조 삭제')),
        findsOneWidget,
      );

      await tester.tap(opener);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        inBlock(
          'showSmashActionSheet',
          1.0,
          find.text('현재 값: 닫았어요 (고른 행동 없음)'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('정적 상태(위험한 행동 포함 등)도 눌러서 열 수 있고 결과가 현재 값에 나온다', (tester) async {
      await open(tester, 'showSmashActionSheet');
      final staticBlock = find.byKey(
        const ValueKey(
          'showSmashActionSheet|1.0|제목과 설명 + 위험한 행동 (처음 포커스가 취소에)',
        ),
      );

      await tester.tap(
        find.descendant(of: staticBlock, matching: find.text('조 관리 메뉴 열기')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SmashSheetFrame), findsOneWidget);
      await tester.tap(find.widgetWithText(SmashButton, '취소'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: staticBlock,
          matching: find.text('현재 값: 닫았어요 (고른 행동 없음)'),
        ),
        findsOneWidget,
      );
    });
  });
}
