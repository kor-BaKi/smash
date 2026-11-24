import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/home/page/admin_menu_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump.dart';
import '../../support/screen_pump.dart';

/// 운영 탭 화면: 이전 Drawer와 같은 구역, 같은 항목, 같은 순서(10개)이고 누르면 화면이 위에 쌓인다
void main() {
  setUpAll(loadPretendard);

  /// 이전 Drawer의 항목 (home_page.dart의 _AdminDrawer): 구역 → 항목
  const drawerOrder = {
    '회원 운영': ['부원 관리', '조 편성 관리', '지원서 관리', '지원 폼 관리', '가입코드 관리'],
    '활동 운영': ['정규활동 일정', '날짜별 활동 관리', '출석 현황', '자유활동 기간 설정'],
    '재정 운영': ['회비 관리'],
  };

  test('구역 이름과 항목 이름, 순서가 이전 Drawer와 같다 (10개)', () {
    expect(
      adminMenuSections.map((s) => s.title).toList(),
      drawerOrder.keys.toList(),
    );
    for (final section in adminMenuSections) {
      expect(
        section.items.map((i) => i.label).toList(),
        drawerOrder[section.title],
        reason: section.title,
      );
    }
    expect(adminMenuSections.expand((s) => s.items).length, 10);
  });

  test('항목마다 아이콘이 있고 이전 Drawer와 같은 아이콘이다', () {
    final icons = adminMenuSections
        .expand((s) => s.items)
        .map((i) => i.icon)
        .toList();
    expect(icons, [
      Icons.person_outline,
      Icons.groups_outlined,
      Icons.assignment_outlined,
      Icons.edit_document,
      Icons.key_outlined,
      Icons.calendar_month_outlined,
      Icons.event_note_outlined,
      Icons.fact_check_outlined,
      Icons.sports_tennis_outlined,
      Icons.wallet_outlined,
    ]);
  });

  Future<void> show(
    WidgetTester tester, {
    List<AdminMenuSection>? sections,
    double width = 360,
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      smashHarness(
        AdminMenuPage(customSections: sections),
        textScale: scale,
        width: width,
      ),
    );
    await tester.pumpAndSettle();
  }

  final stub = [
    AdminMenuSection(
      title: '가 구역',
      items: [
        AdminMenuItem(
          icon: Icons.person_outline,
          label: '첫째',
          builder: (_) => const Scaffold(body: Text('PAGE-1')),
        ),
        AdminMenuItem(
          icon: Icons.groups_outlined,
          label: '둘째',
          builder: (_) => const Scaffold(body: Text('PAGE-2')),
        ),
      ],
    ),
  ];

  testWidgets('제목 운영과 구역 이름, 항목이 순서대로 보인다', (tester) async {
    await show(tester, sections: stub);
    expect(find.text('운영'), findsOneWidget);
    expect(find.text('가 구역'), findsOneWidget);
    final first = tester.getTopLeft(find.text('첫째')).dy;
    final second = tester.getTopLeft(find.text('둘째')).dy;
    expect(first, lessThan(second));
  });

  testWidgets('항목을 누르면 그 화면이 위에 쌓이고, 뒤로 가면 운영 화면으로 돌아온다', (tester) async {
    await show(tester, sections: stub);
    await tester.tap(find.text('둘째'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE-2'), findsOneWidget);
    expect(find.text('PAGE-1'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('PAGE-2'), findsNothing);
    expect(find.text('둘째'), findsOneWidget);
  });

  testWidgets('항목 줄은 높이 56 이상이고 글자 2.0배, 폭 320에서도 넘치지 않는다', (tester) async {
    await show(tester, width: 320, scale: 2.0);
    for (final row in find.byType(SmashListRow).evaluate()) {
      final rect = tester.getRect(find.byWidget(row.widget));
      expect(rect.height, greaterThanOrEqualTo(56));
      expect(rect.right, lessThanOrEqualTo(320.5));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('스크린리더: 제목과 구역 이름은 제목으로, 항목 아이콘은 읽지 않는다', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, sections: stub);
    expect(
      tester.getSemantics(find.text('운영')).flagsCollection.isHeader,
      isTrue,
    );
    expect(
      tester.getSemantics(find.text('가 구역')).flagsCollection.isHeader,
      isTrue,
    );
    expect(find.bySemanticsLabel('첫째'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('앱 전체 테마가 어두워도(옛 앱 테마) 운영 화면은 밝은 SMASH 테마를 쓴다', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      smashHarness(
        Theme(
          data: AppTheme.dark(),
          child: AdminMenuPage(customSections: stub),
        ),
        width: 360,
      ),
    );
    await tester.pumpAndSettle();

    final inner = tester.element(find.byType(SmashListRow).first);
    expect(Theme.of(inner).brightness, Brightness.light);
    expect(Theme.of(inner).colorScheme.primary, SmashColors.brand);
  });

  testWidgets('항목 10개가 모두 스크롤로 닿는다', (tester) async {
    await show(tester);
    for (final label in drawerOrder.values.expand((l) => l)) {
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });
}
