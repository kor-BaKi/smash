import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

Finder get field => find.byType(TextField);
Finder get editable => find.byType(EditableText);
Finder get eye => find.byType(SmashIconButton);

bool isObscured(WidgetTester tester) => tester.widget<EditableText>(editable).obscureText;

/// 선택된 글자가 있을 때 길게 눌러 나오는 메뉴가 담게 될 항목 종류.
/// 입력창이 실제로 쓰는 메뉴 구성 함수를 같은 상태로 불러서 얻는다.
Future<List<ContextMenuButtonType>> menuTypes(
  WidgetTester tester,
  TextEditingController controller,
) async {
  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  await tester.showKeyboard(field);
  await tester.pumpAndSettle();
  final state = tester.state<EditableTextState>(editable);
  final builder = tester.widget<TextField>(field).contextMenuBuilder!;
  final menu = builder(tester.element(editable), state);
  if (menu is! AdaptiveTextSelectionToolbar) return const [];
  return menu.buttonItems!.map((item) => item.type).toList();
}

const _foreground = [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused];

/// 앱이 가려졌다가 돌아오는 과정을 Flutter가 허용하는 순서로 보낸다.
/// (resumed → inactive → hidden → paused, 돌아올 때는 반대로)
void leaveAndReturn(WidgetTester tester, AppLifecycleState to) {
  final binding = tester.binding;
  final steps = _foreground.sublist(0, _foreground.indexOf(to) + 1);
  for (final step in steps) {
    binding.handleAppLifecycleStateChanged(step);
  }
  // paused, hidden에서는 프레임이 멈추므로 앱이 돌아온 뒤에 화면을 확인한다.
  for (final step in steps.reversed.skip(1)) {
    binding.handleAppLifecycleStateChanged(step);
  }
  binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  group('보기/숨기기', () {
    testWidgets('기본은 가려져 있고 눈 아이콘은 "비밀번호 보기"라고 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));

      expect(isObscured(tester), isTrue);
      expect(find.bySemanticsLabel('비밀번호 보기'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      handle.dispose();
    });

    testWidgets('누르면 보이고 문구가 "비밀번호 숨기기"로 바뀌며, 다시 누르면 가려진다', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));

      await tester.tap(eye);
      await tester.pump();
      expect(isObscured(tester), isFalse);
      expect(find.bySemanticsLabel('비밀번호 숨기기'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(controller.text, 'abc12345', reason: '입력한 값은 그대로');

      await tester.tap(eye);
      await tester.pump();
      expect(isObscured(tester), isTrue);
      expect(find.bySemanticsLabel('비밀번호 보기'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('눈 아이콘을 눌러도 입력창 포커스(키보드)가 유지된다', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', focusNode: focus),
      ));
      await tester.tap(field);
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(eye);
      await tester.pump();

      expect(focus.hasFocus, isTrue);
    });

    testWidgets('눈 아이콘 터치 영역은 48x48', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));

      expect(tester.getSize(eye), const Size(48, 48));
    });

    testWidgets('입력창이 비활성이면 눈 아이콘도 비활성이다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashPasswordField(label: '비밀번호', enabled: false),
      ));

      await tester.tap(eye, warnIfMissed: false);
      await tester.pump();

      expect(isObscured(tester), isTrue);
    });
  });

  group('보안: 앱이 비활성이 되면 다시 가린다', () {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      testWidgets('${state.name} 상태가 되면 보이던 비밀번호를 가린다', (tester) async {
        addTearDown(() => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
        await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));
        await tester.tap(eye);
        await tester.pump();
        expect(isObscured(tester), isFalse);

        leaveAndReturn(tester, state);
        await tester.pump();

        expect(isObscured(tester), isTrue, reason: '돌아와도 자동으로 다시 보이지 않는다');
      });
    }

    testWidgets('이미 가려져 있으면 상태 변화가 있어도 그대로 가려져 있다', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));

      leaveAndReturn(tester, AppLifecycleState.paused);
      await tester.pump();

      expect(isObscured(tester), isTrue);
    });

    testWidgets('화면에서 사라지면 앱 상태 관찰을 해제한다 (오류 없이 상태가 바뀜)', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));
      await tester.pumpWidget(smashHarness(const SizedBox()));

      leaveAndReturn(tester, AppLifecycleState.paused);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('보안: 복사와 붙여넣기', () {
    testWidgets('(대조) 일반 입력창의 메뉴에는 복사, 잘라내기, 공유가 있다', (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: '20250001');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '학번', controller: controller),
      ));

      final types = await menuTypes(tester, controller);

      expect(types, containsAll([
        ContextMenuButtonType.copy,
        ContextMenuButtonType.cut,
        ContextMenuButtonType.paste,
        ContextMenuButtonType.share,
      ]));
    });

    testWidgets('비밀번호 입력창(가림 상태)의 메뉴는 붙여넣기만 남고 복사, 잘라내기, 공유가 없다', (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));

      final types = await menuTypes(tester, controller);

      expect(types, contains(ContextMenuButtonType.paste));
      expect(types, isNot(contains(ContextMenuButtonType.copy)));
      expect(types, isNot(contains(ContextMenuButtonType.cut)));
      expect(types, isNot(contains(ContextMenuButtonType.share)));
    });

    testWidgets('비밀번호를 보이게 해도 메뉴에 복사, 잘라내기, 공유가 없다', (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));
      await tester.tap(eye);
      await tester.pump();
      expect(isObscured(tester), isFalse);

      final types = await menuTypes(tester, controller);

      expect(types, contains(ContextMenuButtonType.paste));
      expect(types, isNot(contains(ContextMenuButtonType.copy)));
      expect(types, isNot(contains(ContextMenuButtonType.cut)));
      expect(types, isNot(contains(ContextMenuButtonType.share)));
    });

    testWidgets('붙여넣을 것이 없으면 메뉴에 남는 항목이 없어 메뉴 자체를 그리지 않는다', (tester) async {
      mockClipboard(tester); // 클립보드 비어 있음
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
      await tester.showKeyboard(field);
      await tester.pumpAndSettle();

      final state = tester.state<EditableTextState>(editable);
      final builder = tester.widget<TextField>(field).contextMenuBuilder!;
      final menu = builder(tester.element(editable), state);

      // 전체 선택이 이미 되어 있으므로 남을 항목이 없다
      expect(menu, isA<SizedBox>());
    });

    testWidgets('(대조) 일반 입력창은 Ctrl+C로 클립보드에 복사된다', (tester) async {
      final log = mockClipboard(tester);
      final controller = TextEditingController(text: '20250001');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '학번', controller: controller),
      ));
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
      await tester.showKeyboard(field);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(log.copied, ['20250001']);
    });

    testWidgets('비밀번호 입력창은 보이는 상태에서도 Ctrl+C, Ctrl+X가 클립보드에 쓰지 않는다', (tester) async {
      final log = mockClipboard(tester);
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));
      await tester.tap(eye);
      await tester.pump();
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
      await tester.showKeyboard(field);
      await tester.pump();

      for (final key in [LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyX]) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      expect(log.copied, isEmpty);
      expect(controller.text, 'abc12345', reason: '잘라내기로 지워지지도 않는다');
    });
  });

  // 위의 "메뉴 구성" 검사는 구성 함수의 결과만 본다. 아래는 사용자가 실제로 길게 눌렀을 때
  // 화면에 뜨는 메뉴 항목과, 항목을 눌렀을 때의 동작을 확인한다.
  group('보안: 실제로 뜨는 길게 누르기 메뉴', () {
    testWidgets('(대조) 일반 입력창은 복사, 잘라내기, 공유가 뜬다', (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: 'abc 12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashTextField(label: '메모', controller: controller),
      ));

      await longPressText(tester);

      expect(menuLabels(tester), containsAll(['잘라내기', '복사', '붙여넣기', '공유']));
    });

    testWidgets('가린 비밀번호: 붙여넣기만 뜨고 복사, 잘라내기, 공유는 뜨지 않는다', (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: 'abc 12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));

      await longPressText(tester);

      expect(menuLabels(tester), ['붙여넣기']);
    });

    testWidgets('보이는 비밀번호: 붙여넣기와 전체 선택만 뜬다 (허용 목록의 두 항목이 실제로 뜬다)',
        (tester) async {
      mockClipboard(tester, pasteable: '붙여넣을 값');
      final controller = TextEditingController(text: 'abc 12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));
      await tester.tap(eye);
      await tester.pump();

      await longPressText(tester);

      expect(menuLabels(tester), ['붙여넣기', '전체 선택']);
    });

    testWidgets('붙여넣기를 누르면 비밀번호 입력창에 들어가고 onChanged가 불린다', (tester) async {
      mockClipboard(tester, pasteable: 'P@ssw0rd!');
      final controller = TextEditingController(text: 'old');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller, onChanged: changes.add),
      ));

      await longPressText(tester);
      await tester.tap(find.text('붙여넣기'));
      await tester.pumpAndSettle();

      expect(controller.text, 'P@ssw0rd!');
      expect(changes.last, 'P@ssw0rd!');
    });

    testWidgets('빈 비밀번호 입력창을 길게 눌러도 붙여넣을 수 있다 (비밀번호 관리자에서 복사한 값)',
        (tester) async {
      mockClipboard(tester, pasteable: 'P@ssw0rd!');
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));

      await tester.longPress(field);
      await tester.pumpAndSettle();
      expect(menuLabels(tester), ['붙여넣기']);
      await tester.tap(find.text('붙여넣기'));
      await tester.pumpAndSettle();

      expect(controller.text, 'P@ssw0rd!');
    });

    testWidgets('클립보드가 비어 있고 전부 선택된 상태에서는 메뉴가 뜨지 않는다', (tester) async {
      mockClipboard(tester);
      final controller = TextEditingController(text: 'abc12345');
      addTearDown(controller.dispose);
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(label: '비밀번호', controller: controller),
      ));

      await longPressText(tester);

      expect(menuLabels(tester), isEmpty);
    });
  });

  group('입력 설정', () {
    testWidgets('자동완성 기본은 로그인용 password, 새 비밀번호 화면은 newPassword로 바꾼다', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));
      expect(tester.widget<TextField>(field).autofillHints, [AutofillHints.password]);

      await tester.pumpWidget(smashHarness(
        const SmashPasswordField(label: '새 비밀번호', autofillHints: [AutofillHints.newPassword]),
      ));
      expect(tester.widget<TextField>(field).autofillHints, [AutofillHints.newPassword]);
    });

    testWidgets('자동 교정, 추천어, 개인화 학습이 꺼져 있다', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));

      final widget = tester.widget<TextField>(field);
      expect(widget.autocorrect, isFalse);
      expect(widget.enableSuggestions, isFalse);
      expect(widget.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('엔터 키 동작과 제출, 변경 콜백이 전달된다', (tester) async {
      final changes = <String>[];
      final submits = <String>[];
      await tester.pumpWidget(smashHarness(
        SmashPasswordField(
          label: '비밀번호',
          textInputAction: TextInputAction.done,
          onChanged: changes.add,
          onSubmitted: submits.add,
        ),
      ));

      await tester.enterText(field, 'pw1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(tester.widget<TextField>(field).textInputAction, TextInputAction.done);
      expect(changes, ['pw1234']);
      expect(submits, ['pw1234']);
    });

    testWidgets('한 줄 입력이다 (가린 입력창은 여러 줄이 되지 않는다)', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashPasswordField(label: '비밀번호')));

      expect(tester.widget<TextField>(field).maxLines, 1);
    });
  });

  group('오류와 글자 확대', () {
    testWidgets('오류 문구가 아이콘과 함께 보인다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashPasswordField(label: '비밀번호', errorText: '비밀번호가 맞지 않아요'),
      ));

      expect(find.text('비밀번호가 맞지 않아요'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 눈 아이콘은 48x48을 유지한다', (tester) async {
        await tester.pumpWidget(smashHarness(
          const SmashPasswordField(label: '현재 비밀번호', errorText: '비밀번호가 맞지 않아요'),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(eye), const Size(48, 48));
        expect(tester.getSize(field).height, greaterThanOrEqualTo(52));
      });
    }
  });
}
