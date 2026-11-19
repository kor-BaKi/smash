import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/design/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/pixels.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const _screen = Size(400, 900);
final _boundaryKey = GlobalKey();

Widget app(
  Widget child, {
  double width = 360,
  double scale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
  bool disableAnimations = false,
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
        disableAnimations: disableAnimations,
      ),
      child: a!,
    ),
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: safe.top),
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

/// 탭 줄 + (선택 사항) 본문. 만든 컨트롤러를 [onController]로 알려 준다
class TabHost extends StatefulWidget {
  const TabHost({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.isScrollable,
    this.withBody = false,
    this.onController,
  });

  final List<SmashTab> tabs;
  final int initialIndex;
  final bool? isScrollable;
  final bool withBody;
  final ValueChanged<TabController>? onController;

  @override
  State<TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<TabHost> with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.initialIndex,
  );

  @override
  void initState() {
    super.initState();
    widget.onController?.call(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = SmashTabBar(
      controller: controller,
      tabs: widget.tabs,
      isScrollable: widget.isScrollable,
    );
    if (!widget.withBody) return bar;
    return Column(
      children: [
        bar,
        SizedBox(
          height: 120,
          child: TabBarView(
            controller: controller,
            children: [
              for (final tab in widget.tabs)
                Center(child: Text('${tab.label} 본문')),
            ],
          ),
        ),
      ],
    );
  }
}

const _setA = [
  SmashTab(label: '진행 중'),
  SmashTab(label: '종료된 투표'),
  SmashTab(label: '내 투표'),
];
const _setB = [
  SmashTab(label: '미처리', badgeCount: 12),
  SmashTab(label: '합격', badgeCount: 3),
  SmashTab(label: '불합격', badgeCount: 0),
];
const _setC = [
  SmashTab(label: '조별 현황'),
  SmashTab(label: '미달자'),
  SmashTab(label: '타조참'),
];
const _setD = [
  SmashTab(label: '부원 목록'),
  SmashTab(label: '조 편성'),
  SmashTab(label: '자동 배정'),
];
const _setE = [
  SmashTab(label: '1조'),
  SmashTab(label: '2조'),
  SmashTab(label: '3조'),
  SmashTab(label: '4조'),
  SmashTab(label: '5조'),
  SmashTab(label: '6조'),
  SmashTab(label: '미배정'),
];

const _setShort2 = [
  SmashTab(label: '미처리', badgeCount: 12),
  SmashTab(label: '합격', badgeCount: 3),
];
const _setShort = [
  SmashTab(label: '전체'),
  SmashTab(label: '합격'),
  SmashTab(label: '마감'),
];

Finder tabAt(int i) => find.byType(Tab).at(i);
Finder labelOf(String label) =>
    find.descendant(of: find.byType(Tab), matching: find.text(label));
TabBar tabBarWidget(WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar));

