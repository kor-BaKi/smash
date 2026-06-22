import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smash_app/main.dart';

void main() {
  testWidgets('로그인 화면이 학번/비밀번호 입력란과 로그인 버튼을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmashApp()));

    expect(find.text('SMASH 로그인'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
  });
}
