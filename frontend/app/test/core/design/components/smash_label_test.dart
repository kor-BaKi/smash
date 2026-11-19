import 'dart:ui' show Tristate;

import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/no_char_break.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/design/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const _wj = '⁠';

Widget host(Widget child, {double scale = 1.0, double? width}) => MaterialApp(
  theme: SmashTheme.light(),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: app!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: width == null ? child : SizedBox(width: width, child: child),
    ),
  ),
);

Finder anyText() => find.byWidgetPredicate((w) => w is Text);

RichText richOf(WidgetTester tester) => tester.widget<RichText>(
  find.descendant(of: anyText(), matching: find.byType(RichText)).first,
);

/// RichText가 그려질 때의 설정을 한 덩어리로 (두 위젯이 같은 설정으로 그려지는지 비교하려고)
Map<String, Object?> configOf(RichText r) => {
  'textAlign': r.textAlign,
  'textDirection': r.textDirection,
  'softWrap': r.softWrap,
  'overflow': r.overflow,
  'textScaler': r.textScaler.scale(10),
  'maxLines': r.maxLines,
  'locale': r.locale,
  'strutStyle': r.strutStyle,
  'textWidthBasis': r.textWidthBasis,
  'textHeightBehavior': r.textHeightBehavior,
  'selectionColor': r.selectionColor,
  'style': r.text.style,
};

String plainTextOf(WidgetTester tester) => richOf(tester).text.toPlainText();

int wjCount(String s) => _wj.allMatches(s).length;

