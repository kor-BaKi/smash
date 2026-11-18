import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/dev/catalog/catalog_state_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화면의 안전 영역(노치, 홈 인디케이터)이 상자 안의 스크롤 목록 여백으로 새지 않는지 본다.
/// `ListView`는 `padding`을 안 주면 `MediaQuery.padding`의 위아래를 암묵적으로 여백으로 쓰므로,
/// 상자(시트, 카드, 탭 안)에 둔 목록의 위에 큰 빈 공간이 생긴다.
/// 안전 영역이 없는 화면에서 잰 값과 같아야 한다.
const _noSafeArea = EdgeInsets.zero;
final _safeAreas = {
  '위 59, 아래 34': const EdgeInsets.fromLTRB(0, 59, 0, 34),
  '위 59, 아래 34, 좌우 20': const EdgeInsets.fromLTRB(20, 59, 20, 34),
};

Widget host(Widget child, EdgeInsets safe, {double boxHeight = 400}) =>
    MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: safe, viewPadding: safe),
        child: app!,
      ),
      home: Material(
        child: Align(
          alignment: Alignment.topLeft,
          // 안전 영역보다 아래에 놓인 상자: 상자 자체는 화면 가장자리에 붙어 있지 않다
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: SizedBox(
              key: const ValueKey('box'),
              width: 360,
              height: boxHeight,
              child: child,
            ),
          ),
        ),
      ),
    );

void sizeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

ScrollPosition position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// (상자 윗변에서 첫 항목 윗변까지의 거리, 스크롤 가능한 전체 길이)
Future<(double, double)> measureSkeleton(
  WidgetTester tester,
  EdgeInsets safe, {
  int itemCount = 20,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(host(SmashSkeletonList(itemCount: itemCount), safe));
  final box = tester.getRect(find.byKey(const ValueKey('box')));
  final first = tester.getRect(find.byType(SmashSkeleton).first);
  final extent = position(tester);
  return (first.top - box.top, extent.maxScrollExtent);
}

Future<(double, double)> measureCatalogList(
  WidgetTester tester,
  EdgeInsets safe,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final state = asyncViewEntry.states.firstWhere((s) => s.label.contains('직접'));
  // 시연 위젯은 컨트롤과 높이 360의 상자를 함께 그리므로 넉넉한 높이를 준다
  await tester.pumpWidget(
    host(Builder(builder: state.builder), safe, boxHeight: 780),
  );
  // 로딩이 끝나 데이터 목록이 보일 때까지 기다린다
  for (var i = 0; i < 6 && find.byType(SmashListRow).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 1500));
  }
  expect(
    find.byType(SmashListRow),
    findsWidgets,
    reason: '데이터 목록 상태까지 도달해야 한다',
  );
  final list = tester.getRect(find.byType(ListView).first);
  final firstRow = tester.getRect(find.byType(SmashListRow).first);
  return (firstRow.top - list.top, position(tester).maxScrollExtent);
}

void main() {
  group('SmashSkeletonList: 안전 영역이 위아래 여백으로 새지 않는다', () {
    for (final entry in _safeAreas.entries) {
      testWidgets('안전 영역 ${entry.key}: 첫 막대의 위 여백과 스크롤 길이가 안전 영역이 없을 때와 같다', (
        tester,
      ) async {
        sizeScreen(tester);
        final (baseTop, baseExtent) = await measureSkeleton(
          tester,
          _noSafeArea,
        );
        final (top, extent) = await measureSkeleton(tester, entry.value);

        expect(
          top,
          baseTop,
          reason: '위 여백 (안전 영역 위 ${entry.value.top}이 섞이면 늘어난다)',
        );
        expect(
          extent,
          baseExtent,
          reason:
              '스크롤 길이 (위 ${entry.value.top} + 아래 ${entry.value.bottom}이 섞이면 늘어난다)',
        );
      });
    }

    testWidgets('항목이 적으면(3개) 상자 맨 위에서 항목 안쪽 여백(8)만큼 떨어져 시작한다', (tester) async {
      sizeScreen(tester);
      final (top, _) = await measureSkeleton(
        tester,
        _safeAreas.values.first,
        itemCount: 3,
      );

      // 항목 하나는 위아래 8씩 안쪽 여백을 가지고, 56 높이 안에서 가운데 맞춤이다
      expect(top, lessThan(24), reason: '안전 영역 59가 섞이면 70이 넘는다');
    });
  });

  group('카탈로그 AsyncView 데이터 목록: 안전 영역이 위아래 여백으로 새지 않는다', () {
    for (final entry in _safeAreas.entries) {
      testWidgets('안전 영역 ${entry.key}: 첫 줄의 윗변이 목록 윗변과 같다 (위 여백 0)', (
        tester,
      ) async {
        sizeScreen(tester);
        final (baseTop, baseExtent) = await measureCatalogList(
          tester,
          _noSafeArea,
        );
        final (top, extent) = await measureCatalogList(tester, entry.value);

        expect(baseTop, 0, reason: '안전 영역이 없을 때 위 여백은 0');
        expect(
          top,
          baseTop,
          reason: '위 여백 (안전 영역 위 ${entry.value.top}이 섞이면 늘어난다)',
        );
        expect(extent, baseExtent, reason: '스크롤 길이 (안전 영역이 섞이면 늘어난다)');
      });
    }
  });
}
