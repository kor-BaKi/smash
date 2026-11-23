import 'package:app/app.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 로그인 화면은 성공해도 직접 이동하지 않고, 앱의 라우터 redirect가 /home으로 보낸다.
/// 실제 `routerProvider`(app.dart)의 redirect를 가짜 인증 상태로 그대로 돌려 본다 (화면은 그리지 않는다).
void main() {
  Future<String> resolve(
    WidgetTester tester,
    AuthState auth,
    String location,
  ) async {
    late GoRouter router;
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(initial: auth)),
        ],
        child: Consumer(
          builder: (ctx, ref, _) {
            router = ref.watch(routerProvider);
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    final matches = await router.routeInformationParser
        .parseRouteInformationWithDependencies(
          RouteInformation(
            uri: Uri.parse(location),
            state: RouteInformationState<void>(type: NavigatingType.go),
          ),
          context,
        );
    return matches.uri.path;
  }

  final loggedIn = AuthState(user: FakeAuthNotifier.fakeUser);
  const loggedOut = AuthState();

  testWidgets('로그인한 사용자가 /login에 있으면 /home으로 보낸다', (tester) async {
    expect(await resolve(tester, loggedIn, '/login'), '/home');
  });

  testWidgets('로그인하지 않았으면 /login과 /signup은 그대로 열린다', (tester) async {
    expect(await resolve(tester, loggedOut, '/login'), '/login');
    expect(await resolve(tester, loggedOut, '/signup'), '/signup');
  });

  testWidgets('로그인하지 않았으면 /home은 /login으로 돌려보낸다', (tester) async {
    expect(await resolve(tester, loggedOut, '/home'), '/login');
  });
}
