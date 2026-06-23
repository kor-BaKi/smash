import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/admin_activity_screen.dart';
import '../activity/today_activity_screen.dart';
import '../assignment/assignment_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_user.dart';
import '../availability/availability_screen.dart';
import '../group/group_screen.dart';
import '../invite/invite_code_screen.dart';
import '../schedule/activity_schedule_screen.dart';

// 로그인한 user.role에 따라 임원/부원 홈으로 분기. 각 화면의 실제 내용은 이후 단계(조 배정,
// 투표/이월, 출석현황)에서 채워나간다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 정보가 없습니다.')),
      );
    }

    return user.role == UserRole.admin
        ? _AdminHome(user: user)
        : _MemberHome(user: user);
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('임원 홈')),
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
                builder: (_) => const GroupScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('가입코드 관리'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InviteCodeScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('정규활동 일정 관리'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivityScheduleScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('조 배정'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AssignmentScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('활동 관리'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdminActivityScreen())),
          ),
        ],
      ),
    );
  }
}

class _MemberHome extends StatelessWidget {
  const _MemberHome({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부원 홈')),
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
                .push(MaterialPageRoute(builder: (_) => const AvailabilityScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.how_to_vote),
            title: const Text('오늘의 투표'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TodayActivityScreen())),
          ),
        ],
      ),
    );
  }
}
