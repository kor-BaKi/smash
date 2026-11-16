import 'package:app/core/design/components/components.dart';
import 'package:app/dev/catalog/catalog_app.dart';
import 'package:app/dev/catalog/catalog_entry.dart';
import 'package:app/dev/catalog/catalog_page.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 등록된 컴포넌트가 아직 없어도 카탈로그의 목록, 상태 표, 글자 확대 동작을 확인할 수 있도록
// 가짜 컴포넌트를 넘겨서 검사한다.

/// 자기 위치의 글자 배율을 그대로 보여주는 가짜 컴포넌트
class _ScaleProbe extends StatelessWidget {
  const _ScaleProbe();

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    return Text('배율=$scale');
  }
}

final _fakeEntry = CatalogEntry(
  name: '샘플',
  description: '샘플 설명',
  states: [
    CatalogState('기본', (_) => const _ScaleProbe()),
    CatalogState('눌림', (_) => const Text('눌린 모양')),
    CatalogState('비활성', (_) => const Text('비활성 모양')),
  ],
);

final _otherEntry = CatalogEntry(
  name: '다른 샘플',
  description: '다른 설명',
  states: [CatalogState('기본', (_) => const Text('다른 기본'))],
);

void main() {
  Future<void> useTallScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 40000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> open(WidgetTester tester, CatalogEntry entry, List<CatalogEntry> all) async {
    await useTallScreen(tester);
    await tester.pumpWidget(CatalogApp(entries: all));
    await tester.tap(find.text(entry.name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('목록', () {
    testWidgets('등록된 컴포넌트가 없으면 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(const CatalogApp(entries: []));

      expect(find.text('컴포넌트 카탈로그'), findsOneWidget);
      expect(find.text('등록된 컴포넌트가 없어요'), findsOneWidget);
    });

    testWidgets('등록된 컴포넌트의 이름과 설명이 모두 나온다', (tester) async {
      await tester.pumpWidget(CatalogApp(entries: [_fakeEntry, _otherEntry]));

      expect(find.text('샘플'), findsOneWidget);
      expect(find.text('샘플 설명'), findsOneWidget);
      expect(find.text('다른 샘플'), findsOneWidget);
      expect(find.text('다른 설명'), findsOneWidget);
      expect(find.text('등록된 컴포넌트가 없어요'), findsNothing);
    });

    testWidgets('항목을 누르면 그 컴포넌트 화면으로 이동하고 뒤로 가면 목록으로 돌아온다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry, _otherEntry]);

      expect(find.byType(CatalogEntryPage), findsOneWidget);
      // 목록 화면이 뒤에 남아 있으므로 상세 화면 안에서만 찾는다
      expect(
        find.descendant(of: find.byType(CatalogEntryPage), matching: find.text('샘플 설명')),
        findsOneWidget,
      );

      // 앱바의 뒤로 가기 버튼 (ko 로케일의 툴팁은 "뒤로")
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogEntryPage), findsNothing);
      expect(find.text('다른 샘플'), findsOneWidget);
    });

    testWidgets('기본값(entries 생략)은 등록 목록(catalogEntries)을 보여준다', (tester) async {
      await useTallScreen(tester); // 목록이 길어 기본 화면 밖의 항목은 그려지지 않는다
      await tester.pumpWidget(const CatalogApp());

      for (final entry in catalogEntries) {
        expect(find.text(entry.name), findsOneWidget);
      }
    });
  });

  group('컴포넌트 화면 (상태 × 글자 배율)', () {
    testWidgets('글자 1.0, 1.3, 2.0배 세 블록이 위에서 아래로 나온다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry]);

      expect(catalogTextScales, [1.0, 1.3, 2.0]);
      final tops = [
        for (final scale in catalogTextScales) tester.getTopLeft(find.text('글자 $scale배')).dy,
      ];

      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));
    });

    testWidgets('등록한 모든 상태가 세 배율마다 한 번씩 그려진다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry]);

      for (final scale in catalogTextScales) {
        for (final state in _fakeEntry.states) {
          expect(
            find.byKey(ValueKey('${_fakeEntry.name}|$scale|${state.label}')),
            findsOneWidget,
            reason: '${state.label} @$scale',
          );
        }
      }
      expect(find.text('눌린 모양'), findsNWidgets(3));
      expect(find.text('비활성 모양'), findsNWidgets(3));
    });

    testWidgets('컴포넌트 안에서는 글자 배율이 블록마다 1.0, 1.3, 2.0이다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry]);

      expect(find.text('배율=1.0'), findsOneWidget);
      expect(find.text('배율=1.3'), findsOneWidget);
      expect(find.text('배율=2.0'), findsOneWidget);
    });

    testWidgets('상태 이름(라벨)은 확대되지 않은 글자로 그려진다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry]);

      final labelContext = tester.element(find.text('기본').first);

      expect(MediaQuery.textScalerOf(labelContext).scale(10), 10);
    });

    testWidgets('설명이 첫 번째 배율 블록보다 위에 나온다', (tester) async {
      await open(tester, _fakeEntry, [_fakeEntry]);

      final description = find.descendant(
        of: find.byType(CatalogEntryPage),
        matching: find.text('샘플 설명'),
      );

      expect(description, findsOneWidget);
      expect(
        tester.getTopLeft(description).dy,
        lessThan(tester.getTopLeft(find.text('글자 1.0배')).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('상태가 하나뿐인 컴포넌트도 오류 없이 그려진다', (tester) async {
      await open(tester, _otherEntry, [_otherEntry]);

      expect(find.text('다른 기본'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  // 실제로 등록된 컴포넌트마다 모든 상태가 글자 1.0, 1.3, 2.0배에서 오류 없이 그려지는지 확인한다.
  // 새 컴포넌트를 등록하면 이 검사가 자동으로 따라붙는다.
  group('등록된 실제 컴포넌트', () {
    for (final entry in catalogEntries) {
      testWidgets('${entry.name}: 모든 상태가 세 배율에서 오류 없이 그려진다', (tester) async {
        await open(tester, entry, catalogEntries);

        for (final scale in catalogTextScales) {
          for (final state in entry.states) {
            expect(
              find.byKey(ValueKey('${entry.name}|$scale|${state.label}')),
              findsOneWidget,
              reason: '${state.label} @$scale',
            );
          }
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.name}: 첫 상태는 배율이 클수록 줄어들지 않는다', (tester) async {
        await open(tester, entry, catalogEntries);

        double heightAt(double scale) => tester
            .getSize(find.byKey(ValueKey('${entry.name}|$scale|${entry.states.first.label}')))
            .height;

        expect(heightAt(1.3), greaterThanOrEqualTo(heightAt(1.0)));
        expect(heightAt(2.0), greaterThanOrEqualTo(heightAt(1.3)));
      });
    }
  });

  // 값을 바꾸는 컴포넌트는 정적인 모양만으로는 동작을 알 수 없으므로, 눌러 보면 실제로 값이 바뀌는
  // 상태(interactiveStateLabel)를 카탈로그에 함께 둔다.
  group('직접 눌러 보기 상태 (값을 바꾸는 컴포넌트)', () {
    const interactiveNames = ['SmashSegmentedControl', 'SmashSwitchRow', 'SmashCheckboxRow'];

    CatalogEntry entryNamed(String name) =>
        catalogEntries.firstWhere((e) => e.name == name);

    Finder block(String entryName, double scale, String stateLabel) =>
        find.byKey(ValueKey('$entryName|$scale|$stateLabel'));

    Finder inBlock(String entryName, double scale, String stateLabel, Finder matching) =>
        find.descendant(of: block(entryName, scale, stateLabel), matching: matching);

    Finder checkIconIn(Finder container) =>
        find.descendant(of: container, matching: find.byIcon(Icons.check));

    test('값을 바꾸는 컴포넌트는 모두 직접 눌러 보기 상태를 가진다', () {
      for (final name in interactiveNames) {
        final labels = entryNamed(name).states.map((s) => s.label);

        expect(labels, contains(interactiveStateLabel), reason: name);
      }
    });

    test('기존 정적 상태들도 그대로 남아 있다', () {
      expect(
        entryNamed('SmashSegmentedControl').states.map((s) => s.label),
        containsAll(['기본 (첫째 선택)', '둘째 선택', '일부 비활성', '전체 비활성', '조각 3개']),
      );
      expect(
        entryNamed('SmashSwitchRow').states.map((s) => s.label),
        containsAll(['꺼짐', '켜짐', '설명 포함', '비활성']),
      );
      expect(
        entryNamed('SmashCheckboxRow').states.map((s) => s.label),
        containsAll(['해제', '체크', '설명 포함', '비활성']),
      );
    });

    testWidgets('세그먼트: 다른 조각을 누르면 값과 선택 표시(체크 아이콘)가 바뀌고, 다시 누르면 돌아온다',
        (tester) async {
      final entry = entryNamed('SmashSegmentedControl');
      await open(tester, entry, catalogEntries);
      Finder segment(String label) => find.ancestor(
            of: inBlock(entry.name, 1.0, interactiveStateLabel, find.text(label)),
            matching: find.byType(SmashPressable),
          );
      expect(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: 같이 가요')),
          findsOneWidget);
      expect(checkIconIn(segment('같이 가요')), findsOneWidget);

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('따로 가요')));
      await tester.pump();

      expect(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: 따로 가요')),
          findsOneWidget);
      expect(checkIconIn(segment('따로 가요')), findsOneWidget);
      expect(checkIconIn(segment('같이 가요')), findsNothing);

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('같이 가요')));
      await tester.pump();

      expect(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: 같이 가요')),
          findsOneWidget);
    });

    testWidgets('스위치: 글자를 눌러도 스위치를 눌러도 꺼짐/켜짐이 번갈아 바뀐다', (tester) async {
      final entry = entryNamed('SmashSwitchRow');
      await open(tester, entry, catalogEntries);
      Finder value(String text) =>
          inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: $text'));
      expect(value('꺼짐'), findsOneWidget);

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('투표 알림')));
      await tester.pump();
      expect(value('켜짐'), findsOneWidget);
      expect(
        tester
            .widget<Switch>(inBlock(entry.name, 1.0, interactiveStateLabel, find.byType(Switch)))
            .value,
        isTrue,
      );

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.byType(Switch)));
      await tester.pump();
      expect(value('꺼짐'), findsOneWidget);
    });

    testWidgets('체크박스: 글자를 눌러도 체크박스를 눌러도 해제/체크가 번갈아 바뀐다', (tester) async {
      final entry = entryNamed('SmashCheckboxRow');
      await open(tester, entry, catalogEntries);
      Finder value(String text) =>
          inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: $text'));
      expect(value('해제'), findsOneWidget);

      await tester.tap(inBlock(
          entry.name, 1.0, interactiveStateLabel, find.text('개인정보 처리방침에 동의해요')));
      await tester.pump();
      expect(value('체크'), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(
                inBlock(entry.name, 1.0, interactiveStateLabel, find.byType(Checkbox)))
            .value,
        isTrue,
      );

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.byType(Checkbox)));
      await tester.pump();
      expect(value('해제'), findsOneWidget);
    });

    testWidgets('배율 블록마다 값이 독립이다 (1.0배에서 눌러도 1.3배, 2.0배는 그대로)', (tester) async {
      final entry = entryNamed('SmashSwitchRow');
      await open(tester, entry, catalogEntries);

      await tester.tap(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('투표 알림')));
      await tester.pump();

      expect(inBlock(entry.name, 1.0, interactiveStateLabel, find.text('현재 값: 켜짐')),
          findsOneWidget);
      expect(inBlock(entry.name, 1.3, interactiveStateLabel, find.text('현재 값: 꺼짐')),
          findsOneWidget);
      expect(inBlock(entry.name, 2.0, interactiveStateLabel, find.text('현재 값: 꺼짐')),
          findsOneWidget);
    });

    testWidgets('정적 스위치 상태는 눌러도 값이 바뀌지 않는다 (모양 확인용이므로 그대로)', (tester) async {
      final entry = entryNamed('SmashSwitchRow');
      await open(tester, entry, catalogEntries);

      await tester.tap(inBlock(entry.name, 1.0, '꺼짐', find.text('투표 알림')));
      await tester.pump();

      expect(
        tester.widget<Switch>(inBlock(entry.name, 1.0, '꺼짐', find.byType(Switch))).value,
        isFalse,
      );
    });

    testWidgets('정적 세그먼트 상태는 눌러도 선택이 바뀌지 않는다', (tester) async {
      final entry = entryNamed('SmashSegmentedControl');
      await open(tester, entry, catalogEntries);

      await tester.tap(inBlock(entry.name, 1.0, '기본 (첫째 선택)', find.text('따로 가요')));
      await tester.pump();

      expect(
        checkIconIn(find.ancestor(
          of: inBlock(entry.name, 1.0, '기본 (첫째 선택)', find.text('같이 가요')),
          matching: find.byType(SmashPressable),
        )),
        findsOneWidget,
        reason: '정적 상태의 선택은 그대로 첫째 조각',
      );
    });

    testWidgets('정적 체크박스 상태는 눌러도 값이 바뀌지 않는다', (tester) async {
      final entry = entryNamed('SmashCheckboxRow');
      await open(tester, entry, catalogEntries);

      await tester.tap(inBlock(entry.name, 1.0, '해제', find.text('개인정보 처리방침에 동의해요')));
      await tester.pump();

      expect(
        tester.widget<Checkbox>(inBlock(entry.name, 1.0, '해제', find.byType(Checkbox))).value,
        isFalse,
      );
    });
  });

  group('등록 목록 점검 (컴포넌트가 늘어나도 계속 지켜져야 하는 규칙)', () {
    test('컴포넌트 이름이 중복되지 않는다', () {
      final names = catalogEntries.map((e) => e.name).toList();

      expect(names.toSet().length, names.length);
    });

    test('모든 컴포넌트가 최소 한 가지 상태를 가진다', () {
      for (final entry in catalogEntries) {
        expect(entry.states, isNotEmpty, reason: entry.name);
      }
    });

    test('한 컴포넌트 안에서 상태 이름이 중복되지 않는다', () {
      for (final entry in catalogEntries) {
        final labels = entry.states.map((s) => s.label).toList();

        expect(labels.toSet().length, labels.length, reason: entry.name);
      }
    });
  });
}
