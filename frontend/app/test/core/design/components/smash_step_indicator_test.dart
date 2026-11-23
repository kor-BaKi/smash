import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/pixels.dart';
import '../../../support/pump.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const _signup = ['약관 동의', '이름 입력', '비밀번호'];
const _five = ['약관', '이름', '연락처', '조 선택', '비밀번호'];
const _long = ['개인정보 처리방침 동의', '이름과 연락처 입력', '비밀번호 설정'];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  Future<void> pump(
    WidgetTester tester,
    List<String> steps,
    int current, {
    double width = 360,
    double scale = 1.0,
  }) => tester.pumpWidget(
    smashHarness(
      SmashStepIndicator(steps: steps, current: current),
      width: width,
      textScale: scale,
    ),
  );

  Finder indicator() => find.byType(SmashStepIndicator);
  Finder marker(int i) => find.byKey(ValueKey('step-marker-$i'));
  Rect markerRect(WidgetTester tester, int i) => tester.getRect(marker(i));
  Finder numberIn(int i) =>
      find.descendant(of: marker(i), matching: find.text('${i + 1}'));
  Finder checkIn(int i) =>
      find.descendant(of: marker(i), matching: find.byIcon(Icons.check));
  BoxDecoration decorationOf(WidgetTester tester, int i) =>
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: marker(i),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;
  Color lineColor(WidgetTester tester, String key) =>
      tester.widget<Container>(find.byKey(ValueKey(key))).color!;

  /// 가로 배치인지: 모든 동그라미가 같은 높이에 있다
  bool isHorizontal(WidgetTester tester, int count) {
    final top = markerRect(tester, 0).top;
    return [
      for (var i = 0; i < count; i++) markerRect(tester, i).top,
    ].every((t) => (t - top).abs() < 0.5);
  }

  group('색에만 의존하지 않는 구분', () {
    for (var n = 2; n <= 5; n++) {
      for (var current = 0; current < n; current++) {
        testWidgets(
          '$n단계 중 ${current + 1}단계: 완료는 체크, 현재는 채운 동그라미+숫자, 남은 단계는 빈 동그라미+숫자',
          (tester) async {
            final steps = ['가', '나', '다', '라', '마'].sublist(0, n);
            await pump(tester, steps, current, width: 800);
            expect(
              find.byWidgetPredicate(
                (w) =>
                    w is SizedBox &&
                    w.key is ValueKey &&
                    (w.key! as ValueKey).value.toString().startsWith(
                      'step-marker-',
                    ),
              ),
              findsNWidgets(n),
            );
            for (var i = 0; i < n; i++) {
              final d = decorationOf(tester, i);
              expect(d.shape, BoxShape.circle);
              if (i < current) {
                expect(checkIn(i), findsOneWidget, reason: '완료 $i: 체크');
                expect(numberIn(i), findsNothing, reason: '완료 $i: 숫자 없음');
                expect(d.border, isNotNull, reason: '완료는 굵은 테두리');
                expect(d.color, SmashColors.brandTint);
              } else if (i == current) {
                expect(checkIn(i), findsNothing);
                expect(numberIn(i), findsOneWidget, reason: '현재: 숫자');
                expect(d.border, isNull, reason: '현재는 채운 동그라미 (테두리 없음)');
                expect(d.color, SmashColors.brand);
              } else {
                expect(checkIn(i), findsNothing);
                expect(numberIn(i), findsOneWidget, reason: '남은 단계: 숫자');
                expect(d.border, isNotNull, reason: '남은 단계는 빈 동그라미 (테두리)');
                expect(d.color, SmashColors.surface);
              }
            }
          },
        );
      }
    }

    testWidgets('세 상태의 모양 서명(체크, 숫자, 테두리)이 서로 모두 다르다 (색이 없어도 구분된다)', (
      tester,
    ) async {
      await pump(tester, _signup, 1, width: 800);
      String signature(int i) =>
          '${checkIn(i).evaluate().isNotEmpty}|${numberIn(i).evaluate().isNotEmpty}|${decorationOf(tester, i).border != null}';
      expect({signature(0), signature(1), signature(2)}.length, 3);
    });

    testWidgets('단계 사이 선: 완료한 구간만 브랜드 색이고, 처음과 끝의 바깥쪽 선은 보이지 않는다', (
      tester,
    ) async {
      await pump(tester, _signup, 1, width: 800);
      expect(
        lineColor(tester, 'step-line-0-start'),
        Colors.transparent,
        reason: '처음 바깥',
      );
      expect(
        lineColor(tester, 'step-line-0-end'),
        SmashColors.brand,
        reason: '1→2 구간: 1단계 완료',
      );
      expect(lineColor(tester, 'step-line-1-start'), SmashColors.brand);
      expect(
        lineColor(tester, 'step-line-1-end'),
        SmashColors.line,
        reason: '2→3 구간: 아직',
      );
      expect(lineColor(tester, 'step-line-2-start'), SmashColors.line);
      expect(
        lineColor(tester, 'step-line-2-end'),
        Colors.transparent,
        reason: '끝 바깥',
      );
    });

    testWidgets('이름 글자색: 남은 단계만 보조색이고 굵기는 모두 같다 (크기가 변하지 않게)', (tester) async {
      await pump(tester, _signup, 1, width: 800);
      TextStyle style(String s) => tester
          .widget<Text>(
            find.descendant(of: indicator(), matching: find.text(s)),
          )
          .style!;
      expect(style('약관 동의').color, SmashColors.text);
      expect(style('이름 입력').color, SmashColors.text);
      expect(style('비밀번호').color, SmashColors.textSecondary);
      expect(
        {
          style('약관 동의').fontWeight,
          style('이름 입력').fontWeight,
          style('비밀번호').fontWeight,
        }.length,
        1,
      );
    });

    testWidgets(
      '그려진 색: 현재 동그라미는 브랜드 색, 완료는 연한 브랜드 색 + 브랜드 테두리, 남은 단계는 흰색 + 테두리 (픽셀)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: screenshotBoundary(
                  const ValueKey('shot'),
                  SizedBox(
                    width: 360,
                    child: SmashStepIndicator(steps: _signup, current: 1),
                  ),
                ),
              ),
            ),
          ),
        );
        final pixel = await readPixels(tester, const ValueKey('shot'));
        final origin = tester.getTopLeft(find.byKey(const ValueKey('shot')));
        Color at(int i, double dx) {
          final r = markerRect(tester, i);
          return pixel(
            (r.left - origin.dx + dx).round(),
            (r.center.dy - origin.dy).round(),
          );
        }

        expect(
          colorDistance(at(1, 6), SmashColors.brand),
          0,
          reason: '현재: 채운 동그라미 안쪽',
        );
        expect(
          colorDistance(at(0, 6), SmashColors.brandTint),
          0,
          reason: '완료: 연한 안쪽',
        );
        expect(
          colorDistance(at(0, 1), SmashColors.brand),
          0,
          reason: '완료: 브랜드 테두리',
        );
        expect(
          colorDistance(at(2, 6), SmashColors.surface),
          0,
          reason: '남은 단계: 흰 안쪽',
        );
        expect(
          colorDistance(at(2, 1), SmashColors.border),
          0,
          reason: '남은 단계: 테두리',
        );
      },
    );
  });

  group('색 대비', () {
    test('숫자, 체크, 이름이 배경 위에서 읽힌다 (글자 4.5:1, 아이콘과 테두리 3:1)', () {
      expect(
        contrastRatio(SmashColors.onBrand, SmashColors.brand),
        greaterThanOrEqualTo(4.5),
        reason: '현재 숫자',
      );
      expect(
        contrastRatio(SmashColors.textSecondary, SmashColors.surface),
        greaterThanOrEqualTo(4.5),
        reason: '남은 숫자와 이름',
      );
      expect(
        contrastRatio(SmashColors.text, SmashColors.surface),
        greaterThanOrEqualTo(4.5),
        reason: '이름',
      );
      expect(
        contrastRatio(SmashColors.brand, SmashColors.brandTint),
        greaterThanOrEqualTo(3.0),
        reason: '완료 체크',
      );
      expect(
        contrastRatio(SmashColors.brand, SmashColors.surface),
        greaterThanOrEqualTo(3.0),
        reason: '완료 테두리',
      );
      expect(
        contrastRatio(SmashColors.border, SmashColors.surface),
        greaterThanOrEqualTo(3.0),
        reason: '남은 단계 테두리',
      );
    });
  });

  group('스크린리더', () {
    final cases = {
      (_signup, 0): '3단계 중 1단계, 약관 동의',
      (_signup, 1): '3단계 중 2단계, 이름 입력, 1단계 약관 동의 완료',
      (_signup, 2): '3단계 중 3단계, 비밀번호, 1단계 약관 동의 완료, 2단계 이름 입력 완료',
      (_five, 3): '5단계 중 4단계, 조 선택, 1단계 약관 완료, 2단계 이름 완료, 3단계 연락처 완료',
    };
    for (final entry in cases.entries) {
      testWidgets(
        '${entry.key.$1.length}단계 중 ${entry.key.$2 + 1}단계 → "${entry.value}"',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pump(tester, entry.key.$1, entry.key.$2);
          final node = semanticsNode(tester, (d) => d.label.contains('단계 중'))!;
          expect(node.getSemanticsData().label, entry.value);
          handle.dispose();
        },
      );
    }

    testWidgets('한 노드로 읽는다: 숫자, 이름, 체크가 따로 읽히지 않고, 누르는 요소가 아니다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, _signup, 1);
      final labels = <String>[];
      var buttons = 0;
      void walk(SemanticsNode node) {
        final d = node.getSemanticsData();
        if (d.label.isNotEmpty) labels.add(d.label);
        if (d.flagsCollection.isButton) buttons++;
        node.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      walk(semanticsOwner(tester).rootSemanticsNode!);
      expect(labels.where((l) => l.contains('단계')).length, 1);
      for (final text in ['1', '2', '3', '약관 동의', '이름 입력', '비밀번호']) {
        expect(labels.contains(text), isFalse, reason: '"$text"가 따로 읽힌다');
      }
      expect(buttons, 0);
      handle.dispose();
    });

    testWidgets('세로 배치에서도 같은 읽는 말이다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, _signup, 1, width: 120, scale: 2.0);
      expect(
        semanticsNode(
          tester,
          (d) => d.label.contains('단계 중'),
        )!.getSemanticsData().label,
        '3단계 중 2단계, 이름 입력, 1단계 약관 동의 완료',
      );
      handle.dispose();
    });
  });

  group('가로 ↔ 세로 전환', () {
    /// 실제로 그려진 이름의 가장 긴 낱말 폭
    double longestWord(WidgetTester tester, List<String> steps) {
      var widest = 0.0;
      for (final s in steps) {
        final box = tester.renderObject<RenderBox>(
          find.descendant(of: indicator(), matching: find.text(s)),
        );
        widest = widest > box.getMinIntrinsicWidth(double.infinity)
            ? widest
            : box.getMinIntrinsicWidth(double.infinity);
      }
      return widest;
    }

    for (final steps in [_signup, _five, _long]) {
      testWidgets(
        '${steps.length}단계 ${steps.first}…: 칸이 가장 긴 낱말 + 좌우 여백 4에 맞으면 가로, 1px 모자라면 세로',
        (tester) async {
          await pump(tester, steps, 0, width: 1000);
          expect(isHorizontal(tester, steps.length), isTrue);
          final need = longestWord(tester, steps);
          final boundary = steps.length * (need + 8);
          await pump(tester, steps, 0, width: boundary);
          expect(
            isHorizontal(tester, steps.length),
            isTrue,
            reason: '정확히 들어간다',
          );
          await pump(tester, steps, 0, width: boundary - 1);
          expect(
            isHorizontal(tester, steps.length),
            isFalse,
            reason: '1px 모자란다 → 세로',
          );
        },
      );
    }

    testWidgets('가로/세로 판단은 어느 단계가 현재인지와 무관하다 (경계 폭에서 모든 단계가 같은 배치)', (
      tester,
    ) async {
      await pump(tester, _long, 0, width: 1000);
      final boundary = _long.length * (longestWord(tester, _long) + 8);
      for (final width in [boundary, boundary - 1]) {
        final results = <bool>[];
        for (var current = 0; current < _long.length; current++) {
          await pump(tester, _long, current, width: width);
          results.add(isHorizontal(tester, _long.length));
        }
        expect(results.toSet().length, 1, reason: '폭 $width: $results');
      }
    });

    testWidgets('세로 배치: 동그라미가 같은 왼쪽에서 위에서 아래로 쌓이고, 사이를 선이 빈틈없이 잇는다', (
      tester,
    ) async {
      await pump(tester, _signup, 1, width: 120, scale: 2.0);
      expect(isHorizontal(tester, 3), isFalse);
      final rects = [for (var i = 0; i < 3; i++) markerRect(tester, i)];
      for (var i = 1; i < 3; i++) {
        expect(rects[i].left, rects[0].left, reason: '같은 왼쪽');
        expect(rects[i].top, greaterThan(rects[i - 1].top));
      }
      for (var i = 0; i < 2; i++) {
        final line = tester.getRect(find.byKey(ValueKey('step-line-$i-down')));
        expect(
          line.top,
          closeTo(rects[i].bottom, 0.5),
          reason: '$i번 선이 동그라미 아래에서 시작',
        );
        expect(
          line.bottom,
          closeTo(rects[i + 1].top, 0.5),
          reason: '$i번 선이 다음 동그라미 위에서 끝남',
        );
      }
      expect(
        tester
            .widget<Container>(find.byKey(const ValueKey('step-line-0-down')))
            .color,
        SmashColors.brand,
        reason: '완료 구간',
      );
      expect(
        tester
            .widget<Container>(find.byKey(const ValueKey('step-line-1-down')))
            .color,
        SmashColors.line,
        reason: '아직 구간',
      );
      expect(
        find.byKey(const ValueKey('step-line-2-down')),
        findsNothing,
        reason: '마지막 아래에는 선이 없다',
      );
    });

    testWidgets(
      '세로 배치에서 이름은 동그라미 오른쪽에 있고, 한 줄 이름은 동그라미와 가운데 높이가 같다 (폭 200, 글자 2.0배)',
      (tester) async {
        await pump(tester, _signup, 0, width: 200, scale: 2.0);
        expect(isHorizontal(tester, 3), isFalse);
        for (var i = 0; i < 3; i++) {
          final label = tester.getRect(
            find.descendant(of: indicator(), matching: find.text(_signup[i])),
          );
          expect(
            label.left,
            greaterThan(markerRect(tester, i).right),
            reason: '이름이 동그라미 오른쪽',
          );
          expect(
            label.center.dy,
            closeTo(markerRect(tester, i).center.dy, 0.5),
            reason: '한 줄 이름은 동그라미와 가운데 높이가 같다',
          );
        }
      },
    );
  });

  group('크기와 배치 안정', () {
    for (final entry in {
      '가로(넓은 폭)': (_signup, 800.0, 1.0),
      '세로(좁은 폭)': (_long, 200.0, 1.3),
      '5단계': (_five, 360.0, 1.0),
    }.entries) {
      testWidgets('${entry.key}: 현재 단계가 바뀌어도 전체 크기와 모든 동그라미 위치가 같다', (
        tester,
      ) async {
        final (steps, width, scale) = entry.value;
        Size? size;
        List<Rect>? rects;
        for (var current = 0; current < steps.length; current++) {
          await pump(tester, steps, current, width: width, scale: scale);
          final nowSize = tester.getSize(indicator());
          final nowRects = [
            for (var i = 0; i < steps.length; i++) markerRect(tester, i),
          ];
          size ??= nowSize;
          rects ??= nowRects;
          expect(nowSize, size, reason: '현재 $current');
          expect(nowRects, rects, reason: '현재 $current');
        }
      });
    }

    testWidgets('동그라미 크기: 글자 1.0배 28, 1.3배 36.4, 2.0배는 44에서 멈춘다', (
      tester,
    ) async {
      await pump(tester, _signup, 0, width: 800);
      expect(markerRect(tester, 0).size, const Size(28, 28));
      await pump(tester, _signup, 0, width: 800, scale: 1.3);
      expect(markerRect(tester, 0).width, closeTo(36.4, 0.01));
      await pump(tester, _signup, 0, width: 800, scale: 2.0);
      expect(markerRect(tester, 0).size, const Size(44, 44));
    });

    testWidgets('선 굵기 2이고 동그라미 가운데 높이에 놓인다', (tester) async {
      await pump(tester, _signup, 1, width: 800);
      final line = tester.getRect(
        find.byKey(const ValueKey('step-line-1-end')),
      );
      expect(line.height, 2);
      expect(line.center.dy, closeTo(markerRect(tester, 1).center.dy, 0.5));
    });
  });

  group('폭 × 글자 크기 행렬 (실제 Pretendard)', () {
    final sets = {
      '짧은 3단계': _signup,
      '5단계': _five,
      '긴 이름 3단계': _long,
      '2단계': ['정보 입력', '확인'],
    };
    for (final entry in sets.entries) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
            '${entry.key}, 폭 $width, 글자 $scale배: 낱말 중간 끊김 0, 넘침 0, 틀 안',
            (tester) async {
              final steps = entry.value;
              for (var current = 0; current < steps.length; current++) {
                await pump(
                  tester,
                  steps,
                  current,
                  width: width - 32,
                  scale: scale,
                );
                expect(tester.takeException(), isNull, reason: '현재 $current');
                final box = tester.getRect(indicator());
                expect(box.width, width - 32);
                final texts = find.descendant(
                  of: indicator(),
                  matching: find.byType(Text),
                );
                for (final element in texts.evaluate()) {
                  final text = (element.widget as Text).data!;
                  expect(
                    midWordBreaks(tester, find.byWidget(element.widget)),
                    0,
                    reason: '낱말 중간 끊김: $text',
                  );
                  final r = tester.getRect(find.byWidget(element.widget));
                  expect(
                    r.left,
                    greaterThanOrEqualTo(box.left - 0.01),
                    reason: text,
                  );
                  expect(
                    r.right,
                    lessThanOrEqualTo(box.right + 0.01),
                    reason: text,
                  );
                }
                for (var i = 0; i < steps.length; i++) {
                  final r = markerRect(tester, i);
                  expect(r.left, greaterThanOrEqualTo(box.left - 0.01));
                  expect(r.right, lessThanOrEqualTo(box.right + 0.01));
                  expect(r.width, greaterThanOrEqualTo(28 - 0.01));
                }
              }
            },
          );
        }
      }
    }
  });

  group('치수와 색 (정확한 값)', () {
    TextStyle numberStyle(WidgetTester tester, int i) =>
        tester.widget<Text>(numberIn(i)).style!;

    testWidgets('가로: 동그라미와 이름 사이 4, 이름은 동그라미 아래에 가운데 정렬', (tester) async {
      await pump(tester, _signup, 1, width: 800);
      for (var i = 0; i < 3; i++) {
        final label = tester.getRect(
          find.descendant(of: indicator(), matching: find.text(_signup[i])),
        );
        expect(
          label.top - markerRect(tester, i).bottom,
          4,
          reason: '동그라미와 이름 사이',
        );
        expect(
          label.center.dx,
          closeTo(markerRect(tester, i).center.dx, 0.5),
          reason: '이름이 동그라미 아래 가운데',
        );
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: indicator(),
                  matching: find.text(_signup[i]),
                ),
              )
              .textAlign,
          TextAlign.center,
          reason: '여러 줄이어도 가운데 정렬',
        );
      }
    });

    testWidgets('세로: 동그라미와 이름 사이 16, 단계 사이 간격 16, 마지막 단계 아래 여백 없음', (
      tester,
    ) async {
      await pump(tester, _signup, 1, width: 200, scale: 2.0);
      expect(isHorizontal(tester, 3), isFalse);
      final rects = [for (var i = 0; i < 3; i++) markerRect(tester, i)];
      for (var i = 0; i < 3; i++) {
        final label = tester.getRect(
          find.descendant(of: indicator(), matching: find.text(_signup[i])),
        );
        expect(label.left - rects[i].right, 16, reason: '동그라미와 이름 사이');
      }
      for (var i = 0; i < 2; i++) {
        final label = tester.getRect(
          find.descendant(of: indicator(), matching: find.text(_signup[i])),
        );
        // 한 줄 이름이고 동그라미(44)가 이름(36)보다 크다: 단계 높이 = 동그라미 + 간격 16
        expect(
          rects[i + 1].top - rects[i].top,
          rects[i].height + 16,
          reason: '$i번 단계 높이 = 동그라미 + 16',
        );
        expect(label.height, lessThanOrEqualTo(rects[i].height));
      }
      expect(
        tester.getRect(indicator()).bottom,
        closeTo(rects[2].bottom, 0.5),
        reason: '마지막 단계 아래에는 여백이 없다',
      );
    });

    testWidgets('체크 아이콘: 동그라미의 0.6배 크기, 브랜드 색', (tester) async {
      await pump(tester, _signup, 2, width: 800);
      final icon = tester.widget<Icon>(checkIn(0));
      expect(icon.color, SmashColors.brand);
      expect(icon.size, closeTo(28 * 0.6, 0.001));
      await pump(tester, _signup, 2, width: 800, scale: 2.0);
      expect(
        tester.widget<Icon>(checkIn(0)).size,
        closeTo(44 * 0.6, 0.001),
        reason: '동그라미를 따라 커진다',
      );
    });

    testWidgets('숫자 색: 현재는 브랜드 위 흰색, 남은 단계는 보조 글자색이고 모두 4.5:1 이상이다', (
      tester,
    ) async {
      await pump(tester, _signup, 1, width: 800);
      expect(numberStyle(tester, 1).color, SmashColors.onBrand);
      expect(numberStyle(tester, 2).color, SmashColors.textSecondary);
      expect(
        contrastRatio(
          numberStyle(tester, 1).color!,
          decorationOf(tester, 1).color!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(
          numberStyle(tester, 2).color!,
          decorationOf(tester, 2).color!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(numberStyle(tester, 1).fontWeight, FontWeight.w600);
    });

    testWidgets('남은 단계 테두리색은 조작 요소 테두리색이고 흰 배경 위 3:1 이상이다', (tester) async {
      await pump(tester, _signup, 0, width: 800);
      final border = decorationOf(tester, 2).border! as Border;
      expect(border.top.color, SmashColors.border);
      expect(border.top.width, 2);
      expect(
        contrastRatio(border.top.color, SmashColors.surface),
        greaterThanOrEqualTo(3.0),
      );
    });
  });

  group('잘못된 사용', () {
    test('단계가 1개나 6개이면 assert', () {
      expect(
        () => SmashStepIndicator(steps: const ['가'], current: 0),
        throwsAssertionError,
      );
      expect(
        () => SmashStepIndicator(
          steps: const ['가', '나', '다', '라', '마', '바'],
          current: 0,
        ),
        throwsAssertionError,
      );
    });

    test('current가 범위를 벗어나면 assert', () {
      expect(
        () => SmashStepIndicator(steps: const ['가', '나'], current: -1),
        throwsAssertionError,
      );
      expect(
        () => SmashStepIndicator(steps: const ['가', '나'], current: 2),
        throwsAssertionError,
      );
    });

    test('2~5개는 모두 만들어진다', () {
      for (var n = 2; n <= 5; n++) {
        expect(
          () => SmashStepIndicator(
            steps: ['가', '나', '다', '라', '마'].sublist(0, n),
            current: n - 1,
          ),
          returnsNormally,
        );
      }
    });
  });
}
