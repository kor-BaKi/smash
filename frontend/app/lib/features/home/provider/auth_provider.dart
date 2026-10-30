// 로그인한 유저 정보 상태
import 'dart:async';
import 'dart:io';

import 'package:app/core/api/auth_api.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/fcm_api.dart';

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

  // FCM 토큰 갱신 감시 구독 (로그인 상태에서 한 번만 등록)
  StreamSubscription<String>? _tokenRefreshSub;

  // 비밀번호 변경
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await AuthApi.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
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
      unawaited(_registerFcmToken()); // 앱 시작 속도에 영향 주지 않도록 기다리지 않음
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
      await _registerFcmToken();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '회원가입에 실패했습니다. 가입코드와 학번을 확인해주세요.',
      );
    }
  }

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
      await _registerFcmToken(); // 실패해도 내부에서 처리되어 로그인은 유지됨
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '로그인에 실패했습니다.',
      );
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _tokenRefreshSub?.cancel(); // 로그아웃 후 갱신 이벤트가 401을 내지 않도록
    _tokenRefreshSub = null;
    try {
      // FCM 삭제가 실패해도 서버 로그아웃(refresh token 폐기)은 반드시 진행
      try {
        final token = await FirebaseMessaging.instance.getToken();
        await FcmApi.deleteToken(token);
      } catch (_) {}
      await AuthApi.logout();
    } finally {
      await TokenStorage.deleteAll();
      state = const AuthState();
    }
  }

  // FCM 토큰 등록 + 갱신 감시. 로그인, 회원가입, 자동 로그인에서 공통 사용
  Future<void> _registerFcmToken() async {
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      if (token != null) await _sendFcmToken(token);

      // 토큰이 갱신되면 서버에 다시 등록 (리스너는 한 번만 등록)
      _tokenRefreshSub ??= fcm.onTokenRefresh.listen((newToken) {
        _sendFcmToken(newToken).catchError((_) {});
      });
    } catch (_) {
      // FCM 등록 실패가 로그인을 막으면 안 됨
    }
  }

  Future<void> _sendFcmToken(String token) {
    final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
    return FcmApi.saveToken(token, deviceType);
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
