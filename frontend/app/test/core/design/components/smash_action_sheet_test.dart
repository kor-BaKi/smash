import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pixels.dart';
import '../../../support/semantics_tree.dart';

final _boundaryKey = GlobalKey();

late BuildContext _ctx;

Widget app({double scale = 1.0, EdgeInsets safe = EdgeInsets.zero}) =>
    screenshotBoundary(
      _boundaryKey,
      MaterialApp(
        theme: SmashTheme.light(),
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, a) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: safe,
            viewPadding: safe,
          ),
          child: a!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              _ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 900)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

const edit = SmashAction<String>(
  value: 'edit',
  label: '이름 바꾸기',
  icon: Icons.edit_outlined,
);
const move = SmashAction<String>(
  value: 'move',
  label: '다른 조로 옮기기',
  icon: Icons.swap_horiz,
);
const delete = SmashAction<String>(
  value: 'delete',
  label: '조 삭제',
  icon: Icons.delete_outline,
  destructive: true,
);

Finder sheet() => find.byType(SmashSheetFrame);
Finder inSheet(Finder f) => find.descendant(of: sheet(), matching: f);
Finder row(String label) => find.byWidgetPredicate(
  (w) => w is SmashPressable && w.semanticLabel == label,
);
Finder cancelButton([String label = '취소']) =>
    find.widgetWithText(SmashButton, label);

Future<void> open(
  WidgetTester tester, {
  required List<SmashAction<String>> actions,
  required List<String?> results,
  String? title,
  String? message,
  String cancelLabel = '취소',
}) async {
  showSmashActionSheet<String>(
    context: _ctx,
    title: title,
    message: message,
    actions: actions,
    cancelLabel: cancelLabel,
  ).then(results.add);
  await settle(tester);
}

String? primaryButtonLabel() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context?.findAncestorWidgetOfExactType<SmashButton>()?.label;
}

