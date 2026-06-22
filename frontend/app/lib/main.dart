import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: SmashApp()));
}

class SmashApp extends StatelessWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASH',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const LoginScreen(),
    );
  }
}
