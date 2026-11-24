import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_entry.dart';
import 'package:app/dev/screens/screen_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 화면의 글자 폭이 실제와 같도록 Pretendard를 불러온다 (테스트 기본 글꼴은 폭이 다르다)
Future<void> loadPretendard() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
  await loader.load();
}

/// 화면을 [conditions]의 기기 크기(폭×높이, 배율 1.0)로 띄운다. 화면 크기는 테스트가 끝나면 되돌린다.
/// 로고 같은 그림이 그려지도록 화면 안의 그림을 미리 불러 둔다.
Future<GoRouter> pumpScreen(
  WidgetTester tester,
  ScreenEntry entry,
  ScreenState state, {
  ScreenConditions conditions = const ScreenConditions(),
  Key? boundaryKey,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(conditions.width, conditions.height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late GoRouter router;
  Widget host = ScreenHost(
    // 한 테스트에서 여러 번 열어도 매번 새 상태로 시작한다
    key: UniqueKey(),
    entry: entry,
    state: state,
    conditions: conditions,
    onRouter: (r) => router = r,
  );
  if (boundaryKey != null) {
    host = RepaintBoundary(key: boundaryKey, child: host);
  }
  await tester.pumpWidget(host);
  await tester.pump();
  // 그림을 미리 불러 둔다
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  // 처리 중 표시처럼 끝없이 움직이는 것이 있으면 settle: false로 짧게만 기다린다
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // 첫 화면 뒤에 쌓는 화면(pushes)까지 그려지도록 몇 번 짧게 기다린다
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return router;
}
