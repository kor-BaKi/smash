import 'dart:ui' show CheckedState, Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

void main() {
  group('SmashSwitchRow', () {
    Widget row({bool value = false, ValueChanged<bool>? onChanged, String? description}) =>
        SmashSwitchRow(
          label: '투표 알림',
          description: description,
          value: value,
          onChanged: onChanged,
        );

    testWidgets('줄 어디를 눌러도 값이 바뀐다 (글자 쪽을 눌러도, 스위치를 눌러도)', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(smashHarness(row(onChanged: changes.add)));

      await tester.tap(find.text('투표 알림'));
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changes, [true, true]);
    });

    testWidgets('켜져 있으면 끄는 값(false)을 보낸다', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(smashHarness(row(value: true, onChanged: changes.add)));

      await tester.tap(find.text('투표 알림'));
      await tester.pump();

      expect(changes, [false]);
    });

    testWidgets('설명 문구가 있으면 라벨 아래에 보인다', (tester) async {
      await tester.pumpWidget(smashHarness(
        row(onChanged: (_) {}, description: '새 투표가 올라오면 알려드려요'),
      ));

      expect(find.text('새 투표가 올라오면 알려드려요'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('새 투표가 올라오면 알려드려요')).dy,
        greaterThan(tester.getTopLeft(find.text('투표 알림')).dy),
      );
    });

    testWidgets('비활성이면 눌러도 바뀌지 않고 글자가 비활성 색이다', (tester) async {
      await tester.pumpWidget(smashHarness(row(onChanged: null)));

      await tester.tap(find.text('투표 알림'), warnIfMissed: false);
      await tester.pump();

      expect(tester.widget<Text>(find.text('투표 알림')).style!.color, SmashColors.textDisabled);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('스크린리더: 라벨, 설명, 켜짐 여부를 한 번에 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        row(value: true, onChanged: (_) {}, description: '새 투표가 올라오면 알려드려요'),
      ));

      final data = tester.getSemantics(find.byType(SmashSwitchRow)).getSemanticsData();

      expect(data.label, contains('투표 알림'));
      expect(data.hint, contains('새 투표가 올라오면 알려드려요'));
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('스크린리더: 꺼짐과 비활성도 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(row(onChanged: null)));

      final data = tester.getSemantics(find.byType(SmashSwitchRow)).getSemanticsData();

      expect(data.flagsCollection.isToggled, Tristate.isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 줄 높이는 56 이상, 스위치 터치 영역 48 이상',
          (tester) async {
        await tester.pumpWidget(smashHarness(
          row(onChanged: (_) {}, description: '새 투표가 올라오면 알려드려요'),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(SmashSwitchRow)).height, greaterThanOrEqualTo(56));
        expect(tester.getSize(find.byType(Switch)).height, greaterThanOrEqualTo(48));
      });
    }

    testWidgets('켜짐은 브랜드 트랙, 꺼짐은 border 테두리 (스위치 모양으로도 구분)', (tester) async {
      await tester.pumpWidget(smashHarness(row(value: true, onChanged: (_) {})));
      final on = tester.widget<Switch>(find.byType(Switch));
      expect(on.trackColor!.resolve({WidgetState.selected}), SmashColors.brand);

      await tester.pumpWidget(smashHarness(row(onChanged: (_) {})));
      final off = tester.widget<Switch>(find.byType(Switch));
      expect(off.trackOutlineColor!.resolve({}), SmashColors.border);
    });
  });

  group('SmashCheckboxRow', () {
    Widget row({bool value = false, ValueChanged<bool>? onChanged, String? description}) =>
        SmashCheckboxRow(
          label: '개인정보 처리방침에 동의해요',
          description: description,
          value: value,
          onChanged: onChanged,
        );

    testWidgets('줄 어디를 눌러도 값이 바뀐다 (글자 쪽을 눌러도, 체크박스를 눌러도)', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(smashHarness(row(onChanged: changes.add)));

      await tester.tap(find.text('개인정보 처리방침에 동의해요'));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(changes, [true, true]);
    });

    testWidgets('체크되어 있으면 해제 값(false)을 보낸다', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(smashHarness(row(value: true, onChanged: changes.add)));

      await tester.tap(find.text('개인정보 처리방침에 동의해요'));
      await tester.pump();

      expect(changes, [false]);
    });

    testWidgets('비활성이면 눌러도 바뀌지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(row(onChanged: null)));

      await tester.tap(find.text('개인정보 처리방침에 동의해요'), warnIfMissed: false);
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(
        tester.widget<Text>(find.text('개인정보 처리방침에 동의해요')).style!.color,
        SmashColors.textDisabled,
      );
    });

    testWidgets('체크박스의 테두리와 채움은 토큰 색이다 (border, 선택 시 브랜드)', (tester) async {
      await tester.pumpWidget(smashHarness(row(value: true, onChanged: (_) {})));
      final checked = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checked.fillColor!.resolve({WidgetState.selected}), SmashColors.brand);
      expect(checked.checkColor, SmashColors.onBrand);
      expect((checked.side! as WidgetStateProperty<BorderSide?>).resolve({})!.color, SmashColors.border);
    });

    testWidgets('스크린리더: 라벨, 설명, 체크 여부를 한 번에 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        row(value: true, onChanged: (_) {}, description: '가입을 위해 꼭 필요해요'),
      ));

      final data = tester.getSemantics(find.byType(SmashCheckboxRow)).getSemanticsData();

      expect(data.label, contains('개인정보 처리방침에 동의해요'));
      expect(data.hint, contains('가입을 위해 꼭 필요해요'));
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('스크린리더: 체크 안 됨과 비활성도 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(row(onChanged: null)));

      final data = tester.getSemantics(find.byType(SmashCheckboxRow)).getSemanticsData();

      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 줄 높이와 체크박스 터치 영역은 48 이상', (tester) async {
        await tester.pumpWidget(smashHarness(
          row(onChanged: (_) {}, description: '가입을 위해 꼭 필요해요'),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(SmashCheckboxRow)).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(find.byType(Checkbox)).height, greaterThanOrEqualTo(48));
      });
    }

    testWidgets('긴 라벨은 줄바꿈된다 (2.0배)', (tester) async {
      await tester.pumpWidget(smashHarness(
        row(onChanged: (_) {}),
        textScale: 2.0,
      ));

      final label = tester.widget<Text>(find.text('개인정보 처리방침에 동의해요'));
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      expect(label.maxLines, isNull);
    });
  });
}
