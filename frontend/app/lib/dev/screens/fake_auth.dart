import '../../features/auth/model/auth_model.dart';
import '../../features/home/provider/auth_provider.dart';

/// 갤러리와 테스트가 쓰는 가짜 인증 상태. 서버, 토큰 저장소, Firebase를 건드리지 않는다.
///
/// - 시작 상태는 [initial]이다
/// - `login`, `signup`이 불리면 인자를 [loginCalls], [signupCalls]에 쌓고 요청 중 상태로 바꾼 뒤 [onLogin], [onSignup]에 맡긴다.
///   [onLogin]이 없으면 요청 중 상태로 계속 남는다 (제출 중 화면을 보여 줄 때)
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(),
    this.onLogin,
    this.onSignup,
  }) {
    state = initial;
  }

  final List<(String studentNo, String password)> loginCalls = [];

  Future<void> Function(
    FakeAuthNotifier self,
    String studentNo,
    String password,
  )?
  onLogin;

  final List<(String code, String studentNo, String password)> signupCalls = [];

  /// `signup`이 불렸을 때 할 일. 없으면 요청 중 상태로 계속 남는다
  Future<void> Function(
    FakeAuthNotifier self,
    String code,
    String studentNo,
    String password,
  )?
  onSignup;

  @override
  Future<void> login(String studentNo, String password) async {
    loginCalls.add((studentNo, password));
    // 실제 AuthNotifier처럼 이전 오류 문구는 그대로 둔다 (copyWith는 null로 지우지 못한다)
    state = state.copyWith(isLoading: true);
    await onLogin?.call(this, studentNo, password);
  }

  @override
  Future<void> signup(String code, String studentNo, String password) async {
    signupCalls.add((code, studentNo, password));
    // 실제 AuthNotifier처럼 이전 오류 문구는 그대로 둔다 (copyWith는 null로 지우지 못한다)
    state = state.copyWith(isLoading: true);
    await onSignup?.call(this, code, studentNo, password);
  }

  /// 로그인한 사용자를 바꾼다 (역할이 바뀌는 경우를 보여 줄 때)
  void setUser(UserInfo user) => state = AuthState(user: user);

  /// 로그인 실패: 요청이 끝나고 [message]가 남는다
  void fail(String message) => state = AuthState(errorMessage: message);

  /// 로그인 성공
  void succeed() => state = AuthState(user: fakeUser);

  /// 운영진(ADMIN) 계정
  static final fakeAdmin = UserInfo(
    id: 2,
    name: '임원',
    role: 'ADMIN',
    studentNo: '1',
  );

  static final fakeUser = UserInfo(
    id: 1,
    name: '테스트',
    role: 'MEMBER',
    studentNo: '3',
  );
}
