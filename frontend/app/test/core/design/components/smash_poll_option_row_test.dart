import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/pump.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const _name = '목요일 저녁 7시';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  Widget row({
    String label = _name,
    SmashPollResult? result,
    bool isMine = false,
    VoidCallback? onSelect,
    bool isLoading = false,
  }) => SmashPollOptionRow(
    label: label,
    result: result,
    isMine: isMine,
    onSelect: onSelect,
    isLoading: isLoading,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double scale = 1.0,
  }) => tester.pumpWidget(smashHarness(child, width: width, textScale: scale));

  Finder rowFinder() => find.byType(SmashPollOptionRow);
  Finder textIn(String text) =>
      find.descendant(of: rowFinder(), matching: find.text(text));
  Finder iconIn(IconData icon) =>
      find.descendant(of: rowFinder(), matching: find.byIcon(icon));

  /// 줄의 바깥 테두리 (위에 그려지는 foregroundDecoration)
  Border border(WidgetTester tester) {
    final container = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SmashPollOptionRow),
            matching: find.byType(Container),
          ),
        )
        .firstWhere((c) => c.foregroundDecoration != null);
    return (container.foregroundDecoration! as BoxDecoration).border! as Border;
  }

  const result6of10 = SmashPollResult(votes: 6, totalVotes: 10);

  group('SmashPollResult', () {
    test('비율과 퍼센트: 반올림하고 전체가 0표이면 0이다', () {
      const cases = [
        (0, 0, 0.0, 0),
        (0, 8, 0.0, 0),
        (1, 3, 1 / 3, 33),
        (2, 3, 2 / 3, 67),
        (1, 8, 0.125, 13),
        (1, 2, 0.5, 50),
        (6, 10, 0.6, 60),
        (8, 8, 1.0, 100),
      ];
      for (final (votes, total, ratio, percent) in cases) {
        final r = SmashPollResult(votes: votes, totalVotes: total);
        expect(r.ratio, closeTo(ratio, 1e-9), reason: '$votes/$total');
        expect(r.percent, percent, reason: '$votes/$total');
      }
    });

    test('득표 수가 전체보다 크거나 음수이면 assert', () {
      expect(
        () => SmashPollResult(votes: 3, totalVotes: 2),
        throwsAssertionError,
      );
      expect(
        () => SmashPollResult(votes: -1, totalVotes: 2),
        throwsAssertionError,
      );
    });
  });

  group('투표 전', () {
    testWidgets('이름과 빈 동그라미가 보이고 결과는 없다. 높이는 56 이상이다', (tester) async {
      await pump(tester, row(onSelect: () {}));
      expect(textIn(_name), findsOneWidget);
      expect(iconIn(Icons.radio_button_unchecked), findsOneWidget);
      expect(iconIn(Icons.check_circle), findsNothing);
      expect(
        find.descendant(of: rowFinder(), matching: find.textContaining('%')),
        findsNothing,
      );
      expect(
        find.descendant(of: rowFinder(), matching: find.textContaining('명')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('pollBar')), findsNothing);
      expect(tester.getSize(rowFinder()).height, greaterThanOrEqualTo(56));
    });

    testWidgets('줄 어디를 눌러도 onSelect가 불린다 (가운데, 네 모서리 안쪽)', (tester) async {
      var taps = 0;
      await pump(tester, row(onSelect: () => taps++));
      final rect = tester.getRect(rowFinder());
      for (final p in [
        rect.center,
        rect.topLeft + const Offset(6, 6),
        rect.topRight + const Offset(-6, 6),
        rect.bottomLeft + const Offset(6, -6),
        rect.bottomRight + const Offset(-6, -6),
      ]) {
        await tester.tapAt(p);
      }
      expect(taps, 5);
    });

    testWidgets('빈 동그라미는 결과 막대 위에서도 보이는 색(보조 글자색)이다', (tester) async {
      await pump(tester, row(onSelect: () {}));
      expect(
        tester.widget<Icon>(iconIn(Icons.radio_button_unchecked)).color,
        SmashColors.textSecondary,
      );
    });

    testWidgets('onSelect가 없고 결과도 없으면 누를 수 없고 빈 동그라미도 없다', (tester) async {
      await pump(tester, row());
      expect(iconIn(Icons.radio_button_unchecked), findsNothing);
      expect(
        find.descendant(of: rowFinder(), matching: find.byType(SmashPressable)),
        findsNothing,
      );
    });

    testWidgets('눌린 모양: 배경이 연한 브랜드 색으로 바뀐다', (tester) async {
      Color background() => tester
          .widgetList<Container>(
            find.descendant(of: rowFinder(), matching: find.byType(Container)),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .first
          .color!;
      await pump(tester, row(onSelect: () {}));
      expect(background(), SmashColors.surface);
      await pump(tester, SmashForcePressed(child: row(onSelect: () {})));
      expect(background(), SmashColors.brandTintSoft);
    });
  });

  group('결과', () {
    testWidgets('비율, 득표 수, 막대: 6/10 → "60%", "6명", 막대 폭 = 줄 폭의 60%', (
      tester,
    ) async {
      await pump(tester, row(result: result6of10), width: 320);
      expect(textIn('60%'), findsOneWidget);
      expect(textIn('6명'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('pollBar'))).width,
        closeTo(320 * 0.6, 0.01),
      );
    });

    testWidgets('막대 폭은 반올림하지 않은 비율이다 (1/3 → 33.33%, 1/8 → 12.5%)', (
      tester,
    ) async {
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 1, totalVotes: 3)),
        width: 320,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('pollBar'))).width,
        closeTo(320 / 3, 0.01),
      );
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 1, totalVotes: 8)),
        width: 320,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('pollBar'))).width,
        closeTo(40, 0.01),
      );
    });

    testWidgets('0표이면 막대가 없고 "0%", "0명"이다. 전체가 0표여도 같다', (tester) async {
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 0, totalVotes: 8)),
      );
      expect(find.byKey(const ValueKey('pollBar')), findsNothing);
      expect(textIn('0%'), findsOneWidget);
      expect(textIn('0명'), findsOneWidget);
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 0, totalVotes: 0)),
      );
      expect(textIn('0%'), findsOneWidget);
    });

    testWidgets('100%이면 막대가 줄 전체다', (tester) async {
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 8, totalVotes: 8)),
        width: 320,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('pollBar'))).width,
        closeTo(320, 0.01),
      );
    });

    testWidgets(
      '내 선택: 체크 아이콘, 굵은 글자, 브랜드 색 글자, 브랜드 막대 색이다. 다른 선택지는 보통 굵기와 중립 막대다',
      (tester) async {
        await pump(tester, row(isMine: true, result: result6of10));
        expect(iconIn(Icons.check_circle), findsOneWidget);
        var style = tester
            .widget<Text>(
              find.descendant(of: rowFinder(), matching: find.text(_name)),
            )
            .style!;
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, SmashColors.brand);
        expect(
          tester
              .widget<ColoredBox>(find.byKey(const ValueKey('pollBar')))
              .color,
          SmashColors.brandTint,
        );

        await pump(tester, row(result: result6of10));
        expect(iconIn(Icons.check_circle), findsNothing);
        style = tester
            .widget<Text>(
              find.descendant(of: rowFinder(), matching: find.text(_name)),
            )
            .style!;
        expect(style.fontWeight, FontWeight.w400);
        expect(style.color, SmashColors.text);
        expect(
          tester
              .widget<ColoredBox>(find.byKey(const ValueKey('pollBar')))
              .color,
          SmashColors.fillDisabled,
        );
      },
    );

    testWidgets('기명 투표: 투표한 사람이 이름 아래에 보이고, 익명(빈 목록)이면 없다', (tester) async {
      await pump(
        tester,
        row(
          result: const SmashPollResult(
            votes: 3,
            totalVotes: 8,
            voters: ['김하늘', '이도윤', '박서준'],
          ),
        ),
      );
      expect(textIn('김하늘, 이도윤, 박서준'), findsOneWidget);
      await pump(
        tester,
        row(result: const SmashPollResult(votes: 3, totalVotes: 8)),
      );
      expect(
        find.descendant(of: rowFinder(), matching: find.textContaining('김하늘')),
        findsNothing,
      );
    });

    testWidgets('마감 후(결과만, 누를 수 없음)에는 빈 동그라미가 없고 눌러도 아무 일도 없다', (tester) async {
      await pump(tester, row(result: result6of10));
      expect(iconIn(Icons.radio_button_unchecked), findsNothing);
      await tester.tap(rowFinder(), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });

    testWidgets('내 선택이면서 다시 고를 수 있으면(onSelect) 체크가 보이고 빈 동그라미는 없다', (
      tester,
    ) async {
      await pump(
        tester,
        row(isMine: true, result: result6of10, onSelect: () {}),
      );
      expect(iconIn(Icons.check_circle), findsOneWidget);
      expect(iconIn(Icons.radio_button_unchecked), findsNothing);
    });
  });

  group('테두리와 간격', () {
    testWidgets('테두리: 내 선택은 브랜드 색 2, 선택 가능은 조작 요소 테두리색 1, 누를 수 없는 줄은 장식선 색 1', (
      tester,
    ) async {
      await pump(tester, row(isMine: true, result: result6of10));
      expect(border(tester).top.width, 2);
      expect(border(tester).top.color, SmashColors.brand);
      await pump(tester, row(onSelect: () {}));
      expect(border(tester).top.width, 1);
      expect(border(tester).top.color, SmashColors.border);
      await pump(tester, row(result: result6of10));
      expect(border(tester).top.width, 1);
      expect(border(tester).top.color, SmashColors.line);
    });

    testWidgets('키보드 포커스가 오면 브랜드 색 굵은 테두리가 보인다', (tester) async {
      await pump(tester, row(onSelect: () {}));
      expect(border(tester).top.color, SmashColors.border);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(border(tester).top.width, 2);
      expect(border(tester).top.color, SmashColors.brand);
    });

    testWidgets('이름은 줄 왼쪽에서 여백 18(16 + 테두리 자리 2) + 아이콘 자리 20 + 간격 8만큼 떨어져 있다', (
      tester,
    ) async {
      await pump(tester, row(onSelect: () {}));
      final left =
          tester
              .getTopLeft(
                find.descendant(of: rowFinder(), matching: find.text(_name)),
              )
              .dx -
          tester.getTopLeft(rowFinder()).dx;
      expect(left, 18 + 20 + 8);
      expect(tester.getSize(iconIn(Icons.radio_button_unchecked)).width, 20);
    });
  });

  group('처리 중', () {
    testWidgets('아이콘 자리에 진행 표시가 보이고 누름이 무시된다', (tester) async {
      var taps = 0;
      await pump(tester, row(onSelect: () => taps++, isLoading: true));
      expect(
        find.descendant(
          of: rowFinder(),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(iconIn(Icons.radio_button_unchecked), findsNothing);
      await tester.tap(rowFinder());
      expect(taps, 0);
    });

    testWidgets('상태가 바뀌어도 줄 크기와 이름 위치가 그대로다 (투표 전 → 처리 중 → 내 선택 → 결과)', (
      tester,
    ) async {
      final states = <(String, Widget)>[
        ('선택 가능', row(onSelect: () {})),
        ('처리 중', row(onSelect: () {}, isLoading: true)),
        ('내 선택', row(isMine: true)),
        ('결과 없음, 선택 불가', row()),
      ];
      Rect? first;
      double? firstLeft;
      for (final (name, widget) in states) {
        await pump(tester, widget);
        final rect = tester.getRect(rowFinder());
        final left = tester
            .getTopLeft(
              find.descendant(of: rowFinder(), matching: find.text(_name)),
            )
            .dx;
        first ??= rect;
        firstLeft ??= left;
        expect(rect, first, reason: name);
        expect(left, firstLeft, reason: '이름 위치: $name');
      }
    });

    testWidgets(
      'onSelect가 없어도 처리 중이면 눌림 영역과 읽는 말이 있고 누름은 무시된다 (보내는 중에 다른 선택지를 막는 경우)',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, row(isLoading: true));
        expect(
          find.descendant(
            of: rowFinder(),
            matching: find.byType(SmashPressable),
          ),
          findsOneWidget,
        );
        expect(hasLabel(tester, '$_name, 처리 중'), isTrue);
        await tester.tap(rowFinder());
        expect(tester.takeException(), isNull);
        handle.dispose();
      },
    );

    testWidgets('읽는 말에 "처리 중"이 붙는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, row(onSelect: () {}, isLoading: true));
      expect(hasLabel(tester, '$_name, 처리 중'), isTrue);
      handle.dispose();
    });
  });

  group('색 대비', () {
    test('글자와 아이콘이 막대와 배경 위에서 읽힌다 (일반 글자 4.5:1, 아이콘 3:1)', () {
      final backgrounds = {
        '배경': SmashColors.surface,
        '내 막대': SmashColors.brandTint,
        '다른 막대': SmashColors.fillDisabled,
        '눌림': SmashColors.brandTintSoft,
      };
      for (final entry in backgrounds.entries) {
        expect(
          contrastRatio(SmashColors.text, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: '본문 ${entry.key}',
        );
        expect(
          contrastRatio(SmashColors.textSecondary, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: '보조 글자 ${entry.key}',
        );
        expect(
          contrastRatio(SmashColors.brand, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: '브랜드 글자 ${entry.key}',
        );
        expect(
          contrastRatio(SmashColors.textSecondary, entry.value),
          greaterThanOrEqualTo(3.0),
          reason: '빈 동그라미 ${entry.key}',
        );
      }
    });
  });

  group('폭이 좁으면 결과가 이름 아래로 내려간다', () {
    const label = '목요일 저녁 7시 정기 활동';
    const voters = SmashPollResult(votes: 6, totalVotes: 10);

    /// 실제로 그려진 글자에서 필요한 폭을 구한다: 아이콘 자리(28) + 이름의 가장 긴 낱말 + 간격 16 + 결과 열 + 좌우 여백 (16 + 2) × 2
    double boundary(WidgetTester tester) {
      final labelBox = tester.renderObject<RenderBox>(
        find.descendant(of: rowFinder(), matching: find.text(label)),
      );
      final percent = tester
          .getSize(find.descendant(of: rowFinder(), matching: find.text('60%')))
          .width;
      final count = tester
          .getSize(find.descendant(of: rowFinder(), matching: find.text('6명')))
          .width;
      final resultColumn = percent > count ? percent : count;
      return 28 +
          labelBox.getMinIntrinsicWidth(double.infinity) +
          16 +
          resultColumn +
          2 * (16 + 2);
    }

    bool stacked(WidgetTester tester) =>
        tester
            .getTopLeft(
              find.descendant(of: rowFinder(), matching: find.text('60%')),
            )
            .dy >=
        tester
                .getRect(
                  find.descendant(of: rowFinder(), matching: find.text(label)),
                )
                .bottom -
            0.5;

    testWidgets('경계: 필요한 폭이면 오른쪽 열, 1px 모자라면 이름 아래로 내려간다', (tester) async {
      await pump(tester, row(label: label, result: voters), width: 400);
      final w = boundary(tester);
      expect(stacked(tester), isFalse, reason: '넓으면 오른쪽');
      await pump(
        tester,
        row(label: label, result: voters),
        width: w,
      );
      expect(stacked(tester), isFalse, reason: '정확히 들어간다');
      await pump(
        tester,
        row(label: label, result: voters),
        width: w - 1,
      );
      expect(stacked(tester), isTrue, reason: '1px 모자란다');
    });

    testWidgets('득표 수가 비율보다 넓어도(1% / 1000명) 같은 경계로 전환한다', (tester) async {
      const wideCount = SmashPollResult(votes: 1000, totalVotes: 100000);
      double widest(WidgetTester t) {
        final p = t
            .getSize(
              find.descendant(of: rowFinder(), matching: find.text('1%')),
            )
            .width;
        final c = t
            .getSize(
              find.descendant(of: rowFinder(), matching: find.text('1000명')),
            )
            .width;
        return c > p ? c : p;
      }

      await pump(tester, row(label: label, result: wideCount), width: 500);
      final labelBox = tester.renderObject<RenderBox>(
        find.descendant(of: rowFinder(), matching: find.text(label)),
      );
      final w =
          28 +
          labelBox.getMinIntrinsicWidth(double.infinity) +
          16 +
          widest(tester) +
          2 * (16 + 2);
      expect(
        tester
            .getSize(
              find.descendant(of: rowFinder(), matching: find.text('1000명')),
            )
            .width,
        greaterThan(
          tester
              .getSize(
                find.descendant(of: rowFinder(), matching: find.text('1%')),
              )
              .width,
        ),
      );
      bool stackedNow() =>
          tester
              .getTopLeft(
                find.descendant(of: rowFinder(), matching: find.text('1%')),
              )
              .dy >=
          tester
                  .getRect(
                    find.descendant(
                      of: rowFinder(),
                      matching: find.text(label),
                    ),
                  )
                  .bottom -
              0.5;
      await pump(
        tester,
        row(label: label, result: wideCount),
        width: w,
      );
      expect(stackedNow(), isFalse, reason: '정확히 들어간다');
      await pump(
        tester,
        row(label: label, result: wideCount),
        width: w - 1,
      );
      expect(stackedNow(), isTrue, reason: '1px 모자란다 (득표 수 열 기준)');
    });

    testWidgets('내려가도 비율과 득표 수가 모두 보이고 막대와 내 선택 표시도 그대로다', (tester) async {
      await pump(
        tester,
        row(label: label, result: voters, isMine: true),
        width: 200,
        scale: 2.0,
      );
      expect(textIn('60%'), findsOneWidget);
      expect(textIn('6명'), findsOneWidget);
      expect(find.byKey(const ValueKey('pollBar')), findsOneWidget);
      expect(iconIn(Icons.check_circle), findsOneWidget);
      expect(stacked(tester), isTrue);
    });

    testWidgets('폭을 1px씩 줄여도 전환 지점은 한 번뿐이다 (가로 → 아래로, 다시 가로로 돌아오지 않는다)', (
      tester,
    ) async {
      var switches = 0;
      bool? previous;
      for (var w = 420.0; w >= 150; w -= 1) {
        await pump(
          tester,
          row(label: label, result: voters),
          width: w,
        );
        final now = stacked(tester);
        if (previous != null && now != previous) switches++;
        previous = now;
        expect(tester.takeException(), isNull, reason: '폭 $w');
      }
      expect(switches, 1);
    });
  });

  group('폭 × 글자 크기 행렬 (실제 Pretendard)', () {
    final cases = <String, Widget Function()>{
      '투표 전, 긴 이름': () => row(
        label: '정규 활동을 목요일 저녁 7시에서 토요일 오전 10시로 옮기는 것에 찬성해요',
        onSelect: () {},
      ),
      '결과, 내 선택': () => row(
        isMine: true,
        result: const SmashPollResult(votes: 6, totalVotes: 10),
      ),
      '결과, 기명': () => row(
        result: const SmashPollResult(
          votes: 3,
          totalVotes: 8,
          voters: ['김하늘', '이도윤', '박서준', '최민서', '정다은'],
        ),
      ),
      '결과, 긴 이름과 기명, 내 선택': () => row(
        label: '정규참여신청서제출',
        isMine: true,
        result: const SmashPollResult(
          votes: 12,
          totalVotes: 40,
          voters: ['김하늘', '이도윤', '박서준', '최민서', '정다은', '한유진'],
        ),
      ),
      '처리 중': () => row(isLoading: true, onSelect: () {}),
    };
    for (final entry in cases.entries) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
            '${entry.key}, 폭 $width, 글자 $scale배: 낱말 중간 끊김 0, 넘침 0, 높이 56 이상, 틀 안',
            (tester) async {
              await pump(
                tester,
                entry.value(),
                width: width - 32,
                scale: scale,
              );
              expect(tester.takeException(), isNull);
              final rect = tester.getRect(rowFinder());
              expect(rect.height, greaterThanOrEqualTo(56));
              expect(rect.width, width - 32);
              for (final element
                  in find
                      .descendant(of: rowFinder(), matching: find.byType(Text))
                      .evaluate()) {
                final text = (element.widget as Text).data!;
                expect(
                  midWordBreaks(tester, find.byWidget(element.widget)),
                  0,
                  reason: '낱말 중간 끊김: $text',
                );
                final box = tester.getRect(find.byWidget(element.widget));
                expect(
                  box.left,
                  greaterThanOrEqualTo(rect.left - 0.001),
                  reason: text,
                );
                expect(
                  box.right,
                  lessThanOrEqualTo(rect.right + 0.001),
                  reason: text,
                );
              }
            },
          );
        }
      }
    }
  });

  group('스크린리더', () {
    Future<SemanticsData> read(
      WidgetTester tester,
      Widget child,
      String startsWith,
    ) async {
      await pump(tester, child);
      return semanticsNode(
        tester,
        (d) => d.label.startsWith(startsWith),
      )!.getSemanticsData();
    }

    testWidgets('읽는 말: 이름, 내가 투표함, N명, 퍼센트, 투표한 사람 순서다', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        (await read(
          tester,
          row(
            isMine: true,
            result: const SmashPollResult(
              votes: 3,
              totalVotes: 8,
              voters: ['김하늘', '이도윤'],
            ),
          ),
          _name,
        )).label,
        '$_name, 내가 투표함, 3명, 38%, 투표한 사람 김하늘, 이도윤',
      );
      expect(
        (await read(tester, row(result: result6of10), _name)).label,
        '$_name, 6명, 60%',
      );
      expect((await read(tester, row(onSelect: () {}), _name)).label, _name);
      expect(
        (await read(tester, row(isMine: true), _name)).label,
        '$_name, 내가 투표함',
      );
      handle.dispose();
    });

    testWidgets('눌러서 고를 수 있으면 버튼이고, 선택 상태는 내 선택에만 있다', (tester) async {
      final handle = tester.ensureSemantics();
      var data = await read(tester, row(onSelect: () {}), _name);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isFalse);
      data = await read(tester, row(isMine: true, onSelect: () {}), _name);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      data = await read(tester, row(result: result6of10), _name);
      expect(data.flagsCollection.isButton, isFalse, reason: '마감 후에는 버튼이 아니다');
      handle.dispose();
    });

    testWidgets('스크린리더의 탭 동작으로 고를 수 있고, 처리 중에는 무시된다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pump(tester, row(onSelect: () => taps++));
      semanticsOwner(tester).performAction(
        semanticsNode(tester, (d) => d.label == _name)!.id,
        SemanticsAction.tap,
      );
      expect(taps, 1);
      await pump(tester, row(onSelect: () => taps++, isLoading: true));
      semanticsOwner(tester).performAction(
        semanticsNode(tester, (d) => d.label == '$_name, 처리 중')!.id,
        SemanticsAction.tap,
      );
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('아이콘과 퍼센트 글자가 따로 읽히지 않는다 (한 노드로 읽는다)', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        row(isMine: true, result: result6of10, onSelect: () {}),
      );
      final labels = <String>[];
      void walk(SemanticsNode node) {
        final label = node.getSemanticsData().label;
        if (label.isNotEmpty) labels.add(label);
        node.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      walk(semanticsOwner(tester).rootSemanticsNode!);
      expect(labels.where((l) => l.contains('60%')).length, 1);
      expect(labels.where((l) => l == '60%' || l == '6명'), isEmpty);
      handle.dispose();
    });
  });

  group('목록 안에서', () {
    testWidgets('세로 목록의 여러 항목으로 쓰고 폭을 모두 채운다 (Column, stretch)', (
      tester,
    ) async {
      await pump(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 3; i++)
              row(
                label: '선택지 ${i + 1}',
                result: SmashPollResult(votes: i, totalVotes: 3),
              ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SmashPollOptionRow), findsNWidgets(3));
      for (final e in find.byType(SmashPollOptionRow).evaluate()) {
        expect(tester.getSize(find.byWidget(e.widget)).width, 360);
      }
    });
  });
}
