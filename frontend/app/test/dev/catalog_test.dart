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
    tester.view.physicalSize = const Size(400, 12000);
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
