import 'dart:async';

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/dev/screens/login_screen_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:app/dev/screens/screen_host.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/finders.dart';
import '../../support/pixels.dart';
import '../../support/pump.dart';
import '../../support/screen_pump.dart';

/// S1a 로그인 화면: 동작 보존(login 호출 인자, 이동), 입력 검사, 자동완성, 상태 표시줄, 상태별 모습
void main() {
  setUpAll(loadPretendard);

  // 입력창은 SmashTextField 안의 TextField다: 순서대로 학번, 비밀번호
  Finder textField(int index) => find.byType(TextField).at(index);
  final loginButton = find.widgetWithText(SmashButton, '로그인');
  final signupButton = find.widgetWithText(SmashButton, '가입하기');

  /// 가짜 인증을 넣어 화면을 띄운다
  Future<(FakeAuthNotifier, GoRouter)> open(
    WidgetTester tester, {
    AuthState initial = const AuthState(),
    OnLogin? onLogin,
    ScreenConditions conditions = const ScreenConditions(),
    Key? boundaryKey,
    bool settle = true,
  }) async {
    final fake = FakeAuthNotifier(initial: initial, onLogin: onLogin);
    final router = await pumpScreen(
      tester,
      loginScreenEntry,
      ScreenState(
        'test',
        overrides: [authProvider.overrideWith((ref) => fake)],
      ),
      conditions: conditions,
      boundaryKey: boundaryKey,
      settle: settle,
    );
    return (fake, router);
  }

  /// 지금 화면이 어느 경로인지: 갤러리의 자리 표시 화면이 떠 있으면 그 경로, 아니면 로그인
  String location(WidgetTester tester) {
    final stub = find.byKey(const ValueKey('stub-page'));
    if (stub.evaluate().isEmpty) return '/login';
    return tester.widget<Text>(stub).data!.split(' ').first;
  }

  Future<void> tapLogin(WidgetTester tester) async {
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
  }

  group('동작 보존: login 호출과 이동', () {
    testWidgets('login은 (앞뒤 공백을 지운 학번, 그대로의 비밀번호)로 한 번 불린다', (tester) async {
      final (fake, _) = await open(
        tester,
        onLogin: (self, s, p) async => self.fail('x'),
      );
      await tester.enterText(textField(0), '  20250001 ');
      await tester.enterText(textField(1), ' pass word ');
      await tapLogin(tester);

      expect(fake.loginCalls, [('20250001', ' pass word ')]);
    });

    testWidgets('처리 중에 버튼을 또 눌러도 다시 부르지 않는다', (tester) async {
      final (fake, _) = await open(tester); // onLogin이 없어 요청 중으로 남는다
      await tester.enterText(textField(0), '1');
      await tester.enterText(textField(1), 'pw');
      await tapLogin(tester);
      await tapLogin(tester);
      await tapLogin(tester);

      expect(fake.loginCalls.length, 1);
    });

    testWidgets('비밀번호 칸의 완료 키로도 로그인한다 (한 번)', (tester) async {
      final (fake, _) = await open(
        tester,
        onLogin: (self, s, p) async => self.fail('x'),
      );
      await tester.enterText(textField(0), '20250001');
      await tester.enterText(textField(1), 'pw');
      await tester.showKeyboard(textField(1));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(fake.loginCalls, [('20250001', 'pw')]);
    });

    testWidgets('처리 중에는 키보드 완료 키로도 다시 부르지 않는다', (tester) async {
      final (fake, _) = await open(
        tester,
        initial: const AuthState(isLoading: true),
        settle: false,
      );
      await tester.enterText(textField(0), '1');
      await tester.enterText(textField(1), 'pw');
      await tester.showKeyboard(textField(1));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(fake.loginCalls, isEmpty);
    });

    testWidgets('학번 칸의 다음 키는 비밀번호 칸으로 포커스를 옮기고 로그인하지 않는다', (tester) async {
      final (fake, _) = await open(tester);
      await tester.showKeyboard(textField(0));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(fake.loginCalls, isEmpty);
      expect(
        tester.widget<TextField>(textField(1)).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('가입하기는 /signup을 push로 연다 (뒤로 가면 로그인 화면)', (tester) async {
      final (_, router) = await open(tester);
      expect(location(tester), '/login');

      await tester.ensureVisible(signupButton);
      await tester.tap(signupButton);
      await tester.pumpAndSettle();
      expect(location(tester), '/signup');
      expect(find.byKey(const ValueKey('stub-page')), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(location(tester), '/login');
      expect(loginButton, findsOneWidget);
    });

    testWidgets('로그인에 성공해도 화면이 직접 이동하지 않는다 (/home은 앱의 redirect가 맡는다)', (
      tester,
    ) async {
      final (fake, router) = await open(
        tester,
        onLogin: (self, s, p) async => self.succeed(),
      );
      await tester.enterText(textField(0), '3');
      await tester.enterText(textField(1), 'pw');
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(fake.loginCalls.length, 1);
      expect(location(tester), '/login');
    });
  });

  group('입력 검사: 비면 서버를 부르지 않는다', () {
    testWidgets('둘 다 비면 학번 칸에 안내가 뜨고 포커스가 간다', (tester) async {
      final (fake, _) = await open(tester);
      await tapLogin(tester);

      expect(fake.loginCalls, isEmpty);
      expect(find.text('학번을 입력해주세요.'), findsOneWidget);
      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
      expect(
        tester.widget<TextField>(textField(0)).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('학번만 채우면 비밀번호 칸에 포커스가 간다', (tester) async {
      final (fake, _) = await open(tester);
      await tester.enterText(textField(0), '20250001');
      await tapLogin(tester);

      expect(fake.loginCalls, isEmpty);
      expect(find.text('학번을 입력해주세요.'), findsNothing);
      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
      expect(
        tester.widget<TextField>(textField(1)).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('공백뿐인 학번은 빈 것으로 본다 (예전에는 빈 학번으로 서버를 불렀다)', (tester) async {
      final (fake, _) = await open(tester);
      await tester.enterText(textField(0), '   ');
      await tester.enterText(textField(1), 'pw');
      await tapLogin(tester);

      expect(fake.loginCalls, isEmpty);
      expect(find.text('학번을 입력해주세요.'), findsOneWidget);
    });

    testWidgets('입력을 시작하면 그 칸의 안내가 사라진다', (tester) async {
      await open(tester);
      await tapLogin(tester);
      expect(find.text('학번을 입력해주세요.'), findsOneWidget);

      await tester.enterText(textField(0), '2');
      await tester.pump();
      expect(find.text('학번을 입력해주세요.'), findsNothing);
      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
    });
  });

  group('자동완성과 입력창 설정', () {
    testWidgets('학번은 username, 비밀번호는 password 힌트다', (tester) async {
      await open(tester);
      expect(tester.widget<TextField>(textField(0)).autofillHints, [
        AutofillHints.username,
      ]);
      expect(tester.widget<TextField>(textField(1)).autofillHints, [
        AutofillHints.password,
      ]);
    });

    testWidgets('숫자 키보드, 자동 교정 끔, 비밀번호는 가려지고 두 칸이 한 자동완성 묶음이다', (tester) async {
      await open(tester);
      final student = tester.widget<TextField>(textField(0));
      expect(student.keyboardType, TextInputType.number);
      expect(student.autocorrect, isFalse);
      expect(student.enableSuggestions, isFalse);
      expect(student.obscureText, isFalse);

      final password = tester.widget<TextField>(textField(1));
      expect(password.obscureText, isTrue);
      expect(password.autocorrect, isFalse);

      final group = find.ancestor(
        of: textField(0),
        matching: find.byType(AutofillGroup),
      );
      expect(group, findsOneWidget);
      expect(
        find.descendant(of: group, matching: textField(1)),
        findsOneWidget,
      );
    });

    testWidgets('비밀번호 칸의 복사 차단은 그대로다: 길게 눌러도 복사, 잘라내기가 없고 붙여넣기는 있다', (
      tester,
    ) async {
      mockClipboard(tester, pasteable: 'from-manager');
      await open(tester);
      await tester.enterText(textField(1), 'secret');
      await tester.showKeyboard(textField(1));
      await tester.longPressAt(
        tester.getTopLeft(
              find.descendant(
                of: textField(1),
                matching: find.byType(EditableText),
              ),
            ) +
            const Offset(10, 10),
      );
      await tester.pumpAndSettle();

      final labels = menuLabels(tester);
      expect(labels, isNot(contains('복사')));
      expect(labels, isNot(contains('잘라내기')));
      expect(labels, contains('붙여넣기'));
    });

    testWidgets('로그인에 성공하면 자동완성 정보를 저장한다 (finishAutofillContext)', (
      tester,
    ) async {
      final (_, _) = await open(
        tester,
        onLogin: (self, s, p) async => self.succeed(),
      );
      await tester.enterText(textField(0), '3');
      await tester.enterText(textField(1), 'pw');
      tester.testTextInput.log.clear();
      await tapLogin(tester);
      await tester.pumpAndSettle();

      final finish = tester.testTextInput.log.where(
        (c) => c.method == 'TextInput.finishAutofillContext',
      );
      expect(finish.length, 1);
      expect(finish.single.arguments, true, reason: '저장(shouldSave: true)');
    });

    testWidgets('로그인하지 않고 화면이 사라지면 저장하지 않고 취소한다', (tester) async {
      await open(tester);
      await tester.enterText(textField(0), '3');
      await tester.enterText(textField(1), 'pw');
      tester.testTextInput.log.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      final finish = tester.testTextInput.log
          .where((c) => c.method == 'TextInput.finishAutofillContext')
          .toList();
      expect(
        finish.every((c) => c.arguments == false),
        isTrue,
        reason: '저장하지 않는다',
      );
    });

    testWidgets('실패하면 저장하지 않는다', (tester) async {
      await open(
        tester,
        onLogin: (self, s, p) async => self.fail(loginFailedMessage),
      );
      await tester.enterText(textField(0), '3');
      await tester.enterText(textField(1), 'pw');
      tester.testTextInput.log.clear();
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(
        tester.testTextInput.log.where(
          (c) => c.method == 'TextInput.finishAutofillContext',
        ),
        isEmpty,
      );
    });

    testWidgets('이 화면이 요청하지 않은 로그인 상태 변화(가입 성공 등)에는 저장하지 않는다', (tester) async {
      final (fake, _) = await open(tester);
      tester.testTextInput.log.clear();
      fake.succeed();
      await tester.pumpAndSettle();

      expect(
        tester.testTextInput.log.where(
          (c) => c.method == 'TextInput.finishAutofillContext',
        ),
        isEmpty,
      );
    });
  });

  group('밝은 테마와 상태 표시줄', () {
    testWidgets('화면은 SMASH 라이트 테마와 라이트 배경이다', (tester) async {
      await open(tester);
      final context = tester.element(loginButton);
      expect(Theme.of(context).brightness, Brightness.light);
      expect(
        Theme.of(context).colorScheme.primary,
        SmashColors.brand,
        reason: '화면이 SmashTheme.light()로 감싸져 있다 (Material 기본 보라색이 아니다)',
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        SmashColors.background,
      );
    });

    testWidgets('상태 표시줄 아이콘은 밝은 배경에 맞게 어둡다 (Android, iOS 모두)', (tester) async {
      await open(tester);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      final style = region.value;
      expect(style, SmashSystemUi.light);
      expect(
        style.statusBarIconBrightness,
        Brightness.dark,
        reason: 'Android: 어두운 아이콘',
      );
      expect(
        style.statusBarBrightness,
        Brightness.light,
        reason: 'iOS: 밝은 상태 표시줄 배경 = 어두운 아이콘',
      );
      expect(
        SmashColors.background.computeLuminance(),
        greaterThan(0.5),
        reason: '배경이 실제로 밝다',
      );
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(SmashColors.surface.computeLuminance(), greaterThan(0.5));
    });

    testWidgets('로고는 흰색 투명 그림이라 브랜드 색으로 칠해서 쓰고, 실제로 배경과 구분된다', (tester) async {
      const boundary = ValueKey('login-shot');
      await open(tester, boundaryKey: boundary);
      final logo = tester.widget<Image>(find.byType(Image));
      expect(logo.color, SmashColors.brand);
      expect(logo.colorBlendMode, BlendMode.srcIn);

      final pixel = await readPixels(tester, boundary);
      final rect = tester.getRect(find.byType(Image));
      var brandish = 0;
      for (var y = rect.top.toInt(); y < rect.bottom.toInt(); y += 2) {
        for (var x = rect.left.toInt(); x < rect.right.toInt(); x += 2) {
          if (colorDistance(pixel(x, y), SmashColors.brand) < 900) brandish++;
        }
      }
      expect(
        brandish,
        greaterThan(50),
        reason: '로고 영역에 브랜드 색이 그려진다 (밝은 배경에서 흰 로고가 사라지지 않는다)',
      );
    });
  });

  group('상태별 모습', () {
    testWidgets('초기: 안내 없음, 로그인 버튼은 눌림 가능', (tester) async {
      await open(tester);
      expect(find.byType(SmashInlineNotice), findsNothing);
      expect(tester.widget<SmashButton>(loginButton).isLoading, isFalse);
      expect(tester.widget<SmashButton>(loginButton).onPressed, isNotNull);
      expect(find.text('다시 만나 반가워요'), findsOneWidget);
    });

    testWidgets('제출 중: 버튼이 처리 중으로 읽히고, 이전 오류 문구는 숨는다', (tester) async {
      final handle = tester.ensureSemantics();
      await open(
        tester,
        initial: const AuthState(isLoading: true, errorMessage: '이전 오류'),
        settle: false,
      );
      expect(tester.widget<SmashButton>(loginButton).isLoading, isTrue);
      expect(find.byType(SmashInlineNotice), findsNothing);
      expect(find.bySemanticsLabel('로그인, 처리 중'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('서버·네트워크 오류와 시도 제한: 오류 안내가 문구 그대로 뜨고 스크린리더가 바로 읽는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final message in [
        loginNetworkErrorMessage,
        loginTooManyMessage,
        loginFailedMessage,
      ]) {
        await open(tester, initial: AuthState(errorMessage: message));
        await tester.ensureVisible(find.text(message));
        expect(find.text(message), findsOneWidget);
        final notice = tester.widget<SmashInlineNotice>(
          find.byType(SmashInlineNotice),
        );
        expect(notice.tone, SmashNoticeTone.danger);
        expect(
          tester
              .getSemantics(find.byType(SmashInlineNotice))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
      }
      handle.dispose();
    });

    testWidgets('요청이 실패하면 제출 중이 끝나고 문구가 뜬다, 다시 누르면 문구가 숨고 다시 요청한다', (
      tester,
    ) async {
      var attempt = 0;
      final holds = [Completer<void>(), Completer<void>()];
      final (fake, _) = await open(
        tester,
        onLogin: (self, s, p) async {
          final hold = holds[attempt++];
          await hold.future;
          self.fail(loginNetworkErrorMessage);
        },
      );
      await tester.enterText(textField(0), '1');
      await tester.enterText(textField(1), 'pw');

      await tapLogin(tester);
      expect(tester.widget<SmashButton>(loginButton).isLoading, isTrue);
      holds[0].complete();
      await tester.pumpAndSettle();
      expect(tester.widget<SmashButton>(loginButton).isLoading, isFalse);
      expect(find.text(loginNetworkErrorMessage), findsOneWidget);

      await tapLogin(tester);
      expect(
        find.text(loginNetworkErrorMessage),
        findsNothing,
        reason: '요청 중에는 이전 문구를 숨긴다',
      );
      holds[1].complete();
      await tester.pumpAndSettle();
      expect(find.text(loginNetworkErrorMessage), findsOneWidget);
      expect(fake.loginCalls.length, 2);
    });
  });

  group('키보드가 올라올 때', () {
    testWidgets('로고는 접히고, 입력 내용과 포커스와 입력창은 그대로 남는다', (tester) async {
      const key = GlobalObjectKey('login-host');
      final fake = FakeAuthNotifier();
      final state = ScreenState(
        'test',
        overrides: [authProvider.overrideWith((ref) => fake)],
      );
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      Widget host(double keyboard) => ScreenHost(
        key: key,
        entry: loginScreenEntry,
        state: state,
        conditions: ScreenConditions(keyboardHeight: keyboard),
      );

      await tester.pumpWidget(host(0));
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);

      await tester.enterText(textField(0), '2025');
      await tester.tap(textField(1));
      await tester.pump();
      final editableBefore = tester.state(find.byType(EditableText).first);
      final passwordFocus = tester.widget<TextField>(textField(1)).focusNode!;
      expect(passwordFocus.hasFocus, isTrue);

      await tester.pumpWidget(host(ScreenConditions.keyboardUp));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing, reason: '키보드가 올라오면 로고를 접는다');
      expect(
        tester.state(find.byType(EditableText).first),
        same(editableBefore),
        reason: '입력창이 다시 만들어지면 키보드와 입력이 끊긴다',
      );
      expect(tester.widget<TextField>(textField(0)).controller!.text, '2025');
      expect(
        tester.widget<TextField>(textField(1)).focusNode!.hasFocus,
        isTrue,
      );

      await tester.pumpWidget(host(0));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget, reason: '키보드가 내려가면 다시 보인다');
      expect(tester.widget<TextField>(textField(0)).controller!.text, '2025');
    });
  });

  group('화면 구성', () {
    testWidgets('날 글자 위젯 없이 컴포넌트로만 그린다: 보이는 글자는 모두 SmashLabel이거나 입력창 안이다', (
      tester,
    ) async {
      await open(tester);
      for (final element in anyText().evaluate()) {
        final inField = find.ancestor(
          of: find.byWidget(element.widget),
          matching: find.byType(TextField),
        );
        final isLabel = element.widget is SmashLabel;
        final inButtonOrField = inField.evaluate().isNotEmpty;
        expect(
          isLabel || inButtonOrField,
          isTrue,
          reason: '${(element.widget as Text).data}',
        );
      }
    });

    testWidgets('두 입력칸의 이름(스크린리더)은 학번, 비밀번호다', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(find.bySemanticsLabel('학번'), findsOneWidget);
      expect(find.bySemanticsLabel('비밀번호'), findsOneWidget);
      handle.dispose();
    });
  });
}
