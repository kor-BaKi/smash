import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/haptics.dart';
import 'package:app/core/design/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

AnimatedContainer faceOf(WidgetTester tester) => tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(SmashButton),
        matching: find.byType(AnimatedContainer),
      ),
    );

Color? backgroundOf(WidgetTester tester) =>
    (faceOf(tester).decoration as BoxDecoration).color;

double scaleOf(WidgetTester tester) => tester
    .widget<AnimatedScale>(find.descendant(
      of: find.byType(SmashButton),
      matching: find.byType(AnimatedScale),
    ))
    .scale;

void main() {
  group('눌림과 탭', () {
    testWidgets('탭하면 onPressed가 한 번 호출된다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () => taps++),
      ));

      await tester.tap(find.byType(SmashButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('누르는 동안 0.97배로 작아지고 눌린 색이 되며, 떼면 돌아온다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
      ));
      expect(scaleOf(tester), 1.0);
      expect(backgroundOf(tester), SmashColors.brand);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(SmashButton)));
      await tester.pump();
      await tester.pump(SmashMotion.fast);

      expect(scaleOf(tester), SmashMotion.pressedScale);
      expect(backgroundOf(tester), SmashColors.brandPressed);

      await gesture.up();
      await tester.pump();
      await tester.pump(SmashMotion.fast);

      expect(scaleOf(tester), 1.0);
      expect(backgroundOf(tester), SmashColors.brand);
    });

    testWidgets('모션 줄이기가 켜져 있으면 크기는 변하지 않고 색만 바뀐다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
        disableAnimations: true,
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.byType(SmashButton)));
      await tester.pump();
      await tester.pump(SmashMotion.fast);

      expect(scaleOf(tester), 1.0);
      expect(backgroundOf(tester), SmashColors.brandPressed);
      await gesture.up();
    });

    testWidgets('SmashForcePressed 안에서도 비활성 버튼은 눌린 모양이 되지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashForcePressed(
          child: SmashButton(label: '참여할게요', onPressed: null),
        ),
      ));
      await tester.pump(SmashMotion.fast);

      expect(scaleOf(tester), 1.0);
      expect(backgroundOf(tester), SmashColors.fillDisabled);
    });

    testWidgets('SmashForcePressed 안에서는 손가락 없이 눌린 모양이 된다 (카탈로그용)', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashForcePressed(child: SmashButton(label: '참여할게요', onPressed: () {})),
      ));
      await tester.pump(SmashMotion.fast);

      expect(scaleOf(tester), SmashMotion.pressedScale);
      expect(backgroundOf(tester), SmashColors.brandPressed);
    });
  });

  group('비활성과 로딩', () {
    testWidgets('onPressed가 null이면 비활성: 탭이 먹히지 않고 비활성 색', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashButton(label: '참여할게요', onPressed: null),
      ));

      expect(backgroundOf(tester), SmashColors.fillDisabled);
      final text = tester.widget<Text>(find.text('참여할게요'));
      expect(text.style!.color, SmashColors.textDisabled);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(SmashButton)));
      await tester.pump(SmashMotion.fast);
      expect(scaleOf(tester), 1.0, reason: '비활성은 눌려도 작아지지 않는다');
      await gesture.up();
    });

    testWidgets('로딩 중에는 진행 표시를 보이고 탭을 무시하며 크기가 변하지 않는다', (tester) async {
      var taps = 0;
      Widget build({required bool loading}) => smashHarness(
            SmashButton(label: '참여할게요', isLoading: loading, onPressed: () => taps++),
          );

      await tester.pumpWidget(build(loading: false));
      final before = tester.getSize(find.byType(SmashButton));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(build(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(SmashButton)), before);
      await tester.tap(find.byType(SmashButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('로딩 중에는 비활성 색이 아니라 원래 색을 유지한다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', isLoading: true, onPressed: () {}),
      ));
      await tester.pump();

      expect(backgroundOf(tester), SmashColors.brand);
    });
  });

  group('변형', () {
    final expected = {
      SmashButtonVariant.primary: (SmashColors.brand, SmashColors.onBrand),
      SmashButtonVariant.danger: (SmashColors.danger, SmashColors.onBrand),
      SmashButtonVariant.secondary: (SmashColors.surface, SmashColors.text),
      SmashButtonVariant.text: (Colors.transparent, SmashColors.brand),
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name}: 배경과 글자색', (tester) async {
        await tester.pumpWidget(smashHarness(
          SmashButton(label: '확인', variant: entry.key, onPressed: () {}),
        ));

        expect(backgroundOf(tester), entry.value.$1);
        expect(tester.widget<Text>(find.text('확인')).style!.color, entry.value.$2);
      });
    }

    testWidgets('secondary는 조작 요소 테두리(border) 색을 쓴다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '취소', variant: SmashButtonVariant.secondary, onPressed: () {}),
      ));

      final decoration = faceOf(tester).decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, SmashColors.border);
    });
  });

  group('크기와 글자 확대', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: large 높이 52 이상, medium 48 이상, 오류 없음', (tester) async {
        await tester.pumpWidget(smashHarness(
          Column(mainAxisSize: MainAxisSize.min, children: [
            SmashButton(label: '참여 여부를 선택해 주세요', onPressed: () {}),
            SmashButton(
              label: '취소',
              size: SmashButtonSize.medium,
              variant: SmashButtonVariant.secondary,
              onPressed: () {},
            ),
          ]),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        final sizes = tester
            .widgetList(find.byType(SmashButton))
            .map((w) => tester.getSize(find.byWidget(w)))
            .toList();
        expect(sizes[0].height, greaterThanOrEqualTo(52));
        expect(sizes[1].height, greaterThanOrEqualTo(48));
        if (scale == 1.0) {
          // 높이가 정확히 52, 48이어야 한다 (부모 공간을 채우며 커지지 않음)
          expect(sizes[0].height, 52);
          expect(sizes[1].height, 48);
        }
      });
    }

    testWidgets('글자가 커지면 버튼이 줄지 않고 늘어난다', (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpWidget(smashHarness(
          SmashButton(label: '참여 여부를 선택해 주세요', onPressed: () {}),
          textScale: scale,
        ));
        return tester.getSize(find.byType(SmashButton)).height;
      }

      final normal = await heightAt(1.0);
      final large = await heightAt(2.0);

      expect(large, greaterThan(normal));
    });

    testWidgets('expanded: false이면 글자 너비만큼만 차지하되 터치 영역은 48 이상', (tester) async {
      await tester.pumpWidget(smashHarness(
        Align(
          alignment: Alignment.centerLeft,
          child: SmashButton(label: '확인', expanded: false, onPressed: () {}),
        ),
      ));

      final size = tester.getSize(find.byType(SmashButton));
      expect(size.width, lessThan(320));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('접근성과 키보드', () {
    testWidgets('스크린리더: 버튼 역할과 글자, 활성 상태를 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
      ));

      final node = tester.getSemantics(find.descendant(of: find.byType(SmashButton), matching: find.byType(SmashPressable)));
      final data = node.getSemanticsData();

      expect(data.label, contains('참여할게요'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('비활성이면 활성 상태가 꺼진 것으로 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const SmashButton(label: '참여할게요', onPressed: null),
      ));

      final data = tester.getSemantics(find.descendant(of: find.byType(SmashButton), matching: find.byType(SmashPressable))).getSemanticsData();

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('로딩 중이면 "처리 중"을 함께 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', isLoading: true, onPressed: () {}),
      ));
      await tester.pump();

      final data = tester.getSemantics(find.descendant(of: find.byType(SmashButton), matching: find.byType(SmashPressable))).getSemanticsData();

      expect(data.label, '참여할게요, 처리 중');
      handle.dispose();
    });

    testWidgets('키보드: Tab으로 포커스하면 링이 보이고 Enter로 실행된다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () => taps++),
      ));
      expect(faceOf(tester).foregroundDecoration, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(faceOf(tester).foregroundDecoration, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('입력 방식이 터치로 고정이면 키보드로 이동해도 링이 보이지 않는다 (링은 키보드 이동일 때만)',
        (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
      ));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(faceOf(tester).foregroundDecoration, isNull);
    });

    testWidgets('터치로 눌렀을 때는 포커스 링이 남지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
      ));

      await tester.tap(find.byType(SmashButton));
      await tester.pump();

      expect(faceOf(tester).foregroundDecoration, isNull);
    });
  });

  group('햅틱', () {
    testWidgets('haptic을 지정하면 누르는 순간 해당 햅틱이 한 번 나간다', (tester) async {
      final calls = captureHaptics(tester);
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '삭제', haptic: SmashHaptic.medium, onPressed: () {}),
      ));

      await tester.tap(find.byType(SmashButton));
      await tester.pump();

      expect(calls, ['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('지정하지 않으면 햅틱이 나가지 않는다 (성공 확정 뒤에 화면이 부른다)', (tester) async {
      final calls = captureHaptics(tester);
      await tester.pumpWidget(smashHarness(
        SmashButton(label: '참여할게요', onPressed: () {}),
      ));

      await tester.tap(find.byType(SmashButton));
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('로딩 중에 눌러도 햅틱이 나가지 않는다', (tester) async {
      final calls = captureHaptics(tester);
      await tester.pumpWidget(smashHarness(
        SmashButton(
          label: '삭제',
          isLoading: true,
          haptic: SmashHaptic.medium,
          onPressed: () {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(SmashButton));
      await tester.pump();

      expect(calls, isEmpty);
    });
  });
}
