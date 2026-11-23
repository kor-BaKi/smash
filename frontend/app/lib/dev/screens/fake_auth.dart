import '../../features/auth/model/auth_model.dart';
import '../../features/home/provider/auth_provider.dart';

/// 갤러리와 테스트가 쓰는 가짜 인증 상태. 서버, 토큰 저장소, Firebase를 건드리지 않는다.
///
/// - 시작 상태는 [initial]이다
/// - `login`이 불리면 인자를 [loginCalls]에 쌓고 요청 중 상태로 바꾼 뒤 [onLogin]에 맡긴다.
///   [onLogin]이 없으면 요청 중 상태로 계속 남는다 (제출 중 화면을 보여 줄 때)
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({AuthState initial = const AuthState(), this.onLogin}) {
    state = initial;
  }

  final List<(String studentNo, String password)> loginCalls = [];

  Future<void> Function(
    FakeAuthNotifier self,
    String studentNo,
    String password,
  )?
  onLogin;

  @override
  Future<void> login(String studentNo, String password) async {
    loginCalls.add((studentNo, password));
    state = AuthState(isLoading: true, user: state.user);
    await onLogin?.call(this, studentNo, password);
  }

  /// 로그인 실패: 요청이 끝나고 [message]가 남는다
  void fail(String message) => state = AuthState(errorMessage: message);

  /// 로그인 성공
  void succeed() => state = AuthState(user: fakeUser);

  static final fakeUser = UserInfo(
    id: 1,
    name: '테스트',
    role: 'MEMBER',
    studentNo: '3',
  );
}
