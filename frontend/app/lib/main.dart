import 'package:app/features/home/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  final container = ProviderContainer();
  await container.read(authProvider.notifier).checkToken();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmashApp(),
    ),
  );
}
