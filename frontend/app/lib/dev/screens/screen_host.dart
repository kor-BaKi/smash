import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screen_conditions.dart';
import 'screen_entry.dart';

/// 화면 하나를 [ScreenState]의 가짜 프로바이더와 [ScreenConditions] 아래에서 띄운다.
///
/// 앱과 같은 한국어 로케일과 go_router를 쓰고, 화면이 이동하는 다른 경로([ScreenEntry.stubPaths])는 자리 표시 화면으로 대신한다.
/// 기기 크기는 이 위젯을 놓은 자리의 크기를 따르므로, 갤러리는 SizedBox로, 테스트는 테스트 화면 크기로 정한다.
class ScreenHost extends StatefulWidget {
  const ScreenHost({
    super.key,
    required this.entry,
    required this.state,
    this.conditions = const ScreenConditions(),
    this.onRouter,
  });

  final ScreenEntry entry;
  final ScreenState state;
  final ScreenConditions conditions;

  /// 라우터가 만들어졌을 때 알려 준다 (테스트가 현재 경로를 확인할 때 쓴다)
  final ValueChanged<GoRouter>? onRouter;

  @override
  State<ScreenHost> createState() => _ScreenHostState();
}

class _ScreenHostState extends State<ScreenHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.entry.path,
    routes: [
      GoRoute(
        path: widget.entry.path,
        builder: (context, _) => widget.entry.builder(context),
      ),
      for (final path in widget.entry.stubPaths)
        GoRoute(
          path: path,
          builder: (context, _) => _StubPage(path: path),
        ),
    ],
  );

  @override
  void initState() {
    super.initState();
    widget.onRouter?.call(_router);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conditions;
    final bottomSafe = math.max(
      0.0,
      ScreenConditions.safeBottom - c.keyboardHeight,
    );
    return ProviderScope(
      overrides: widget.state.overrides,
      child: MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(c.width, c.height),
            textScaler: TextScaler.linear(c.textScale),
            padding: EdgeInsets.only(
              top: ScreenConditions.safeTop,
              bottom: bottomSafe,
            ),
            viewPadding: const EdgeInsets.only(
              top: ScreenConditions.safeTop,
              bottom: ScreenConditions.safeBottom,
            ),
            viewInsets: EdgeInsets.only(bottom: c.keyboardHeight),
          ),
          child: child!,
        ),
      ),
    );
  }
}

class _StubPage extends StatelessWidget {
  const _StubPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('$path (갤러리의 자리 표시 화면)', key: const ValueKey('stub-page')),
      ),
    );
  }
}
