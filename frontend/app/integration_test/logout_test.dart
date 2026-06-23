import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smash_app/app.dart';

// 목(mock) 없이 실제 백엔드(localhost:8080)로 부원 로그인 -> 로그아웃을 확인한다.
// 사전 조건: 백엔드가 떠 있고, test/test1234 MEMBER 계정이 DB에 있어야 한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('부원이 로그인 후 로그아웃하면 로그인 화면으로 돌아간다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    await tester.enterText(find.byType(TextField).first, 'test');
    await tester.enterText(find.byType(TextField).last, 'test1234');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('부원 홈'), findsOneWidget);
    expect(find.textContaining('테스트부원'), findsOneWidget);

    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('SMASH 로그인'), findsOneWidget);
  });
}
