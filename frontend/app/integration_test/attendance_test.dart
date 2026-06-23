import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/main.dart';

// 실제 백엔드로 5단계(출석 현황) 화면을 검증한다.
// 사전 조건: 화 3-5시 조에 부원(테스트부원)이 있고, 2026년 6월 기준
// guaranteed=5, fulfilled=3(REGULAR 3건), shortfall=2, 타조참 1건이 미리 세팅되어 있어야 한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('임원이 출석 현황 3개 탭을 확인한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'smash2026');
    await tester.enterText(find.byType(TextField).last, 'smash2017');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('출석 현황'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 연/월 기본값(오늘 날짜 기준)이 테스트 데이터 기준월(2026-06)과 같아 별도 변경 없이 진행.
    expect(find.text('2026년'), findsOneWidget);
    expect(find.text('6월'), findsOneWidget);

    // 조별 현황 탭: 조 선택 후 충족/보장/미달 확인
    await tester.tap(find.text('조 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('화 3-5시').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('보장 횟수: 5회'), findsOneWidget);
    expect(find.text('충족 3 / 보장 5'), findsOneWidget);
    expect(find.text('미달 2'), findsOneWidget);

    // 전체 미달자 탭
    await tester.tap(find.text('전체 미달자'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('화 3-5시'), findsOneWidget);

    // 타조참 탭
    await tester.tap(find.text('타조참'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('1회'), findsOneWidget);

    await tester.tap(find.textContaining('1회'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('2026-06-08'), findsOneWidget);
  });
}
