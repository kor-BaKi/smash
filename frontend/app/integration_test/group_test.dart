import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/app.dart';

// 실제 백엔드(localhost:8080)로 2단계(운영 설정) 화면 3개를 순서대로 검증한다.
// 사전 조건: 백엔드가 떠 있고, smash2026/smash2017 ADMIN 계정만 있고
// club_groups/invite_code 테이블이 비어 있어야 한다 (각 화면의 "비어있을 때" 분기까지 같이 확인).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('조 관리 -> 가입코드 관리 -> 일정 관리 화면이 실제 백엔드와 정상 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'smash2026');
    await tester.enterText(find.byType(TextField).last, 'smash2017');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 조 관리: 비어있을 때 -> 기본 10개 조 생성
    await tester.tap(find.text('조 관리'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('기본 10개 조 생성'), findsOneWidget);

    await tester.tap(find.text('기본 10개 조 생성'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(ListTile), findsNWidgets(10));

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 가입코드 관리: 비어있을 때 -> 발급
    await tester.tap(find.text('가입코드 관리'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('가입코드 발급'), findsOneWidget);

    await tester.tap(find.text('가입코드 발급'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('활성'), findsOneWidget);

    // 비활성 토글
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('비활성'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 정규활동 일정 관리: 10개 조합 전부 표시 + 토글
    await tester.tap(find.text('정규활동 일정 관리'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(SwitchListTile), findsNWidgets(10));

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SwitchListTile), findsNWidgets(10));
  });
}
