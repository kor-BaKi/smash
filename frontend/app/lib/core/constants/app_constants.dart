// Spring: 엔티티 → Repository → Service → Controller (DB부터 바깥으로)
// Flutter: 상수/저장소 → API 클라이언트 → 모델 → Provider → 화면 (기반부터 바깥으로)

// app_constants  →  token_storage  →  api_client(Dio)  →  auth_api  →  AuthProvider  →  LoginPage
//      ↑                ↑                   ↑                ↑              ↑               ↑
//    상수 정의        토큰 저장소          HTTP 클라이언트    API 호출      상태 관리         화면

// 서버 주소, 토큰 키 이름 같은 상수를 한 곳에 모음
// 나중에 Dio 클라이언트, Provider 등 모든 곳에서 이 값을 가져다 씀

class AppConstants {
  // API
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
