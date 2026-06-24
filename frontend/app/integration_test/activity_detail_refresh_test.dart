import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/app.dart';

// 실제 백엔드로 회귀 검증: activityDetailProvider가 autoDispose가 아니면 상세보기를 한 번
// 본 뒤 참여를 추가해도 다시 들어갔을 때 캐시된 옛 값(0명)이 그대로 보이는 버그가 있었다.
// 사전 조건: test/test1234 MEMBER 계정, 오늘 그룹 38(수 3-5시) 활동에 해당 계정의 참여 기록이 없고
// 투표가 아직 마감(15:00) 전이어야 한다 (SLOT_15_17 마감 시각 기준).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('타조참여 후 상세보기를 다시 열면 최신 인원으로 갱신된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'test');
    await tester.enterText(find.byType(TextField).last, 'test1234');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('오늘의 투표'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('전체 조'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final card = find.ancestor(of: find.text('수 3-5시'), matching: find.byType(Card));
    expect(card, findsOneWidget);

    // 상세보기를 먼저 한 번 열어 0명 상태를 캐시에 남긴다.
    await tester.tap(find.descendant(of: card, matching: find.widgetWithText(TextButton, '상세보기')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('테스트부원'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 같은 활동에 타조참여로 응답.
    await tester.tap(find.descendant(of: card, matching: find.widgetWithText(OutlinedButton, '타조참여')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 상세보기를 다시 열었을 때 캐시된 0명이 아니라 갱신된 1명이 보여야 한다.
    await tester.tap(find.descendant(of: card, matching: find.widgetWithText(TextButton, '상세보기')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('테스트부원'), findsOneWidget);
  });
}
