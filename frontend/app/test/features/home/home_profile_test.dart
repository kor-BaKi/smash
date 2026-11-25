import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:app/features/home/page/home_page.dart';
import 'package:app/features/home/page/home_profile_button.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_pump.dart';

/// 프로필 버튼: 위치, 크기, 읽어 주는 말, 눌렀을 때 열리는 화면
void main() {
  setUpAll(loadPretendard);

  Future<void> open(
    WidgetTester tester, {
    UserInfo? user,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final fake = FakeAuthNotifier(
      initial: AuthState(user: user ?? FakeAuthNotifier.fakeUser),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((r) => fake)],
        child: MaterialApp(
          home: HomePage(
            tabBuilder: (context, tab, user) =>
                Center(child: Text('TAB-${tab.name}')),
            profileBuilder: (_) => Scaffold(
              body: Column(
                children: [
                  const Text('PROFILE'),
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('프로필 버튼은 앱바 오른쪽 끝에 있고 터치 영역이 48 이상이다', (tester) async {
    await open(tester);
    final button = tester.getRect(find.byType(HomeProfileButton));
    final appBar = tester.getRect(find.byType(SmashAppBar));
    expect(button.width, greaterThanOrEqualTo(48));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(button.right, lessThanOrEqualTo(appBar.right));
    expect(
      button.right,
      greaterThan(appBar.right - 16),
      reason: '오른쪽 끝에 붙어 있다',
    );
    expect(button.top, greaterThanOrEqualTo(appBar.top));
    expect(button.bottom, lessThanOrEqualTo(appBar.bottom + 0.5));
  });

  testWidgets('이름 첫 글자가 원 안에 보이고, 스크린리더는 "내 정보"만 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, user: FakeAuthNotifier.fakeUser);
    final avatar = tester.widget<SmashAvatar>(find.byType(SmashAvatar));
    expect(avatar.name, FakeAuthNotifier.fakeUser.name);
    expect(find.bySemanticsLabel('내 정보'), findsOneWidget);
    expect(HomeProfileButton.semanticLabel, '내 정보');
    handle.dispose();
  });

  testWidgets('이름이 비어 있으면 사람 아이콘이 보인다 (글자가 없어도 버튼이 있다)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeProfileButton(name: '', onPressed: () {}),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('누르면 프로필 화면이 위에 열리고 닫으면 같은 탭으로 돌아온다', (tester) async {
    await open(tester);
    await tester.tap(find.byType(HomeProfileButton));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsNothing);
    expect(find.text('TAB-home'), findsOneWidget);
  });

  testWidgets('운영진도 같은 버튼이고 폭 320, 글자 크게에서도 넘치지 않는다', (tester) async {
    await open(
      tester,
      user: FakeAuthNotifier.fakeAdmin,
      size: const Size(320, 568),
    );
    expect(find.byType(HomeProfileButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
