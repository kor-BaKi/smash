import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/haptics.dart';
import 'package:app/core/design/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

Widget iconButton({VoidCallback? onPressed, SmashHaptic? haptic, Color? color}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: SmashIconButton(
      icon: Icons.close,
      semanticLabel: '닫기',
      onPressed: onPressed,
      haptic: haptic,
      color: color,
    ),
  );
}

Icon iconOf(WidgetTester tester) => tester.widget<Icon>(find.byIcon(Icons.close));

void main() {
  testWidgets('탭하면 onPressed가 한 번 호출된다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(smashHarness(iconButton(onPressed: () => taps++)));

    await tester.tap(find.byType(SmashIconButton));
    await tester.pump();

    expect(taps, 1);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('배율 $scale: 터치 영역은 항상 48x48, 아이콘은 24', (tester) async {
      await tester.pumpWidget(smashHarness(iconButton(onPressed: () {}), textScale: scale));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SmashIconButton)), const Size(48, 48));
      expect(iconOf(tester).size, 24);
    });
  }

  testWidgets('색: 기본은 본문색, 지정하면 그 색, 비활성은 비활성 색', (tester) async {
    await tester.pumpWidget(smashHarness(iconButton(onPressed: () {})));
    expect(iconOf(tester).color, SmashColors.text);

    await tester.pumpWidget(smashHarness(iconButton(onPressed: () {}, color: SmashColors.danger)));
    expect(iconOf(tester).color, SmashColors.danger);

    await tester.pumpWidget(smashHarness(iconButton(onPressed: null, color: SmashColors.danger)));
    expect(iconOf(tester).color, SmashColors.textDisabled);
  });

  testWidgets('비활성이면 탭이 먹히지 않고 눌러도 작아지지 않는다', (tester) async {
    await tester.pumpWidget(smashHarness(iconButton(onPressed: null)));

    final gesture = await tester.startGesture(tester.getCenter(find.byType(SmashIconButton)));
    await tester.pump(SmashMotion.fast);

    final scale = tester.widget<AnimatedScale>(find.descendant(
      of: find.byType(SmashIconButton),
      matching: find.byType(AnimatedScale),
    ));
    expect(scale.scale, 1.0);
    await gesture.up();
  });

  testWidgets('스크린리더: 버튼 역할과 지정한 문구를 읽고, 아이콘 자체는 읽지 않는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(smashHarness(iconButton(onPressed: () {})));

    final data = tester
        .getSemantics(find.descendant(
          of: find.byType(SmashIconButton),
          matching: find.byType(SmashPressable),
        ))
        .getSemanticsData();

    expect(data.label, '닫기');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    handle.dispose();
  });

  test('semanticLabel이 비어 있으면 만들 수 없다 (아이콘만 있는 버튼은 라벨 필수)', () {
    expect(
      () => SmashIconButton(icon: Icons.close, semanticLabel: '', onPressed: () {}),
      throwsAssertionError,
    );
  });

  testWidgets('haptic을 지정하면 누르는 순간 햅틱이 나간다', (tester) async {
    final calls = captureHaptics(tester);
    await tester.pumpWidget(smashHarness(
      iconButton(onPressed: () {}, haptic: SmashHaptic.selection),
    ));

    await tester.tap(find.byType(SmashIconButton));
    await tester.pump();

    expect(calls, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('눌리면 연한 배경 원이 나타난다', (tester) async {
    await tester.pumpWidget(smashHarness(
      SmashForcePressed(child: iconButton(onPressed: () {})),
    ));
    await tester.pump(SmashMotion.fast);

    final face = tester.widget<AnimatedContainer>(find.descendant(
      of: find.byType(SmashIconButton),
      matching: find.byType(AnimatedContainer),
    ));
    expect((face.decoration as BoxDecoration).color, SmashColors.fillDisabled);
  });
}
