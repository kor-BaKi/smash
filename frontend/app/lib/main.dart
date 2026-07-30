import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(authProvider.notifier).checkToken();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmashApp(),
    ),
  );
}
