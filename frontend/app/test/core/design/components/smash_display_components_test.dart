import 'dart:ui' show Tristate;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/pump.dart';

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder finder) =>
      tester.getSemantics(finder).getSemanticsData();

  group('SmashChip', () {
    testWidgets('누르면 onPressed가 한 번 불린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(smashHarness(SmashChip(label: '이번 주', onPressed: () => taps++)));

      await tester.tap(find.text('이번 주'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('비활성(onPressed null)이면 눌러도 아무 일도 없다', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashChip(label: '이번 주', onPressed: null)));

      await tester.tap(find.text('이번 주'), warnIfMissed: false);
      await tester.pump();

      expect(tester.widget<Text>(find.text('이번 주')).style!.color, SmashColors.textDisabled);
    });

    testWidgets('눈에 보이는 높이는 40, 터치 영역은 48이다', (tester) async {
      await tester.pumpWidget(smashHarness(SmashChip(label: '이번 주', onPressed: () {})));

      expect(tester.getSize(find.byType(AnimatedContainer)).height, 40);
      expect(tester.getSize(find.byType(SmashPressable)).height, 48);
    });

    testWidgets('선택되면 체크 아이콘이 붙고 글자가 굵어진다 (색만으로 구분하지 않는다)', (tester) async {
      await tester.pumpWidget(smashHarness(
        Column(children: [
          SmashChip(label: '선택 안 됨', onPressed: () {}),
          SmashChip(label: '선택됨', selected: true, onPressed: () {}),
        ]),
      ));

      final off = find.ancestor(of: find.text('선택 안 됨'), matching: find.byType(Row));
      final on = find.ancestor(of: find.text('선택됨'), matching: find.byType(Row));
      expect(find.descendant(of: off, matching: find.byIcon(Icons.check)), findsNothing);
      expect(find.descendant(of: on, matching: find.byIcon(Icons.check)), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('선택됨')).style!.fontWeight,
        isNot(tester.widget<Text>(find.text('선택 안 됨')).style!.fontWeight),
      );
    });

    testWidgets('스크린리더: 버튼이고 선택 여부를 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        SmashChip(label: '이번 주', selected: true, onPressed: () {}),
      ));

      final data = semanticsOf(tester, find.byType(SmashChip));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.label, contains('이번 주'));
      handle.dispose();
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('글자 $scale배에서도 오류 없이 그려지고 높이가 줄지 않는다', (tester) async {
        await tester.pumpWidget(smashHarness(
          SmashChip(label: '이번 달에 참여하지 못한 활동만 보기', onPressed: () {}),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(AnimatedContainer)).height, greaterThanOrEqualTo(40));
      });
    }

    test('선택됨 색 조합은 글자 대비 4.5 이상이다', () {
      expect(contrastRatio(SmashColors.brand, SmashColors.brandTintSoft), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.brand, SmashColors.brandTint), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.text, SmashColors.surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('SmashBadge', () {
    testWidgets('tone마다 기본 아이콘이 있고 neutral만 없다', (tester) async {
      for (final tone in SmashBadgeTone.values) {
        await tester.pumpWidget(smashHarness(SmashBadge(label: '상태', tone: tone)));
        final expected = SmashBadge.iconFor(tone);
        if (expected == null) {
          expect(find.byType(Icon), findsNothing, reason: '$tone');
        } else {
          expect(find.byIcon(expected), findsOneWidget, reason: '$tone');
        }
      }
      expect(SmashBadge.iconFor(SmashBadgeTone.neutral), isNull);
      expect(
        {for (final t in SmashBadgeTone.values.where((t) => t != SmashBadgeTone.neutral)) SmashBadge.iconFor(t)}.length,
        SmashBadgeTone.values.length - 1,
        reason: 'tone끼리 아이콘이 겹치지 않아야 색 없이도 구분된다',
      );
    });

    testWidgets('showIcon false이면 아이콘을 숨긴다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashBadge(label: '납부 완료', tone: SmashBadgeTone.success, showIcon: false),
      ));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('스크린리더는 글자만 읽고 아이콘은 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const SmashBadge(label: '납부 완료', tone: SmashBadgeTone.success),
      ));

      // SmashBadge는 자기 노드가 없고 글자 노드 하나만 생긴다 (아이콘 노드가 없다)
      final label = find.bySemanticsLabel('납부 완료');
      expect(label, findsOneWidget);
      expect(semanticsOf(tester, label).flagsCollection.isButton, isFalse);
      final texts = tester.getSemantics(label).getSemanticsData();
      expect(texts.label, '납부 완료');
      handle.dispose();
    });

    test('모든 tone의 글자 대비가 4.5 이상이다 (위젯이 실제로 쓰는 색 기준)', () {
      for (final tone in SmashBadgeTone.values) {
        final (background, foreground) = SmashBadge.colorsFor(tone);
        expect(contrastRatio(background, foreground), greaterThanOrEqualTo(4.5), reason: '$tone');
      }
    });

    testWidgets('화면에 그려지는 색이 colorsFor와 같다', (tester) async {
      for (final tone in SmashBadgeTone.values) {
        await tester.pumpWidget(smashHarness(SmashBadge(label: '상태', tone: tone)));
        final (background, foreground) = SmashBadge.colorsFor(tone);
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(SmashBadge), matching: find.byType(DecoratedBox)),
        );
        expect((box.decoration as BoxDecoration).color, background, reason: '$tone');
        expect(tester.widget<Text>(find.text('상태')).style!.color, foreground, reason: '$tone');
      }
    });

    testWidgets('좁은 폭 + 글자 2.0배에서도 넘치지 않고 줄바꿈된다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashBadge(label: '이번 달에 참여하지 못한 날이 있어요', tone: SmashBadgeTone.warning),
        textScale: 2.0,
        width: 160,
      ));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SmashBadge)).width, lessThanOrEqualTo(160));
    });
  });

  group('SmashListRow', () {
    testWidgets('높이는 56 이상이고 onTap이 있으면 줄 어디를 눌러도 반응한다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(smashHarness(
        SmashListRow(title: '김민수', trailing: const SmashBadge(label: '참석'), onTap: () => taps++),
      ));

      expect(tester.getSize(find.byType(SmashListRow)).height, greaterThanOrEqualTo(56));
      final rect = tester.getRect(find.byType(SmashListRow));
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      await tester.pump();
      await tester.tapAt(rect.centerRight - const Offset(2, 0));
      await tester.pump();

      expect(taps, 2);
    });

    testWidgets('onTap이 있으면 스크린리더가 버튼으로 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(SmashListRow(title: '김민수', onTap: () {})));

      expect(semanticsOf(tester, find.byType(SmashListRow)).flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('onTap이 없으면 버튼이 아니고 눌러도 아무 일도 없다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(const SmashListRow(title: '김민수')));

      expect(find.byType(InkWell), findsNothing);
      expect(semanticsOf(tester, find.byType(SmashListRow)).flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('선택됨: 왼쪽 막대가 생기고 스크린리더가 선택됨을 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        Column(children: [
          SmashListRow(title: '일반', onTap: () {}),
          SmashListRow(title: '선택', selected: true, onTap: () {}),
        ]),
      ));

      Finder bar(String title) => find.descendant(
            of: find.ancestor(of: find.text(title), matching: find.byType(SmashListRow)),
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == SmashColors.brand,
            ),
          );
      expect(bar('일반'), findsNothing);
      expect(bar('선택'), findsOneWidget);
      expect(
        semanticsOf(tester, find.widgetWithText(SmashListRow, '선택')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('제목과 부제는 2줄을 넘으면 말줄임으로 줄이고 줄 높이가 끝없이 커지지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashListRow(title: '아주 긴 이름 ' * 30, subtitle: '아주 긴 메모 ' * 30),
      ));

      final title = tester.widget<Text>(find.textContaining('아주 긴 이름'));
      final subtitle = tester.widget<Text>(find.textContaining('아주 긴 메모'));
      expect([title.maxLines, subtitle.maxLines], [2, 2]);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.byType(SmashListRow)).height, lessThan(160));
    });

    testWidgets('showDivider가 false이면 구분선이 없다', (tester) async {
      await tester.pumpWidget(smashHarness(
        Column(children: const [
          SmashListRow(title: '선 있음'),
          SmashListRow(title: '선 없음', showDivider: false),
        ]),
      ));

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('글자 2.0배에서도 오류 없이 그려진다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashListRow(
          title: '김민수',
          subtitle: '20240001',
          leading: const SmashAvatar(name: '김민수'),
          trailing: const SmashBadge(label: '참석', tone: SmashBadgeTone.success),
          onTap: () {},
        ),
        textScale: 2.0,
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('SmashSectionHeader', () {
    testWidgets('스크린리더에서 제목(heading)으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(const SmashSectionHeader(title: '오늘 활동')));

      final data = semanticsOf(tester, find.bySemanticsLabel('오늘 활동'));
      expect(data.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('trailing이 있으면 오른쪽에 놓인다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashSectionHeader(
          title: '진행 중인 투표',
          trailing: SmashButton(
            label: '전체 보기',
            variant: SmashButtonVariant.text,
            size: SmashButtonSize.medium,
            expanded: false,
            onPressed: () {},
          ),
        ),
      ));

      expect(
        tester.getTopLeft(find.text('전체 보기')).dx,
        greaterThan(tester.getTopRight(find.text('진행 중인 투표')).dx - 1),
      );
      expect(tester.getSize(find.byType(SmashButton)).height, greaterThanOrEqualTo(48));
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('긴 제목 + 오른쪽 동작이 글자 $scale배에서도 넘치지 않는다', (tester) async {
        await tester.pumpWidget(smashHarness(
          SmashSectionHeader(
            title: '이번 달에 참여하지 못한 날을 이월로 채울 수 있는 활동 목록',
            trailing: SmashButton(
              label: '전체 보기',
              variant: SmashButtonVariant.text,
              size: SmashButtonSize.medium,
              expanded: false,
              onPressed: () {},
            ),
          ),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('expanded: true(기본값) 버튼을 trailing에 넣어도 예외 없이 그려지고 글자 폭만 차지한다 (글자 $scale배)', (tester) async {
        await tester.pumpWidget(smashHarness(
          SmashSectionHeader(
            title: '진행 중인 투표',
            trailing: SmashButton(label: '전체 보기', variant: SmashButtonVariant.text, onPressed: () {}),
          ),
          textScale: scale,
        ));

        expect(tester.takeException(), isNull);
        final button = tester.getSize(find.byType(SmashButton)).width;
        expect(button, lessThan(160 * scale), reason: '버튼이 줄 전체로 퍼지지 않는다');
        // 제목도 자리를 잃지 않고 보인다
        expect(tester.getSize(find.text('진행 중인 투표')).width, greaterThan(0));
        expect(
          tester.getTopRight(find.byType(SmashButton)).dx,
          lessThanOrEqualTo(tester.getTopRight(find.byType(SmashSectionHeader)).dx),
        );
      });
    }
  });

  group('SmashPanel', () {
    testWidgets('onTap이 있으면 눌리고 버튼으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(smashHarness(
        SmashPanel(onTap: () => taps++, child: const Text('오늘 활동')),
      ));

      await tester.tap(find.text('오늘 활동'));
      await tester.pump();

      expect(taps, 1);
      expect(semanticsOf(tester, find.byType(SmashPanel)).flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('onTap이 없으면 눌림 모양도 버튼 역할도 없다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(const SmashPanel(child: Text('안내'))));

      expect(find.byType(SmashPressable), findsNothing);
      expect(semanticsOf(tester, find.byType(SmashPanel)).flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('filled 안의 글자와 아이콘 기본색은 브랜드 위 흰색이다', (tester) async {
      await tester.pumpWidget(smashHarness(
        const SmashPanel(
          variant: SmashPanelVariant.filled,
          child: Row(children: [Icon(Icons.event), Text('오늘 활동')]),
        ),
      ));

      final context = tester.element(find.text('오늘 활동'));
      expect(DefaultTextStyle.of(context).style.color, SmashColors.onBrand);
      expect(IconTheme.of(context).color, SmashColors.onBrand);
    });

    testWidgets('outlined, tinted 안의 기본 글자색은 본문색이다', (tester) async {
      for (final variant in [SmashPanelVariant.outlined, SmashPanelVariant.tinted]) {
        await tester.pumpWidget(smashHarness(SmashPanel(variant: variant, child: const Text('안내'))));
        expect(
          DefaultTextStyle.of(tester.element(find.text('안내'))).style.color,
          SmashColors.text,
          reason: '$variant',
        );
      }
    });

    test('variant별 글자 대비가 4.5 이상이다', () {
      expect(contrastRatio(SmashColors.onBrand, SmashColors.brand), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.onBrand, SmashColors.brandPressed), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.text, SmashColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.text, SmashColors.brandTintSoft), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(SmashColors.text, SmashColors.brandTint), greaterThanOrEqualTo(4.5));
    });

    testWidgets('글자 2.0배에서 안의 글자가 길어도 면이 늘어나며 넘치지 않는다', (tester) async {
      await tester.pumpWidget(smashHarness(
        SmashPanel(onTap: () {}, child: Text('이번 달에 참여하지 못한 날이 2일 있어요 ' * 3)),
        textScale: 2.0,
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('SmashAvatar', () {
    test('initialOf: 첫 글자, 공백 제거, 비어 있으면 null', () {
      expect(SmashAvatar.initialOf('김민수'), '김');
      expect(SmashAvatar.initialOf('  이서연 '), '이');
      expect(SmashAvatar.initialOf('Alex'), 'A');
      expect(SmashAvatar.initialOf('   '), isNull);
      expect(SmashAvatar.initialOf(''), isNull);
      // 코드 유닛이 아니라 한 글자 단위로 자른다 (깨진 글자가 나오지 않는다)
      expect(SmashAvatar.initialOf('👨‍👩‍👧 가족'), '👨‍👩‍👧');
    });

    testWidgets('이름 첫 글자를 보여주고 이름이 비면 사람 아이콘을 보여준다', (tester) async {
      await tester.pumpWidget(smashHarness(const SmashAvatar(name: '김민수')));
      expect(find.text('김'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);

      await tester.pumpWidget(smashHarness(const SmashAvatar(name: ' ')));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('크기는 size 그대로이고 글자 확대를 따라가지 않는다', (tester) async {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(smashHarness(
          const Align(child: SmashAvatar(name: '김민수', size: 40)), // 하네스의 강제 폭에서 풀어 준다
          textScale: scale,
        ));
        expect(tester.getSize(find.byType(SmashAvatar)), const Size.square(40), reason: '$scale');
        expect(tester.takeException(), isNull);
        final context = tester.element(find.text('김'));
        expect(MediaQuery.textScalerOf(context), TextScaler.noScaling, reason: '$scale');
      }
    });

    testWidgets('스크린리더는 읽지 않는다 (이름은 옆에 글자로 있다)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(smashHarness(
        const Row(children: [SmashAvatar(name: '김민수'), Text('김민수')]),
      ));

      expect(find.bySemanticsLabel('김'), findsNothing);
      expect(find.bySemanticsLabel('김민수'), findsOneWidget);
      handle.dispose();
    });

    test('글자 대비가 4.5 이상이다', () {
      expect(contrastRatio(SmashColors.brand, SmashColors.brandTint), greaterThanOrEqualTo(4.5));
    });
  });
}
