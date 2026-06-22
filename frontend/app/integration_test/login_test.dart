import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/main.dart';

// 목(mock) 없이 실제 백엔드(localhost:8080)로 로그인해서 ADMIN 홈까지 분기되는지 확인한다.
// 사전 조건: 백엔드가 떠 있고, smash2026/smash2017 ADMIN 계정이 DB에 있어야 한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 백엔드로 로그인하면 ADMIN 홈으로 분기된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'smash2026');
    await tester.enterText(find.byType(TextField).last, 'smash2017');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));

    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('임원 홈'), findsOneWidget);
    expect(find.textContaining('테스트관리자'), findsOneWidget);
    expect(find.textContaining('ADMIN'), findsOneWidget);
  });
}
