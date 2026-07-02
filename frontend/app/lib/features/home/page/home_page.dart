import 'package:app/features/home/page/availability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import 'member_home_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // ref : riberpod의 모든 Provider에게 접근할 수 있는 통로
  // ref.watch(provider) : 상태를 구독. 그 상태가 바뀌면 이 위젯이 자동으로 다시 빌드
  // ref.read(provider.notifier) : 상태를 구독하지 않고 메서드만 호출. 버튼 클릭 같은 이벤트 핸들러 안에서 사용
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
              // 로그아웃 메서드만 실행, 구독 안 함
            },
          ),
        ],
      ),
      body: user.isAdmin
          ? const Center(child: Text('임원 홈 (준비 중)'))
          : user.groupId == null
          ? const AvailabilityPage()
          : const MemberHomeView(),
    );
  }
}
