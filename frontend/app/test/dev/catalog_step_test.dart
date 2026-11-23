import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// SmashStepIndicator 카탈로그 항목
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  const name = 'SmashStepIndicator';
  const narrow = '세로 전환 (3단계 이름, 폭 200, 글자 2.0배)';
  const wide = '가로 (3단계, 폭 320, 글자 2.0배)';

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

  Rect markerIn(WidgetTester tester, Finder within, int i) => tester.getRect(
    find.descendant(
      of: within,
      matching: find.byKey(ValueKey('step-marker-$i')),
    ),
  );

  test('필요한 상태가 모두 있고 이름이 중복되지 않는다', () {
    final labels = catalogEntries
        .firstWhere((e) => e.name == name)
        .states
        .map((s) => s.label)
        .toList();
    expect(
      labels,
      containsAll([
        '1단계 (3단계 중)',
        '2단계 (3단계 중)',
        '3단계 (3단계 중, 마지막)',
        '2단계 짜리 (2단계 중 1)',
        '5단계 짜리 (3단계)',
        narrow,
        wide,
        interactiveStateLabel,
      ]),
    );
    expect(labels.toSet().length, labels.length);
  });

  testWidgets('상태마다 단계 수와 현재 단계가 이름대로다 (동그라미 수, 체크 수)', (tester) async {
    await open(tester);
    final expected = {
      '1단계 (3단계 중)': (3, 0),
      '2단계 (3단계 중)': (3, 1),
      '3단계 (3단계 중, 마지막)': (3, 2),
      '2단계 짜리 (2단계 중 1)': (2, 0),
      '5단계 짜리 (3단계)': (5, 2),
    };
    for (final entry in expected.entries) {
      final (count, checks) = entry.value;
      final b = block(1.0, entry.key);
      expect(
        find.descendant(
          of: b,
          matching: find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey &&
                (w.key! as ValueKey).value.toString().startsWith(
                  'step-marker-',
                ),
          ),
        ),
        findsNWidgets(count),
        reason: entry.key,
      );
      expect(
        find.descendant(of: b, matching: find.byIcon(Icons.check)),
        findsNWidgets(checks),
        reason: entry.key,
      );
    }
  });

  testWidgets('세로 전환 상태는 글자 배율 블록(1.0/1.3/2.0)과 무관하게 세로, 가로 상태는 가로다', (
    tester,
  ) async {
    await open(tester);
    for (final scale in [1.0, 1.3, 2.0]) {
      final v = [
        for (var i = 0; i < 3; i++) markerIn(tester, block(scale, narrow), i),
      ];
      expect(
        {for (final r in v) r.left}.length,
        1,
        reason: '세로: 같은 왼쪽 (배율 $scale)',
      );
      expect({for (final r in v) r.top}.length, 3, reason: '세로: 위에서 아래로');
      final h = [
        for (var i = 0; i < 3; i++) markerIn(tester, block(scale, wide), i),
      ];
      expect(
        {for (final r in h) r.top}.length,
        1,
        reason: '가로: 같은 높이 (배율 $scale)',
      );
      expect(h[0].width, closeTo(44, 0.001), reason: '글자 2.0배: 동그라미 44');
    }
  });

  testWidgets('직접 눌러 보기: 이전/다음으로 단계가 바뀌고 크기와 동그라미 위치가 그대로이며 처음과 끝에서 버튼이 막힌다', (
    tester,
  ) async {
    await open(tester);
    final lab = block(1.0, interactiveStateLabel);
    Finder inLab(Finder f) => find.descendant(of: lab, matching: f);
    SmashButton button(String label) => tester.widget<SmashButton>(
      find
          .ancestor(
            of: inLab(find.text(label)),
            matching: find.byType(SmashButton),
          )
          .first,
    );

    expect(inLab(find.text('현재 값: 1단계 (약관 동의)')), findsOneWidget);
    expect(button('이전').onPressed, isNull, reason: '처음에서는 이전이 막힌다');
    final indicator = inLab(find.byType(SmashStepIndicator));
    final size = tester.getSize(indicator);
    final markers = [for (var i = 0; i < 3; i++) markerIn(tester, lab, i)];

    for (final expected in ['2단계 (이름 입력)', '3단계 (비밀번호)']) {
      await tester.tap(inLab(find.text('다음')));
      await tester.pump();
      expect(inLab(find.text('현재 값: $expected')), findsOneWidget);
      expect(tester.getSize(indicator), size, reason: '단계가 바뀌어도 크기가 같다');
      expect([for (var i = 0; i < 3; i++) markerIn(tester, lab, i)], markers);
    }
    expect(button('다음').onPressed, isNull, reason: '끝에서는 다음이 막힌다');
    expect(
      find.descendant(of: lab.first, matching: find.byIcon(Icons.check)),
      findsNWidgets(2),
      reason: '앞의 두 단계가 완료(체크)',
    );

    await tester.tap(inLab(find.text('이전')));
    await tester.pump();
    expect(inLab(find.text('현재 값: 2단계 (이름 입력)')), findsOneWidget);
    expect(
      find.descendant(of: lab.first, matching: find.byIcon(Icons.check)),
      findsNWidgets(1),
    );
  });
}
