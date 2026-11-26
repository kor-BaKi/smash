import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/model/auth_model.dart';
import '../../features/home/page/admin_menu_page.dart';
import '../../features/home/page/home_need_group_notice.dart';
import '../../features/home/page/home_page.dart';
import '../../features/home/page/legacy_tab_frame.dart';
import '../../features/home/page/schedule_tab.dart';
import '../../features/home/provider/auth_provider.dart';
import 'fake_auth.dart';
import 'screen_entry.dart';

/// 갤러리에서 처음 선택할 탭 (상태마다 다르게 덮어쓴다)
final _initialTabProvider = Provider<HomeTab>((ref) => HomeTab.home);

/// 일정 탭에서 처음 보일 것 (달력 또는 투표)
final _initialViewProvider = Provider<ScheduleView>(
  (ref) => ScheduleView.calendar,
);

/// 옛 화면(어두운 화면, 자기 Scaffold와 AppBar)을 흉내 낸 임시 화면.
/// 홈 셸 안에서 옛 화면이 어떻게 보이는지 확인하려는 것이고, 화면이 새 디자인으로 바뀌면(S3b~S8) 필요 없어진다.
class _OldStylePage extends StatelessWidget {
  const _OldStylePage(this.title, {this.withAppBar = true, this.actions});

  final String title;

  /// 옛 투표 화면처럼 자기 앱바(제목, 임원의 + 버튼)를 가진 모양인지. 옛 달력 화면은 앱바가 없고 머리글만 있다
  final bool withAppBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: withAppBar ? AppBar(title: Text(title), actions: actions) : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!withAppBar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          for (var i = 1; i <= 8; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$title 옛 화면 카드 $i',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// 내 정보 탭 안쪽 흉내: 눌러서 역할(운영진/부원)을 바꿔 탭이 4개에서 3개로(또는 반대로) 바뀌는 것을 볼 수 있다
class _RoleSwitchPage extends ConsumerWidget {
  const _RoleSwitchPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final auth = ref.read(authProvider.notifier) as FakeAuthNotifier;
            auth.setUser(
              isAdmin ? FakeAuthNotifier.fakeUser : FakeAuthNotifier.fakeAdmin,
            );
          },
          child: Text(isAdmin ? '부원으로 바꾸기' : '운영진으로 바꾸기'),
        ),
      ),
    );
  }
}

/// 실제 운영 메뉴와 같은 구역, 같은 항목, 같은 순서이고 누르면 임시 화면이 열린다 (서버 없이 보려는 것)
final List<AdminMenuSection> _stubAdminSections = [
  for (final section in adminMenuSections)
    AdminMenuSection(
      title: section.title,
      items: [
        for (final item in section.items)
          AdminMenuItem(
            icon: item.icon,
            label: item.label,
            builder: (_) => _OldStylePage(item.label),
          ),
      ],
    ),
];

Widget _galleryTab(BuildContext context, HomeTab tab, UserInfo user) {
  return switch (tab) {
    HomeTab.home => LegacyTabFrame(
      child: user.groupId == null
          ? NeedGroupNotice(isAdmin: user.isAdmin)
          : const _OldStylePage('홈', withAppBar: false),
    ),
    HomeTab.schedule => ScheduleTab(
      initialView: ProviderScope.containerOf(
        context,
      ).read(_initialViewProvider),
      calendarBuilder: (_) => const _OldStylePage('캘린더', withAppBar: false),
      pollsBuilder: (_) => _OldStylePage(
        '투표',
        actions: user.isAdmin
            ? [IconButton(icon: const Icon(Icons.add), onPressed: () {})]
            : null,
      ),
    ),
    HomeTab.admin => AdminMenuPage(customSections: _stubAdminSections),
    HomeTab.profile => const LegacyTabFrame(child: _RoleSwitchPage()),
  };
}

List<Override> _overrides(
  UserInfo user,
  HomeTab tab, {
  ScheduleView view = ScheduleView.calendar,
}) => [
  authProvider.overrideWith(
    (ref) => FakeAuthNotifier(initial: AuthState(user: user)),
  ),
  _initialTabProvider.overrideWithValue(tab),
  _initialViewProvider.overrideWithValue(view),
];

final homeShellScreenEntry = ScreenEntry(
  name: '홈 셸 (S3a-1b)',
  description:
      '하단 탭(부원은 홈, 일정, 내 정보 / 운영진은 홈, 일정, 운영, 내 정보). 일정 탭은 달력 | 투표 전환. 탭 안쪽 화면은 옛 화면을 흉내 낸 임시 화면이다 (S3b~S8에서 교체)',
  path: '/home',
  // 실제 앱처럼 앱 전체 테마는 옛 어두운 테마다
  builder: (_) => Theme(
    data: AppTheme.dark(),
    child: Consumer(
      builder: (context, ref, _) => HomePage(
        initialTab: ref.watch(_initialTabProvider),
        tabBuilder: _galleryTab,
      ),
    ),
  ),
  stubPaths: const ['/login'],
  states: [
    ScreenState(
      '부원 홈 탭 (탭 3개, 조 미배정 안내)',
      overrides: _overrides(FakeAuthNotifier.fakeUser, HomeTab.home),
    ),
    ScreenState(
      '부원 일정 탭: 달력 (옛 화면 흉내)',
      overrides: _overrides(FakeAuthNotifier.fakeUser, HomeTab.schedule),
    ),
    ScreenState(
      '부원 일정 탭: 투표 (옛 화면 흉내: 자기 앱바가 겹침)',
      overrides: _overrides(
        FakeAuthNotifier.fakeUser,
        HomeTab.schedule,
        view: ScheduleView.polls,
      ),
    ),
    ScreenState(
      '임원 홈 탭 (탭 4개)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.home),
    ),
    ScreenState(
      '임원 운영 탭 (10개 항목)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.admin),
    ),
    ScreenState(
      '내 정보 탭 (옛 설정 화면 흉내)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.profile),
    ),
    ScreenState(
      '직접 눌러 보기 (내 정보 탭에서 역할 바꾸기)',
      hint:
          '운영 탭을 선택한 채로 내 정보 탭을 눌러 "부원으로 바꾸기"를 누르면 탭이 4개에서 3개로 바뀌고 내 정보 탭이 그대로 선택되어 있는지, 일정 탭에서 달력 | 투표를 눌러 보세요',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.admin),
    ),
  ],
);
