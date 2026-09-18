import 'package:app/features/home/page/poll_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';
import 'activity_admin_page.dart';
import 'application_form_page.dart';
import 'application_list_page.dart';
import 'availability_page.dart';
import 'calendar_tab_page.dart';
import 'dues_page.dart';
import 'free_period_page.dart';
import 'invite_code_page.dart';
import 'member_home_view.dart';
import 'member_management_page.dart';
import 'schedule_page.dart';
import 'setting_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    final pages = [
      user.groupId == null
          ? _NeedGroupNotice(isAdmin: user.isAdmin)
          : const MemberHomeView(),
      const PollListPage(),
      const CalendarTabPage(),
      const SettingPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: user.isAdmin ? const _AdminDrawer() : null,
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.how_to_vote_outlined,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? AppColors.onPrimary : AppColors.darkGray,
        ),
      ),
    );
  }
}

class _NeedGroupNotice extends StatelessWidget {
  const _NeedGroupNotice({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 32,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '아직 조가 배정되지 않았어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? '왼쪽 상단 메뉴에서 운영 기능을 이용할 수 있습니다.'
                  : '참여 가능한 요일을 먼저 제출해주세요.',
              style: const TextStyle(fontSize: 14, color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvailabilityPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '가능 요일 제출하기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends ConsumerWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.name.substring(0, 1) ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '임원',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lime,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                children: [
                  _sectionLabel('회원 운영'),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: '부원 관리',
                    onTap: () => _push(context, const MemberManagementPage()),
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    label: '지원서 관리',
                    onTap: () => _push(context, const ApplicationListPage()),
                  ),
                  _DrawerItem(
                    icon: Icons.edit_document,
                    label: '지원 폼 관리',
                    onTap: () => _push(context, const ApplicationFormPage()),
                  ),
                  _DrawerItem(
                    icon: Icons.key_outlined,
                    label: '가입코드 관리',
                    onTap: () => _push(context, const InviteCodePage()),
                  ),
                  _sectionLabel('활동 운영'),
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: '정규활동 일정',
                    onTap: () => _push(context, const SchedulePage()),
                  ),
                  _DrawerItem(
                    icon: Icons.event_note_outlined,
                    label: '날짜별 활동 관리',
                    onTap: () => _push(context, const ActivityAdminPage()),
                  ),
                  _DrawerItem(
                    icon: Icons.sports_tennis_outlined,
                    label: '자유활동 기간 설정',
                    onTap: () => _push(context, const FreePeriodPage()),
                  ),
                  _sectionLabel('재정 운영'),
                  _DrawerItem(
                    icon: Icons.wallet_outlined,
                    label: '회비 관리',
                    onTap: () => _push(context, const DuesPage()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGray,
        letterSpacing: 0.08,
      ),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
