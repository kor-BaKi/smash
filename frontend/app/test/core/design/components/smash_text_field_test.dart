import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

Finder get field => find.byType(TextField);

TextField textFieldOf(WidgetTester tester) => tester.widget<TextField>(field);

OutlineInputBorder? borderOf(WidgetTester tester, {bool focused = false}) {
  final decoration = textFieldOf(tester).decoration!;
  return (focused ? decoration.focusedBorder : decoration.enabledBorder) as OutlineInputBorder?;
}

// 힌트는 사라지는 것이 아니라 투명도가 0이 된다
double hintOpacity(WidgetTester tester, String hint) => tester
    .widget<AnimatedOpacity>(find
        .ancestor(of: find.text(hint), matching: find.byType(AnimatedOpacity))
        .first)
    .opacity;

SemanticsData semanticsOf(WidgetTester tester) =>
    tester.getSemantics(field).getSemanticsData();

void main() {
  group('라벨, 힌트, 도움말', () {
    testWidgets('라벨은 입력창 위에 항상 보이고, 힌트는 비어 있을 때만 보인다', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '학번', hint: '예: 20250001', controller: controller),
      ));

      expect(find.text('학번'), findsOneWidget);
      expect(hintOpacity(tester, '예: 20250001'), 1.0);
      expect(tester.getTopLeft(find.text('학번')).dy, lessThan(tester.getTopLeft(field).dy));

      await tester.enterText(field, '20250001');
      await tester.pump();

      expect(find.text('학번'), findsOneWidget, reason: '입력해도 라벨은 사라지지 않는다');
      expect(hintOpacity(tester, '예: 20250001'), 0.0, reason: '입력하면 힌트는 투명해진다');
    });

    testWidgets('입력하면 controller와 onChanged에 반영되고 제출하면 onSubmitted가 불린다', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      final submits = <String>[];
      await tester.pumpWidget(smashHarness(
        SmashTextField(
          label: '이름',
          controller: controller,
          onChanged: changes.add,
          onSubmitted: submits.add,
        ),
      ));

      await tester.enterText(field, '김스매시');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(controller.text, '김스매시');
      expect(changes, ['김스매시']);
      expect(submits, ['김스매시']);
    });

    testWidgets('도움말은 입력창 아래에 보이고, 오류가 생기면 오류로 바뀐다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '학번', helper: '숫자만 입력해 주세요'),
      ));
      expect(find.text('숫자만 입력해 주세요'), findsOneWidget);
      expect(tester.getTopLeft(find.text('숫자만 입력해 주세요')).dy,
          greaterThan(tester.getBottomLeft(field).dy - 1));

      await tester.pumpWidget(smashHarness(
        const SmashTextField(
          label: '학번',
          helper: '숫자만 입력해 주세요',
          errorText: '등록되지 않은 학번이에요',
        ),
      ));
      expect(find.text('숫자만 입력해 주세요'), findsNothing);
      expect(find.text('등록되지 않은 학번이에요'), findsOneWidget);
    });
  });

  group('오류 표시 (색만으로 전달하지 않는다)', () {
    testWidgets('오류는 아이콘과 문구, 위험색 테두리로 보인다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '비밀번호', errorText: '비밀번호가 맞지 않아요'),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('비밀번호가 맞지 않아요'), findsOneWidget);
      expect(borderOf(tester)!.borderSide.color, SmashColors.danger);
      expect(borderOf(tester, focused: true)!.borderSide.color, SmashColors.danger);
      final errorText = tester.widget<Text>(find.text('비밀번호가 맞지 않아요'));
      expect(errorText.style!.color, SmashColors.danger);
    });

    testWidgets('오류가 없으면 테두리는 border 색, 포커스는 브랜드 2px', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashTextField(label: '학번')));

      expect(borderOf(tester)!.borderSide.color, SmashColors.border);
      expect(borderOf(tester, focused: true)!.borderSide.color, SmashColors.brand);
      expect(borderOf(tester, focused: true)!.borderSide.width, 2);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('빈 문자열 오류는 오류로 취급하지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '학번', errorText: ''),
      ));

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(borderOf(tester)!.borderSide.color, SmashColors.border);
    });
  });

  group('스크린리더', () {
    testWidgets('입력창이 라벨과 도움말을 함께 읽고, 라벨 글자를 따로 한 번 더 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '학번', helper: '숫자만 입력해 주세요'),
      ));

      final data = semanticsOf(tester);
      expect(data.label, contains('학번'));
      expect(data.hint, contains('숫자만 입력해 주세요'));
      expect(data.flagsCollection.isTextField, isTrue);
      expect(find.bySemanticsLabel('학번'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('오류는 "오류: …"로 읽히고 실시간 안내(liveRegion)로 알려진다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '비밀번호', errorText: '비밀번호가 맞지 않아요'),
      ));

      final node = tester.getSemantics(find.bySemanticsLabel('오류: 비밀번호가 맞지 않아요'));
      final data = node.getSemanticsData();

      expect(data.label, '오류: 비밀번호가 맞지 않아요');
      expect(data.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('비활성이면 활성 상태가 꺼진 것으로 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '학번', enabled: false),
      ));

      expect(semanticsOf(tester).flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('상태', () {
    testWidgets('비활성: 입력할 수 없고 비활성 배경과 테두리', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '학번', enabled: false),
      ));

      final decoration = textFieldOf(tester).decoration!;
      expect(textFieldOf(tester).enabled, isFalse);
      expect(decoration.fillColor, SmashColors.fillDisabled);
      expect((decoration.disabledBorder as OutlineInputBorder).borderSide.color, SmashColors.line);
    });

    testWidgets('읽기 전용: 값은 보이지만 입력으로 바뀌지 않는다', (tester) async {
      final controller = TextEditingController(text: '20250001');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '학번', controller: controller, readOnly: true),
      ));

      expect(textFieldOf(tester).readOnly, isTrue);
      expect(find.text('20250001'), findsOneWidget);
    });

    testWidgets('글자 수 제한 글자수 표시(카운터)는 보이지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '메모', maxLength: 10),
      ));

      expect(find.text('0/10'), findsNothing);
      expect(textFieldOf(tester).maxLength, 10);
    });

    testWidgets('여러 줄 입력: maxLines와 minLines가 전달된다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(label: '메모', maxLines: 5, minLines: 3),
      ));

      expect(textFieldOf(tester).maxLines, 5);
      expect(textFieldOf(tester).minLines, 3);
    });

    testWidgets('prefix와 suffix를 누르는 동안 입력창 포커스가 유지된다', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var taps = 0;
      await tester.pumpWidget(smashHarness(
        SmashTextField(
          label: '검색',
          focusNode: focus,
          suffix: SmashIconButton(icon: Icons.close, semanticLabel: '지우기', onPressed: () => taps++),
        ),
      ));
      await tester.tap(field);
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.byType(SmashIconButton));
      await tester.pump();

      expect(taps, 1);
      expect(focus.hasFocus, isTrue, reason: '아이콘을 눌러도 키보드가 내려가지 않는다');
    });
  });

  group('한국어 입력과 키보드', () {
    testWidgets('키보드 종류, 엔터 키 동작, 자동완성 힌트가 그대로 전달된다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(
          label: '학번',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofillHints: [AutofillHints.username],
        ),
      ));

      final widget = textFieldOf(tester);
      expect(widget.keyboardType, TextInputType.number);
      expect(widget.textInputAction, TextInputAction.next);
      expect(widget.autofillHints, [AutofillHints.username]);
    });

    testWidgets('자동 교정, 추천어, 개인화 학습을 끌 수 있다 (학번, 가입코드)', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashTextField(
          label: '가입코드',
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
        ),
      ));

      final widget = textFieldOf(tester);
      expect(widget.autocorrect, isFalse);
      expect(widget.enableSuggestions, isFalse);
      expect(widget.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('입력창 바깥을 누르면 키보드가 내려간다 (숫자 키패드에는 완료 키가 없는 기기가 있음)',
        (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(smashHarness(
        Column(children: [
          SmashTextField(label: '학번', focusNode: focus),
          const SizedBox(height: 200),
          const Text('바깥 영역'),
        ]),
      ));
      await tester.tap(field);
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.text('바깥 영역'));
      await tester.pump();

      expect(focus.hasFocus, isFalse);
    });

    testWidgets('한글 조합 중에는 isComposing이 true이고, 조합이 끝나면 false다', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '이름', controller: controller),
      ));
      await tester.showKeyboard(field);

      // "한"을 입력하는 중: 조합 범위가 글자 전체
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '한',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ));
      await tester.pump();
      expect(controller.value.isComposing, isTrue);

      // 조합 확정
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '한',
        selection: TextSelection.collapsed(offset: 1),
      ));
      await tester.pump();
      expect(controller.value.isComposing, isFalse);
    });

    testWidgets('조합 중에도 onChanged가 불리므로 검증은 isComposing이 false일 때만 해야 한다', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final composingFlags = <bool>[];
      await tester.pumpWidget(smashHarness(
        SmashTextField(
          label: '이름',
          controller: controller,
          onChanged: (_) => composingFlags.add(controller.value.isComposing),
        ),
      ));
      await tester.showKeyboard(field);

      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '하',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ));
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '한',
        selection: TextSelection.collapsed(offset: 1),
      ));
      await tester.pump();

      expect(composingFlags, [true, false]);
    });

    testWidgets('글자 수 제한: 조합 중에는 자르지 않고 조합이 끝난 뒤에 자른다 (조합이 끊기지 않음)',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '이름', controller: controller, maxLength: 2),
      ));
      await tester.showKeyboard(field);

      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '한글입',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 2, end: 3),
      ));
      await tester.pump();
      expect(controller.text, '한글입', reason: '조합 중에는 글자를 자르지 않는다');

      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '한글입',
        selection: TextSelection.collapsed(offset: 3),
      ));
      await tester.pump();
      expect(controller.text, '한글', reason: '조합이 끝나면 제한(2글자)에 맞춰 자른다');
    });

    testWidgets('붙여넣기를 막지 않는다 (비밀번호 관리자, 학번 복사)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '학번', controller: controller),
      ));
      await tester.showKeyboard(field);

      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '20250001',
        selection: TextSelection.collapsed(offset: 8),
      ));
      await tester.pump();

      expect(controller.text, '20250001');
    });
  });

  group('글자 확대', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 입력창 높이 52 이상, 긴 라벨과 오류는 줄바꿈', (tester) async {
        await tester.pumpWidget(smashHarness(
          const SmashTextField(
            label: '정산 계좌번호를 입력해 주세요',
            hint: '예: 123-456-789012',
            errorText: '계좌번호는 숫자와 하이픈만 입력할 수 있어요',
          ),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(field).height, greaterThanOrEqualTo(52));
        final label = tester.widget<Text>(find.text('정산 계좌번호를 입력해 주세요'));
        expect(label.overflow, isNot(TextOverflow.ellipsis));
        expect(label.maxLines, isNull);
        final error = tester.widget<Text>(find.text('계좌번호는 숫자와 하이픈만 입력할 수 있어요'));
        expect(error.maxLines, isNull);
      });
    }

    testWidgets('글자가 커지면 입력창이 줄지 않고 늘어난다', (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpWidget(smashHarness(
          const SmashTextField(label: '학번', hint: '예: 20250001'),
          textScale: scale,
        ));
        return tester.getSize(field).height;
      }

      expect(await heightAt(2.0), greaterThan(await heightAt(1.0)));
    });
  });
}
