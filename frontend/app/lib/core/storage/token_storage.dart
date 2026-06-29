import 'package:app/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 토큰을 저장/조회/삭제하는 창구
// 나중에 만들 Dio 인터셉터에서 토큰을 꺼내서 헤더에 붙임
// 인터셉터를 만들기 전에 저장소가 있어야함
class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: AppConstants.refreshTokenKey,
    );
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
