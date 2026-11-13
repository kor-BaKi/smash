import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    // 실제 앱과 같게 한국어 로케일을 쓴다 (기본 위젯의 문구: 복사, 붙여넣기, 뒤로 등)
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
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


/// 클립보드로 나가는 복사 호출을 모으고, 붙여넣기용 값을 돌려준다.
class ClipboardLog {
  final List<String> copied = [];
  String? pasteable;
}

ClipboardLog mockClipboard(WidgetTester tester, {String? pasteable}) {
  final log = ClipboardLog()..pasteable = pasteable;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          log.copied.add((call.arguments as Map)['text'] as String);
          return null;
        case 'Clipboard.getData':
          return log.pasteable == null ? null : <String, dynamic>{'text': log.pasteable};
        case 'Clipboard.hasStrings':
          return <String, dynamic>{'value': log.pasteable != null};
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return log;
}

/// 글자가 있는 위치(입력창 왼쪽)를 길게 눌러 글자를 선택하고 메뉴를 띄운다.
Future<void> longPressText(WidgetTester tester, {Offset offset = const Offset(10, 10)}) async {
  await tester.longPressAt(tester.getTopLeft(find.byType(EditableText)) + offset);
  await tester.pumpAndSettle();
}

/// 지금 화면에 떠 있는 길게 누르기 메뉴의 항목 이름들 (예: [잘라내기, 복사, 붙여넣기])
List<String> menuLabels(WidgetTester tester) => tester
    .widgetList<TextSelectionToolbarTextButton>(find.byType(TextSelectionToolbarTextButton))
    .map((button) => (button.child as Text).data!)
    .toList();
