import 'dart:async';
import 'dart:io';

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/signup_screen_states.dart';
import 'package:app/features/auth/page/signup_page.dart';
import 'package:app/features/auth/provider/signup_draft_provider.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/finders.dart';
import '../../support/pump.dart';
import '../../support/screen_pump.dart';
import '../../support/signup_flow.dart';

/// S1b 가입 3단계: 단계 이동, 입력 검사, 서버 호출(한 번), 뒤로 가기, 실패 복구, 자동완성, 메모리 보관
void main() {
  setUpAll(loadPretendard);

  bool onStub() =>
      find.byKey(const ValueKey('login-stub')).evaluate().isNotEmpty;
  bool at(Type page) => find.byType(page).hitTestable().evaluate().isNotEmpty;
  bool onCode() => at(SignupPage);
  bool onId() => at(SignupIdPage);
  bool onPassword() => at(SignupPasswordPage);

  Finder field() => find.byType(TextField).last; // 화면 맨 위 단계의 입력창
  final next = find.widgetWithText(SmashButton, '다음');
  final submit = find.widgetWithText(SmashButton, '가입하기');

  Future<void> tapButton(WidgetTester tester, Finder button) async {
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// 안드로이드 시스템 뒤로 가기 버튼
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> fillAll(
    WidgetTester tester, {
    String code = 'CODE',
    String id = '2025',
    String pw = 'pw12',
  }) async {
    await tester.enterText(field(), code);
    await tapButton(tester, next);
    await tester.enterText(field(), id);
    await tapButton(tester, next);
    await tester.enterText(field(), pw);
  }

  group('단계와 화면 구성', () {
    testWidgets('단계 이름은 가입코드, 학번, 비밀번호이고 각 화면이 자기 단계를 가리킨다', (tester) async {
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
      );
      final indicator = tester.widget<SmashStepIndicator>(
        find.byType(SmashStepIndicator).last,
      );
      expect(indicator.steps, ['가입코드', '학번', '비밀번호']);
      expect(indicator.current, 2);

      await systemBack(tester);
      expect(
        tester
            .widget<SmashStepIndicator>(find.byType(SmashStepIndicator).last)
            .current,
        1,
      );
      await systemBack(tester);
      expect(
        tester
            .widget<SmashStepIndicator>(find.byType(SmashStepIndicator).last)
            .current,
        0,
      );
    });

    testWidgets('1단계: 가입코드 칸은 기존 입력 속성(기본 키보드, 자동 수정, 글자 수 제한 없음)을 그대로 쓴다', (
      tester,
    ) async {
      await openSignupFlow(tester);
      final f = tester.widget<TextField>(field());
      expect(f.keyboardType, TextInputType.text, reason: '지정하지 않은 기본 키보드');
      expect(f.textCapitalization, TextCapitalization.none);
      expect(f.autocorrect, isTrue);
      expect(f.maxLength, isNull);
      expect(f.obscureText, isFalse);
      expect(find.text('동아리에서 받은 가입코드가 필요해요'), findsOneWidget);
    });

    testWidgets('2단계: 학번 칸은 숫자 키보드다', (tester) async {
      await openSignupFlow(tester, steps: const [signupCodePath, signupIdPath]);
      expect(
        tester.widget<TextField>(field()).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('3단계: 비밀번호 칸은 가려지고 newPassword 자동완성 힌트이며 복사 차단이 유지된다', (
      tester,
    ) async {
      mockClipboard(tester, pasteable: 'x');
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
      );
      final f = tester.widget<TextField>(field());
      expect(f.obscureText, isTrue);
      expect(f.autofillHints, [AutofillHints.newPassword]);
      expect(
        find.ancestor(of: field(), matching: find.byType(AutofillGroup)),
        findsOneWidget,
      );

      await tester.enterText(field(), 'secret');
      await tester.showKeyboard(field());
      await tester.longPressAt(
        tester.getTopLeft(
              find.descendant(of: field(), matching: find.byType(EditableText)),
            ) +
            const Offset(10, 10),
      );
      await tester.pumpAndSettle();
      final labels = menuLabels(tester);
      expect(labels, isNot(contains('복사')));
      expect(labels, contains('붙여넣기'));
    });

    testWidgets('단계 화면에 들어오면 그 단계의 입력창에 포커스가 간다', (tester) async {
      await openSignupFlow(tester);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(field(), 'CODE');
      await tapButton(tester, next);
      expect(onId(), isTrue);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('모든 단계가 밝은 테마와 어두운 상태 표시줄 아이콘이다', (tester) async {
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
      );
      for (var i = 0; i < 3; i++) {
        final context = tester.element(find.byType(SmashStepIndicator).last);
        expect(Theme.of(context).colorScheme.primary, SmashColors.brand);
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
        );
        expect(region.value, SmashSystemUi.light);
        if (i < 2) await systemBack(tester);
      }
    });
  });

  group('단계 이동과 입력 검사', () {
    testWidgets('1단계: 비었거나 공백뿐이면 안내하고 넘어가지 않는다', (tester) async {
      final flow = await openSignupFlow(tester);
      await tapButton(tester, next);
      expect(find.text('가입코드를 입력해주세요.'), findsOneWidget);
      expect(onCode(), isTrue);

      await tester.enterText(field(), '   ');
      await tapButton(tester, next);
      expect(find.text('가입코드를 입력해주세요.'), findsOneWidget);
      expect(onCode(), isTrue);

      await tester.enterText(field(), 'A');
      await tester.pump();
      expect(find.text('가입코드를 입력해주세요.'), findsNothing, reason: '입력하면 안내가 사라진다');
      expect(flow.fake.signupCalls, isEmpty);
    });

    testWidgets('2단계: 비었으면 안내하고 넘어가지 않는다', (tester) async {
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath],
        draft: const SignupDraft(code: 'C'),
      );
      await tapButton(tester, next);
      expect(find.text('학번을 입력해주세요.'), findsOneWidget);
      expect(onId(), isTrue);
    });

    testWidgets('3단계: 비었으면, 4자 미만이면 안내하고 서버를 부르지 않는다', (tester) async {
      final flow = await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
      );
      await tapButton(tester, submit);
      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);

      await tester.enterText(field(), 'abc');
      await tapButton(tester, submit);
      expect(find.text('비밀번호는 4자 이상이어야 합니다.'), findsOneWidget);
      expect(flow.fake.signupCalls, isEmpty);

      await tester.enterText(field(), 'abcd');
      await tester.pump();
      expect(find.text('비밀번호는 4자 이상이어야 합니다.'), findsNothing);
    });

    testWidgets('키보드의 다음/완료 키로도 단계가 넘어간다', (tester) async {
      await openSignupFlow(tester);
      await tester.enterText(field(), 'CODE');
      await tester.showKeyboard(field());
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(onId(), isTrue);
    });
  });

  group('서버 호출: 3단계 제출 때 signup 한 번', () {
    testWidgets('인자는 (trim한 가입코드, trim한 학번, 그대로의 비밀번호)이고 앞 단계에서는 부르지 않는다', (
      tester,
    ) async {
      final flow = await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async => self.fail(signupFailedMessage),
      );
      await tester.enterText(field(), '  CODE ');
      await tapButton(tester, next);
      expect(flow.fake.signupCalls, isEmpty);
      await tester.enterText(field(), ' 2025 ');
      await tapButton(tester, next);
      expect(flow.fake.signupCalls, isEmpty);
      await tester.enterText(field(), ' pw12 ');
      await tapButton(tester, submit);

      expect(flow.fake.signupCalls, [('CODE', '2025', ' pw12 ')]);
    });

    testWidgets('처리 중에는 버튼과 완료 키로 다시 부르지 않는다', (tester) async {
      final flow = await openSignupFlow(tester); // onSignup이 없어 요청 중으로 남는다
      await fillAll(tester);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      await tester.showKeyboard(field());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(flow.fake.signupCalls.length, 1);
      expect(tester.widget<SmashButton>(submit).isLoading, isTrue);
    });

    testWidgets('성공해도 화면이 직접 이동하지 않는다 (/home은 앱의 redirect가 맡는다)', (
      tester,
    ) async {
      final flow = await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async => self.succeed(),
      );
      await fillAll(tester);
      await tapButton(tester, submit);
      expect(flow.fake.signupCalls.length, 1);
      expect(onPassword(), isTrue);
      expect(find.byKey(const ValueKey('stub-page')), findsNothing);
    });
  });

  group('뒤로 가기: 2·3단계는 이전 단계로, 1단계는 가입 화면을 나간다', () {
    testWidgets('시스템 뒤로 가기가 3 → 2 → 1 → 로그인 순으로 가고 입력이 남는다', (tester) async {
      await openSignupFlow(tester);
      await fillAll(tester, code: 'CODE', id: '2025', pw: 'pw12');
      expect(onPassword(), isTrue);

      await systemBack(tester);
      expect(onId(), isTrue);
      expect(tester.widget<TextField>(field()).controller!.text, '2025');
      await systemBack(tester);
      expect(onCode(), isTrue);
      expect(tester.widget<TextField>(field()).controller!.text, 'CODE');

      await systemBack(tester);
      expect(onStub(), isTrue, reason: '1단계에서 뒤로 가면 가입 화면을 나간다');
      expect(onCode(), isFalse);
    });

    testWidgets('앱바 뒤로 버튼도 같다', (tester) async {
      await openSignupFlow(tester, steps: const [signupCodePath, signupIdPath]);
      await tester.tap(
        find.bySemanticsLabel('뒤로').hitTestable().last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      // 시맨틱이 꺼져 있으면 아이콘 버튼을 직접 누른다
      if (onId()) {
        await tester.tap(find.byType(SmashIconButton).hitTestable().last);
        await tester.pumpAndSettle();
      }
      expect(onCode(), isTrue);
    });

    testWidgets('3단계 이전 화면으로 돌아가서 다시 넘어가도 입력이 이어진다 (되돌아가 학번 고치기)', (
      tester,
    ) async {
      await openSignupFlow(tester);
      await fillAll(tester, code: 'CODE', id: '2025', pw: 'pw12');
      await systemBack(tester);
      await tester.enterText(field(), '2026');
      await tapButton(tester, next);
      expect(onPassword(), isTrue);
      expect(
        tester.widget<TextField>(field()).controller!.text,
        'pw12',
        reason: '비밀번호는 남아 있다',
      );
    });

    testWidgets('요청 중에는 3단계에서 나갈 수 없다 (뒤로 가기와 앱바 뒤로)', (tester) async {
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
        initial: const AuthState(isLoading: true),
        draft: const SignupDraft(
          code: 'C',
          studentNo: '2025',
          password: 'pw12',
          attempted: true,
        ),
        settle: false,
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(onPassword(), isTrue);
      expect(find.bySemanticsLabel('뒤로'), findsNothing);
    });
  });

  group('실패 복구', () {
    const steps = [signupCodePath, signupIdPath, signupPasswordPath];
    const draft = SignupDraft(
      code: 'CODE',
      studentNo: '2025',
      password: 'pw12',
      attempted: true,
    );

    testWidgets('실패 안내 상자와 1단계로 가기 버튼이 뜬다', (tester) async {
      await openSignupFlow(
        tester,
        steps: steps,
        draft: draft,
        initial: const AuthState(errorMessage: signupFailedMessage),
      );
      expect(find.text(signupFailedMessage), findsOneWidget);
      final notice = tester.widget<SmashInlineNotice>(
        find.byType(SmashInlineNotice),
      );
      expect(notice.tone, SmashNoticeTone.danger);
      expect(notice.actionLabel, '1단계로 가기');
    });

    testWidgets('1단계로 가기: 1단계가 열리고 세 입력이 모두 남는다', (tester) async {
      final flow = await openSignupFlow(
        tester,
        steps: steps,
        draft: draft,
        initial: const AuthState(errorMessage: signupFailedMessage),
      );
      await tester.tap(find.text('1단계로 가기'));
      await tester.pumpAndSettle();

      expect(onCode(), isTrue);
      expect(tester.widget<TextField>(field()).controller!.text, 'CODE');
      await tapButton(tester, next);
      expect(tester.widget<TextField>(field()).controller!.text, '2025');
      await tapButton(tester, next);
      expect(tester.widget<TextField>(field()).controller!.text, 'pw12');
      expect(
        find.byType(SmashInlineNotice),
        findsNothing,
        reason: '다시 3단계에 와도 지난 실패 안내는 요청 전에는 보이지 않는다',
      );
      expect(flow.fake.signupCalls, isEmpty);
    });

    testWidgets('요청하지 않은 지난 오류 문구(다른 화면이 남긴 것)는 3단계에 미리 뜨지 않는다', (
      tester,
    ) async {
      await openSignupFlow(
        tester,
        steps: steps,
        initial: const AuthState(errorMessage: '로그인에 실패했습니다.'),
      );
      expect(find.byType(SmashInlineNotice), findsNothing);
    });

    testWidgets('실제로 요청해서 실패하면 안내가 뜨고, 다시 눌러 요청하는 동안은 숨는다', (tester) async {
      final holds = [Completer<void>(), Completer<void>()];
      var n = 0;
      final flow = await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async {
          await holds[n++].future;
          self.fail(signupFailedMessage);
        },
      );
      await fillAll(tester);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(tester.widget<SmashButton>(submit).isLoading, isTrue);
      holds[0].complete();
      await tester.pumpAndSettle();
      expect(find.text(signupFailedMessage), findsOneWidget);

      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(
        find.text(signupFailedMessage),
        findsNothing,
        reason: '요청 중에는 이전 문구를 숨긴다',
      );
      holds[1].complete();
      await tester.pumpAndSettle();
      expect(find.text(signupFailedMessage), findsOneWidget);
      expect(flow.fake.signupCalls.length, 2);
    });
  });

  group('자동완성 저장', () {
    Iterable<MethodCall> finishCalls(WidgetTester tester) => tester
        .testTextInput
        .log
        .where((c) => c.method == 'TextInput.finishAutofillContext');

    testWidgets('가입을 요청해 성공하면 저장한다 (finishAutofillContext true 한 번)', (
      tester,
    ) async {
      final response = Completer<void>();
      await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async {
          await response.future;
          self.succeed();
        },
      );
      await fillAll(tester);
      tester.testTextInput.log.clear();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump(const Duration(milliseconds: 300));
      response.complete();
      await tester.pumpAndSettle();

      expect(finishCalls(tester).where((c) => c.arguments == true).length, 1);
    });

    testWidgets('이 화면이 요청하지 않은 로그인 상태 변화에는 저장하지 않는다', (tester) async {
      final flow = await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
      );
      tester.testTextInput.log.clear();
      flow.fake.succeed();
      await tester.pumpAndSettle();
      expect(finishCalls(tester).where((c) => c.arguments == true), isEmpty);
    });

    testWidgets('실패하면 저장하지 않고, 화면이 그냥 사라지면 취소한다', (tester) async {
      await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async => self.fail(signupFailedMessage),
      );
      await fillAll(tester);
      tester.testTextInput.log.clear();
      await tapButton(tester, submit);
      expect(finishCalls(tester).where((c) => c.arguments == true), isEmpty);

      tester.testTextInput.log.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(finishCalls(tester).every((c) => c.arguments == false), isTrue);
    });
  });

  group('입력은 메모리에만, 가입 흐름이 끝나면 사라진다', () {
    testWidgets('가입 화면을 나갔다가 다시 들어오면 입력이 비어 있다 (autoDispose)', (tester) async {
      final flow = await openSignupFlow(tester);
      await fillAll(tester, code: 'CODE', id: '2025', pw: 'pw12');
      await systemBack(tester);
      await systemBack(tester);
      await systemBack(tester);
      expect(onStub(), isTrue);

      flow.router.push(signupCodePath);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field()).controller!.text, isEmpty);
      await tapButton(tester, next);
      expect(find.text('가입코드를 입력해주세요.'), findsOneWidget);
    });

    SignupDraft draftOf(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(SmashStepIndicator).last),
    ).read(signupDraftProvider);

    testWidgets('입력은 적는 즉시 상태에 반영된다 (다음 단계로 넘어가기 전에도, 앞뒤 공백 그대로)', (
      tester,
    ) async {
      await openSignupFlow(tester);
      await tester.enterText(field(), ' AB ');
      expect(draftOf(tester).code, ' AB ', reason: '1단계 입력');
      await tapButton(tester, next);

      await tester.enterText(field(), ' 20 ');
      expect(draftOf(tester).studentNo, ' 20 ', reason: '2단계 입력');
      await tapButton(tester, next);

      await tester.enterText(field(), ' pw ');
      expect(draftOf(tester).password, ' pw ', reason: '3단계 입력');
      expect(draftOf(tester).attempted, isFalse, reason: '요청 전에는 시도 표시가 없다');
    });

    testWidgets('제출한 비밀번호는 입력 이벤트 없이 바뀐 값이라도 실패 후 1단계로 갔다 와도 남는다', (
      tester,
    ) async {
      await openSignupFlow(
        tester,
        onSignup: (self, c, s, p) async => self.fail(signupFailedMessage),
      );
      await tester.enterText(field(), 'CODE');
      await tapButton(tester, next);
      await tester.enterText(field(), '2025');
      await tapButton(tester, next);

      // 입력 이벤트(onChanged) 없이 컨트롤러 값만 바꾼다 (붙여넣기나 자동완성이 이벤트 없이 값을 채우는 경우를 흉내)
      tester.widget<TextField>(field()).controller!.text = 'pw12';
      await tapButton(tester, submit);
      expect(find.text(signupFailedMessage), findsOneWidget);

      await tester.tap(find.text('1단계로 가기'));
      await tester.pumpAndSettle();
      await tapButton(tester, next);
      await tapButton(tester, next);
      expect(tester.widget<TextField>(field()).controller!.text, 'pw12');
    });

    test('가입 화면과 상태 소스는 디스크 저장소를 쓰지 않는다', () {
      for (final path in [
        'lib/features/auth/page/signup_page.dart',
        'lib/features/auth/provider/signup_draft_provider.dart',
      ]) {
        final text = File(path).readAsStringSync();
        for (final banned in [
          'shared_preferences',
          'flutter_secure_storage',
          'TokenStorage',
          'dart:io',
          'sqflite',
          'hive',
        ]) {
          expect(text.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });
  });

  group('화면 구성', () {
    testWidgets('보이는 글자는 모두 SmashLabel이거나 입력창 안이다', (tester) async {
      await openSignupFlow(
        tester,
        steps: const [signupCodePath, signupIdPath, signupPasswordPath],
        initial: const AuthState(errorMessage: signupFailedMessage),
        draft: const SignupDraft(attempted: true),
      );
      for (final element in anyText().evaluate()) {
        final inField = find
            .ancestor(
              of: find.byWidget(element.widget),
              matching: find.byType(TextField),
            )
            .evaluate()
            .isNotEmpty;
        expect(
          element.widget is SmashLabel || inField,
          isTrue,
          reason: '${(element.widget as Text).data}',
        );
      }
    });

    test('draft 상태: 복사본은 바뀐 값만 바꾼다', () {
      const d = SignupDraft(code: 'a', studentNo: 'b', password: 'c');
      final e = d.copyWith(password: 'z', attempted: true);
      expect(
        (e.code, e.studentNo, e.password, e.attempted),
        ('a', 'b', 'z', true),
      );
    });
  });
}
