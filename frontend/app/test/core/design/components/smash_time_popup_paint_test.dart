import 'dart:ui' as ui;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/radius.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _screen = Size(400, 900);
final _boundaryKey = GlobalKey();

/// 안전 영역(노치, 홈 인디케이터)이 있는 화면에 시간 입력 하나를 둔다.
/// 입력은 안전 영역 안쪽 위에 놓여 팝업이 칸 아래에 열린다
Widget host({
  required DateTime value,
  double scale = 1.0,
  EdgeInsets safe = const EdgeInsets.fromLTRB(0, 59, 0, 34),
}) => RepaintBoundary(
  key: _boundaryKey,
  child: MaterialApp(
    theme: SmashTheme.light(),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        padding: safe,
        viewPadding: safe,
      ),
      child: app!,
    ),
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          safe.left + 16,
          safe.top + 16,
          safe.right + 16,
          0,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SmashTimeFieldPicker(
            value: value,
            isSelectable: (_) => true,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  ),
);

void sizeScreen(WidgetTester tester) {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder cell(String prefix) => find.byWidgetPredicate(
  (w) => w is SmashPressable && (w.semanticLabel ?? '').startsWith(prefix),
);
Finder row(String label) => find.byWidgetPredicate(
  (w) => w is SmashPressable && w.semanticLabel == label,
);
Finder popupBox() => find
    .ancestor(of: find.byType(ListView), matching: find.byType(Opacity))
    .first;

/// 팝업(시 또는 분)을 연다
Future<void> openPopup(WidgetTester tester, {required bool hour}) async {
  await tester.tap(cell(hour ? '시 선택' : '분 선택'));
  await settle(tester);
}

ScrollPosition scrollPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// 화면 전체(RepaintBoundary)의 픽셀을 읽는다 (devicePixelRatio 1.0이라 논리 좌표 = 픽셀)
Future<Color Function(int x, int y)> readPixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
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

double distance(Color a, Color b) {
  final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
  return (dr * dr + dg * dg + db * db);
}

void main() {
  group('시/분 목록의 위아래 여백 (안전 영역이 목록 안으로 새지 않는다)', () {
    final safes = {
      '위 59, 아래 34': const EdgeInsets.fromLTRB(0, 59, 0, 34),
      '위 59, 아래 34, 좌우 20': const EdgeInsets.fromLTRB(20, 59, 20, 34),
    };
    // (목록, 값, 첫 줄/마지막 줄/가운데)
    final cases =
        <
          ({String name, bool hour, DateTime value, int index, String position})
        >[
          (
            name: '시, 1시(맨 위)',
            hour: true,
            value: DateTime(2026, 11, 12, 1, 30),
            index: 0,
            position: 'first',
          ),
          (
            name: '시, 6시(가운데)',
            hour: true,
            value: DateTime(2026, 11, 12, 6, 30),
            index: 5,
            position: 'middle',
          ),
          (
            name: '시, 12시(맨 아래)',
            hour: true,
            value: DateTime(2026, 11, 12, 12, 30),
            index: 11,
            position: 'last',
          ),
          (
            name: '분, 00분(맨 위)',
            hour: false,
            value: DateTime(2026, 11, 12, 9, 0),
            index: 0,
            position: 'first',
          ),
          (
            name: '분, 30분(가운데)',
            hour: false,
            value: DateTime(2026, 11, 12, 9, 30),
            index: 30,
            position: 'middle',
          ),
          (
            name: '분, 59분(맨 아래)',
            hour: false,
            value: DateTime(2026, 11, 12, 9, 59),
            index: 59,
            position: 'last',
          ),
        ];
    for (final safeEntry in safes.entries) {
      for (final scale in [1.0, 2.0]) {
        for (final c in cases) {
          testWidgets(
            '안전 영역 ${safeEntry.key}, 글자 $scale배, ${c.name}: 위/아래 공백 0이고 초기 스크롤 위치가 맞다',
            (tester) async {
              sizeScreen(tester);
              await tester.pumpWidget(
                host(value: c.value, scale: scale, safe: safeEntry.value),
              );
              await openPopup(tester, hour: c.hour);

              final list = tester.getRect(find.byType(ListView));
              final position = scrollPosition(tester);
              final itemCount = c.hour ? 12 : 60;
              final first = row(c.hour ? '오전 1시' : '0분');
              final last = row(c.hour ? '오후 12시' : '59분');
              // 줄 높이는 글자 크기를 따른다. 목록 높이 = 보이는 줄 수 × 줄 높이
              final rowH = (await _rowHeight(tester, c.hour));
              final visibleRows = (list.height / rowH).round();
              expect(visibleRows, 5, reason: '5줄이 보인다 (공간이 충분한 화면)');
              expect(list.height, closeTo(visibleRows * rowH, 0.01));

              // 스크롤 범위: 위/아래 여백이 없으면 전체 높이 = 줄 수 × 줄 높이
              expect(position.minScrollExtent, 0);
              expect(
                position.maxScrollExtent,
                closeTo(itemCount * rowH - list.height, 0.01),
                reason: '안전 영역 여백이 스크롤 범위에 섞이지 않는다',
              );

              // 초기 스크롤 위치: 고른 줄이 위에서 두 번째(index-1)에 오고, 양 끝에서는 끝에 닿는다
              final expectedPixels = ((c.index - 1) * rowH).clamp(
                0.0,
                itemCount * rowH - list.height,
              );
              expect(position.pixels, closeTo(expectedPixels, 0.01));

              if (c.position == 'first') {
                expect(
                  tester.getRect(first).top,
                  closeTo(list.top, 0.01),
                  reason: '첫 줄의 윗변 = 목록 윗변 (위 공백 0)',
                );
              }
              if (c.position == 'last') {
                await tester.scrollUntilVisible(
                  last,
                  50,
                  scrollable: find.descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable),
                  ),
                );
                expect(
                  tester.getRect(last).bottom,
                  closeTo(list.bottom, 0.01),
                  reason: '마지막 줄의 아랫변 = 목록 아랫변 (아래 공백 0)',
                );
              }
              // 어느 위치에서든 목록의 위아래는 줄로 채워져 있다 (빈 공백이 아니다)
              final rows = find.descendant(
                of: find.byType(ListView),
                matching: find.byType(SmashPressable),
              );
              final top = tester.getRect(rows.first).top;
              final bottom = tester.getRect(rows.last).bottom;
              expect(top, lessThanOrEqualTo(list.top + 0.01));
              expect(bottom, greaterThanOrEqualTo(list.bottom - 0.01));
            },
          );
        }
      }
    }
  });

  group('선택된 줄의 강조가 팝업 테두리를 넘거나 끊지 않는다 (실제 픽셀)', () {
    const radius = SmashRadius.md;

    /// 색이 "강조 색(0) → 테두리 색(1)" 사이 어디쯤인지. 테두리 위에 강조가 덧그려지면 0에 가깝고, 테두리가 온전하면 1에 가깝다
    /// (선이 얇아 두 픽셀에 번지는 경우에도 절반 이상은 테두리 색이다)
    double borderStrength(Color color) {
      final h = SmashColors.brandTintSoft;
      final b = SmashColors.border;
      final dr = (b.r - h.r) * 255,
          dg = (b.g - h.g) * 255,
          db = (b.b - h.b) * 255;
      final cr = (color.r - h.r) * 255,
          cg = (color.g - h.g) * 255,
          cb = (color.b - h.b) * 255;
      return (cr * dr + cg * dg + cb * db) / (dr * dr + dg * dg + db * db);
    }

    /// 팝업 둘레의 테두리 띠에 있는 픽셀들의 "테두리 세기" 중 가장 약한 값과 그 위치.
    /// 모서리는 호(바깥 반지름 12, 띠 폭 1)의 한가운데 띠를, 변은 가운데 구간을 본다
    Future<Map<String, double>> weakestBorder(
      WidgetTester tester, {
      required bool hour,
      required DateTime value,
      required double scale,
    }) async {
      // 이전 캡처의 팝업과 상태가 남지 않게 한 번 비운 뒤 다시 그린다
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(value: value, scale: scale));
      await openPopup(tester, hour: hour);
      final box = tester.getRect(popupBox());
      final pixel = await readPixels(tester);

      final result = <String, double>{};
      void note(String key, double strength) {
        final current = result[key];
        if (current == null || strength < current) result[key] = strength;
      }

      final corners = {
        '왼쪽 위 모서리': Offset(box.left + radius, box.top + radius),
        '오른쪽 위 모서리': Offset(box.right - radius, box.top + radius),
        '왼쪽 아래 모서리': Offset(box.left + radius, box.bottom - radius),
        '오른쪽 아래 모서리': Offset(box.right - radius, box.bottom - radius),
      };
      for (final entry in corners.entries) {
        final center = entry.value;
        final left = entry.key.startsWith('왼쪽');
        final top = entry.key.contains('위');
        for (var dy = 0; dy < radius; dy++) {
          for (var dx = 0; dx < radius; dx++) {
            // 모서리 사분면 안의 픽셀 중심
            final px = (left ? center.dx - radius : center.dx).floor() + dx;
            final py = (top ? center.dy - radius : center.dy).floor() + dy;
            final rho = (Offset(px + 0.5, py + 0.5) - center).distance;
            if (rho >= radius - 0.8 && rho <= radius - 0.2) {
              note(entry.key, borderStrength(pixel(px, py)));
            }
          }
        }
      }
      for (
        var x = (box.center.dx - 20).floor();
        x <= (box.center.dx + 20).floor();
        x++
      ) {
        note('윗변', borderStrength(pixel(x, (box.top + 0.5).floor())));
        note('아랫변', borderStrength(pixel(x, (box.bottom - 0.5).floor())));
      }
      for (
        var y = (box.center.dy - 20).floor();
        y <= (box.center.dy + 20).floor();
        y++
      ) {
        note('왼쪽 변', borderStrength(pixel((box.left + 0.5).floor(), y)));
        note('오른쪽 변', borderStrength(pixel((box.right - 0.5).floor(), y)));
      }
      return result;
    }

    final cases = <({String name, bool hour, DateTime value})>[
      (
        name: '시 1시(맨 위 줄 선택)',
        hour: true,
        value: DateTime(2026, 11, 12, 1, 30),
      ),
      (
        name: '시 12시(맨 아래 줄 선택)',
        hour: true,
        value: DateTime(2026, 11, 12, 12, 30),
      ),
      (
        name: '시 6시(가운데 줄 선택, 비교용)',
        hour: true,
        value: DateTime(2026, 11, 12, 6, 30),
      ),
      (
        name: '분 00분(맨 위 줄 선택)',
        hour: false,
        value: DateTime(2026, 11, 12, 9, 0),
      ),
      (
        name: '분 59분(맨 아래 줄 선택)',
        hour: false,
        value: DateTime(2026, 11, 12, 9, 59),
      ),
      (
        name: '분 30분(가운데 줄 선택, 비교용)',
        hour: false,
        value: DateTime(2026, 11, 12, 9, 30),
      ),
    ];
    for (final scale in [1.0, 2.0]) {
      for (final c in cases) {
        testWidgets(
          '글자 $scale배, ${c.name}: 네 모서리와 위·아래·양옆 테두리가 끊기지 않고 강조 색이 덧그려지지 않는다',
          (tester) async {
            sizeScreen(tester);
            final weakest = await weakestBorder(
              tester,
              hour: c.hour,
              value: c.value,
              scale: scale,
            );
            // ignore: avoid_print
            print(
              'STRENGTH ${c.name} $scale ${weakest.map((k, v) => MapEntry(k, v.toStringAsFixed(2)))}',
            );
            for (final e in weakest.entries) {
              expect(
                e.value,
                greaterThan(0.4),
                reason:
                    '${e.key}: 테두리 띠의 가장 약한 픽셀이 강조 색 쪽이다 (${e.value.toStringAsFixed(2)}). 강조가 테두리 위에 덧그려졌다',
              );
            }
          },
        );
      }
    }

    testWidgets('기준이 헛돌지 않는다: 강조된 줄 안쪽 픽셀은 강조 색이다', (tester) async {
      sizeScreen(tester);
      await tester.pumpWidget(host(value: DateTime(2026, 11, 12, 6, 30)));
      await openPopup(tester, hour: true);
      final selected = tester.getRect(row('오전 6시'));
      final pixel = await readPixels(tester);
      final inside = pixel(
        (selected.left + selected.width * 0.55).floor(),
        (selected.top + 6).floor(),
      );

      expect(
        distance(inside, SmashColors.brandTintSoft),
        lessThan(30),
        reason: '선택된 줄 안쪽 $inside 는 강조 색이어야 한다 (이 검사가 헛돌지 않아야 테두리 검사를 믿을 수 있다)',
      );
      expect(
        distance(inside, SmashColors.surface),
        greaterThan(
          distance(SmashColors.brandTintSoft, SmashColors.surface) / 2,
        ),
      );
    });
  });
}

Future<double> _rowHeight(WidgetTester tester, bool hour) async {
  final rowFinder = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(SmashPressable),
  );
  return tester.getSize(rowFinder.first).height;
}
