import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_user.dart';

// 로그인한 user.role에 따라 임원/부원 홈으로 분기. 각 화면의 실제 내용은 이후 단계(조 배정,
// 투표/이월, 출석현황)에서 채워나간다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인 정보가 없습니다.')));
    }

    return user.role == UserRole.admin ? _AdminHome(user: user) : _MemberHome(user: user);
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('임원 홈')),
      body: Center(child: Text('${user.name}님, 환영합니다 (ADMIN)')),
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
      body: Center(child: Text('${user.name}님, 환영합니다 (MEMBER)')),
    );
  }
}
