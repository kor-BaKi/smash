import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/page/admin_activity_page.dart';
import '../../activity/page/today_activity_page.dart';
import '../../assignment/page/assignment_page.dart';
import '../../attendance/page/attendance_page.dart';
import '../../auth/model/auth_user.dart';
import '../../auth/page/login_page.dart';
import '../../auth/provider/auth_controller.dart';
import '../../availability/page/availability_page.dart';
import '../../group/page/group_page.dart';
import '../../invite/page/invite_code_page.dart';
import '../../schedule/page/activity_schedule_page.dart';
import '../../statistics/page/statistics_page.dart';

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

// 로그인한 user.role에 따라 임원/부원 홈으로 분기. 각 화면의 실제 내용은 이후 단계(조 배정,
// 투표/이월, 출석현황)에서 채워나간다.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 정보가 없습니다.')),
      );
    }

    return user.role == UserRole.admin
        ? _AdminHome(user: user, ref: ref)
        : _MemberHome(user: user, ref: ref);
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user, required this.ref});

  final AuthUser user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('임원 홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${user.name}님, 환영합니다 (ADMIN)'),
          ),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('조 관리'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GroupPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('가입코드 관리'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InviteCodePage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('정규활동 일정 관리'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivitySchedulePage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('조 배정'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AssignmentPage())),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('활동 관리'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdminActivityPage())),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('출석 현황'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AttendancePage())),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('통계'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatisticsPage())),
          ),
        ],
      ),
    );
  }
}

class _MemberHome extends StatelessWidget {
  const _MemberHome({required this.user, required this.ref});

  final AuthUser user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부원 홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${user.name}님, 환영합니다 (MEMBER)'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('가능요일 제출'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AvailabilityPage())),
          ),
          ListTile(
            leading: const Icon(Icons.how_to_vote),
            title: const Text('오늘의 투표'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TodayActivityPage())),
          ),
        ],
      ),
    );
  }
}
