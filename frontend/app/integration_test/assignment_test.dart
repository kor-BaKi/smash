import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/main.dart';

// 실제 백엔드로 3단계(엔진1 조 배정) 화면을 검증한다.
// 사전 조건: club_groups에 10개 조가 이미 있고, 부원 계정(30001/test1234, group_id=NULL)이 있어야 한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('부원이 가능요일을 제출한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, '30001');
    await tester.enterText(find.byType(TextField).last, 'test1234');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('부원 홈'), findsOneWidget);

    await tester.tap(find.text('가능요일 제출'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(CheckboxListTile), findsNWidgets(10));

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '제출'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('이미 조 배정이 완료되었습니다'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNWidgets(10));
  });

  testWidgets('임원이 미배정자를 자동배정 확정한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'smash2026');
    await tester.enterText(find.byType(TextField).last, 'smash2017');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('조 배정'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('테스트부원'), findsOneWidget);

    await tester.tap(find.text('자동배정 미리보기'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('배정 결과'), findsOneWidget);

    final confirmButton = find.widgetWithText(FilledButton, '확정');
    await tester.ensureVisible(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(confirmButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('미배정자가 없습니다.'), findsOneWidget);
  });
}