void main() {
  group('noCharBreak: 한글과 이웃한 경계에만 WORD JOINER를 넣는다', () {
    test('한글 낱말은 글자 사이마다, 공백 옆에는 넣지 않는다', () {
      expect(noCharBreak('오전'), '오$_wj전');
      expect(noCharBreak('같이 가요'), '같$_wj이 가$_wj요');
      expect(noCharBreak('다른  조'), '다$_wj른  조');
      expect(noCharBreak(' 가 '), ' 가 ');
    });

    test('숫자와 영문만 있는 글자는 그대로이고 새 문자열도 만들지 않는다', () {
      for (final s in [
        '12',
        '120',
        '3:30',
        'ABC',
        'abc def',
        '2026-11-19',
        '(1)',
        '',
      ]) {
        expect(noCharBreak(s), s);
        expect(
          identical(noCharBreak(s), s),
          isTrue,
          reason: '"$s"는 같은 문자열 그대로',
        );
      }
    });

    test('숫자, 영문과 한글이 이웃한 경계에는 넣고, 숫자끼리·영문끼리는 넣지 않는다', () {
      expect(noCharBreak('12분'), '12$_wj분');
      expect(noCharBreak('3명'), '3$_wj명');
      expect(noCharBreak('A형'), 'A$_wj형');
      expect(noCharBreak('분12'), '분${_wj}12');
      expect(noCharBreak('11월 11일 (수)'), '11$_wj월 11$_wj일 ($_wj수$_wj)');
      expect(noCharBreak('AB형CD'), 'AB$_wj형${_wj}CD');
    });

    test('자모(호환 자모 포함)와 음절 범위의 양 끝도 한글로 본다 (영문과 이웃시켜 범위 경계를 검사)', () {
      // 같은 종류의 자모(초성+초성 등)는 한 글자(그래핌)로 합쳐지므로, 한글이 아닌 영문 옆에 놓아 경계가 생기게 한다
      const ends = {
        '음절 시작 가': '\uAC00',
        '음절 끝 힣': '\uD7A3',
        '자모 시작': '\u1100',
        '자모 끝': '\u11FF',
        '호환 자모 시작': '\u3130',
        '호환 자모 끝': '\u318F',
        '자모 확장 A 시작': '\uA960',
        '자모 확장 A 끝': '\uA97F',
        '자모 확장 B 시작': '\uD7B0',
        '자모 확장 B 끝': '\uD7FF',
      };
      for (final entry in ends.entries) {
        expect(
          noCharBreak('A${entry.value}'),
          'A$_wj${entry.value}',
          reason: entry.key,
        );
        expect(
          noCharBreak('${entry.value}A'),
          '${entry.value}${_wj}A',
          reason: entry.key,
        );
      }
      expect(noCharBreak('ㄱㄴ'), 'ㄱ$_wjㄴ', reason: '호환 자모 두 글자');
      expect(
        noCharBreak('\u1100\u1161\u1100\u1161'),
        '\u1100\u1161$_wj\u1100\u1161',
        reason: '자모 조합은 한 글자(그래핌) 단위',
      );
    });

    test('범위 바로 밖의 글자는 한글이 아니다 (영문 옆에 놓아도 WORD JOINER가 없다)', () {
      const outside = {
        'AC00 바로 앞': '\uABFF',
        'D7A3 바로 뒤': '\uD7A4',
        '3130 바로 앞': '\u312F',
        '318F 바로 뒤': '\u3190',
        '1100 바로 앞': '\u10FF',
        '11FF 바로 뒤': '\u1200',
        'A960 바로 앞': '\uA95F',
        'A97F 바로 뒤': '\uA980',
        'D7B0 바로 앞': '\uD7AF',
      };
      for (final entry in outside.entries) {
        expect(
          noCharBreak('A${entry.value}'),
          'A${entry.value}',
          reason: entry.key,
        );
      }
    });

    test('이모지처럼 여러 코드 조각으로 된 글자는 가운데를 끊지 않는다', () {
      const family = '👨‍👩‍👧';
      expect(noCharBreak(family), family);
      expect(noCharBreak('$family가'), '$family$_wj가');
    });

    test('WORD JOINER를 지우면 언제나 원문이고, 공백 바로 옆에는 없다', () {
      for (final s in [
        '오전',
        '같이 가요',
        '1주일 뒤',
        '12분',
        'A형 B',
        '11월 11일 (수)',
        ' 가 ',
        '다른  조 참여',
      ]) {
        final out = noCharBreak(s);
        expect(out.replaceAll(_wj, ''), s, reason: s);
        expect(
          RegExp('\\s$_wj|$_wj\\s').hasMatch(out),
          isFalse,
          reason: '$s: 공백 옆 WORD JOINER',
        );
      }
    });
  });

  group('SmashLabel: Text의 하위 클래스', () {
    testWidgets('Text이고 data는 원문이며 const로 만들 수 있다', (tester) async {
      await tester.pumpWidget(host(const SmashLabel('오전 오후')));

      final widget = tester.widget<Text>(anyText());
      expect(widget, isA<SmashLabel>());
      expect(widget.data, '오전 오후');
      expect(widget.textSpan, isNull);
    });

    testWidgets('find.text, textContaining, widget<Text>가 원문으로 그대로 동작한다', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SmashLabel('같이 이동하고 싶어요', style: TextStyle(fontSize: 20))),
      );

      expect(find.text('같이 이동하고 싶어요'), findsOneWidget);
      expect(find.textContaining('이동하고'), findsOneWidget);
      expect(tester.widget<Text>(find.text('같이 이동하고 싶어요')).style!.fontSize, 20);
      expect(
        find.text('같⁠이'),
        findsNothing,
        reason: '그려지는 글자(WORD JOINER 포함)로는 찾지 않는다',
      );
    });

    testWidgets(
      '알려진 한계: find.byType(Text)는 정확한 타입 비교라 SmashLabel을 찾지 못한다 (byWidgetPredicate 사용)',
      (tester) async {
        await tester.pumpWidget(host(const SmashLabel('오전')));

        expect(find.byType(Text), findsNothing);
        expect(anyText(), findsOneWidget);
      },
    );

    testWidgets('그려지는 글자는 noCharBreak을 거친 글자이고, 한글이 없으면 원문 그대로다', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SmashLabel('같이 가요')));
      expect(plainTextOf(tester), '같$_wj이 가$_wj요');

      await tester.pumpWidget(host(const SmashLabel('3:30')));
      expect(plainTextOf(tester), '3:30');
    });
  });

  group('SmashLabel: 스크린리더', () {
    testWidgets('지정하지 않으면 원문을 읽고 WORD JOINER가 섞이지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const SmashLabel('같이 가요')));

      expect(hasLabel(tester, '같이 가요'), isTrue);
      expect(hasLabel(tester, _wj), isFalse);
      handle.dispose();
    });

    testWidgets('호출자가 semanticsLabel을 지정하면 그것이 우선이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const SmashLabel('타조참', semanticsLabel: '타조참, 다른 조 활동에 참여')),
      );

      expect(hasLabel(tester, '타조참, 다른 조 활동에 참여'), isTrue);
      expect(
        semanticsNode(tester, (d) => d.label == '타조참'),
        isNull,
        reason: '원문은 읽히지 않는다',
      );
      expect(hasLabel(tester, _wj), isFalse);
      handle.dispose();
    });

    testWidgets('빈 문자열도 "지정"으로 본다 (원문으로 되돌아가지 않는다)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const SmashLabel('장식 글자', semanticsLabel: '')),
      );

      expect(semanticsNode(tester, (d) => d.label == '장식 글자'), isNull);
      handle.dispose();
    });

    testWidgets('semanticsIdentifier가 전달된다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const SmashLabel('오전', semanticsIdentifier: 'half-am')),
      );

      final node = semanticsNode(tester, (d) => d.label == '오전');
      expect(node, isNotNull);
      expect(node!.getSemanticsData().identifier, 'half-am');
      handle.dispose();
    });

    testWidgets('텍스트로 읽히는 노드이고 버튼 등 다른 역할을 만들지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const SmashLabel('오전')));

      final data = semanticsNode(
        tester,
        (d) => d.label == '오전',
      )!.getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isEnabled, isNot(Tristate.isFalse));
      handle.dispose();
    });
  });

  group('SmashLabel: Text의 모든 인자가 일반 Text와 같이 전달된다', () {
    // 인자 하나만 바꿔서 SmashLabel과 같은 인자의 Text가 같은 설정으로 그려지는지 본다.
    // 인자가 실제로 설정을 바꾸는지(검사가 헛돌지 않는지)도 함께 확인한다.
    const text = '가나 다라';
    final cases = <String, Widget Function(bool smash)>{
      'style': (s) => s
          ? const SmashLabel(
              text,
              style: TextStyle(
                color: Color(0xFFAA0000),
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            )
          : const Text(
              text,
              style: TextStyle(
                color: Color(0xFFAA0000),
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
      'strutStyle': (s) => s
          ? const SmashLabel(
              text,
              strutStyle: StrutStyle(fontSize: 30, forceStrutHeight: true),
            )
          : const Text(
              text,
              strutStyle: StrutStyle(fontSize: 30, forceStrutHeight: true),
            ),
      'textAlign': (s) => s
          ? const SmashLabel(text, textAlign: TextAlign.center)
          : const Text(text, textAlign: TextAlign.center),
      'textDirection': (s) => s
          ? const SmashLabel(text, textDirection: TextDirection.rtl)
          : const Text(text, textDirection: TextDirection.rtl),
      'locale': (s) => s
          ? const SmashLabel(text, locale: Locale('ja'))
          : const Text(text, locale: Locale('ja')),
      'softWrap': (s) => s
          ? const SmashLabel(text, softWrap: false)
          : const Text(text, softWrap: false),
      'overflow': (s) => s
          ? const SmashLabel(text, overflow: TextOverflow.fade)
          : const Text(text, overflow: TextOverflow.fade),
      'textScaler': (s) => s
          ? const SmashLabel(text, textScaler: TextScaler.linear(1.7))
          : const Text(text, textScaler: TextScaler.linear(1.7)),
      'maxLines': (s) => s
          ? const SmashLabel(text, maxLines: 3)
          : const Text(text, maxLines: 3),
      'textWidthBasis': (s) => s
          ? const SmashLabel(text, textWidthBasis: TextWidthBasis.longestLine)
          : const Text(text, textWidthBasis: TextWidthBasis.longestLine),
      'textHeightBehavior': (s) => s
          ? const SmashLabel(
              text,
              textHeightBehavior: TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
            )
          : const Text(
              text,
              textHeightBehavior: TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
            ),
      'selectionColor': (s) => s
          ? const SmashLabel(text, selectionColor: Color(0xFF00AA00))
          : const Text(text, selectionColor: Color(0xFF00AA00)),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key}: 일반 Text와 같은 설정으로 그려지고, 이 인자가 실제로 설정을 바꾼다', (
        tester,
      ) async {
        Widget wrap(Widget w) =>
            entry.key == 'selectionColor' ? SelectionArea(child: w) : w;

        await tester.pumpWidget(host(wrap(const Text(text))));
        final defaults = configOf(richOf(tester));
        await tester.pumpWidget(host(wrap(entry.value(false))));
        final plain = configOf(richOf(tester));
        await tester.pumpWidget(host(wrap(entry.value(true))));
        final smash = configOf(richOf(tester));

        final changed = plain.keys
            .where((k) => plain[k] != defaults[k])
            .toList();
        expect(
          changed,
          isNotEmpty,
          reason: '${entry.key} 인자가 설정을 바꾸지 못하면 이 검사는 헛돈다',
        );
        for (final key in changed) {
          expect(
            smash[key],
            plain[key],
            reason: '${entry.key} → $key 가 SmashLabel에서 전달되지 않았다',
          );
        }
        expect(smash, plain, reason: '${entry.key}: 나머지 설정도 일반 Text와 같다');
      });
    }

    testWidgets('아무 인자도 없을 때도 일반 Text와 같은 설정이다', (tester) async {
      await tester.pumpWidget(host(const Text('가나 다라')));
      final plain = configOf(richOf(tester));
      await tester.pumpWidget(host(const SmashLabel('가나 다라')));

      expect(configOf(richOf(tester)), plain);
    });

    testWidgets('주변 DefaultTextStyle과 글자 배율(MediaQuery)도 일반 Text처럼 따른다', (
      tester,
    ) async {
      Widget inherited(Widget w) => DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF123456), fontSize: 19),
        child: w,
      );
      await tester.pumpWidget(host(inherited(const Text('가나 다라')), scale: 1.5));
      final plain = configOf(richOf(tester));
      await tester.pumpWidget(
        host(inherited(const SmashLabel('가나 다라')), scale: 1.5),
      );

      expect(configOf(richOf(tester)), plain);
    });
  });

  group('SmashLabel: 줄바꿈', () {
    testWidgets('좁은 상자에서 일반 Text는 낱말 중간에서 끊기고 SmashLabel은 끊기지 않는다 (줄 수는 같다)', (
      tester,
    ) async {
      const sentence = '같이 이동하고 싶어요 오늘도';
      await tester.pumpWidget(
        host(const Text(sentence, key: ValueKey('plain')), width: 150),
      );
      final plainBreaks = midWordBreaks(
        tester,
        find.byKey(const ValueKey('plain')),
      );
      final plainLines = lineCount(tester, find.byKey(const ValueKey('plain')));
      await tester.pumpWidget(
        host(const SmashLabel(sentence, key: ValueKey('label')), width: 150),
      );

      expect(
        plainBreaks,
        greaterThan(0),
        reason: '이 폭에서 일반 Text는 낱말 중간에서 끊긴다 (검사가 헛돌지 않는다)',
      );
      expect(midWordBreaks(tester, find.byKey(const ValueKey('label'))), 0);
      expect(
        lineCount(tester, find.byKey(const ValueKey('label'))),
        plainLines,
      );
    });

    testWidgets('낱말이 상자보다 길면 엔진이 글자 단위로 끊는다 (알려진 한계)', (tester) async {
      await tester.pumpWidget(
        host(const SmashLabel('신청하기', key: ValueKey('label')), width: 40),
      );

      expect(
        lineCount(tester, find.byKey(const ValueKey('label'))),
        greaterThan(1),
      );
    });

    testWidgets('maxLines와 말줄임이 동작한다', (tester) async {
      await tester.pumpWidget(
        host(
          const SmashLabel(
            '아주 긴 안내 문구가 두 줄을 넘어가면 말줄임으로 줄여요 정말로 그렇게 해요',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          width: 150,
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: anyText(), matching: find.byType(RichText)).first,
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(lineCount(tester, anyText()), 2);
    });

    testWidgets('다시 그려도 같은 결과다 (다시 그릴 때마다 WORD JOINER가 쌓이지 않는다)', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SmashLabel('같이 가요')));
      final first = plainTextOf(tester);
      await tester.pumpWidget(host(const SmashLabel('같이 가요')));
      await tester.pump();

      expect(plainTextOf(tester), first);
      expect(wjCount(plainTextOf(tester)), 2);
    });
  });

  group('SmashLabel: 고유 폭 (SmashAdaptiveRow가 기대는 성질)', () {
    testWidgets('최소 고유 폭은 가장 긴 낱말 폭이고, 일반 Text는 한 음절 폭이다', (tester) async {
      const style = TextStyle(fontSize: 16, letterSpacing: 0);
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              Text('같이 가요 오늘', style: style, key: ValueKey('plain')),
              SmashLabel('같이 가요 오늘', style: style, key: ValueKey('label')),
            ],
          ),
        ),
      );
      double minOf(String key) => tester
          .renderObject<RenderBox>(find.byKey(ValueKey(key)))
          .getMinIntrinsicWidth(double.infinity);

      expect(minOf('plain'), closeTo(16, 0.01), reason: '일반 Text: 한 음절');
      expect(
        minOf('label'),
        closeTo(32, 0.01),
        reason: 'SmashLabel: 가장 긴 낱말(두 음절)',
      );
    });
  });

  group('측정 점검: TextPainter로 잰 폭 = 실제로 그려진 폭', () {
    const strings = [
      '오전',
      '미처리',
      '같이 가요',
      '1주일 뒤',
      '12',
      '120',
      '11월 11일 (수)',
      '12분',
      'A형',
      'ABC',
    ];

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '글자 $scale배, 자간 0: SmashLabel의 실제 폭 = TextPainter(noCharBreak 적용 글자) 폭 (WORD JOINER는 폭이 없다)',
        (tester) async {
          final style = SmashText.bodyStrong.copyWith(letterSpacing: 0);
          for (final s in strings) {
            final painter = TextPainter(
              text: TextSpan(text: noCharBreak(s), style: style),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.linear(scale),
              maxLines: 1,
            )..layout();
            await tester.pumpWidget(
              host(
                SmashLabel(s, style: style, maxLines: 1, softWrap: false),
                scale: scale,
              ),
            );

            expect(
              tester.getSize(anyText()).width,
              closeTo(painter.width, 0.01),
              reason: '"$s" 배율 $scale',
            );
            painter.dispose();
          }
        },
      );

      testWidgets(
        '글자 $scale배: 자간이 있으면 글자 폭에 더해서 WORD JOINER마다 자간만큼 더 넓어진다 (Material 기본 자간 0.25가 섞이는 경우)',
        (tester) async {
          // 스타일에 자간을 명시하지 않으면 Scaffold 본문에서는 Material 기본 글자 스타일의 자간(0.25)이 섞인다
          for (final s in strings) {
            await tester.pumpWidget(
              host(
                Text(s, style: SmashText.body, maxLines: 1, softWrap: false),
                scale: scale,
              ),
            );
            final plainStyle = richOf(tester).text.style!;
            final plain = tester.getSize(anyText()).width;
            await tester.pumpWidget(
              host(
                SmashLabel(
                  s,
                  style: SmashText.body,
                  maxLines: 1,
                  softWrap: false,
                ),
                scale: scale,
              ),
            );
            final label = tester.getSize(anyText()).width;

            expect(
              plainStyle.letterSpacing,
              0.25,
              reason: 'SmashText.body는 자간을 명시하지 않아 Material 기본 자간이 섞인다',
            );
            expect(
              label - plain,
              closeTo(0.25 * wjCount(noCharBreak(s)), 0.01),
              reason: '"$s"',
            );
          }
        },
      );
    }
  });

  group('측정 점검: SmashTabBar.contentWidth = 실제로 그려진 탭 내용 폭', () {
    final tabs = <SmashTab>[
      const SmashTab(label: '합격'),
      const SmashTab(label: '종료된 투표'),
      const SmashTab(label: '미처리', badgeCount: 12),
      const SmashTab(label: '조별 현황', badgeCount: 120),
      const SmashTab(label: '이번 달 정규 참여 신청 현황', badgeCount: 0),
    ];

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        '글자 $scale배: 모든 탭 구성에서 contentWidth가 실제 폭과 같고, 탭 글자의 자간은 0이다',
        (tester) async {
          for (final tab in tabs) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpWidget(
              host(_TabProbe(tab: tab), scale: scale, width: 1000),
            );
            final label = tester
                .getSize(
                  find.descendant(
                    of: find.byType(Tab).first,
                    matching: find.text(tab.label),
                  ),
                )
                .width;
            var rendered = label;
            if (tab.badgeCount != null) {
              final count = tester
                  .getSize(
                    find.descendant(
                      of: find.byType(Tab).first,
                      matching: find.text('${tab.badgeCount}'),
                    ),
                  )
                  .width;
              rendered = label + 8 + count;
            }
            final labelStyle = tester
                .renderObject<RenderParagraph>(
                  find
                      .descendant(
                        of: find.descendant(
                          of: find.byType(Tab).first,
                          matching: find.text(tab.label),
                        ),
                        matching: find.byType(RichText),
                      )
                      .first,
                )
                .text
                .style!;

            expect(
              labelStyle.letterSpacing,
              0,
              reason:
                  '${tab.label}: 자간을 명시하지 않으면 Material 기본 자간(0.1)이 섞여 측정과 어긋난다',
            );
            expect(
              SmashTabBar.contentWidth(tab, TextScaler.linear(scale)),
              closeTo(rendered, 0.01),
              reason: '${tab.label} 배율 $scale',
            );
          }
        },
      );
    }
  });
}

class _TabProbe extends StatefulWidget {
  const _TabProbe({required this.tab});

  final SmashTab tab;

  @override
  State<_TabProbe> createState() => _TabProbeState();
}

class _TabProbeState extends State<_TabProbe>
    with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SmashTabBar(
    controller: controller,
    isScrollable: true,
    tabs: [
      widget.tab,
      const SmashTab(label: '다른 탭'),
    ],
  );
}
