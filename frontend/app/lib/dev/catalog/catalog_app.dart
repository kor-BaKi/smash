import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/design/smash_theme.dart';
import 'catalog_entry.dart';
import 'catalog_page.dart';
import 'catalog_registry.dart';

/// 개발용 카탈로그 앱. 인증, 서버, Firebase 없이 컴포넌트만 띄운다.
class CatalogApp extends StatelessWidget {
  /// [entries]를 넘기지 않으면 등록된 전체 목록([catalogEntries])을 보여준다.
  /// 테스트에서 가짜 컴포넌트로 카탈로그 동작을 확인할 때만 넘긴다.
  const CatalogApp({super.key, this.entries});

  final List<CatalogEntry>? entries;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASH 카탈로그',
      theme: SmashTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: CatalogPage(entries: entries ?? catalogEntries),
    );
  }
}
