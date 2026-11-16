import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';

/// 시트, 대화상자, 스낵바를 띄우려면 Navigator와 ScaffoldMessenger가 필요하다 (MaterialApp이 제공).
Widget host(Widget Function(BuildContext context) builder, {double textScale = 1.0}) => MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(body: Builder(builder: builder)),
    );

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 800)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 시트 본체(둥근 Material)의 사각형. SmashSheetFrame 전체는 키보드 여백을 포함한다
Rect sheetRect(WidgetTester tester) =>
    tester.getRect(find.descendant(of: find.byType(SmashSheetFrame), matching: find.byType(Material)).first);

/// 지금 포커스가 [matching] 위젯 안쪽(그 위젯의 하위 요소)에 있는가.
/// 포커스가 화면 전체 범위(FocusScope)에 있을 때는 사각형이 겹쳐 보여도 false다.
bool focusInside(Finder matching) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  return find
      .ancestor(of: find.byElementPredicate((e) => identical(e, focusContext)), matching: matching)
      .evaluate()
      .isNotEmpty;
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _long = '이월은 다음 달 정규 활동에 한 번 빠져도 괜찮도록 미리 쌓아 두는 횟수예요. ';

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder f) => tester.getSemantics(f).getSemanticsData();

  group('showSmashSheet', () {
    late BuildContext ctx;
    Future<void> pump(WidgetTester tester, {double textScale = 1.0}) async {
      sizeScreen(tester);
      await tester.pumpWidget(host((c) {
        ctx = c;
        return const SizedBox();
      }, textScale: textScale));
    }

    testWidgets('제목과 내용이 보이고 닫기 버튼으로 닫으면 null이 돌아온다', (tester) async {
      await pump(tester);
      final result = showSmashSheet<String>(context: ctx, title: '이동 방식', builder: (_) => const Text('내용'));
      await settle(tester);
      expect(find.text('이동 방식'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.text('내용'), findsNothing); // 닫히지 않았다면 아래 await가 끝나지 않으므로 먼저 확인한다
      expect(await result, isNull);
    });

    testWidgets('Navigator.pop(값)으로 값을 돌려준다', (tester) async {
      await pump(tester);
      final result = showSmashSheet<String>(
        context: ctx,
        builder: (c) => SmashButton(label: '선택', onPressed: () => Navigator.of(c).pop('같이 가요')),
      );
      await settle(tester);

      await tester.tap(find.text('선택'));
      await settle(tester);

      expect(find.text('선택'), findsNothing);
      expect(await result, '같이 가요');
    });

    testWidgets('isDismissible: 바깥을 누르면 닫히고, false이면 닫히지 않는다', (tester) async {
      await pump(tester);
      showSmashSheet<void>(context: ctx, builder: (_) => const Text('내용'));
      await settle(tester);
      await tester.tapAt(const Offset(200, 40));
      await settle(tester);
      expect(find.text('내용'), findsNothing);

      showSmashSheet<void>(context: ctx, isDismissible: false, enableDrag: false, builder: (_) => const Text('내용'));
      await settle(tester);
      await tester.tapAt(const Offset(200, 40));
      await settle(tester);
      expect(find.text('내용'), findsOneWidget);
    });

    testWidgets('enableDrag: 끌어내리면 닫히고, false이면 손잡이도 없고 끌어도 닫히지 않는다', (tester) async {
      Finder handle() => find.byWidgetPredicate(
            (w) => w is Container && w.constraints == const BoxConstraints.tightFor(width: 40, height: 4),
          );

      await pump(tester);
      showSmashSheet<void>(context: ctx, builder: (_) => const SizedBox(height: 100, child: Text('내용')));
      await settle(tester);
      expect(handle(), findsOneWidget);
      await tester.fling(find.text('내용'), const Offset(0, 400), 1500);
      await settle(tester);
      expect(find.text('내용'), findsNothing);

      showSmashSheet<void>(
        context: ctx,
        enableDrag: false,
        isDismissible: false,
        builder: (_) => const SizedBox(height: 100, child: Text('내용')),
      );
      await settle(tester);
      expect(handle(), findsNothing);
      await tester.fling(find.text('내용'), const Offset(0, 400), 1500);
      await settle(tester);
      expect(find.text('내용'), findsOneWidget);
    });

    testWidgets('showCloseButton false이면 닫기 버튼이 없다', (tester) async {
      await pump(tester);
      showSmashSheet<void>(context: ctx, title: '제목', showCloseButton: false, builder: (_) => const Text('내용'));
      await settle(tester);

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('키보드가 올라오면 시트가 키보드 위로 올라간다', (tester) async {
      await pump(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      showSmashSheet<void>(
        context: ctx,
        title: '메모',
        builder: (_) => const SmashTextField(label: '메모'),
      );
      await settle(tester);

      expect(sheetRect(tester).bottom, lessThanOrEqualTo(800 - 300));
      expect(tester.getRect(find.byType(SmashTextField)).bottom, lessThanOrEqualTo(800 - 300));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('내용이 아주 길면 시트는 화면의 90%를 넘지 않고 안에서 스크롤된다 (글자 $scale배)', (tester) async {
        await pump(tester, textScale: scale);
        showSmashSheet<void>(context: ctx, title: '안내', builder: (_) => Text(_long * 60));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(sheetRect(tester).height, lessThanOrEqualTo(800 * 0.9 + 0.5));
        final scrollable = find.descendant(of: find.byType(SmashSheetFrame), matching: find.byType(Scrollable));
        final before = tester.getTopLeft(find.textContaining('이월은').first).dy;
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pump();
        expect(tester.getTopLeft(find.textContaining('이월은').first).dy, lessThan(before));
      });
    }

    testWidgets('스크린리더: 제목은 heading, 닫기 버튼은 "닫기"로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      showSmashSheet<void>(context: ctx, title: '이동 방식', builder: (_) => const Text('내용'));
      await settle(tester);

      expect(semanticsOf(tester, find.text('이동 방식')).flagsCollection.isHeader, isTrue);
      expect(find.bySemanticsLabel('닫기'), findsOneWidget);
      final closeSize = tester.getSize(find.byType(SmashIconButton));
      expect(closeSize, const Size(48, 48));
      handle.dispose();
    });
  });

  group('showSmashConfirm / showSmashAlert / SmashDialog', () {
    late BuildContext ctx;
    Future<void> pump(WidgetTester tester, {double textScale = 1.0}) async {
      sizeScreen(tester);
      await tester.pumpWidget(host((c) {
        ctx = c;
        return const SizedBox();
      }, textScale: textScale));
    }

    testWidgets('확인을 누르면 true, 취소를 누르면 false', (tester) async {
      await pump(tester);
      var result = showSmashConfirm(context: ctx, title: '보낼까요?', confirmLabel: '보내기');
      await settle(tester);
      await tester.tap(find.text('보내기'));
      await settle(tester);
      expect(find.byType(SmashDialog), findsNothing);
      expect(await result, isTrue);

      result = showSmashConfirm(context: ctx, title: '보낼까요?', confirmLabel: '보내기');
      await settle(tester);
      await tester.tap(find.text('취소'));
      await settle(tester);
      expect(find.byType(SmashDialog), findsNothing);
      expect(await result, isFalse);
    });

    testWidgets('바깥을 눌러 닫으면 false (확인으로 취급하지 않는다)', (tester) async {
      await pump(tester);
      final result = showSmashConfirm(context: ctx, title: '삭제할까요?', confirmLabel: '삭제', destructive: true);
      await settle(tester);

      await tester.tapAt(const Offset(5, 5));
      await settle(tester);

      expect(find.byType(SmashDialog), findsNothing);
      expect(await result, isFalse);
    });

    testWidgets('barrierDismissible false이면 바깥을 눌러도 닫히지 않는다', (tester) async {
      await pump(tester);
      showSmashConfirm(context: ctx, title: '삭제할까요?', confirmLabel: '삭제', barrierDismissible: false);
      await settle(tester);

      await tester.tapAt(const Offset(5, 5));
      await settle(tester);

      expect(find.text('삭제할까요?'), findsOneWidget);
    });

    testWidgets('destructive이면 확인 버튼이 위험(빨강) 종류, 아니면 기본 종류다', (tester) async {
      await pump(tester);
      showSmashConfirm(context: ctx, title: '삭제할까요?', confirmLabel: '삭제', destructive: true);
      await settle(tester);
      expect(tester.widget<SmashButton>(find.widgetWithText(SmashButton, '삭제')).variant, SmashButtonVariant.danger);
      expect(tester.widget<SmashButton>(find.widgetWithText(SmashButton, '취소')).variant, SmashButtonVariant.secondary);
      await tester.tap(find.text('취소'));
      await settle(tester);

      showSmashConfirm(context: ctx, title: '보낼까요?', confirmLabel: '보내기');
      await settle(tester);
      expect(tester.widget<SmashButton>(find.widgetWithText(SmashButton, '보내기')).variant, SmashButtonVariant.primary);
    });

    testWidgets('버튼은 세로로 쌓인다: 확인이 위, 취소가 아래, 폭이 같고 높이는 48 이상이다', (tester) async {
      await pump(tester);
      showSmashConfirm(context: ctx, title: '보낼까요?', confirmLabel: '보내기');
      await settle(tester);

      final ok = tester.getRect(find.widgetWithText(SmashButton, '보내기'));
      final cancel = tester.getRect(find.widgetWithText(SmashButton, '취소'));
      expect(ok.bottom, lessThan(cancel.top));
      expect(ok.left, cancel.left);
      expect(ok.width, cancel.width);
      expect(ok.height, greaterThanOrEqualTo(48));
      expect(cancel.height, greaterThanOrEqualTo(48));
    });

    group('위험한 확인(destructive)의 안전장치', () {
      bool focusOn(WidgetTester tester, String label) => focusInside(find.widgetWithText(SmashButton, label));

      testWidgets('destructive이면 처음 포커스가 취소 버튼에 가고, 화면 순서(확인 위, 취소 아래)는 그대로다', (tester) async {
        await pump(tester);
        showSmashConfirm(context: ctx, title: '활동을 삭제할까요?', confirmLabel: '삭제', destructive: true);
        await settle(tester);

        expect(focusOn(tester, '취소'), isTrue);
        expect(focusOn(tester, '삭제'), isFalse);
        expect(
          tester.getTopLeft(find.widgetWithText(SmashButton, '삭제')).dy,
          lessThan(tester.getTopLeft(find.widgetWithText(SmashButton, '취소')).dy),
        );
      });

      testWidgets('destructive에서 키보드 Enter를 눌러도 삭제되지 않고 취소(false)가 된다', (tester) async {
        await pump(tester);
        final result = showSmashConfirm(context: ctx, title: '활동을 삭제할까요?', confirmLabel: '삭제', destructive: true);
        await settle(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);

        expect(find.byType(SmashDialog), findsNothing);
        expect(await result, isFalse);
      });

      testWidgets('destructive가 아니면 동작을 바꾸지 않는다: 처음 포커스가 어느 버튼에도 없고 Enter로 닫히지 않는다', (tester) async {
        await pump(tester);
        showSmashConfirm(context: ctx, title: '보낼까요?', confirmLabel: '보내기');
        await settle(tester);

        expect(focusOn(tester, '보내기'), isFalse);
        expect(focusOn(tester, '취소'), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle(tester);
        expect(find.byType(SmashDialog), findsOneWidget);
      });

      for (final vague in ['확인', '예', '네', ' 확인 ']) {
        testWidgets("destructive에서 confirmLabel '$vague'은 assert로 막힌다 (호출한 자리에서 바로)", (tester) async {
          await pump(tester);

          // throwsAssertionError는 함수가 Future를 돌려주면 그 Future가 끝나길 기다려서, assert가 깨지면 실패가 아니라 멈춘다.
          // 그래서 직접 잡아서 확인한다 (깨지면 바로 실패)
          Object? thrown;
          try {
            showSmashConfirm(context: ctx, title: '삭제할까요?', confirmLabel: vague, destructive: true);
          } catch (e) {
            thrown = e;
          }
          expect(thrown, isA<AssertionError>());
        });
      }

      testWidgets("destructive가 아니면 '확인'도 허용하고, destructive의 구체적인 글자('삭제', '탈퇴하기')도 허용한다", (tester) async {
        await pump(tester);

        showSmashConfirm(context: ctx, title: '진행할까요?', confirmLabel: '확인');
        await settle(tester);
        expect(find.widgetWithText(SmashButton, '확인'), findsOneWidget);
        await tester.tap(find.text('취소'));
        await settle(tester);

        showSmashConfirm(context: ctx, title: '탈퇴할까요?', confirmLabel: '탈퇴하기', destructive: true);
        await settle(tester);
        expect(find.widgetWithText(SmashButton, '탈퇴하기'), findsOneWidget);
      });
    });

    testWidgets('showSmashAlert: 버튼 하나이고 누르면 닫힌다', (tester) async {
      await pump(tester);
      final done = showSmashAlert(context: ctx, title: '저장했어요', message: '반영됐어요.');
      await settle(tester);
      expect(find.byType(SmashButton), findsOneWidget);

      await tester.tap(find.text('확인'));
      await settle(tester);

      expect(find.text('저장했어요'), findsNothing);
      await done;
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('메시지가 아주 길어도 대화상자는 화면을 넘지 않고 버튼은 보인다 (글자 $scale배)', (tester) async {
        await pump(tester, textScale: scale);
        showSmashConfirm(context: ctx, title: '이용 안내', message: _long * 40, confirmLabel: '확인했어요');
        await settle(tester);

        expect(tester.takeException(), isNull);
        final dialog = tester.getRect(find.byType(Dialog));
        expect(dialog.top, greaterThanOrEqualTo(0));
        expect(dialog.bottom, lessThanOrEqualTo(800));
        expect(tester.getRect(find.widgetWithText(SmashButton, '확인했어요')).bottom, lessThanOrEqualTo(800));
        expect(find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable)), findsOneWidget);
      });
    }

    testWidgets('content 자리에 입력창을 넣을 수 있다', (tester) async {
      await pump(tester);
      showSmashDialog<void>(
        context: ctx,
        builder: (_) => const SmashDialog(
          title: '거절 사유',
          message: '사유를 적어 주세요.',
          content: SmashTextField(label: '사유'),
        ),
      );
      await settle(tester);

      expect(find.byType(SmashTextField), findsOneWidget);
      expect(tester.getTopLeft(find.byType(SmashTextField)).dy, greaterThan(tester.getBottomLeft(find.text('사유를 적어 주세요.')).dy));
    });

    testWidgets('스크린리더: 제목이 heading이고 대화상자 이름으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      showSmashAlert(context: ctx, title: '저장했어요');
      await settle(tester);

      expect(find.bySemanticsLabel('저장했어요'), findsWidgets);
      expect(semanticsOf(tester, find.text('저장했어요')).flagsCollection.isHeader, isTrue);
      handle.dispose();
    });
  });

  group('showSmashSnackBar', () {
    late BuildContext ctx;
    Future<void> pump(WidgetTester tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(host((c) {
        ctx = c;
        return const SizedBox();
      }));
    }

    Future<void> end(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox()); // 남은 스낵바 타이머 정리
    }

    testWidgets('메시지가 보이고, 연달아 띄우면 마지막 것만 남는다 (쌓이지 않는다)', (tester) async {
      await pump(tester);
      showSmashSnackBar(ctx, '첫 번째');
      showSmashSnackBar(ctx, '두 번째');
      showSmashSnackBar(ctx, '세 번째');
      await settle(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('세 번째'), findsOneWidget);
      expect(find.text('첫 번째'), findsNothing);
      expect(find.text('두 번째'), findsNothing);
      await end(tester);
    });

    testWidgets('진행 중 → replace로 완료로 교체: 스낵바는 계속 하나이고 진행 표시가 사라진다', (tester) async {
      await pump(tester);
      final handle = showSmashSnackBar(ctx, '사진을 올리는 중이에요', tone: SmashSnackTone.progress);
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(handle.isActive, isTrue);

      handle.replace('사진을 올렸어요');
      await settle(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('사진을 올렸어요'), findsOneWidget);
      expect(find.text('사진을 올리는 중이에요'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await end(tester);
    });

    testWidgets('진행 중 스낵바는 직접 끝낼 때까지 사라지지 않는다', (tester) async {
      await pump(tester);
      showSmashSnackBar(ctx, '올리는 중', tone: SmashSnackTone.progress);
      await tester.pump();
      await tester.pump(const Duration(minutes: 5));

      expect(find.text('올리는 중'), findsOneWidget);
      await end(tester);
    });

    testWidgets('진행 중 스낵바가 다른 스낵바에 밀려 사라졌어도 replace는 결과를 보여준다', (tester) async {
      await pump(tester);
      final handle = showSmashSnackBar(ctx, '올리는 중', tone: SmashSnackTone.progress);
      await settle(tester);
      showSmashSnackBar(ctx, '다른 안내');
      await settle(tester);

      handle.replace('올렸어요');
      await settle(tester);

      expect(find.text('올렸어요'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      await end(tester);
    });

    testWidgets('dismiss: 닫히고 isActive가 false가 된다', (tester) async {
      await pump(tester);
      final handle = showSmashSnackBar(ctx, '안내');
      await settle(tester);

      handle.dismiss();
      await settle(tester);

      expect(find.text('안내'), findsNothing);
      expect(handle.isActive, isFalse);
      await end(tester);
    });

    testWidgets('오류는 약 6초, 완료는 약 3초 동안 보인다', (tester) async {
      await pump(tester);
      // 표시 시간은 스낵바가 다 나타난 뒤부터 센다. 한 번에 길게 pump하면 중간 프레임이 없어 타이머가 늦게 시작되므로 나눠서 흘린다
      showSmashSnackBar(ctx, '저장 실패', tone: SmashSnackTone.error);
      await settle(tester);
      await tester.pump(const Duration(seconds: 5)); // 약 5.4초
      expect(find.text('저장 실패'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2)); // 약 7.4초: 6초 타이머는 끝났다
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('저장 실패'), findsNothing);

      showSmashSnackBar(ctx, '저장했어요', tone: SmashSnackTone.success);
      await settle(tester);
      await tester.pump(const Duration(seconds: 2)); // 약 2.4초
      expect(find.text('저장했어요'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2)); // 약 4.4초: 3초 타이머는 끝났다
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('저장했어요'), findsNothing);
      await end(tester);
    });

    test('종류별 기본 표시 시간 표', () {
      expect(SmashSnackHandle.defaultDuration(SmashSnackTone.info), const Duration(seconds: 4));
      expect(SmashSnackHandle.defaultDuration(SmashSnackTone.success), const Duration(seconds: 3));
      expect(SmashSnackHandle.defaultDuration(SmashSnackTone.error), const Duration(seconds: 6));
      expect(SmashSnackHandle.defaultDuration(SmashSnackTone.progress), greaterThan(const Duration(minutes: 1)));
    });

    testWidgets('작업 버튼이 있으면 누를 수 있고 onAction이 불린다', (tester) async {
      await pump(tester);
      var retries = 0;
      showSmashSnackBar(ctx, '저장 실패', tone: SmashSnackTone.error, actionLabel: '다시 시도', onAction: () => retries++);
      await settle(tester);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(retries, 1);
      await end(tester);
    });

    testWidgets('종류마다 아이콘이 다르다 (색만으로 구분하지 않는다)', (tester) async {
      await pump(tester);
      showSmashSnackBar(ctx, '안내');
      await settle(tester);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      showSmashSnackBar(ctx, '성공', tone: SmashSnackTone.success);
      await settle(tester);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      showSmashSnackBar(ctx, '실패', tone: SmashSnackTone.error);
      await settle(tester);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await end(tester);
    });

    testWidgets('스크린리더: 종류를 말로 붙여 바로 읽는다 (liveRegion)', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      showSmashSnackBar(ctx, '저장하지 못했어요', tone: SmashSnackTone.error);
      await settle(tester);

      final node = find.bySemanticsLabel('오류, 저장하지 못했어요');
      expect(node, findsOneWidget);
      expect(semanticsOf(tester, node).flagsCollection.isLiveRegion, isTrue);
      await end(tester);
      handle.dispose();
    });

    test('글자 대비: 어두운 바탕 위의 글자와 종류별 아이콘', () {
      expect(contrastRatio(SmashColors.onBrand, SmashColors.text), greaterThanOrEqualTo(4.5));
      for (final icon in [SmashColors.brandTint, SmashColors.successBg, SmashColors.dangerBg]) {
        expect(contrastRatio(icon, SmashColors.text), greaterThanOrEqualTo(3.0));
      }
      expect(contrastRatio(SmashColors.brandTint, SmashColors.text), greaterThanOrEqualTo(4.5)); // 작업 버튼 글자
    });

    testWidgets('SmashScaffold의 하단 막대가 있으면 스낵바는 막대 위에 뜬다 (겹치지 않는다)', (tester) async {
      sizeScreen(tester);
      late BuildContext inner;
      await tester.pumpWidget(MaterialApp(
        theme: SmashTheme.light(),
        home: Builder(builder: (c) {
          inner = c;
          return SmashScaffold(
            body: const SizedBox(),
            bottom: SmashBottomBar(child: SmashButton(label: '저장', onPressed: () {})),
          );
        }),
      ));
      showSmashSnackBar(inner, '안내');
      await settle(tester);

      final snack = tester.getRect(find.byType(SnackBar));
      final bar = tester.getRect(find.byType(SmashBottomBar));
      expect(snack.bottom, lessThanOrEqualTo(bar.top));
      await end(tester);
    });
  });

  group('SmashButton autofocus 전달', () {
    Widget app(bool autofocus) => MaterialApp(
          theme: SmashTheme.light(),
          home: Scaffold(
            body: Column(children: [
              SmashButton(label: '대상', autofocus: autofocus, onPressed: () {}),
              SmashButton(label: '다른 버튼', onPressed: () {}),
            ]),
          ),
        );

    testWidgets('autofocus 기본값은 false이고, true이면 열릴 때 그 버튼에 포커스가 간다', (tester) async {
      await tester.pumpWidget(app(false));
      await tester.pump();
      expect(focusInside(find.widgetWithText(SmashButton, '대상')), isFalse);

      await tester.pumpWidget(app(true));
      await tester.pump();
      expect(focusInside(find.widgetWithText(SmashButton, '대상')), isTrue);
    });
  });

  group('SmashInlineNotice', () {
    Widget host1(Widget child, {double textScale = 1.0, double width = 320}) => MaterialApp(
          theme: SmashTheme.light(),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: app!,
          ),
          home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
        );

    testWidgets('종류마다 다른 아이콘이 있다', (tester) async {
      final icons = <IconData>{};
      for (final tone in SmashNoticeTone.values) {
        await tester.pumpWidget(host1(SmashInlineNotice(tone: tone, message: '안내')));
        expect(find.byIcon(SmashInlineNotice.iconFor(tone)), findsOneWidget, reason: '$tone');
        icons.add(SmashInlineNotice.iconFor(tone));
      }
      expect(icons.length, SmashNoticeTone.values.length);
    });

    testWidgets('제목은 있을 때만 보이고, 작업 버튼은 글자와 콜백이 모두 있을 때만 보인다', (tester) async {
      await tester.pumpWidget(host1(const SmashInlineNotice(message: '본문')));
      expect(find.byType(SmashButton), findsNothing);

      await tester.pumpWidget(host1(const SmashInlineNotice(message: '본문', actionLabel: '다시 시도')));
      expect(find.byType(SmashButton), findsNothing);

      var taps = 0;
      await tester.pumpWidget(host1(
        SmashInlineNotice(title: '제목', message: '본문', actionLabel: '다시 시도', onAction: () => taps++),
      ));
      expect(find.text('제목'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(taps, 1);
      expect(tester.getSize(find.byType(SmashButton)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('오류(danger)만 나타날 때 바로 읽히는 liveRegion이다', (tester) async {
      final handle = tester.ensureSemantics();
      for (final tone in SmashNoticeTone.values) {
        await tester.pumpWidget(host1(SmashInlineNotice(tone: tone, message: '안내 $tone')));
        final data = tester.getSemantics(find.bySemanticsLabel(RegExp('안내'))).getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, tone == SmashNoticeTone.danger, reason: '$tone');
      }
      handle.dispose();
    });

    testWidgets('화면에 그려지는 배경색이 colorsFor와 같다', (tester) async {
      for (final tone in SmashNoticeTone.values) {
        await tester.pumpWidget(host1(SmashInlineNotice(tone: tone, message: '안내')));
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(SmashInlineNotice), matching: find.byType(DecoratedBox)).first,
        );
        expect((box.decoration as BoxDecoration).color, SmashInlineNotice.colorsFor(tone).$1, reason: '$tone');
      }
    });

    test('본문 글자와 아이콘 대비가 기준 이상이다', () {
      for (final tone in SmashNoticeTone.values) {
        final (background, accent) = SmashInlineNotice.colorsFor(tone);
        expect(contrastRatio(SmashColors.text, background), greaterThanOrEqualTo(4.5), reason: '$tone 본문');
        expect(contrastRatio(accent, background), greaterThanOrEqualTo(3.0), reason: '$tone 아이콘');
      }
    });

    testWidgets('긴 글 + 글자 2.0배 + 좁은 폭에서도 넘치지 않는다', (tester) async {
      await tester.pumpWidget(host1(
        SmashInlineNotice(
          tone: SmashNoticeTone.warning,
          title: '이월 안내',
          message: _long,
          actionLabel: '다시 시도',
          onAction: () {},
        ),
        textScale: 2.0,
        width: 280,
      ));

      expect(tester.takeException(), isNull);
    });
  });

  test('(Tristate import 사용 확인)', () => expect(Tristate.isTrue, isNotNull));
}
