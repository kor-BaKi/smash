import 'package:app/features/home/page/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/provider/auth_provider.dart';
import 'activity_admin_page.dart';
import 'applicant_page.dart';
import 'assignment_page.dart';
import 'availability_page.dart';
import 'free_period_page.dart';
import 'group_management_page.dart';
import 'invite_code_page.dart';
import 'member_home_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: user.isAdmin ? const _AdminDrawer() : null,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 인사말 카드
            Container(
              width: double.infinity,
              color: AppColors.cardBg,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => user.isAdmin
                        ? IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                Scaffold.of(context).openDrawer(),
                            padding: EdgeInsets.zero,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          fontFamily: 'Pretendard',
                        ),
                        children: [
                          const TextSpan(text: '안녕하세요, '),
                          TextSpan(
                            text: user.name,
                            style: const TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: '님'),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: user.groupId == null
                  ? _NeedGroupNotice(isAdmin: user.isAdmin)
                  : const MemberHomeView(),
            ),
          ],
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
            const Text(
              '아직 조가 배정되지 않았어요.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (isAdmin) ...[
              Text(
                '왼쪽 상단 메뉴에서 운영 기능을 이용할 수 있습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                '참여 가능한 요일을 제출해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AvailabilityPage(),
                    ),
                  );
                },
                child: const Text('가능 요일 제출하기'),
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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Drawer(
      backgroundColor: AppColors.cardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/icon/logo_transparent.png',
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '임원',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.neutralBg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                children: [
                  _sectionLabel('모집 관리'),
                  _DrawerItem(
                    icon: '🎟️',
                    label: '가입코드 관리',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InviteCodePage(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: '📋',
                    label: '지원자 관리',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApplicantPage(),
                        ),
                      );
                    },
                  ),
                  _sectionLabel('조 편성'),
                  _DrawerItem(
                    icon: '👥',
                    label: '조 편성 관리',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GroupManagementPage(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: '⚡',
                    label: '자동 배정',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssignmentPage(),
                        ),
                      );
                    },
                  ),
                  _sectionLabel('활동 운영'),
                  _DrawerItem(
                    icon: '🗓️',
                    label: '정규활동 일정',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SchedulePage(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: '📅',
                    label: '날짜별 활동 관리',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActivityAdminPage(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: '🏸',
                    label: '자유활동 기간 설정',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FreePeriodPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  final String icon;
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
