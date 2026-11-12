import 'package:app/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// 실제 SmashApp 의 MaterialApp.router 설정을 확인한다.
// 라우터만 가짜로 바꾸므로 인증이나 화면 코드는 실행되지 않는다.
void main() {
  const homeKey = Key('test-home');

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox(key: homeKey)),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const SmashApp(),
      ),
    );
    await tester.pumpAndSettle();

    return tester.element(find.byKey(homeKey));
  }

  testWidgets('MaterialApp 에 ko_KR 로케일과 델리게이트 3종이 설정된다', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('ko', 'KR'));
    expect(app.supportedLocales, const [Locale('ko', 'KR')]);
    expect(
      app.localizationsDelegates,
      containsAll(<LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ]),
    );
  });

  testWidgets('실제로 한국어가 적용된다 (Material, Cupertino, 텍스트 방향)', (tester) async {
    final context = await pumpApp(tester);

    expect(Localizations.localeOf(context), const Locale('ko', 'KR'));
    expect(MaterialLocalizations.of(context).okButtonLabel, '확인');
    expect(MaterialLocalizations.of(context).cancelButtonLabel, '취소');
    expect(CupertinoLocalizations.of(context).alertDialogLabel, isNotEmpty);
    expect(Directionality.of(context), TextDirection.ltr);
  });
}
