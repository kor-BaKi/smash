import 'package:app/features/auth/page/login_page.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/page/signup_page.dart';
import 'features/home/provider/auth_provider.dart';

/// 로그인 여부가 바뀔 때 라우터에게 알린다. 라우터를 다시 만들지 않고 redirect만 다시 돌리게 하려는 것이다.
class _AuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

// 라우터는 앱이 사는 동안 한 번만 만든다. 로그인 여부가 바뀌면 _AuthRefresh가 알려서 지금 위치에 redirect만 다시 적용한다
// (라우터를 새로 만들면 쌓아 둔 화면과 위치가 사라지고 시작 경로 /login으로 돌아간다).
// redirect가 읽는 값은 로그인 여부뿐이다.
final routerProvider = Provider<GoRouter>((ref) {
  // ref : riberpod의 모든 Provider에게 접근할 수 있는 통로
  // ref.listen(provider) : 값이 바뀔 때 함수를 부른다 (이 Provider를 다시 만들지는 않는다)
  // ref.read(provider) : 지금 값을 한 번 읽는다
  final refresh = _AuthRefresh();
  ref.listen<bool>(
    authProvider.select((state) => state.isLoggedIn),
    (previous, next) => refresh.notify(),
  );

  final router = GoRouter(
    initialLocation: '/login', // 앱 처음 실행 시 보여줄 경로
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final location = state.matchedLocation;
      final isLoginPage = location == '/login';
      // 가입은 3단계 경로(/signup, /signup/id, /signup/password)다
      final isSignupPage =
          location == signupCodePath || location.startsWith('$signupCodePath/');

      if (!isLoggedIn && !isLoginPage && !isSignupPage) return '/login';
      // 로그인하거나 가입에 성공하면 로그인, 가입 화면에서 홈으로 보낸다
      if (isLoggedIn && (isLoginPage || isSignupPage)) return '/home';
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
      ...signupRoutes(),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class SmashApp extends ConsumerWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SMASH',
      theme: AppTheme.dark(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