void main() {
  group('모양', () {
    testWidgets(
      '제목, 설명, 행동 행(아이콘 + 글자, 높이 56 이상), 맨 아래 취소 버튼이 순서대로 있고 제목줄 ✕는 없다',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app());
        await open(
          tester,
          actions: [edit, move],
          results: [],
          title: '2조',
          message: '조를 관리해요',
        );

        expect(inSheet(find.text('2조')), findsOneWidget);
        expect(inSheet(find.text('조를 관리해요')), findsOneWidget);
        expect(
          find.byIcon(Icons.close),
          findsNothing,
          reason: '취소 버튼이 있으므로 ✕는 없다',
        );
        final first = tester.getRect(row('이름 바꾸기'));
        final second = tester.getRect(row('다른 조로 옮기기'));
        final cancel = tester.getRect(cancelButton());
        expect(first.top, lessThan(second.top));
        expect(
          second.bottom,
          lessThanOrEqualTo(cancel.top),
          reason: '취소는 행동 아래',
        );
        expect(first.height, greaterThanOrEqualTo(56));
        expect(second.height, greaterThanOrEqualTo(56));
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      },
    );

    testWidgets('행 사이에만 구분선이 있다 (행동 3개이면 2줄, 하나면 없음)', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, move, delete], results: []);
      expect(inSheet(find.byType(Divider)), findsNWidgets(2));
      await tester.tap(cancelButton());
      await tester.pumpAndSettle();

      await open(tester, actions: [edit], results: []);
      expect(inSheet(find.byType(Divider)), findsNothing);
    });

    testWidgets('취소 버튼 글자는 cancelLabel로 바꿀 수 있다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(tester, actions: [edit], results: [], cancelLabel: '닫기');

      expect(cancelButton('닫기'), findsOneWidget);
      expect(cancelButton(), findsNothing);
    });

    testWidgets('위험한 행동은 빨간 글자(굵게)와 빨간 아이콘, 일반 행동은 기본 색이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, delete], results: []);

      final dangerText = tester.widget<Text>(
        find.descendant(of: row('조 삭제'), matching: find.text('조 삭제')),
      );
      expect(dangerText.style!.color, SmashColors.danger);
      expect(dangerText.style!.fontWeight, FontWeight.w600);
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: row('조 삭제'),
                matching: find.byIcon(Icons.delete_outline),
              ),
            )
            .color,
        SmashColors.danger,
      );
      final normalText = tester.widget<Text>(
        find.descendant(of: row('이름 바꾸기'), matching: find.text('이름 바꾸기')),
      );
      expect(normalText.style!.color, SmashColors.text);
    });

    testWidgets('위험한 행동에 아이콘이 없으면 assert로 알려 준다', (tester) async {
      expect(
        () => SmashAction<String>(value: 'x', label: '삭제', destructive: true),
        throwsAssertionError,
      );
      expect(
        () => SmashAction<String>(
          value: 'x',
          label: '삭제',
          icon: Icons.delete_outline,
          destructive: true,
        ),
        returnsNormally,
      );
    });

    testWidgets('행동이 하나도 없으면 assert로 알려 준다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      expect(
        () => showSmashActionSheet<String>(context: _ctx, actions: const []),
        throwsAssertionError,
      );
    });
  });

  group('결과와 닫힘 규칙', () {
    testWidgets('행동을 누르면 그 value가 돌아오고 시트가 닫힌다', (tester) async {
      sizeScreen(tester);
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, move, delete], results: results);

      await tester.tap(row('다른 조로 옮기기'));
      await tester.pumpAndSettle();

      expect(results, ['move']);
      expect(sheet(), findsNothing);
    });

    testWidgets('취소 버튼은 null이다', (tester) async {
      sizeScreen(tester);
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(tester, actions: [edit], results: results);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(sheet(), findsNothing);
    });

    for (final entry in <String, Future<void> Function(WidgetTester)>{
      '바깥(배경) 누르기': (t) async => t.tapAt(const Offset(200, 20)),
      '뒤로 가기': (t) async => t.binding.handlePopRoute(),
      '아래로 끌기': (t) async =>
          t.fling(find.byType(SmashButton), const Offset(0, 700), 2500),
    }.entries) {
      testWidgets('${entry.key}: null이 돌아오고 시트가 닫힌다', (tester) async {
        sizeScreen(tester);
        final results = <String?>[];
        await tester.pumpWidget(app());
        await open(tester, actions: [edit, delete], results: results);

        await entry.value(tester);
        await tester.pumpAndSettle();

        expect(results, [null]);
        expect(sheet(), findsNothing);
      });
    }

    testWidgets('스크린리더 탈출 제스처(dismiss): null이 돌아오고 시트가 닫힌다', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, delete], results: results);

      final node = semanticsNode(
        tester,
        (d) => d.hasAction(SemanticsAction.dismiss),
      );
      expect(node, isNotNull);
      semanticsOwner(tester).performAction(node!.id, SemanticsAction.dismiss);
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(sheet(), findsNothing);
      handle.dispose();
    });

    testWidgets('고를 수 없는 행동은 눌러도 시트가 닫히지 않고 결과도 없다', (tester) async {
      sizeScreen(tester);
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(
        tester,
        actions: [
          edit,
          const SmashAction<String>(
            value: 'delete',
            label: '삭제 (권한 없음)',
            icon: Icons.delete_outline,
            destructive: true,
            enabled: false,
          ),
        ],
        results: results,
      );

      await tester.tap(row('삭제 (권한 없음)'));
      await tester.pumpAndSettle();

      expect(sheet(), findsOneWidget);
      expect(results, isEmpty);
      final text = tester.widget<Text>(
        find.descendant(
          of: row('삭제 (권한 없음)'),
          matching: find.text('삭제 (권한 없음)'),
        ),
      );
      expect(text.style!.color, SmashColors.textDisabled);
    });

    testWidgets('값 타입은 enum도 된다 (T extends Object)', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      Axis? picked;
      showSmashActionSheet<Axis>(
        context: _ctx,
        actions: const [
          SmashAction(value: Axis.horizontal, label: '가로'),
          SmashAction(value: Axis.vertical, label: '세로'),
        ],
      ).then((v) => picked = v);
      await settle(tester);

      await tester.tap(row('세로'));
      await tester.pumpAndSettle();

      expect(picked, Axis.vertical);
    });
  });

  group('포커스', () {
    testWidgets('위험한 행동이 있으면 처음 포커스가 취소 버튼에 간다 (Enter로 위험한 일이 실행되지 않는다)', (
      tester,
    ) async {
      sizeScreen(tester);
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(tester, actions: [delete, edit], results: results);

      expect(primaryButtonLabel(), '취소');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results, [null], reason: 'Enter는 취소를 눌러 위험한 행동이 실행되지 않는다');
    });

    testWidgets('위험한 행동이 없으면 취소 버튼으로 포커스를 강제로 옮기지 않는다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, move], results: []);

      expect(primaryButtonLabel(), isNot('취소'));
    });
  });

  group('접근성', () {
    testWidgets('행은 버튼으로 읽히고, 위험한 행동에는 주의 안내가, 고를 수 없는 행동에는 비활성이 있다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(
        tester,
        actions: [
          edit,
          delete,
          const SmashAction<String>(
            value: 'x',
            label: '내보내기',
            icon: Icons.upload,
            enabled: false,
          ),
        ],
        results: [],
      );

      final normal = semanticsNode(
        tester,
        (d) => d.label == '이름 바꾸기',
      )!.getSemanticsData();
      expect(normal.flagsCollection.isButton, isTrue);
      expect(normal.flagsCollection.isEnabled, Tristate.isTrue);
      final danger = semanticsNode(
        tester,
        (d) => d.label.contains('조 삭제'),
      )!.getSemanticsData();
      expect(danger.hint, '되돌리기 어려울 수 있는 작업이에요');
      final disabled = semanticsNode(
        tester,
        (d) => d.label == '내보내기',
      )!.getSemanticsData();
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('긴 목록과 낮은 화면', () {
    testWidgets('행동 8개가 낮은 화면(높이 480)에서 시트 안에서 스크롤되고 취소까지 닿는다', (tester) async {
      sizeScreen(tester, size: const Size(400, 480));
      final results = <String?>[];
      await tester.pumpWidget(app());
      await open(
        tester,
        actions: [
          for (var i = 1; i <= 8; i++)
            SmashAction<String>(
              value: '행동 $i',
              label: '행동 $i',
              icon: Icons.chevron_right,
            ),
        ],
        results: results,
        title: '부원 관리',
      );

      expect(tester.takeException(), isNull);
      final sheetRect = tester.getRect(sheet());
      expect(
        sheetRect.height,
        lessThanOrEqualTo(480 * 0.9 + 0.01),
        reason: '시트는 화면의 90%까지',
      );
      await tester.scrollUntilVisible(
        cancelButton(),
        100,
        scrollable: find
            .descendant(of: sheet(), matching: find.byType(Scrollable))
            .first,
      );
      await tester.tap(cancelButton());
      await tester.pumpAndSettle();
      expect(results, [null]);
    });
  });

  group('폭 320/360/390 × 글자 1.0/1.3/2.0', () {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('폭 $width, 글자 $scale배: 넘치지 않고 행 높이 56 이상, 행이 시트 폭을 채운다', (
          tester,
        ) async {
          sizeScreen(tester, size: Size(width, 900));
          await tester.pumpWidget(app(scale: scale));
          await open(
            tester,
            actions: [
              edit,
              move,
              delete,
              const SmashAction<String>(
                value: 'long',
                label: '이번 달 정규 참여 신청한 부원 전체에게 알림 보내기',
                icon: Icons.notifications_none,
              ),
            ],
            results: [],
            title: '조 관리',
            message: '조를 지우면 소속 부원은 미배정이 되고 이번 달 출석부터 적용돼요.',
          );

          expect(tester.takeException(), isNull);
          final sheetRect = tester.getRect(sheet());
          for (final label in [
            '이름 바꾸기',
            '다른 조로 옮기기',
            '조 삭제',
            '이번 달 정규 참여 신청한 부원 전체에게 알림 보내기',
          ]) {
            final rect = tester.getRect(row(label));
            expect(rect.height, greaterThanOrEqualTo(56), reason: label);
            expect(rect.left, greaterThanOrEqualTo(sheetRect.left));
            expect(rect.right, lessThanOrEqualTo(sheetRect.right + 0.01));
            expect(
              rect.width,
              greaterThan(width * 0.8),
              reason: '$label 행이 시트 폭을 채운다(터치 영역)',
            );
          }
        });
      }
    }
  });

  group('안전 영역(위 59, 아래 34, 좌우 20)이 시트 목록으로 새지 않는다', () {
    testWidgets('첫 행의 위 여백이 안전 영역이 없을 때와 같고, 아래는 시트가 의도한 안전 영역(34)만큼만 늘어난다', (
      tester,
    ) async {
      sizeScreen(tester);
      Future<(double, double)> measure(EdgeInsets safe) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(app(safe: safe));
        await open(tester, actions: [edit, move], results: [], title: '조');
        final sheetRect = tester.getRect(sheet());
        return (
          tester.getRect(row('이름 바꾸기')).top - sheetRect.top,
          sheetRect.bottom - tester.getRect(cancelButton()).bottom,
        );
      }

      final base = await measure(EdgeInsets.zero);
      final padded = await measure(const EdgeInsets.fromLTRB(20, 59, 20, 34));

      expect(padded.$1, base.$1, reason: '위 여백은 같아야 한다');
      expect(
        padded.$2 - base.$2,
        closeTo(34, 0.01),
        reason: '아래는 시트가 홈 인디케이터 영역만큼만 비운다',
      );
    });
  });

  group('눌린 행의 강조 (실제 픽셀)', () {
    testWidgets('제목 없는 시트에서 첫 행을 누르고 있어도 강조가 시트의 둥근 모서리나 시트 밖으로 새지 않는다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app());
      await open(tester, actions: [edit, move], results: []);
      final rowRect = tester.getRect(row('이름 바꾸기'));
      final sheetRect = tester.getRect(sheet());

      final gesture = await tester.startGesture(rowRect.center);
      await tester.pump(const Duration(milliseconds: 200));
      final px = await readPixels(tester, _boundaryKey);
      final tint = SmashColors.brandTintSoft;
      final y = (rowRect.top + 6).round();

      expect(
        colorDistance(
          px((rowRect.left + rowRect.width * 0.6).round(), y),
          tint,
        ),
        lessThan(30),
        reason: '눌린 행 안쪽은 강조 색',
      );
      expect(
        colorDistance(px((rowRect.left - 3).round(), y), tint),
        greaterThan(30),
        reason: '행 왼쪽 바깥',
      );
      expect(
        colorDistance(px((rowRect.right + 3).round(), y), tint),
        greaterThan(30),
        reason: '행 오른쪽 바깥',
      );
      for (final x in [
        sheetRect.left.round() + 1,
        sheetRect.right.round() - 2,
      ]) {
        expect(
          colorDistance(px(x, sheetRect.top.round() + 1), tint),
          greaterThan(30),
          reason: '시트 모서리 $x',
        );
      }
      expect(
        colorDistance(
          px((rowRect.center.dx).round(), (rowRect.bottom + 2).round()),
          tint,
        ),
        greaterThan(30),
        reason: '이웃한 행으로 새지 않는다',
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
