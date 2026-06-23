import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/auth_api.dart';
import '../model/auth_user.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(
      AuthController.new,
    );

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  FutureOr<AuthUser?> build() => null;

  Future<void> login(String studentNo, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authApiProvider)
          .login(studentNo, password),
    );
  }
}