void main() {
  group('동작', () {
    testWidgets('탭을 누르면 컨트롤러 인덱스와 본문이 바뀐다', (tester) async {
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(
          TabHost(
            tabs: _setB,
            withBody: true,
            onController: (c) => controller = c,
          ),
        ),
      );
      expect(controller.index, 0);
      expect(find.text('미처리 본문'), findsOneWidget);

      await tester.tap(labelOf('합격'));
      await tester.pumpAndSettle();

      expect(controller.index, 1);
      expect(find.text('합격 본문'), findsOneWidget);
    });

    testWidgets('본문을 옆으로 밀어도 탭 선택이 따라간다', (tester) async {
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(
          TabHost(
            tabs: _setB,
            withBody: true,
            onController: (c) => controller = c,
          ),
        ),
      );

      await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();

      expect(controller.index, 1);
      expect(find.text('합격 본문'), findsOneWidget);
    });

    testWidgets('개수: 0도 숫자로 보이고 null이면 없다. 배경 모양(타원) 없이 숫자만 있다', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          const TabHost(
            tabs: [
              SmashTab(label: '미처리', badgeCount: 12),
              SmashTab(label: '합격', badgeCount: 0),
              SmashTab(label: '불합격'),
            ],
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(
        find.descendant(of: tabAt(0), matching: find.byType(Text)),
        findsNWidgets(2),
        reason: '라벨 + 숫자',
      );
      expect(
        find.descendant(of: tabAt(1), matching: find.byType(Text)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: tabAt(2), matching: find.byType(Text)),
        findsOneWidget,
        reason: '개수가 없으면 라벨뿐',
      );
      for (var i = 0; i < 3; i++) {
        expect(
          find.descendant(of: tabAt(i), matching: find.byType(Container)),
          findsNothing,
          reason: '$i번째 탭에 배경 컨테이너가 없다',
        );
        expect(
          find.descendant(of: tabAt(i), matching: find.byType(DecoratedBox)),
          findsNothing,
          reason: '$i번째 탭에 배경 모양(타원)이 없다',
        );
      }
    });

    testWidgets('탭 수와 컨트롤러 length가 다르면 assert로 알려 준다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(const _MismatchHost()));

      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('글자는 항상 한 줄이다 (폭 320/360/390 × 글자 1.0/1.3/2.0)', () {
    final sets = {
      '진행 중|종료된 투표|내 투표': _setA,
      '미처리 12|합격 3|불합격 0': _setB,
      '조별 현황|미달자|타조참': _setC,
      '부원 목록|조 편성|자동 배정': _setD,
      '조 7개': _setE,
    };
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final entry in sets.entries) {
          testWidgets(
            '폭 $width, 글자 $scale배, ${entry.key}: 모든 탭 글자가 한 줄이고 낱말 중간에서 끊기지 않으며 잘리지 않는다',
            (tester) async {
              sizeScreen(tester);
              await tester.pumpWidget(
                app(
                  TabHost(tabs: entry.value),
                  width: width,
                  scale: scale,
                ),
              );
              final scaler = TextScaler.linear(scale);

              expect(tester.takeException(), isNull);
              final bar = tester.getRect(find.byType(TabBar));
              expect(
                bar.height,
                lessThanOrEqualTo(52),
                reason: '탭 줄 높이는 탭 48 + 밑줄 여유',
              );
              for (var i = 0; i < entry.value.length; i++) {
                final tab = entry.value[i];
                final text = labelOf(tab.label);
                expect(lineCount(tester, text), 1, reason: '${tab.label} 줄 수');
                expect(midWordBreaks(tester, text), 0, reason: tab.label);
                final natural = SmashTabBar.contentWidth(
                  SmashTab(label: tab.label),
                  scaler,
                );
                expect(
                  tester.getSize(text).width,
                  greaterThanOrEqualTo(natural - 0.5),
                  reason: '${tab.label} 글자가 잘리지 않는다',
                );
                expect(
                  tester.getRect(tabAt(i)).height,
                  greaterThanOrEqualTo(48),
                  reason: '터치 높이 48 이상',
                );
              }
              if (!tabBarWidget(tester).isScrollable) {
                for (var i = 0; i < entry.value.length; i++) {
                  final r = tester.getRect(tabAt(i));
                  expect(r.left, greaterThanOrEqualTo(bar.left - 0.01));
                  expect(
                    r.right,
                    lessThanOrEqualTo(bar.right + 0.01),
                    reason: '고정 모드에서는 모든 탭이 줄 안에 있다',
                  );
                }
              }
            },
          );
        }
      }
    }

    testWidgets(
      '자동 전환: 넉넉하면 고정, 모자라면 스크롤형 (같은 탭 3개: 폭 390×1.0은 고정, 폭 320×2.0은 스크롤)',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app(const TabHost(tabs: _setA), width: 390));
        expect(tabBarWidget(tester).isScrollable, isFalse);

        await tester.pumpWidget(
          app(const TabHost(tabs: _setA), width: 320, scale: 2.0),
        );
        expect(tabBarWidget(tester).isScrollable, isTrue);
      },
    );

    testWidgets('탭 7개는 폭이 넉넉해도 스크롤형이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(const TabHost(tabs: _setE), width: 390));

      expect(tabBarWidget(tester).isScrollable, isTrue);
    });

    testWidgets('isScrollable로 강제하면 자동 판단을 따르지 않는다 (탭 2개도 스크롤형, 긴 탭도 고정)', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          const TabHost(
            tabs: [
              SmashTab(label: '진행 중'),
              SmashTab(label: '종료'),
            ],
            isScrollable: true,
          ),
          width: 390,
        ),
      );
      expect(tabBarWidget(tester).isScrollable, isTrue);

      // 탭 수가 다른 새 컨트롤러가 필요하므로 한 번 비운 뒤 다시 그린다
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        app(
          const TabHost(tabs: _setA, isScrollable: false),
          width: 320,
          scale: 2.0,
        ),
      );
      expect(tabBarWidget(tester).isScrollable, isFalse);
      expect(
        tester.takeException(),
        isNull,
        reason: '강제 고정인데 모자라도 넘침 오류가 아니라 한 줄 안에서 잘린다',
      );
      expect(lineCount(tester, labelOf('종료된 투표')), 1);
    });

    testWidgets(
      'contentWidth: 개수가 있으면 간격 8 + 숫자 폭(배경 여백 없음)만큼 넓어지고, 자릿수가 늘면 한 자리 폭씩 넓어진다',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app(const SizedBox()));
        const scaler = TextScaler.linear(1.0);
        double width(int? count) => SmashTabBar.contentWidth(
          SmashTab(label: '합격', badgeCount: count),
          scaler,
        );
        // 숫자 폭: 13px, w600, 자릿수 폭이 같은 숫자
        double digit(String s) {
          final painter = TextPainter(
            text: TextSpan(
              text: s,
              style: SmashText.tabular(
                const TextStyle(
                  fontFamily: SmashText.family,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          return painter.width;
        }

        expect(
          width(0) - width(null),
          closeTo(8 + digit('0'), 0.01),
          reason: '간격 8 + 숫자 폭, 타원 여백(좌우 6, 최소 폭 20)이 없다',
        );
        expect(width(12) - width(null), closeTo(8 + digit('12'), 0.01));
        expect(width(120) - width(null), closeTo(8 + digit('120'), 0.01));
        expect(width(120), greaterThan(width(12)));
        expect(width(12), greaterThan(width(0)));
      },
    );

    test('fitsFixed 경계: 칸 폭(좌우 여백 8씩 + 1px 여유)과 정확히 같으면 고정, 1px 모자라면 스크롤', () {
      // 내용 폭 w가 칸(available / 개수) 안에 들어가려면 w + 16 + 1 <= 칸
      expect(
        SmashTabBar.fitsFixed(contentWidths: [83, 83], available: 200),
        isTrue,
      ); // 칸 100 = 83 + 17
      expect(
        SmashTabBar.fitsFixed(contentWidths: [83.01, 83], available: 200),
        isFalse,
      );
      expect(
        SmashTabBar.fitsFixed(contentWidths: const [], available: 100),
        isTrue,
      );
    });
  });

  group('개수 숫자 (배경 모양 없이 숫자만)', () {
    TextStyle? resolved(WidgetTester tester, Finder text) => tester
        .renderObject<RenderParagraph>(
          find.descendant(of: text, matching: find.byType(RichText)).first,
        )
        .text
        .style;
    Finder countOf(int tab, String digits) =>
        find.descendant(of: tabAt(tab), matching: find.text(digits));

    testWidgets(
      '굵기는 선택과 상관없이 w600 고정이고 자릿수 폭이 같은 숫자(tabular figures)이며, 선택이 바뀌어도 탭 폭이 변하지 않는다',
      (tester) async {
        sizeScreen(tester);
        late TabController controller;
        await tester.pumpWidget(
          app(TabHost(tabs: _setB, onController: (c) => controller = c)),
        );

        List<double> widths() => [
          for (var i = 0; i < 3; i++) tester.getRect(tabAt(i)).width,
        ];
        final before = widths();
        for (final (tab, digits) in [(0, '12'), (1, '3'), (2, '0')]) {
          final style = resolved(tester, countOf(tab, digits))!;
          expect(style.fontWeight, FontWeight.w600, reason: '$digits 선택 전 굵기');
          expect(
            style.fontFeatures,
            contains(const FontFeature.tabularFigures()),
            reason: '$digits 자릿수 폭 같은 숫자',
          );
        }

        controller.animateTo(2);
        await tester.pumpAndSettle();
        for (final (tab, digits) in [(0, '12'), (1, '3'), (2, '0')]) {
          expect(
            resolved(tester, countOf(tab, digits))!.fontWeight,
            FontWeight.w600,
            reason: '$digits 선택 후 굵기',
          );
        }
        final after = widths();
        for (var i = 0; i < 3; i++) {
          expect(
            after[i],
            closeTo(before[i], 0.01),
            reason: '선택이 바뀌어도 ${i + 1}번째 탭 폭이 같다',
          );
        }
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets('글자 $scale배: 라벨과 숫자 사이는 8이고(배율과 무관), 숫자는 라벨 오른쪽에 같은 줄에 있다', (
        tester,
      ) async {
        sizeScreen(tester);
        await tester.pumpWidget(
          app(const TabHost(tabs: _setShort2), width: 390, scale: scale),
        );
        final label = tester.getRect(labelOf('미처리'));
        final count = tester.getRect(countOf(0, '12'));

        expect(count.left - label.right, closeTo(8, 0.01), reason: '간격');
        expect(
          (count.center.dy - label.center.dy).abs(),
          lessThan(8),
          reason: '같은 줄',
        );
      });
    }

    testWidgets(
      '숫자 색: 선택된 탭은 브랜드 색, 선택되지 않은 탭은 보조색이고, 흰 배경과 포커스 배경(연한 브랜드) 모두에서 대비 4.5:1 이상이다',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(app(TabHost(tabs: _setB)));

        final selected = resolved(tester, countOf(0, '12'))!.color!;
        final unselected = resolved(tester, countOf(1, '3'))!.color!;
        expect(selected, SmashColors.brand);
        expect(unselected, SmashColors.textSecondary);
        for (final (name, color) in [
          ('선택', selected),
          ('선택 안 됨', unselected),
        ]) {
          expect(
            contrastRatio(color, SmashColors.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name 숫자 / 흰 배경',
          );
          expect(
            contrastRatio(color, SmashColors.brandTintSoft),
            greaterThanOrEqualTo(4.5),
            reason: '$name 숫자 / 포커스 배경',
          );
        }
        // 선택은 색에만 의존하지 않는다: 같은 색 구분과 함께 밑줄이 있다 (밑줄 픽셀은 아래 "밑줄과 구분선"에서 검사)
        expect(find.byType(TabBar), findsOneWidget);
        expect(tabBarWidget(tester).indicator, isA<UnderlineTabIndicator>());
      },
    );

    testWidgets('숫자 색은 선택이 바뀌면 따라 바뀐다 (선택 → 보조색, 새 선택 → 브랜드 색)', (
      tester,
    ) async {
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(TabHost(tabs: _setB, onController: (c) => controller = c)),
      );

      controller.animateTo(1);
      await tester.pumpAndSettle();

      expect(
        resolved(tester, countOf(0, '12'))!.color,
        SmashColors.textSecondary,
      );
      expect(resolved(tester, countOf(1, '3'))!.color, SmashColors.brand);
    });

    // 숫자 한 자리, 0, 세 자리 × 폭 3 × 배율 3
    for (final count in [0, 7, 120]) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
            '개수 $count, 폭 $width, 글자 $scale배: 라벨과 숫자 모두 한 줄이고 안 잘리며, 선택이 바뀌어도 폭이 같다',
            (tester) async {
              sizeScreen(tester);
              late TabController controller;
              final tabs = [
                SmashTab(label: '미처리', badgeCount: count),
                SmashTab(label: '합격', badgeCount: count),
                SmashTab(label: '불합격', badgeCount: count),
              ];
              await tester.pumpWidget(
                app(
                  TabHost(tabs: tabs, onController: (c) => controller = c),
                  width: width,
                  scale: scale,
                ),
              );
              final scaler = TextScaler.linear(scale);

              expect(tester.takeException(), isNull);
              final bar = tester.getRect(find.byType(TabBar));
              for (var i = 0; i < tabs.length; i++) {
                final tab = tabs[i];
                final label = labelOf(tab.label);
                final digits = countOf(i, '$count');
                expect(lineCount(tester, label), 1, reason: '${tab.label} 줄 수');
                expect(lineCount(tester, digits), 1, reason: '$count 줄 수');
                expect(midWordBreaks(tester, label), 0);
                final naturalLabel = SmashTabBar.contentWidth(
                  SmashTab(label: tab.label),
                  scaler,
                );
                final naturalCount =
                    SmashTabBar.contentWidth(tab, scaler) - naturalLabel - 8;
                expect(
                  tester.getSize(label).width,
                  greaterThanOrEqualTo(naturalLabel - 0.5),
                  reason: '${tab.label} 잘리지 않는다',
                );
                expect(
                  tester.getSize(digits).width,
                  greaterThanOrEqualTo(naturalCount - 0.5),
                  reason: '$count 잘리지 않는다',
                );
                expect(
                  tester.getRect(tabAt(i)).height,
                  greaterThanOrEqualTo(48),
                );
                expect(
                  tester.getRect(digits).left,
                  greaterThanOrEqualTo(tester.getRect(label).right + 8 - 0.01),
                  reason: '숫자는 라벨 오른쪽, 간격 8 이상',
                );
              }
              if (!tabBarWidget(tester).isScrollable) {
                for (var i = 0; i < tabs.length; i++) {
                  expect(
                    tester.getRect(tabAt(i)).right,
                    lessThanOrEqualTo(bar.right + 0.01),
                    reason: '고정 모드에서는 모든 탭이 줄 안에 있다',
                  );
                }
              }
              final before = [
                for (var i = 0; i < 3; i++) tester.getRect(tabAt(i)).width,
              ];
              controller.animateTo(2);
              await tester.pumpAndSettle();
              for (var i = 0; i < 3; i++) {
                expect(
                  tester.getRect(tabAt(i)).width,
                  closeTo(before[i], 0.01),
                  reason: '선택이 바뀌어도 ${i + 1}번째 탭 폭이 같다',
                );
              }
            },
          );
        }
      }
    }
  });

  group('선택된 탭이 화면 안에 있다 (스크롤형)', () {
    testWidgets('처음부터 마지막 탭이 선택돼 있으면 그 탭이 줄 안에 보인다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(const TabHost(tabs: _setE, initialIndex: 6), width: 320),
      );
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(TabBar));
      final last = tester.getRect(tabAt(6));
      expect(last.left, greaterThanOrEqualTo(bar.left));
      expect(last.right, lessThanOrEqualTo(bar.right + 0.01));
    });

    testWidgets('컨트롤러로 마지막 탭으로 옮기면 선택된 탭이 줄 안으로 스크롤된다', (tester) async {
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(
          TabHost(tabs: _setE, onController: (c) => controller = c),
          width: 320,
        ),
      );
      expect(
        tester.getRect(tabAt(6)).left,
        greaterThan(320),
        reason: '처음에는 마지막 탭이 줄 밖에 있다',
      );

      controller.animateTo(6);
      await tester.pumpAndSettle();

      expect(tester.getRect(tabAt(6)).right, lessThanOrEqualTo(320.01));
    });

    testWidgets('스크롤형 탭 줄은 끝에서 튕기지 않는다 (ClampingScrollPhysics)', (
      tester,
    ) async {
      sizeScreen(tester);
      await tester.pumpWidget(app(const TabHost(tabs: _setE), width: 320));

      expect(tabBarWidget(tester).physics, isA<ClampingScrollPhysics>());
    });
  });

  group('안전 영역(위 59, 아래 34, 좌우 20)이 탭 줄 안으로 새지 않는다', () {
    testWidgets('고정과 스크롤형 모두 높이와 첫 탭의 왼쪽 위치가 안전 영역이 없을 때와 같다', (tester) async {
      sizeScreen(tester);
      for (final tabs in [_setB, _setE]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(app(TabHost(tabs: tabs), width: 320));
        final base = (
          tester.getSize(find.byType(TabBar)),
          tester.getRect(tabAt(0)).left,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          app(
            TabHost(tabs: tabs),
            width: 320,
            safe: const EdgeInsets.fromLTRB(20, 59, 20, 34),
          ),
        );
        final padded = (
          tester.getSize(find.byType(TabBar)),
          tester.getRect(tabAt(0)).left,
        );

        expect(padded.$1, base.$1, reason: '높이 ${tabs.length}탭');
        expect(padded.$2, base.$2, reason: '첫 탭 왼쪽 ${tabs.length}탭');
      }
    });
  });

  group('접근성', () {
    testWidgets('탭마다 "라벨, 12건"으로 읽히고, 위치("3개 중 1번째")와 선택 상태가 있다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(app(const TabHost(tabs: _setB)));

      final first = semanticsNode(
        tester,
        (d) => d.label.contains('미처리'),
      )!.getSemanticsData();
      expect(first.label, contains('미처리, 12건'));
      expect(first.label, contains('3개 중 1번째'), reason: '위치: ${first.label}');
      expect(first.flagsCollection.isSelected, Tristate.isTrue);
      final second = semanticsNode(
        tester,
        (d) => d.label.contains('합격'),
      )!.getSemanticsData();
      expect(second.label, contains('합격, 3건'));
      expect(second.flagsCollection.isSelected, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('semanticLabel을 넘기면 그 말을 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      await tester.pumpWidget(
        app(
          const TabHost(
            tabs: [
              SmashTab(
                label: '미처리',
                badgeCount: 12,
                semanticLabel: '아직 처리하지 않은 신청 12건',
              ),
              SmashTab(label: '합격'),
            ],
          ),
        ),
      );

      expect(hasLabel(tester, '아직 처리하지 않은 신청 12건'), isTrue);
      handle.dispose();
    });

    testWidgets('탭을 바꾸면 선택 상태가 따라 바뀐다', (tester) async {
      final handle = tester.ensureSemantics();
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(TabHost(tabs: _setB, onController: (c) => controller = c)),
      );

      controller.animateTo(2);
      await tester.pumpAndSettle();

      final third = semanticsNode(
        tester,
        (d) => d.label.contains('불합격'),
      )!.getSemanticsData();
      expect(third.flagsCollection.isSelected, Tristate.isTrue);
      final first = semanticsNode(
        tester,
        (d) => d.label.contains('미처리'),
      )!.getSemanticsData();
      expect(first.flagsCollection.isSelected, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('키보드: Tab으로 첫 탭에 포커스가 가고, 오른쪽 방향키로 다음 탭으로 옮겨 Enter로 고른다', (
      tester,
    ) async {
      sizeScreen(tester);
      late TabController controller;
      await tester.pumpWidget(
        app(TabHost(tabs: _setB, onController: (c) => controller = c)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.index, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.index, 0);
    });

    testWidgets('동작 줄이기: animationDurationOf는 켜져 있으면 0, 꺼져 있으면 기본 길이다', (
      tester,
    ) async {
      sizeScreen(tester);
      late Duration normal;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (c) {
              normal = SmashTabBar.animationDurationOf(c);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(normal, kTabScrollDuration);

      late Duration reduced;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (c) {
              reduced = SmashTabBar.animationDurationOf(c);
              return const SizedBox();
            },
          ),
          disableAnimations: true,
        ),
      );
      expect(reduced, Duration.zero);
    });
  });

  group('밑줄과 구분선 (실제 픽셀)', () {
    // 탭 줄은 높이 50: 탭 48 + 구분선(맨 아래 1px). 밑줄은 선택된 칸의 맨 아래 3px(y 47~49)에 구분선 위로 그려진다
    const underlineY = 48;
    const dividerY = 49;

    Future<void> checkFixed(
      WidgetTester tester, {
      required List<SmashTab> tabs,
      required double width,
      required int selected,
      required double scale,
    }) async {
      late TabController controller;
      await tester.pumpWidget(
        app(
          TabHost(
            tabs: tabs,
            initialIndex: selected,
            onController: (c) => controller = c,
          ),
          width: width,
          scale: scale,
        ),
      );
      await tester.pump();
      expect(controller.index, selected);
      final bar = tester.getRect(find.byType(TabBar));
      expect(
        tabBarWidget(tester).isScrollable,
        isFalse,
        reason: '이 검사는 고정 모드에서 한다',
      );
      final px = await readPixels(tester, _boundaryKey);
      final slot = bar.width / 3;
      final brand = SmashColors.brand;
      final line = SmashColors.line;

      for (var i = 0; i < 3; i++) {
        final left = (bar.left + i * slot).round();
        final right = (bar.left + (i + 1) * slot).round();
        for (var x = left + 6; x < right - 6; x += 5) {
          if (i == selected) {
            expect(
              colorDistance(px(x, underlineY), brand),
              lessThan(30),
              reason: '선택된 칸 $i 밑줄 x=$x',
            );
          } else {
            expect(
              colorDistance(px(x, underlineY), brand),
              greaterThan(3000),
              reason: '다른 칸 $i 에는 밑줄이 없다 x=$x',
            );
            expect(
              colorDistance(px(x, dividerY), line),
              lessThan(30),
              reason: '다른 칸 $i 의 구분선이 끊기지 않는다 x=$x',
            );
          }
        }
      }
      // 줄의 양 끝(첫 탭 왼쪽 끝, 마지막 탭 오른쪽 끝)에서도 구분선이 끊기지 않는다 (그 탭이 선택되지 않았을 때)
      if (selected != 0) {
        expect(
          colorDistance(px(0, dividerY), line),
          lessThan(30),
          reason: '왼쪽 끝 구분선',
        );
      }
      if (selected != 2) {
        expect(
          colorDistance(px(bar.right.round() - 1, dividerY), line),
          lessThan(30),
          reason: '오른쪽 끝 구분선',
        );
      }
      // 밑줄이 선택된 칸 밖(이웃 칸, 줄 밖)으로 새지 않는다
      final selLeft = (bar.left + selected * slot).round();
      final selRight = (bar.left + (selected + 1) * slot).round();
      if (selected > 0) {
        expect(
          colorDistance(px(selLeft - 3, underlineY), brand),
          greaterThan(3000),
          reason: '왼쪽 이웃으로 새지 않는다',
        );
      }
      if (selected < 2) {
        expect(
          colorDistance(px(selRight + 2, underlineY), brand),
          greaterThan(3000),
          reason: '오른쪽 이웃으로 새지 않는다',
        );
      }
      expect(
        colorDistance(px(bar.right.round() + 3, underlineY), brand),
        greaterThan(3000),
        reason: '줄 오른쪽 밖으로 새지 않는다',
      );
    }

    for (final scale in [1.0, 2.0]) {
      for (final selected in [0, 1, 2]) {
        testWidgets(
          '글자 $scale배, ${selected + 1}번째 탭 선택: 밑줄은 선택된 칸 안에만 있고 구분선은 다른 칸에서 끊기지 않는다',
          (tester) async {
            sizeScreen(tester);
            // 글자 2.0배에서는 개수 배지가 있는 탭이 고정 폭에 안 들어가 스크롤형이 되므로, 고정 모드가 유지되는 짧은 탭을 쓴다
            await checkFixed(
              tester,
              tabs: scale == 1.0 ? _setB : _setShort,
              width: scale == 1.0 ? 360 : 390,
              selected: selected,
              scale: scale,
            );
          },
        );
      }
    }

    testWidgets('스크롤형에서 마지막 탭이 선택돼도 밑줄이 줄 오른쪽 밖으로 나가지 않는다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(
        app(const TabHost(tabs: _setE, initialIndex: 6), width: 320),
      );
      await tester.pumpAndSettle();
      final px = await readPixels(tester, _boundaryKey);
      final bar = tester.getRect(find.byType(TabBar));

      expect(tabBarWidget(tester).isScrollable, isTrue);
      final last = tester.getRect(tabAt(6));
      expect(
        colorDistance(
          px(last.center.dx.round(), underlineY),
          SmashColors.brand,
        ),
        lessThan(30),
        reason: '마지막 탭 밑줄이 그 탭 아래에 보인다',
      );
      expect(
        colorDistance(px(bar.right.round() + 3, underlineY), SmashColors.brand),
        greaterThan(3000),
        reason: '줄 밖으로 새지 않는다',
      );
    });

    testWidgets('기준이 헛돌지 않는다: 밑줄 색과 구분선 색은 서로 충분히 다르다', (tester) async {
      expect(
        colorDistance(SmashColors.brand, SmashColors.line),
        greaterThan(30000),
      );
      expect(
        colorDistance(SmashColors.brand, Colors.white),
        greaterThan(30000),
      );
    });
  });
}

class _MismatchHost extends StatefulWidget {
  const _MismatchHost();

  @override
  State<_MismatchHost> createState() => _MismatchHostState();
}

class _MismatchHostState extends State<_MismatchHost>
    with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SmashTabBar(controller: controller, tabs: _setA); // 탭 3개, 컨트롤러 2개
}
