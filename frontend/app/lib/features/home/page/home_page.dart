import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/components.dart';
import '../../auth/model/auth_model.dart';
import '../provider/auth_provider.dart';
import 'admin_menu_page.dart';
import 'calendar_tab_page.dart';
import 'home_need_group_notice.dart';
import 'legacy_tab_frame.dart';
import 'member_home_view.dart';
import 'poll_list_page.dart';
import 'setting_page.dart';

/// 홈 하단 탭. 운영진은 "운영" 탭이 하나 더 있다 (마지막).
enum HomeTab {
  home('홈', Icons.home_outlined, Icons.home),
  polls('투표', Icons.how_to_vote_outlined, Icons.how_to_vote),
  calendar('달력', Icons.calendar_month_outlined, Icons.calendar_month),
  settings('설정', Icons.settings_outlined, Icons.settings),
  admin('운영', Icons.shield_outlined, Icons.shield);

  const HomeTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  SmashNavDestination get destination =>
      SmashNavDestination(label: label, icon: icon, selectedIcon: selectedIcon);
}

/// 역할에 따른 탭 목록: 회원 4개, 운영진 5개
List<HomeTab> homeTabsFor({required bool isAdmin}) => [
  HomeTab.home,
  HomeTab.polls,
  HomeTab.calendar,
  HomeTab.settings,
  if (isAdmin) HomeTab.admin,
];

/// 탭 하나의 내용을 만든다 (기본은 [buildHomeTab])
typedef HomeTabBuilder =
    Widget Function(BuildContext context, HomeTab tab, UserInfo user);

/// 탭 안쪽 화면. 홈, 투표, 달력, 설정 화면은 아직 옛 디자인(어두운 화면, 자기 Scaffold)이고 S3~S6에서 교체한다.
Widget buildHomeTab(BuildContext context, HomeTab tab, UserInfo user) {
  return switch (tab) {
    HomeTab.home => LegacyTabFrame(
      child: user.groupId == null
          ? NeedGroupNotice(isAdmin: user.isAdmin)
          : const MemberHomeView(),
    ),
    HomeTab.polls => const LegacyTabFrame(child: PollListPage()),
    HomeTab.calendar => const LegacyTabFrame(child: CalendarTabPage()),
    HomeTab.settings => const LegacyTabFrame(child: SettingPage()),
    HomeTab.admin => const AdminMenuPage(),
  };
}

/// 로그인한 뒤의 첫 화면: 하단 탭이 있는 앱 셸.
///
/// - 탭 전환은 지금 탭의 내용만 새로 만든다 (다른 탭으로 갔다 오면 처음부터 다시 불러온다. 탭 상태를 유지하지 않는다)
/// - 선택한 탭은 종류로 기억한다. 역할이 바뀌어 탭 목록에서 사라지면(운영진 → 회원) 홈으로 돌아간다
/// - 키보드가 올라오면 탭 막대를 숨긴다
class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.initialTab = HomeTab.home,
    this.tabBuilder = buildHomeTab,
  });

  /// 처음에 선택된 탭 (갤러리와 테스트에서 정한다)
  final HomeTab initialTab;

  /// 탭 내용 만들기 (테스트와 갤러리에서 가짜 화면으로 바꿔 끼울 때만 넘긴다)
  final HomeTabBuilder tabBuilder;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late HomeTab _selected = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    if (user == null) {
      return const SmashScaffold(body: Center(child: SmashLabel('로그인이 필요합니다')));
    }

    final tabs = homeTabsFor(isAdmin: user.isAdmin);
    // 선택한 탭이 목록에서 사라졌으면(운영진 → 회원) 홈으로 돌아간다
    if (!tabs.contains(_selected)) _selected = HomeTab.home;

    return SmashTabShell(
      destinations: [for (final tab in tabs) tab.destination],
      selectedIndex: tabs.indexOf(_selected),
      onSelected: (index) => setState(() => _selected = tabs[index]),
      body: KeyedSubtree(
        key: ValueKey(_selected),
        child: widget.tabBuilder(context, _selected, user),
      ),
    );
  }
}
