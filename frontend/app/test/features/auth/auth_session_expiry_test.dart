import 'package:app/core/api/api_client.dart';
import 'package:app/dev/screens/fake_auth.dart';
import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// AuthNotifier의 세션 만료 처리와 ApiClient 연결
void main() {
  tearDown(() => ApiClient.onSessionExpired = null);

  AuthNotifier loggedIn() =>
      AuthNotifier(initial: AuthState(user: FakeAuthNotifier.fakeUser));

  test('로그인 중이면 로그아웃 상태가 되고 만료 안내 문구가 남는다', () {
    final auth = loggedIn();
    addTearDown(auth.dispose);
    auth.expireSession();

    expect(auth.state.isLoggedIn, isFalse);
    expect(auth.state.isLoading, isFalse);
    expect(auth.state.errorMessage, '로그인 정보가 만료되었어요. 다시 로그인해 주세요.');
  });

  test('로그인 중이 아니면 아무것도 바꾸지 않는다 (로그인 화면에 만료 문구가 뜨지 않는다)', () {
    final auth = AuthNotifier();
    addTearDown(auth.dispose);
    final before = auth.state;
    var notified = 0;
    auth.addListener((_) => notified++, fireImmediately: false);

    auth.expireSession();
    auth.expireSession();

    expect(identical(auth.state, before), isTrue);
    expect(auth.state.errorMessage, isNull);
    expect(notified, 0);
  });

  test('로그인 중에 여러 번 불러도 상태 변화는 한 번이다', () {
    final auth = loggedIn();
    addTearDown(auth.dispose);
    var notified = 0;
    auth.addListener((_) => notified++, fireImmediately: false);

    auth.expireSession();
    auth.expireSession();
    auth.expireSession();
    expect(notified, 1);
  });

  group('ApiClient 연결', () {
    test('AuthNotifier가 만들어지면 ApiClient에 연결되고, 불리면 로그아웃한다', () {
      ApiClient.onSessionExpired = null;
      final auth = loggedIn();
      addTearDown(auth.dispose);

      expect(ApiClient.onSessionExpired, isNotNull);
      ApiClient.onSessionExpired!.call();
      expect(auth.state.isLoggedIn, isFalse);
    });

    test('AuthNotifier가 사라지면 연결이 풀린다', () {
      final auth = loggedIn();
      auth.dispose();
      expect(ApiClient.onSessionExpired, isNull);
    });

    test('먼저 만든 AuthNotifier가 사라져도 나중에 만든 것의 연결은 남는다', () {
      final first = loggedIn();
      final second = loggedIn();
      addTearDown(second.dispose);

      first.dispose();
      expect(ApiClient.onSessionExpired, isNotNull);
      ApiClient.onSessionExpired!.call();
      expect(second.state.isLoggedIn, isFalse, reason: '두 번째 것이 처리한다');
    });
  });
}
