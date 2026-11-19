import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pixels.dart';
import '../../../support/semantics_tree.dart';

const _screen = Size(400, 900);
final _boundaryKey = GlobalKey();

Widget app(
  Widget child, {
  double width = 360,
  double scale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
}) => screenshotBoundary(
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
      body: Padding(
        padding: EdgeInsets.only(top: safe.top + 16),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

void sizeScreen(WidgetTester tester) {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

const groups = [
  SmashOption(value: 'g1', label: '1조'),
  SmashOption(value: 'g2', label: '2조'),
  SmashOption(value: 'g3', label: '3조'),
];

/// 값을 들고 있다가 바뀌면 다시 그리는 틀. 바뀐 값은 [log]에 쌓는다
class Host<T> extends StatefulWidget {
  const Host({
    super.key,
    required this.options,
    required this.log,
    this.initial,
    this.label = '조',
    this.sheetTitle,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.placeholder = '선택해 주세요',
  });

  final List<SmashOption<T>> options;
  final List<T> log;
  final T? initial;
  final String label;
  final String? sheetTitle;
  final String? helper;
  final String? errorText;
  final bool enabled;
  final String placeholder;

  @override
  State<Host<T>> createState() => _HostState<T>();
}

class _HostState<T> extends State<Host<T>> {
  late T? value = widget.initial;

  @override
  Widget build(BuildContext context) => SmashSelectField<T>(
    label: widget.label,
    value: value,
    options: widget.options,
    sheetTitle: widget.sheetTitle,
    helper: widget.helper,
    errorText: widget.errorText,
    enabled: widget.enabled,
    placeholder: widget.placeholder,
    onChanged: (next) {
      widget.log.add(next);
      setState(() => value = next);
    },
  );
}

Finder field() => find.byWidgetPredicate((w) => w is SmashSelectField);
Finder fieldBox() =>
    find.descendant(of: field(), matching: find.byType(SmashPressable));
Finder sheet() => find.byType(SmashSheetFrame);
Finder inSheet(Finder f) => find.descendant(of: sheet(), matching: f);
Finder option(String label) => inSheet(find.text(label));
Finder optionRow(String label) =>
    find.ancestor(of: option(label), matching: find.byType(SmashListRow)).first;

String? primaryLabel() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<SmashPressable>()
    ?.semanticLabel;

void main() {
  group('모양', () {
    testWidgets('값 없음: 안내 문구(보조색), 라벨은 칸 위, 칸 높이는 52 이상, 오른쪽 화살표', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, log: const [])),
      );

      expect(find.text('선택해 주세요'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('선택해 주세요')).style!.color,
        SmashColors.textSecondary,
      );
      expect(tester.getSize(fieldBox()).height, greaterThanOrEqualTo(52));
      expect(
        tester.getRect(find.text('조')).bottom,
        lessThanOrEqualTo(tester.getRect(fieldBox()).top + 0.01),
        reason: '라벨은 칸 위',
      );
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('값 있음: 고른 선택지의 라벨이 보이고 글자색이 기본이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'g2', log: const [])),
      );

      expect(
        tester
            .widget<Text>(
              find.descendant(of: fieldBox(), matching: find.text('2조')),
            )
            .style!
            .color,
        SmashColors.text,
      );
    });

    testWidgets('값이 선택지에 없으면 안내 문구를 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'zz', log: const [])),
      );

      expect(find.text('선택해 주세요'), findsOneWidget);
    });

    testWidgets('오류: 칸 아래에 아이콘과 문구, 빨간 두꺼운 테두리. 오류가 있으면 도움말은 사라진다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(
            options: groups,
            log: const [],
            helper: '도움말',
            errorText: '조를 골라 주세요',
          ),
        ),
      );

      expect(find.text('조를 골라 주세요'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('도움말'), findsNothing);
      final border =
          (tester
                          .widget<Container>(
                            find
                                .descendant(
                                  of: fieldBox(),
                                  matching: find.byType(Container),
                                )
                                .first,
                          )
                          .decoration
                      as BoxDecoration)
                  .border
              as Border;
      expect(border.top.color, SmashColors.danger);
      expect(border.top.width, 2);
    });

    testWidgets('도움말: 오류가 없으면 칸 아래에 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(options: groups, log: const [], helper: '조를 바꾸면 적용돼요'),
        ),
      );

      expect(find.text('조를 바꾸면 적용돼요'), findsOneWidget);
    });

    testWidgets('비활성이면 눌러도 열리지 않고 흐리게 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(
            options: groups,
            initial: 'g1',
            log: const [],
            enabled: false,
          ),
        ),
      );

      await tester.tap(fieldBox(), warnIfMissed: false);
      await settle(tester);

      expect(sheet(), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.descendant(of: fieldBox(), matching: find.text('1조')),
            )
            .style!
            .color,
        SmashColors.textDisabled,
      );
    });

    testWidgets('선택지가 없으면 비활성이고 열리지 않는다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: const [], log: const [])),
      );

      await tester.tap(fieldBox(), warnIfMissed: false);
      await settle(tester);

      expect(sheet(), findsNothing);
    });
  });

  group('열기와 고르기', () {
    testWidgets(
      '누르면 시트가 열리고 제목은 라벨이다 (sheetTitle이 있으면 그것). 선택지가 모두 나오고 고른 선택지에 체크가 있다',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(
          app(Host<String>(options: groups, initial: 'g2', log: const [])),
        );

        await tester.tap(fieldBox());
        await settle(tester);

        expect(inSheet(find.text('조')), findsOneWidget, reason: '제목 = 라벨');
        for (final label in ['1조', '2조', '3조']) {
          expect(option(label), findsOneWidget);
        }
        expect(
          find.descendant(
            of: optionRow('2조'),
            matching: find.byIcon(Icons.check),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: optionRow('1조'),
            matching: find.byIcon(Icons.check),
          ),
          findsNothing,
        );
        expect(tester.widget<SmashListRow>(optionRow('2조')).selected, isTrue);
      },
    );

    testWidgets('sheetTitle을 넘기면 그것이 제목이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(options: groups, log: const [], sheetTitle: '조를 골라 주세요'),
        ),
      );

      await tester.tap(fieldBox());
      await settle(tester);

      expect(inSheet(find.text('조를 골라 주세요')), findsOneWidget);
    });

    testWidgets('다른 선택지를 고르면 onChanged가 한 번 불리고 시트가 닫히며 칸에 새 값이 보인다', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <String>[];
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'g1', log: log)),
      );

      await tester.tap(fieldBox());
      await settle(tester);
      await tester.tap(option('3조'));
      await settle(tester);

      expect(log, ['g3']);
      expect(sheet(), findsNothing);
      expect(
        find.descendant(of: fieldBox(), matching: find.text('3조')),
        findsOneWidget,
      );
    });

    testWidgets('지금과 같은 선택지를 고르면 시트만 닫히고 onChanged는 불리지 않는다', (tester) async {
      sizeScreen(tester);
      final log = <String>[];
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'g2', log: log)),
      );

      await tester.tap(fieldBox());
      await settle(tester);
      await tester.tap(option('2조'));
      await settle(tester);

      expect(sheet(), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('값이 null인 선택지("미배정")도 고를 수 있고, 닫아서 null인 것과 구분된다', (
      tester,
    ) async {
      sizeScreen(tester);
      final log = <String?>[];
      await tester.pumpWidget(
        app(
          Host<String?>(
            options: const [
              SmashOption<String?>(value: null, label: '미배정'),
              SmashOption<String?>(value: 'g1', label: '1조'),
            ],
            initial: 'g1',
            log: log,
          ),
        ),
      );

      await tester.tap(fieldBox());
      await settle(tester);
      await tester.tap(option('미배정'));
      await settle(tester);

      expect(log, [null]);
      expect(
        find.descendant(of: fieldBox(), matching: find.text('미배정')),
        findsOneWidget,
      );
    });

    testWidgets('고를 수 없는 선택지는 눌러도 시트가 닫히지 않고 값도 그대로다', (tester) async {
      sizeScreen(tester);
      final log = <String>[];
      await tester.pumpWidget(
        app(
          Host<String>(
            options: const [
              SmashOption(value: 'a', label: '가능'),
              SmashOption(value: 'b', label: '불가', enabled: false),
            ],
            initial: 'a',
            log: log,
          ),
        ),
      );

      await tester.tap(fieldBox());
      await settle(tester);
      await tester.tap(option('불가'));
      await settle(tester);

      expect(sheet(), findsOneWidget);
      expect(log, isEmpty);
    });

    testWidgets('고를 수 없는 선택지는 흐리게(투명도 0.45) 보이고, 고를 수 있는 선택지는 흐리지 않다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(
            options: const [
              SmashOption(value: 'a', label: '가능'),
              SmashOption(value: 'b', label: '불가', enabled: false),
            ],
            initial: 'a',
            log: <String>[],
          ),
        ),
      );

      await tester.tap(fieldBox());
      await settle(tester);

      final dim = find.ancestor(
        of: optionRow('불가'),
        matching: find.byType(Opacity),
      );
      expect(dim, findsOneWidget);
      expect(tester.widget<Opacity>(dim).opacity, 0.45);
      expect(
        find.ancestor(of: optionRow('가능'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('선택지가 30개이면 시트 안에서 스크롤되고, 열릴 때 고른 선택지(24번)가 시트 안에 보인다', (
      tester,
    ) async {
      sizeScreen(tester);
      final many = [
        for (var i = 1; i <= 30; i++) SmashOption(value: i, label: '참여자 $i'),
      ];
      await tester.pumpWidget(
        app(Host<int>(options: many, initial: 24, log: const [], label: '참여자')),
      );

      await tester.tap(fieldBox());
      await settle(tester);

      final selectedRect = tester.getRect(optionRow('참여자 24'));
      final sheetRect = tester.getRect(sheet());
      expect(selectedRect.top, greaterThanOrEqualTo(sheetRect.top));
      expect(selectedRect.bottom, lessThanOrEqualTo(sheetRect.bottom));
      expect(
        tester.getRect(optionRow('참여자 1')).bottom,
        lessThan(sheetRect.top + 100),
        reason: '맨 위 선택지는 시트 위쪽으로 스크롤되어 보이지 않는다',
      );
    });
  });

  group('닫힘 규칙: 값은 그대로이고 포커스가 칸으로 돌아온다', () {
    Future<void> open(WidgetTester tester, List<String> log) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'g2', log: log)),
      );
      await tester.tap(fieldBox());
      await settle(tester);
      expect(sheet(), findsOneWidget);
    }

    void expectUnchanged(WidgetTester tester, List<String> log) {
      expect(sheet(), findsNothing);
      expect(log, isEmpty);
      expect(
        find.descendant(of: fieldBox(), matching: find.text('2조')),
        findsOneWidget,
      );
      expect(primaryLabel(), '조, 2조');
    }

    testWidgets('항목 선택: 칸으로 포커스가 돌아온다', (tester) async {
      final log = <String>[];
      await open(tester, log);
      await tester.tap(option('1조'));
      await settle(tester);

      expect(primaryLabel(), startsWith('조, '));
      expect(log, ['g1']);
    });

    testWidgets('닫기 버튼(✕)', (tester) async {
      final log = <String>[];
      await open(tester, log);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expectUnchanged(tester, log);
    });

    testWidgets('바깥(배경) 누르기', (tester) async {
      final log = <String>[];
      await open(tester, log);
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);

      expectUnchanged(tester, log);
    });

    testWidgets('뒤로 가기', (tester) async {
      final log = <String>[];
      await open(tester, log);
      await tester.binding.handlePopRoute();
      await settle(tester);

      expectUnchanged(tester, log);
    });

    testWidgets('아래로 끌기', (tester) async {
      final log = <String>[];
      await open(tester, log);
      await tester.fling(inSheet(find.text('조')), const Offset(0, 600), 2500);
      await settle(tester);

      expectUnchanged(tester, log);
    });

    testWidgets('스크린리더 탈출 제스처(dismiss)', (tester) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      await open(tester, log);

      final node = semanticsNode(
        tester,
        (d) => d.hasAction(SemanticsAction.dismiss),
      );
      expect(node, isNotNull, reason: '탈출 제스처를 받는 노드');
      semanticsOwner(tester).performAction(node!.id, SemanticsAction.dismiss);
      await tester.pumpAndSettle();

      expectUnchanged(tester, log);
      handle.dispose();
    });
  });

  group('접근성', () {
    testWidgets('칸은 "라벨, 값"(없으면 "선택 안 함")을 버튼으로 읽고 안내를 한다. 값이 바뀌면 따라 바뀐다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, log: <String>[])),
      );

      var node = semanticsNode(
        tester,
        (d) => d.label == '조, 선택 안 함',
      )!.getSemanticsData();
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.hint, '눌러서 선택해요');

      await tester.tap(fieldBox());
      await settle(tester);
      await tester.tap(option('3조'));
      await settle(tester);
      node = semanticsNode(
        tester,
        (d) => d.label == '조, 3조',
      )!.getSemanticsData();
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('선택지가 없으면 "선택할 항목이 없어요"로 안내한다', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: const [], log: const [])),
      );

      final node = semanticsNode(
        tester,
        (d) => d.label == '조, 선택 안 함',
      )!.getSemanticsData();
      expect(node.hint, '선택할 항목이 없어요');
      handle.dispose();
    });

    testWidgets('시트의 고른 선택지는 선택됨으로, 고를 수 없는 선택지는 비활성과 이유로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(
            options: const [
              SmashOption(value: 'a', label: '가능'),
              SmashOption(value: 'b', label: '불가', enabled: false),
            ],
            initial: 'a',
            log: const [],
          ),
        ),
      );

      await tester.tap(fieldBox());
      await settle(tester);

      final selected = semanticsNode(
        tester,
        (d) =>
            d.label.contains('가능') &&
            d.flagsCollection.isSelected == Tristate.isTrue,
      );
      expect(selected, isNotNull, reason: '고른 선택지는 selected');
      final disabled = semanticsNode(
        tester,
        (d) => d.label.contains('불가'),
      )!.getSemanticsData();
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(disabled.hint, '지금은 고를 수 없어요');
      handle.dispose();
    });

    testWidgets('오류 문구는 바로 읽힌다 (liveRegion)', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          Host<String>(options: groups, log: const [], errorText: '조를 골라 주세요'),
        ),
      );

      final node = semanticsNode(
        tester,
        (d) => d.label == '오류: 조를 골라 주세요',
      )!.getSemanticsData();
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('폭 320/360/390 × 글자 1.0/1.3/2.0', () {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          '폭 $width, 글자 $scale배: 칸과 시트가 넘치지 않고 칸 높이 52 이상, 긴 값도 칸 안에 있다',
          (tester) async {
            sizeScreen(tester);
            await tester.pumpWidget(
              app(
                Host<String>(
                  options: const [
                    SmashOption(
                      value: 'a',
                      label: '정규 참여 신청한 부원 전체 보기',
                      subtitle: '이번 달 활동에 참여하기로 한 사람',
                    ),
                    SmashOption(value: 'b', label: '이월'),
                  ],
                  initial: 'a',
                  log: const [],
                  errorText: '항목을 하나 골라 주세요',
                ),
                width: width,
                scale: scale,
              ),
            );

            expect(tester.takeException(), isNull);
            expect(tester.getSize(fieldBox()).height, greaterThanOrEqualTo(52));
            expect(
              tester.getRect(fieldBox()).right,
              lessThanOrEqualTo(width + 0.01),
            );

            await tester.tap(fieldBox());
            await settle(tester);
            expect(tester.takeException(), isNull);
            expect(sheet(), findsOneWidget);
            for (final row in find.byType(SmashListRow).evaluate()) {
              final rect = tester.getRect(find.byWidget(row.widget));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(_screen.width + 0.01));
              expect(
                rect.height,
                greaterThanOrEqualTo(56),
                reason: '터치 높이 56 이상',
              );
            }
          },
        );
      }
    }
  });

  group('안전 영역(위 59, 아래 34, 좌우 20)이 시트 목록으로 새지 않는다', () {
    testWidgets('첫 선택지의 위 여백이 안전 영역이 없을 때와 같고, 아래는 시트가 의도한 안전 영역(34)만큼만 늘어난다', (
      tester,
    ) async {
      sizeScreen(tester);
      Future<(double, double)> measure(EdgeInsets safe) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          app(
            Host<String>(options: groups, initial: 'g1', log: const []),
            safe: safe,
          ),
        );
        await tester.tap(fieldBox());
        await settle(tester);
        final sheetRect = tester.getRect(sheet());
        final first = tester.getRect(optionRow('1조'));
        final last = tester.getRect(optionRow('3조'));
        // 시트 맨 위에서 첫 선택지까지, 마지막 선택지에서 시트 맨 아래까지
        return (first.top - sheetRect.top, sheetRect.bottom - last.bottom);
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

  group('선택된 줄의 강조 (실제 픽셀)', () {
    testWidgets('고른 줄의 강조는 그 줄 안에만 있고 시트 바깥 여백이나 모서리로 새지 않는다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(Host<String>(options: groups, initial: 'g1', log: const [])),
      );
      await tester.tap(fieldBox());
      await settle(tester);
      final px = await readPixels(tester, _boundaryKey);
      final row = tester.getRect(optionRow('1조'));
      final other = tester.getRect(optionRow('2조'));
      final sheetRect = tester.getRect(sheet());
      final tint = SmashColors.brandTintSoft;
      final y = (row.top + 6).round();

      // 줄 안쪽(글자와 체크를 피한 곳)은 강조 색
      expect(
        colorDistance(px((row.left + row.width * 0.55).round(), y), tint),
        lessThan(30),
        reason: '고른 줄 안쪽',
      );
      // 왼쪽의 굵은 막대(4px)는 브랜드 색
      expect(
        colorDistance(
          px((row.left + 1).round(), (row.center.dy).round()),
          SmashColors.brand,
        ),
        lessThan(30),
        reason: '왼쪽 막대',
      );
      // 줄 바깥(시트 안쪽 여백)과 시트의 위쪽 두 모서리, 다른 줄에는 강조가 없다
      expect(
        colorDistance(px((row.left - 4).round(), y), tint),
        greaterThan(30),
        reason: '줄 왼쪽 바깥',
      );
      expect(
        colorDistance(px((row.right + 4).round(), y), tint),
        greaterThan(30),
        reason: '줄 오른쪽 바깥',
      );
      expect(
        colorDistance(
          px(
            (other.left + other.width * 0.55).round(),
            (other.top + 6).round(),
          ),
          tint,
        ),
        greaterThan(30),
        reason: '다른 줄',
      );
      for (final x in [
        sheetRect.left.round() + 1,
        sheetRect.right.round() - 2,
      ]) {
        final corner = px(x, sheetRect.top.round() + 1);
        expect(
          colorDistance(corner, SmashColors.brand),
          greaterThan(3000),
          reason: '시트 모서리 $x',
        );
        expect(
          colorDistance(corner, tint),
          greaterThan(30),
          reason: '시트 모서리 $x',
        );
      }
    });

    testWidgets('기준이 헛돌지 않는다: 강조 색과 흰색, 브랜드 색은 서로 다르다', (tester) async {
      expect(
        colorDistance(SmashColors.brandTintSoft, Colors.white),
        greaterThan(30),
      );
      expect(
        colorDistance(SmashColors.brand, SmashColors.brandTintSoft),
        greaterThan(30000),
      );
    });
  });
}
