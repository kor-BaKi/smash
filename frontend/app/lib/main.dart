import 'package:app/features/home/provider/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // 알림 권한 요청
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // iOS APNs 토큰 대기 후 FCM 토큰 가져오기
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // APNS 토큰 대기 (최대 5초)
      for (int i = 0; i < 10; i++) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          print('APNS Token: $apnsToken');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
  } catch (e) {
    print('FCM Token 가져오기 실패: $e');
  }

  final container = ProviderContainer();
  await container.read(authProvider.notifier).checkToken();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmashApp(),
    ),
  );
}
