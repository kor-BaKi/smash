import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const attend = SmashParticipationAction.attend;
const absent = SmashParticipationAction.absent;
const carryover = SmashParticipationAction.carryover;
const otherGroup = SmashParticipationAction.otherGroup;
const all4 = [attend, absent, carryover, otherGroup];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  Widget buttons({
    List<SmashParticipationAction> actions = all4,
    FutureOr<void> Function(SmashParticipationAction)? onAction,
    SmashParticipationAction? loading,
    bool enabled = true,
    bool nullHandler = false,
  }) => SmashParticipationButtons(
    actions: actions,
    onAction: nullHandler ? null : (onAction ?? (_) {}),
    loadingAction: loading,
    enabled: enabled,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double scale = 1.0,
  }) => tester.pumpWidget(smashHarness(child, width: width, textScale: scale));

  Finder buttonOf(SmashParticipationAction a) => find.byKey(ValueKey(a));
  Finder labelOf(SmashParticipationAction a) =>
      find.descendant(of: buttonOf(a), matching: find.text(a.label));

  Rect rectOf(WidgetTester tester, SmashParticipationAction a) =>
      tester.getTopLeft(buttonOf(a)) & tester.getSize(buttonOf(a));

  int columns(WidgetTester tester, List<SmashParticipationAction> actions) {
    final top = rectOf(tester, actions.first).top;
    return actions
        .where((a) => (rectOf(tester, a).top - top).abs() < 0.5)
        .length;
  }

  double need(WidgetTester tester) => tester
      .renderObject<RenderBox>(find.byType(SmashAdaptiveRow))
      .getMinIntrinsicWidth(double.infinity);

  group('보이는 모습', () {
    testWidgets('actions 순서대로 라벨이 보이고, 참여만 주된 버튼이고 나머지는 보조 버튼이다', (
      tester,
    ) async {
      await pump(tester, buttons(), width: 800);
      final order = [
        for (final w in tester.widgetList<SmashButton>(
          find.byType(SmashButton),
        ))
          w.label,
      ];
      expect(order, ['참여', '불참', '이월', '타조참']);
      final variants = {
        for (final w in tester.widgetList<SmashButton>(
          find.byType(SmashButton),
        ))
          w.label: w.variant,
      };
      expect(variants['참여'], SmashButtonVariant.primary);
      expect(variants['불참'], SmashButtonVariant.secondary);
      expect(variants['이월'], SmashButtonVariant.secondary);
      expect(variants['타조참'], SmashButtonVariant.secondary);
    });

    testWidgets('서버가 준 순서와 개수를 그대로 따른다 (2개, 3개, 순서 바뀜)', (tester) async {
      await pump(
        tester,
        buttons(actions: const [otherGroup, attend]),
        width: 800,
      );
      expect(
        [
          for (final w in tester.widgetList<SmashButton>(
            find.byType(SmashButton),
          ))
            w.label,
        ],
        ['타조참', '참여'],
      );
      await pump(
        tester,
        buttons(actions: const [attend, carryover, otherGroup]),
        width: 800,
      );
      expect(
        [
          for (final w in tester.widgetList<SmashButton>(
            find.byType(SmashButton),
          ))
            w.label,
        ],
        ['참여', '이월', '타조참'],
      );
    });

    testWidgets('버튼은 글자 좌우 여백 8의 좁은 버튼이고 높이는 52 이상이다', (tester) async {
      await pump(tester, buttons(), width: 800);
      for (final w in tester.widgetList<SmashButton>(
        find.byType(SmashButton),
      )) {
        expect(w.horizontalPadding, 8);
        expect(w.expanded, isFalse);
      }
      for (final a in all4) {
        expect(rectOf(tester, a).height, greaterThanOrEqualTo(52));
      }
    });
  });

  group('누르기', () {
    testWidgets('각 버튼을 누르면 해당 행동 하나가 onAction으로 전달된다', (tester) async {
      final calls = <SmashParticipationAction>[];
      await pump(tester, buttons(onAction: calls.add), width: 800);
      for (final a in all4) {
        await tester.tap(buttonOf(a));
      }
      expect(calls, all4);
    });

    testWidgets('동기 처리기는 연속으로 눌러도 매번 전달된다 (처리 중 상태가 없다)', (tester) async {
      final calls = <SmashParticipationAction>[];
      await pump(tester, buttons(onAction: calls.add), width: 800);
      await tester.tap(buttonOf(attend));
      await tester.tap(buttonOf(attend));
      expect(calls, [attend, attend]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('비활성', () {
    testWidgets('onAction이 null이면 모든 버튼이 비활성이고 눌러도 아무 일도 없다', (tester) async {
      await pump(tester, buttons(nullHandler: true), width: 800);
      for (final w in tester.widgetList<SmashButton>(
        find.byType(SmashButton),
      )) {
        expect(w.onPressed, isNull, reason: w.label);
      }
      for (final a in all4) {
        await tester.tap(buttonOf(a), warnIfMissed: false);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('enabled가 false여도 같다 (누름이 전달되지 않는다)', (tester) async {
      final calls = <SmashParticipationAction>[];
      await pump(
        tester,
        buttons(enabled: false, onAction: calls.add),
        width: 800,
      );
      for (final w in tester.widgetList<SmashButton>(
        find.byType(SmashButton),
      )) {
        expect(w.onPressed, isNull, reason: w.label);
      }
      for (final a in all4) {
        await tester.tap(buttonOf(a), warnIfMissed: false);
      }
      expect(calls, isEmpty);
    });

    testWidgets('비활성 의미: 스크린리더가 사용 불가로 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, buttons(enabled: false), width: 800);
      final node = semanticsNode(
        tester,
        (d) => d.label.startsWith('참여, 이 활동에 참여'),
      )!.getSemanticsData();
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('처리 중 (화면이 알려 줌: loadingAction)', () {
    testWidgets('해당 버튼만 진행 표시를 보이고, 다른 버튼은 비활성이고, 모든 누름이 무시된다', (tester) async {
      final calls = <SmashParticipationAction>[];
      await pump(
        tester,
        buttons(loading: absent, onAction: calls.add),
        width: 800,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: buttonOf(absent),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      for (final a in all4) {
        await tester.tap(buttonOf(a), warnIfMissed: false);
      }
      expect(calls, isEmpty);
      final buttonsNow = {
        for (final w in tester.widgetList<SmashButton>(
          find.byType(SmashButton),
        ))
          w.label: w,
      };
      expect(buttonsNow['불참']!.isLoading, isTrue);
      expect(buttonsNow['참여']!.isLoading, isFalse);
      expect(buttonsNow['참여']!.onPressed, isNull, reason: '다른 버튼은 비활성으로 보인다');
    });

    testWidgets('처리 중에도 버튼 크기와 배치가 그대로다 (화면이 흔들리지 않는다)', (tester) async {
      await pump(tester, buttons(), width: 360);
      final before = [for (final a in all4) rectOf(tester, a)];
      await pump(tester, buttons(loading: attend), width: 360);
      expect([for (final a in all4) rectOf(tester, a)], before);
    });

    testWidgets('읽는 말에 "처리 중"이 붙고 풀어 읽는 말은 그대로다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, buttons(loading: attend), width: 800);
      expect(hasLabel(tester, '참여, 이 활동에 참여, 처리 중'), isTrue);
      handle.dispose();
    });

    testWidgets('loadingAction이 null로 돌아오면 다시 눌린다', (tester) async {
      final calls = <SmashParticipationAction>[];
      await pump(
        tester,
        buttons(loading: attend, onAction: calls.add),
        width: 800,
      );
      await tester.tap(buttonOf(absent), warnIfMissed: false);
      expect(calls, isEmpty);
      await pump(tester, buttons(onAction: calls.add), width: 800);
      await tester.tap(buttonOf(absent));
      expect(calls, [absent]);
    });
  });

  group('중복 탭 방지 (onAction이 Future)', () {
    testWidgets('같은 버튼을 연달아 눌러도 한 번만 전달되고, 끝나면 다시 눌린다', (tester) async {
      final calls = <SmashParticipationAction>[];
      final completer = Completer<void>();
      await pump(
        tester,
        buttons(
          onAction: (a) {
            calls.add(a);
            return completer.future;
          },
        ),
        width: 800,
      );

      await tester.tap(buttonOf(attend));
      await tester.pump();
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: '처리 중 표시',
      );
      await tester.tap(buttonOf(attend), warnIfMissed: false);
      await tester.tap(buttonOf(attend), warnIfMissed: false);
      expect(calls, [attend]);

      completer.complete();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(buttonOf(attend));
      expect(calls, [attend, attend], reason: '끝난 뒤에는 다시 전달된다');
    });

    testWidgets('처리 중에는 다른 버튼을 눌러도 전달되지 않는다 (두 가지 응답이 동시에 가지 않는다)', (
      tester,
    ) async {
      final calls = <SmashParticipationAction>[];
      final completer = Completer<void>();
      await pump(
        tester,
        buttons(
          onAction: (a) {
            calls.add(a);
            return completer.future;
          },
        ),
        width: 800,
      );
      await tester.tap(buttonOf(absent));
      await tester.pump();
      for (final a in [attend, carryover, otherGroup]) {
        await tester.tap(buttonOf(a), warnIfMissed: false);
      }
      expect(calls, [absent]);
      completer.complete();
      await tester.pump();
    });

    testWidgets('같은 프레임 안에서 연달아 눌러도 한 번만 전달된다 (다시 그리기를 기다리지 않는다)', (
      tester,
    ) async {
      final calls = <SmashParticipationAction>[];
      final completer = Completer<void>();
      await pump(
        tester,
        buttons(
          onAction: (a) {
            calls.add(a);
            return completer.future;
          },
        ),
        width: 800,
      );
      final first = tester.widget<SmashButton>(
        find
                .descendant(
                  of: buttonOf(attend),
                  matching: find.byType(SmashButton),
                )
                .evaluate()
                .isEmpty
            ? buttonOf(attend)
            : find.descendant(
                of: buttonOf(attend),
                matching: find.byType(SmashButton),
              ),
      );
      first.onPressed!();
      first.onPressed!();
      expect(calls, [attend]);
      completer.complete();
      await tester.pump();
    });

    testWidgets('Future가 오류로 끝나도 처리 중 표시가 사라지고 오류는 삼켜지지 않고 보고된다', (
      tester,
    ) async {
      await pump(
        tester,
        buttons(onAction: (a) => Future<void>.error(StateError('서버 오류'))),
        width: 800,
      );
      await tester.tap(buttonOf(attend));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final error = tester.takeException();
      expect(error, isA<StateError>(), reason: '오류는 보고된다');
      await tester.tap(buttonOf(attend));
      await tester.pump();
      await tester.pump();
      expect(
        tester.takeException(),
        isA<StateError>(),
        reason: '처리 중이 끝났으므로 다시 눌리고, 같은 오류가 다시 보고된다',
      );
    });

    testWidgets('끝나기 전에 화면이 사라져도 오류가 나지 않는다', (tester) async {
      final completer = Completer<void>();
      await pump(
        tester,
        buttons(onAction: (a) => completer.future),
        width: 800,
      );
      await tester.tap(buttonOf(attend));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      completer.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '화면이 loadingAction을 직접 주면 그것이 우선이다 (Future가 끝나도 화면이 정한 상태가 유지)',
      (tester) async {
        final completer = Completer<void>();
        await pump(
          tester,
          buttons(onAction: (a) => completer.future),
          width: 800,
        );
        await tester.tap(buttonOf(attend));
        await tester.pump();
        await pump(
          tester,
          buttons(onAction: (a) => completer.future, loading: carryover),
          width: 800,
        );
        expect(
          find.descendant(
            of: buttonOf(carryover),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: buttonOf(attend),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsNothing,
        );
        completer.complete();
        await tester.pump();
      },
    );
  });

  group('좁은 폭에서 배치: 4개 → 2×2 → 세로', () {
    testWidgets('판단 경계: 칸 폭 = 필요한 폭이면 4열, 1px 모자라면 2열, 2열도 모자라면 1열', (
      tester,
    ) async {
      await pump(tester, buttons(), width: 800);
      final n = need(tester);
      await pump(tester, buttons(), width: 4 * n + 3 * 8);
      expect(columns(tester, all4), 4);
      await pump(tester, buttons(), width: 4 * n + 3 * 8 - 1);
      expect(columns(tester, all4), 2);
      await pump(tester, buttons(), width: 2 * n + 8);
      expect(columns(tester, all4), 2);
      await pump(tester, buttons(), width: 2 * n + 8 - 1);
      expect(columns(tester, all4), 1);
    });

    testWidgets('3개는 3열 ↔ 1열, 2개는 2열 ↔ 1열 (2+1 배치는 없다)', (tester) async {
      final three = const [attend, carryover, otherGroup];
      await pump(tester, buttons(actions: three), width: 800);
      final n3 = need(tester);
      await pump(tester, buttons(actions: three), width: 3 * n3 + 16);
      expect(columns(tester, three), 3);
      await pump(tester, buttons(actions: three), width: 3 * n3 + 16 - 1);
      expect(columns(tester, three), 1);
      final two = const [attend, absent];
      await pump(tester, buttons(actions: two), width: 2 * n3 + 8 - 1);
      expect(columns(tester, two), anyOf(1, 2));
    });

    testWidgets('같은 행동의 버튼은 배치가 바뀌어도 같은 요소로 이어진다 (처리 중 표시가 끊기지 않는다)', (
      tester,
    ) async {
      await pump(tester, buttons(loading: attend), width: 800);
      final element = tester.element(buttonOf(attend));
      await pump(tester, buttons(loading: attend), width: 200, scale: 2.0);
      expect(tester.element(buttonOf(attend)), same(element));
    });

    for (final entry in {
      '4개': all4,
      '3개': const [attend, carryover, otherGroup],
      '2개': const [attend, absent],
    }.entries) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
            '${entry.key}, 폭 $width, 글자 $scale배: 낱말 중간 끊김 0, 넘침 0, 터치 48 이상, 칸 폭 같음',
            (tester) async {
              final actions = entry.value;
              await pump(
                tester,
                buttons(actions: actions),
                width: width - 32,
                scale: scale,
              );
              expect(tester.takeException(), isNull);
              final container = tester.getRect(
                find.byType(SmashParticipationButtons),
              );
              final rects = [for (final a in actions) rectOf(tester, a)];
              for (var i = 0; i < actions.length; i++) {
                expect(
                  midWordBreaks(tester, labelOf(actions[i])),
                  0,
                  reason: '낱말 중간 끊김: ${actions[i].label}',
                );
                expect(rects[i].height, greaterThanOrEqualTo(52));
                expect(rects[i].width, greaterThanOrEqualTo(48));
                expect(
                  rects[i].left,
                  greaterThanOrEqualTo(container.left - 0.001),
                );
                expect(
                  rects[i].right,
                  lessThanOrEqualTo(container.right + 0.001),
                );
                expect(
                  (rects[i].width - rects[0].width).abs(),
                  lessThan(0.001),
                  reason: '칸 폭 같음',
                );
              }
            },
          );
        }
      }
    }

    testWidgets('버튼 사이 간격은 가로 8, 줄 사이 8이다 (한 줄, 2×2, 세로)', (tester) async {
      await pump(tester, buttons(), width: 800);
      expect(
        rectOf(tester, absent).left - rectOf(tester, attend).right,
        8,
        reason: '한 줄: 가로 8',
      );
      final n = need(tester);
      await pump(tester, buttons(), width: 2 * n + 8 + 40);
      expect(columns(tester, all4), 2);
      expect(
        rectOf(tester, absent).left - rectOf(tester, attend).right,
        8,
        reason: '2×2: 가로 8',
      );
      expect(
        rectOf(tester, carryover).top - rectOf(tester, attend).bottom,
        8,
        reason: '2×2: 줄 8',
      );
      await pump(tester, buttons(), width: 2 * n + 8 - 1);
      expect(columns(tester, all4), 1);
      expect(
        rectOf(tester, absent).top - rectOf(tester, attend).bottom,
        8,
        reason: '세로: 줄 8',
      );
    });

    testWidgets('글자 2.0배, 폭 200에서는 세로로 쌓이고 모두 한 줄 전체 폭이다', (tester) async {
      await pump(tester, buttons(), width: 200, scale: 2.0);
      expect(columns(tester, all4), 1);
      for (var i = 1; i < all4.length; i++) {
        expect(
          rectOf(tester, all4[i]).top,
          greaterThan(rectOf(tester, all4[i - 1]).top),
        );
        expect(rectOf(tester, all4[i]).width, 200);
      }
    });

    testWidgets('글자 1.0배, 폭 320: 4개가 한 줄에 들어가는가 (현재 값을 기록)', (tester) async {
      await pump(tester, buttons(), width: 320 - 32);
      // 문구: 4열에는 288 이상이 필요한지 경계로 확인한다
      final n = need(tester);
      expect(columns(tester, all4), 4 * n + 24 <= 288 ? 4 : 2);
    });

    testWidgets('각 배치에서 어느 버튼을 눌러도 그 행동이 전달된다 (한 줄, 2×2, 세로)', (tester) async {
      for (final setup in [(800.0, 1.0), (200.0, 1.0), (200.0, 2.0)]) {
        final calls = <SmashParticipationAction>[];
        await pump(
          tester,
          buttons(onAction: calls.add),
          width: setup.$1,
          scale: setup.$2,
        );
        for (final a in all4) {
          await tester.tap(buttonOf(a));
        }
        expect(calls, all4, reason: '폭 ${setup.$1}, 글자 ${setup.$2}배');
      }
    });

    testWidgets('dry layout과 실제 크기가 같다', (tester) async {
      for (final setup in [(800.0, 1.0), (300.0, 1.0), (200.0, 2.0)]) {
        await pump(tester, buttons(), width: setup.$1, scale: setup.$2);
        final box = tester.renderObject<RenderBox>(
          find.byType(SmashParticipationButtons),
        );
        expect(box.getDryLayout(box.constraints), box.size);
      }
    });
  });

  group('스크린리더', () {
    testWidgets('버튼 줄 라벨이 먼저 읽히고, 각 버튼은 풀어서 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, buttons(), width: 800);
      expect(hasLabel(tester, '참여 방법'), isTrue);
      for (final a in all4) {
        expect(hasLabel(tester, a.readAs), isTrue, reason: a.readAs);
      }
      expect(SmashParticipationAction.attend.readAs, '참여, 이 활동에 참여');
      expect(SmashParticipationAction.absent.readAs, '불참, 이 활동에 불참');
      expect(SmashParticipationAction.carryover.readAs, '이월, 이월할 날짜를 고르기');
      expect(SmashParticipationAction.otherGroup.readAs, '타조참, 다른 조 활동에 참여');
      expect([for (final a in all4) a.label], ['참여', '불참', '이월', '타조참']);
      handle.dispose();
    });

    testWidgets('읽는 순서는 배치와 상관없이 actions 순서다 (한 줄, 2×2, 세로)', (tester) async {
      final handle = tester.ensureSemantics();
      for (final setup in [(800.0, 1.0), (200.0, 1.0), (200.0, 2.0)]) {
        await pump(tester, buttons(), width: setup.$1, scale: setup.$2);
        final order = <String>[];
        void walk(SemanticsNode node) {
          final label = node.getSemanticsData().label;
          for (final a in all4) {
            if (label == a.readAs) order.add(a.readAs);
          }
          for (final c in node.debugListChildrenInOrder(
            DebugSemanticsDumpOrder.traversalOrder,
          )) {
            walk(c);
          }
        }

        walk(semanticsOwner(tester).rootSemanticsNode!);
        expect(order, [
          for (final a in all4) a.readAs,
        ], reason: '폭 ${setup.$1}, 글자 ${setup.$2}배');
      }
      handle.dispose();
    });

    testWidgets('스크린리더의 탭 동작으로 눌러도 onAction이 불린다', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <SmashParticipationAction>[];
      await pump(tester, buttons(onAction: calls.add), width: 800);
      final node = semanticsNode(tester, (d) => d.label == otherGroup.readAs)!;
      semanticsOwner(tester).performAction(node.id, SemanticsAction.tap);
      expect(calls, [otherGroup]);
      handle.dispose();
    });

    testWidgets('처리 중에는 스크린리더의 탭 동작도 무시된다', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <SmashParticipationAction>[];
      await pump(
        tester,
        buttons(loading: attend, onAction: calls.add),
        width: 800,
      );
      final node = semanticsNode(
        tester,
        (d) => d.label == '참여, 이 활동에 참여, 처리 중',
      )!;
      semanticsOwner(tester).performAction(node.id, SemanticsAction.tap);
      expect(calls, isEmpty);
      handle.dispose();
    });
  });

  group('안전 영역', () {
    testWidgets('SafeArea가 좌우를 줄이면 줄어든 폭으로 열 수를 정한다', (tester) async {
      Widget host(EdgeInsets padding) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: padding),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Align(alignment: Alignment.topLeft, child: buttons()),
          ),
        ),
      );
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pump(tester, buttons(), width: 800);
      final n = need(tester);
      final fit = 4 * n + 24;
      tester.view.physicalSize = Size(fit + 40, 800);
      await tester.pumpWidget(host(EdgeInsets.zero));
      expect(columns(tester, all4), 4);
      await tester.pumpWidget(host(const EdgeInsets.symmetric(horizontal: 20)));
      expect(
        tester.getSize(find.byType(SmashParticipationButtons)).width,
        closeTo(fit, 0.001),
      );
      expect(columns(tester, all4), 4, reason: '정확히 들어간다');
      await tester.pumpWidget(host(const EdgeInsets.symmetric(horizontal: 21)));
      expect(columns(tester, all4), 2, reason: '2px 모자라서 2×2');
      expect(tester.getTopLeft(find.byType(SmashParticipationButtons)).dx, 21);
    });
  });

  group('잘못된 사용', () {
    test('행동이 0개나 5개 이상이면 assert', () {
      expect(
        () => SmashParticipationButtons(actions: const [], onAction: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => SmashParticipationButtons(
          actions: const [attend, absent, carryover, otherGroup, attend],
          onAction: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('같은 행동이 두 번 들어 있으면 오류가 난다', (tester) async {
      final errors = <Object>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exception);
      try {
        await pump(
          tester,
          buttons(actions: const [attend, attend]),
          width: 800,
        );
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors, isNotEmpty);
      expect(errors.first.toString(), contains('같은 행동'));
    });
  });

  group('SmashButton 추가 인자', () {
    test('horizontalPadding이 음수이면 assert', () {
      expect(
        () => SmashButton(label: 'a', onPressed: null, horizontalPadding: -1),
        throwsAssertionError,
      );
    });

    testWidgets(
      'semanticLabel을 주면 글자 대신 그 말을 읽고, 안 주면 라벨 그대로 읽는다 (기본 여백 24 유지)',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          Column(
            children: [
              SmashButton(
                label: '확인',
                semanticLabel: '확인, 저장하고 닫기',
                onPressed: () {},
              ),
              SmashButton(
                label: '취소',
                onPressed: () {},
                variant: SmashButtonVariant.secondary,
              ),
              SmashButton(
                label: '로딩',
                semanticLabel: '읽는 말',
                isLoading: true,
                onPressed: () {},
              ),
            ],
          ),
          width: 360,
        );
        expect(hasLabel(tester, '확인, 저장하고 닫기'), isTrue);
        expect(hasLabel(tester, '취소'), isTrue);
        expect(hasLabel(tester, '읽는 말, 처리 중'), isTrue);
        expect(
          const SmashButton(label: 'a', onPressed: null).horizontalPadding,
          24,
        );
        handle.dispose();
      },
    );

    testWidgets('horizontalPadding이 글자 좌우 여백이다 (기본 24, 줄이면 고유 폭이 줄어든다)', (
      tester,
    ) async {
      Future<double> minWidth(double padding) async {
        await pump(
          tester,
          SmashButton(
            label: '타조참',
            expanded: false,
            horizontalPadding: padding,
            onPressed: () {},
          ),
          width: 800,
        );
        // 버튼 모양은 부드럽게 바뀐다 (여백 변화도 끝날 때까지 기다린다)
        await tester.pump(const Duration(seconds: 1));
        return tester
            .renderObject<RenderBox>(find.byType(SmashButton))
            .getMinIntrinsicWidth(double.infinity);
      }

      final wide = await minWidth(24);
      final narrow = await minWidth(8);
      expect(wide - narrow, closeTo(32, 0.01));
      expect(SmashText.bodyStrong.fontSize, 16);
    });
  });
}
