import 'package:app/features/home/page/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import 'activity_admin_page.dart';
import 'applicant_page.dart';
import 'assignment_page.dart';
import 'attendance_page.dart';
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
      appBar: AppBar(
        title: Text('${user.name}님'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      // 임원만 사이드 메뉴 노출
      drawer: user.isAdmin ? const _AdminDrawer() : null,
      body: user.groupId == null
          ? _NeedGroupNotice(isAdmin: user.isAdmin)
          : const MemberHomeView(),
    );
  }
}

class _NeedGroupNotice extends StatelessWidget {
  const _NeedGroupNotice({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('조 배정을 기다리는 중입니다.'),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              '왼쪽 상단 메뉴에서 운영 기능을 이용할 수 있습니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text(
                '임원 메뉴',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.groups,
              label: '조 편성 관리',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupManagementPage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.bar_chart,
              label: '출석 현황',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendancePage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.event_available,
              label: '정규활동 일정',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SchedulePage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.calendar_month,
              label: '날짜별 활동 관리',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityAdminPage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.auto_awesome,
              label: '자동 배정',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignmentPage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.person_add,
              label: '지원자 관리',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplicantPage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.vpn_key,
              label: '가입코드 관리',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InviteCodePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
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
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
