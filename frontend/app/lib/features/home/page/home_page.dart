import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
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
          ? const _NeedGroupNotice()
          : const MemberHomeView(),
    );
  }
}

class _NeedGroupNotice extends StatelessWidget {
  const _NeedGroupNotice();

  @override
  Widget build(BuildContext context) {
    // 조 미배정 상태 (가능 요일 제출 화면은 별도 라우트로 이미 처리 중이므로
    // 여기서는 안내만 표시. 라우팅에서 이미 걸러지는 케이스.
    return const Center(child: Text('조 배정을 기다리는 중입니다.'));
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
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.bar_chart,
              label: '출석 현황',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.auto_awesome,
              label: '자동 배정',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.person_add,
              label: '합격자 등록',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.vpn_key,
              label: '가입코드 관리',
              onTap: () => Navigator.pop(context),
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
