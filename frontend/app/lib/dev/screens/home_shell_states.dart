import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/model/auth_model.dart';
import '../../features/home/page/admin_menu_page.dart';
import '../../features/home/page/home_need_group_notice.dart';
import '../../features/home/page/home_page.dart';
import '../../features/home/page/legacy_tab_frame.dart';
import '../../features/home/provider/auth_provider.dart';
import 'fake_auth.dart';
import 'screen_entry.dart';

/// 갤러리에서 처음 선택할 탭 (상태마다 다르게 덮어쓴다)
final _initialTabProvider = Provider<HomeTab>((ref) => HomeTab.home);

/// 옛 화면(어두운 화면, 자기 Scaffold와 AppBar)을 흉내 낸 임시 탭 내용.
/// 홈 셸 안에서 옛 화면이 어떻게 보이는지 확인하려는 것이고, 탭 화면이 새 디자인으로 바뀌면(S3~S6) 필요 없어진다.
class _OldStylePage extends StatelessWidget {
  const _OldStylePage(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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

/// 설정 탭 흉내: 눌러서 역할(운영진/회원)을 바꿔 탭이 5개에서 4개로(또는 반대로) 바뀌는 것을 볼 수 있다
class _RoleSwitchPage extends ConsumerWidget {
  const _RoleSwitchPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final auth = ref.read(authProvider.notifier) as FakeAuthNotifier;
            auth.setUser(
              isAdmin ? FakeAuthNotifier.fakeUser : FakeAuthNotifier.fakeAdmin,
            );
          },
          child: Text(isAdmin ? '회원으로 바꾸기' : '운영진으로 바꾸기'),
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
          : const _OldStylePage('홈'),
    ),
    HomeTab.polls => const LegacyTabFrame(child: _OldStylePage('투표')),
    HomeTab.calendar => const LegacyTabFrame(child: _OldStylePage('달력')),
    HomeTab.settings => const LegacyTabFrame(child: _RoleSwitchPage()),
    HomeTab.admin => AdminMenuPage(customSections: _stubAdminSections),
  };
}

List<Override> _overrides(UserInfo user, HomeTab tab) => [
  authProvider.overrideWith(
    (ref) => FakeAuthNotifier(initial: AuthState(user: user)),
  ),
  _initialTabProvider.overrideWithValue(tab),
];

final homeShellScreenEntry = ScreenEntry(
  name: '홈 셸 (S2b)',
  description:
      '하단 탭(홈, 투표, 달력, 설정, 운영진은 운영). 탭 안쪽 화면은 옛 화면을 흉내 낸 임시 화면이다 (S3~S6에서 교체)',
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
      '회원 홈 탭 (4탭, 조 미배정 안내)',
      overrides: _overrides(FakeAuthNotifier.fakeUser, HomeTab.home),
    ),
    ScreenState(
      '회원 투표 탭 (옛 화면 흉내: 자기 AppBar)',
      overrides: _overrides(FakeAuthNotifier.fakeUser, HomeTab.polls),
    ),
    ScreenState(
      '운영진 홈 탭 (5탭)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.home),
    ),
    ScreenState(
      '운영진 운영 탭 (10개 항목)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.admin),
    ),
    ScreenState(
      '운영진 설정 탭 (옛 화면 흉내: 자기 Scaffold와 AppBar)',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.settings),
    ),
    ScreenState(
      '직접 눌러 보기 (설정 탭에서 역할 바꾸기)',
      hint:
          '운영 탭을 선택한 채로 설정 탭에서 "회원으로 바꾸기"를 눌러 탭이 5개에서 4개로 바뀌고 홈으로 돌아가는지, 키보드 올린 모양에서 탭 막대가 숨는지 확인해 보세요',
      overrides: _overrides(FakeAuthNotifier.fakeAdmin, HomeTab.settings),
    ),
  ],
);
