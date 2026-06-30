import 'package:app/features/auth/page/login_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/provider/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  // ref : riberpod의 모든 Provider에게 접근할 수 있는 통로
  // ref.watch(provider) : 상태를 구독. 그 상태가 바뀌면 이 위젯이 자동으로 다시 빌드
  // ref.read(provider.notifier) : 상태를 구독하지 않고 메서드만 호출. 버튼 클릭 같은 이벤트 핸들러 안에서 사용

  return GoRouter(
    initialLocation: '/login', // 앱 처음 실행 시 보여줄 경로
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});

class SmashApp extends ConsumerWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SMASH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
