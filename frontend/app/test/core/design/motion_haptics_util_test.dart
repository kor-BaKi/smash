import 'package:app/core/design/haptics.dart';
import 'package:app/core/design/motion.dart';
import 'package:app/core/design/motion_context.dart';
import 'package:app/core/design/smash_haptics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump.dart';

void main() {
  group('모션 줄이기', () {
    Future<BuildContext> pumpWith(WidgetTester tester, {required bool reduce}) async {
      late BuildContext captured;
      await tester.pumpWidget(smashHarness(
        Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
        disableAnimations: reduce,
      ));
      return captured;
    }

    testWidgets('설정이 꺼져 있으면 이동 모션 길이를 그대로 쓴다', (tester) async {
      final context = await pumpWith(tester, reduce: false);

      expect(context.reduceMotion, isFalse);
      expect(context.moveDuration(SmashMotion.slow), SmashMotion.slow);
    });

    testWidgets('설정이 켜져 있으면 이동 모션 길이는 0이다', (tester) async {
      final context = await pumpWith(tester, reduce: true);

      expect(context.reduceMotion, isTrue);
      expect(context.moveDuration(SmashMotion.slow), Duration.zero);
      expect(context.moveDuration(SmashMotion.fast), Duration.zero);
    });
  });

  group('햅틱 호출', () {
    final expected = {
      SmashHaptic.selection: 'HapticFeedbackType.selectionClick',
      SmashHaptic.light: 'HapticFeedbackType.lightImpact',
      SmashHaptic.medium: 'HapticFeedbackType.mediumImpact',
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} → ${entry.value}', (tester) async {
        final calls = captureHaptics(tester);

        await SmashHaptics.fire(entry.key);

        expect(calls, [entry.value]);
      });
    }

    test('정의된 모든 햅틱 종류가 호출 방식을 가진다', () {
      expect(expected.keys.toSet(), SmashHaptic.values.toSet());
    });
  });
}
