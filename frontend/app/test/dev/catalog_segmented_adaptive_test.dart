import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/segment_label.dart';

/// C16b: SmashSegmentedControl 카탈로그의 세로 전환 상태와 폭 슬라이더 (실제 글꼴로 본다)
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const name = 'SmashSegmentedControl';
  const grid = '2×2 전환 (조각 4개, 폭 320, 글자 2.0배)';
  const vertical = '세로 전환 (조각 4개, 긴 낱말, 폭 320, 글자 2.0배)';
  const slider = '폭 슬라이더로 줄여 보기 (직접 눌러 보기)';
  const normal = ['정규 참여', '이월 참여', '다른 조 참여', '불참 신청'];
  const long = ['정규참여', '이월참여신청', '다른조참여', '불참신청'];

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

  Offset pos(WidgetTester tester, double scale, String state, String label) =>
      tester.getTopLeft(
        find
            .ancestor(
              of: find.descendant(
                of: block(scale, state),
                matching: segmentLabel(label),
              ),
              matching: find.byType(SmashPressable),
            )
            .first,
      );

  test('상태 이름이 중복되지 않고 세 상태가 모두 있다', () {
    final labels = catalogEntries
        .firstWhere((e) => e.name == name)
        .states
        .map((s) => s.label)
        .toList();
    expect(
      labels,
      containsAll([grid, vertical, slider, interactiveStateLabel]),
    );
    expect(labels.toSet().length, labels.length);
  });

  testWidgets('2×2 전환 상태: 두 줄, 두 칸, 글자 배율 블록(1.0/1.3/2.0)과 무관하게 같은 모습', (
    tester,
  ) async {
    await open(tester);
    for (final scale in [1.0, 1.3, 2.0]) {
      expect(
        tester
            .getSize(
              find.descendant(
                of: block(scale, grid),
                matching: find.byType(SmashSegmentedControl<int>),
              ),
            )
            .width,
        320,
        reason: '폭 320 고정 (배율 $scale)',
      );
      final p = [for (final l in normal) pos(tester, scale, grid, l)];
      expect({for (final o in p) o.dy}.length, 2, reason: '줄 수 (배율 $scale)');
      expect({for (final o in p) o.dx}.length, 2, reason: '열 수 (배율 $scale)');
      expect(p[0].dy, p[1].dy);
      expect(p[2].dy, p[3].dy);
      expect(p[0].dx, p[2].dx);
    }
  });

  testWidgets('세로 전환 상태: 4줄이 같은 왼쪽에서 위에서 아래로 쌓인다', (tester) async {
    await open(tester);
    for (final scale in [1.0, 1.3, 2.0]) {
      expect(
        tester
            .getSize(
              find.descendant(
                of: block(scale, vertical),
                matching: find.byType(SmashSegmentedControl<int>),
              ),
            )
            .width,
        320,
        reason: '폭 320 고정 (배율 $scale)',
      );
      final p = [for (final l in long) pos(tester, scale, vertical, l)];
      expect({for (final o in p) o.dx}.length, 1, reason: '같은 왼쪽 (배율 $scale)');
      for (var i = 1; i < p.length; i++) {
        expect(p[i].dy, greaterThan(p[i - 1].dy));
      }
    }
  });

  testWidgets('폭 슬라이더: 줄이면 2열 → 세로로 바뀌고, 세로에서도 눌러서 선택이 바뀐다', (tester) async {
    await open(tester);
    expect(
      find.descendant(
        of: block(1.0, slider),
        matching: find.text('현재 값: 폭 360, 선택 이월참여신청'),
      ),
      findsOneWidget,
    );
    final wide = [for (final l in long) pos(tester, 1.0, slider, l)];
    expect(
      {for (final o in wide) o.dy}.length,
      lessThan(4),
      reason: '폭 360에서는 세로가 아니다',
    );

    await tester.drag(
      find.descendant(of: block(1.0, slider), matching: find.byType(Slider)),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: block(1.0, slider),
        matching: find.textContaining('현재 값: 폭 160'),
      ),
      findsOneWidget,
    );
    final narrow = [for (final l in long) pos(tester, 1.0, slider, l)];
    expect({for (final o in narrow) o.dx}.length, 1, reason: '폭 160: 세로');
    expect({for (final o in narrow) o.dy}.length, 4);

    await tester.tap(
      find.descendant(of: block(1.0, slider), matching: segmentLabel('불참신청')),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: block(1.0, slider),
        matching: find.text('현재 값: 폭 160, 선택 불참신청'),
      ),
      findsOneWidget,
    );
    // 선택을 바꿔도 배치(열 수)는 그대로
    final after = [for (final l in long) pos(tester, 1.0, slider, l)];
    expect({for (final o in after) o.dx}.length, 1);
  });
}
