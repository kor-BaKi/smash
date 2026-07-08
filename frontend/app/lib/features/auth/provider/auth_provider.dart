// 로그인한 유저 정보 상태
import 'package:app/core/api/auth_api.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  // 앱의 로그인 상태를 표현하는 데이터 클래스 (지금 누가 로그인했는지)
  // user = null, isLoading = false  → 비로그인 상태
  // user = null, isLoading = true   → 로그인 요청 중
  // user = UserInfo, isLoading = false → 로그인 완료
  // user = null, errorMessage = "실패" → 로그인 실패
  final UserInfo? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserInfo? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      // ?? :  null 이면 오른쪽 값 사용
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // 로그인
  Future<void> login(String studentNo, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await AuthApi.login(
        studentNo: studentNo,
        password: password,
      );

      final auth = AuthResponse.fromJson(response);

      await TokenStorage.saveAccessToken(auth.accessToken);
      await TokenStorage.saveRefreshToken(auth.refreshToken);

      state = state.copyWith(user: auth.user, isLoading: false);
    } catch (e) {
      print('로그인 에러: $e'); // 추가
      state = state.copyWith(
        isLoading: false,
        errorMessage: '로그인에 실패했습니다.',
      );
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      await AuthApi.logout();
    } finally {
      await TokenStorage.deleteAll();
      state = const AuthState();
    }
  }

  // 앱 시작 시 토큰 확인
  Future<void> checkToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return; // 토큰 없으면 로그인 화면

    try {
      final response = await AuthApi.getMe();
      final user = UserInfo.fromJson(response['data']);
      state = state.copyWith(user: user);
    } catch (e) {
      // 토큰 만료 or 오류 -> 토큰 삭제 후 로그인 화면
      await TokenStorage.deleteAll();
    }
  }

  // 회원가입
  Future<void> signup(
    String code,
    String studentNo,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await AuthApi.signup(
        code: code,
        studentNo: studentNo,
        password: password,
      );

      final auth = AuthResponse.fromJson(response);

      await TokenStorage.saveAccessToken(auth.accessToken);
      await TokenStorage.saveRefreshToken(auth.refreshToken);

      state = state.copyWith(user: auth.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '회원가입에 실패했습니다. 가입코드와 학번을 확인해주세요.',
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
