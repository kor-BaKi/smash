import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화면의 한 영역을 `RepaintBoundary`로 감싼다 (픽셀을 읽으려면 필요하다)
Widget screenshotBoundary(Key key, Widget child) =>
    RepaintBoundary(key: key, child: child);

/// [boundaryKey]의 `RepaintBoundary`를 그려 픽셀 색을 읽는 함수를 돌려준다.
/// `devicePixelRatio`를 1.0으로 맞춘 테스트에서는 논리 좌표 = 픽셀이다
Future<Color Function(int x, int y)> readPixels(
  WidgetTester tester,
  Key boundaryKey,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return (x, y) {
    final i = (y * image.width + x) * 4;
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

/// 두 색의 거리(제곱, 0~255 단위). 같은 색이면 0
double colorDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
  return dr * dr + dg * dg + db * db;
}
