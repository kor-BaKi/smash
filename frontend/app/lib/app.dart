import 'package:flutter/material.dart';

import 'features/auth/page/login_page.dart';
import 'shared/theme/app_theme.dart';

class SmashApp extends StatelessWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASH',
      theme: appTheme,
      home: const LoginPage(),
    );
  }
}
