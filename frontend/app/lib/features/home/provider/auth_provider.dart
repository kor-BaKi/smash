// 로그인한 유저 정보 상태
import 'dart:async';
import 'dart:io';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/auth_api.dart';
import 'package:app/core/error/error_messages.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/auth_messages.dart';
import 'package:app/features/auth/model/auth_model.dart';
import 'package:dio/dio.dart';
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

  AuthState copyWith({UserInfo? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      // ?? :  null 이면 오른쪽 값 사용
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({AuthState initial = const AuthState()}) : super(initial) {
    // 토큰 갱신을 서버가 거부하면 ApiClient가 알려 준다 (ApiClient가 이 파일을 알지 않도록 여기서 연결한다)
    ApiClient.onSessionExpired = expireSession;
  }

  static const sessionExpiredMessage = AuthMessages.sessionExpired;

  /// 서버가 토큰 갱신을 거부해서 세션이 끝났다. 로그인 상태를 풀면 라우터가 로그인 화면으로 보낸다.
  /// (저장된 토큰은 ApiClient가 이미 지웠다. 동시에 여러 요청이 실패해도 처음 한 번만 처리한다)
  void expireSession() {
    if (!state.isLoggedIn) return;
    final sub = _tokenRefreshSub;
    _tokenRefreshSub = null;
    sub?.cancel();
    state = const AuthState(errorMessage: sessionExpiredMessage);
  }

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

  // 회원 탈퇴 요청. 성공하면 null, 실패하면 사용자에게 보여 줄 메시지를 돌려준다.
  // 로컬 세션 정리는 화면이 다이얼로그를 닫은 뒤 clearSessionAfterWithdrawal()로 한다.
  Future<String?> withdraw(String password) async {
    try {
      await AuthApi.withdraw(password: password);
      return null;
    } on DioException catch (e) {
      return _withdrawErrorMessage(e);
    } catch (_) {
      return '탈퇴에 실패했습니다.';
    }
  }

  // 탈퇴가 서버에서 끝난 뒤 이 기기의 로그인 정보를 정리한다.
  Future<void> clearSessionAfterWithdrawal() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    await TokenStorage.deleteAll();
    state = const AuthState();
  }

  String _withdrawErrorMessage(DioException e) {
    final response = e.response;
    if (response == null) return '네트워크 연결을 확인해 주세요.';

    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (response.statusCode == 429) {
      return '시도가 너무 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    return '탈퇴에 실패했습니다.';
  }

  // 앱 시작 시 토큰 확인
  Future<void> checkToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;

    try {
      final response = await AuthApi.getMe();
      final user = UserInfo.fromJson(response['data']);
      state = state.copyWith(user: user);
      unawaited(_registerFcmToken());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await TokenStorage.deleteAll();
      }
    }
  }

  // 회원가입
  Future<void> signup(String code, String studentNo, String password) async {
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
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _signupErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthMessages.signupRejected,
      );
    }
  }

  // 가입 실패 문구. 서버가 준 문구는 쓰지 않고 연결 상태와 상태 코드만 본다
  static String _signupErrorMessage(DioException e) {
    final response = e.response;
    if (response == null) {
      return switch (ErrorMessages.of(e)) {
        ErrorMessages.offline => AuthMessages.signupOffline,
        ErrorMessages.timeout => AuthMessages.signupTimeout,
        _ => AuthMessages.signupRejected,
      };
    }
    final status = response.statusCode ?? 0;
    if (status == 429) return AuthMessages.signupTooMany;
    if (status >= 500) return AuthMessages.signupServer;
    return AuthMessages.signupRejected;
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
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _loginErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthMessages.loginUnknown,
      );
    }
  }

  // 로그인 실패 문구. 서버가 준 문구는 쓰지 않고 연결 상태와 상태 코드만 본다.
  // 400, 401, 403 등 서버가 거절한 경우는 모두 같은 문구라서 계정이 있는지, 어떤 상태인지를 드러내지 않는다
  static String _loginErrorMessage(DioException e) {
    final response = e.response;
    if (response == null) {
      return switch (ErrorMessages.of(e)) {
        ErrorMessages.offline => AuthMessages.loginOffline,
        ErrorMessages.timeout => AuthMessages.loginTimeout,
        _ => AuthMessages.loginUnknown,
      };
    }
    final status = response.statusCode ?? 0;
    if (status == 429) return AuthMessages.loginTooMany;
    if (status >= 500) return AuthMessages.loginServer;
    return AuthMessages.loginRejected;
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

      if (Platform.isIOS) {
        for (var i = 0; i < 10; i++) {
          if (await fcm.getAPNSToken() != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

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
    if (ApiClient.onSessionExpired == expireSession) {
      ApiClient.onSessionExpired = null;
    }
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
