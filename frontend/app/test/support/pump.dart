import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 컴포넌트 위젯 테스트용 공통 틀: SMASH 라이트 테마 + 글자 배율 + 모션 줄이기 설정
Widget smashHarness(
  Widget child, {
  double textScale = 1.0,
  bool disableAnimations = false,
  double width = 320,
}) {
  return MaterialApp(
    theme: SmashTheme.light(),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: app!,
    ),
    home: Scaffold(
      body: Center(child: SizedBox(width: width, child: child)),
    ),
  );
}

/// 플랫폼 채널로 나가는 햅틱 호출을 모아 둔다.
/// 반환된 목록에 'HapticFeedbackType.lightImpact' 같은 인자가 쌓인다.
List<String> captureHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}
