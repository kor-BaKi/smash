import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/main.dart';

// 실제 백엔드로 4단계(엔진2 활동/투표) 화면을 검증한다.
// 사전 조건: 부원(30001/test1234)이 화 3-5시 조에 배정되어 있고, 오늘(화) 활동이 이미 생성되어 있어야 한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('부원이 오늘 활동에 참석 응답하고 취소한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, '30001');
    await tester.enterText(find.byType(TextField).last, 'test1234');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('오늘의 투표'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('화 3-5시'), findsOneWidget);
    expect(find.text('응답 없음'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '참석'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('내 응답: 참석'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '응답 취소'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('응답 없음'), findsOneWidget);
  });

  testWidgets('임원이 활동 관리 화면에서 활동을 취소/복구한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'smash2026');
    await tester.enterText(find.byType(TextField).last, 'smash2017');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('활동 관리'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.textContaining('화 3-5시'), findsOneWidget);

    final switches = find.byType(Switch);
    await tester.tap(switches.last);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('(취소됨)'), findsWidgets);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('(취소됨)'), findsNothing);

    // D-5: 상세 화면 진입 확인
    await tester.tap(find.textContaining('화 3-5시').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('활동 상세'), findsOneWidget);
  });
}
