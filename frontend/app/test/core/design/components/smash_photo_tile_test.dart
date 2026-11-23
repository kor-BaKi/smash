import 'dart:async';
import 'dart:ui' as ui;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/contrast.dart';
import '../../../support/pump.dart';
import '../../../support/semantics_tree.dart';
import '../../../support/text_lines.dart';

const _label = '활동 사진 3장 중 1번째';

/// 호출 횟수와 취소 신호를 기록하고, 결과를 테스트가 정하는 로더
class FakeLoader {
  final List<SmashPhotoCancel> signals = [];
  final List<Completer<Uint8List>> completers = [];
  int get calls => signals.length;

  Future<Uint8List> call(SmashPhotoCancel cancel) {
    signals.add(cancel);
    final completer = Completer<Uint8List>();
    completers.add(completer);
    return completer.future;
  }

  void complete(Uint8List bytes, [int index = -1]) =>
      completers[index < 0 ? completers.length - 1 : index].complete(bytes);
  void fail([int index = -1]) =>
      completers[index < 0 ? completers.length - 1 : index].completeError(
        StateError('실패'),
      );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    await loader.load();
  });

  /// [width]×[height] 픽셀의 PNG
  Future<Uint8List> png(WidgetTester tester, int width, int height) async {
    return (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = const Color(0xFF1F4FD8),
      );
      final image = await recorder.endRecording().toImage(width, height);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;
  }

  /// 엔진이 사진 크기를 읽고 디코딩하는 동안 기다린다 (테스트 시계 밖에서 진행된다)
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
    }
  }

  Widget tile({
    Object photoKey = 'a',
    SmashPhotoLoader? loader,
    String label = _label,
    VoidCallback? onTap,
    String? caption,
    double aspectRatio = 1,
  }) => SmashPhotoTile(
    photoKey: photoKey,
    loader: loader,
    semanticLabel: label,
    onTap: onTap,
    caption: caption,
    aspectRatio: aspectRatio,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 168,
    double scale = 1.0,
  }) => tester.pumpWidget(smashHarness(child, width: width, textScale: scale));

  Finder tileFinder() => find.byType(SmashPhotoTile);
  Finder spinner() => find.descendant(
    of: tileFinder(),
    matching: find.byType(CircularProgressIndicator),
  );
  Finder retry() =>
      find.descendant(of: tileFinder(), matching: find.text('다시 시도'));
  Finder photo() =>
      find.descendant(of: tileFinder(), matching: find.byType(Image));

  group('디코딩 크기 (decodeWidth)', () {
    int? width(int iw, int ih, double bw, double bh, double dpr) =>
        SmashPhotoTile.decodeWidth(
          imageWidth: iw,
          imageHeight: ih,
          boxWidth: bw,
          boxHeight: bh,
          devicePixelRatio: dpr,
        );

    test('칸을 가득 채우는(cover) 크기로 줄인다 (32px 단위로 올림)', () {
      expect(
        width(4000, 3000, 168, 168, 3),
        672,
        reason: '가로 사진: 높이 3000 → 504가 되는 배율 0.168, 너비 672',
      );
      expect(
        width(3000, 4000, 168, 168, 3),
        512,
        reason: '세로 사진: 너비 3000 → 504가 되는 배율 0.168, 너비 504 → 512',
      );
      expect(
        width(3000, 2000, 168, 168, 3),
        768,
        reason: '3000×2000: 배율 0.252, 너비 756 → 768',
      );
    });

    test('어떤 경우에도 디코딩한 사진이 칸보다 작아지지 않는다 (가로, 세로 모두 칸 이상)', () {
      for (final (iw, ih) in [
        (4000, 3000),
        (3000, 4000),
        (4000, 4000),
        (6000, 1000),
        (1000, 6000),
      ]) {
        for (final (bw, bh) in [
          (168.0, 168.0),
          (100.0, 133.0),
          (320.0, 180.0),
        ]) {
          for (final dpr in [1.0, 2.0, 3.0]) {
            final w = width(iw, ih, bw, bh, dpr);
            if (w == null) continue;
            expect(w, lessThan(iw), reason: '원본보다 크게 디코딩하지 않는다');
            expect(
              w,
              greaterThanOrEqualTo(bw * dpr - 0.001),
              reason: '$iw×$ih → ${bw}x$bh@$dpr 너비',
            );
            expect(
              w * ih / iw,
              greaterThanOrEqualTo(bh * dpr - 0.001),
              reason: '$iw×$ih → ${bw}x$bh@$dpr 높이',
            );
          }
        }
      }
    });

    test('원본이 칸보다 작거나 같으면 줄이지 않는다 (null: 원본 크기로 디코딩)', () {
      expect(width(100, 100, 168, 168, 3), isNull);
      expect(width(504, 504, 168, 168, 3), isNull, reason: '정확히 같다');
      expect(width(168, 168, 168, 168, 1), isNull);
      expect(
        width(1000, 1000, 168, 168, 1),
        192,
        reason: '화면 배율 1: 칸이 168px이니 1000px 사진은 192로 줄인다',
      );
    });

    test('32px 단위로 올렸더니 원본 너비 이상이 되면 줄이지 않는다 (510px 사진, 칸 504px → 512)', () {
      expect(width(510, 510, 168, 168, 3), isNull);
      expect(width(520, 520, 168, 168, 3), 512, reason: '520px 사진은 512로 줄어든다');
    });

    test('칸 크기가 조금 변해도 같은 너비다 (32px 단위)', () {
      expect(
        width(4000, 3000, 164, 164, 3),
        width(4000, 3000, 168, 168, 3),
        reason: '같은 단위 안',
      );
      expect(
        width(4000, 3000, 168, 168, 3),
        isNot(width(4000, 3000, 180, 180, 3)),
      );
    });

    test('0이나 음수 크기는 null', () {
      expect(width(0, 100, 168, 168, 3), isNull);
      expect(width(100, 0, 168, 168, 3), isNull);
      expect(width(4000, 3000, 0, 168, 3), isNull);
      expect(width(4000, 3000, 168, -1, 3), isNull);
    });
  });

  group('불러오는 중, 성공, 실패, 빈 자리', () {
    testWidgets('불러오는 중: 로더를 한 번 부르고 진행 표시가 보이며 읽는 말에 상태가 붙는다', (tester) async {
      final handle = tester.ensureSemantics();
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      expect(loader.calls, 1);
      expect(spinner(), findsOneWidget);
      expect(hasLabel(tester, '$_label, 불러오는 중'), isTrue);
      handle.dispose();
    });

    testWidgets('성공: 사진이 보이고 진행 표시가 사라지며 읽는 말은 라벨 그대로이고 사진은 따로 읽히지 않는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(photo(), findsOneWidget);
      expect(spinner(), findsNothing);
      expect(hasLabel(tester, _label), isTrue);
      expect(hasLabel(tester, '$_label, 불러오는 중'), isFalse);
      expect(tester.widget<Image>(photo()).excludeFromSemantics, isTrue);
      handle.dispose();
    });

    testWidgets('실패: 다시 시도 버튼이 보이고, 읽는 말은 "불러오지 못했어요", 다시 시도 버튼은 따로 읽힌다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.fail();
      await tester.pump();
      await tester.pump();
      expect(retry(), findsOneWidget);
      expect(spinner(), findsNothing);
      expect(hasLabel(tester, '$_label, 불러오지 못했어요'), isTrue);
      final button = semanticsNode(
        tester,
        (d) => d.label == '$_label, 다시 시도',
      )!.getSemanticsData();
      expect(button.flagsCollection.isButton, isTrue, reason: '다시 시도는 버튼이다');
      handle.dispose();
    });

    testWidgets('다시 시도를 누르면 로더를 다시 부르고 불러오는 중으로 돌아가며, 성공하면 사진이 보인다', (
      tester,
    ) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.fail();
      await tester.pump();
      await tester.pump();
      await tester.tap(retry());
      await tester.pump();
      await tester.pump();
      expect(loader.calls, 2);
      expect(spinner(), findsOneWidget);
      expect(loader.signals[0].isCancelled, isTrue, reason: '이전 요청은 취소된다');
      expect(loader.signals[1].isCancelled, isFalse);
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(photo(), findsOneWidget);
    });

    testWidgets('빈 자리: 로더를 부르지 않고 빈 자리 모양과 "사진 없음"을 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, tile());
      await tester.pump();
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(spinner(), findsNothing);
      expect(hasLabel(tester, '$_label, 사진 없음'), isTrue);
      handle.dispose();
    });

    testWidgets('로더가 바로 던져도(동기 오류) 실패로 보여 주고 앱이 죽지 않는다', (tester) async {
      await pump(tester, tile(loader: (cancel) => throw StateError('바로 실패')));
      await tester.pump();
      await tester.pump();
      expect(retry(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('사진이 아닌 바이트가 오면 실패로 보여 준다 (다시 시도 가능)', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(Uint8List.fromList([1, 2, 3, 4, 5]));
      await settle(tester);
      expect(retry(), findsOneWidget);
      expect(photo(), findsNothing);
    });

    testWidgets('빈 바이트도 실패다', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(Uint8List(0));
      await settle(tester);
      expect(retry(), findsOneWidget);
    });
  });

  group('크기와 비율이 상태가 바뀌어도 그대로다', () {
    for (final ratio in [1.0, 4 / 3, 3 / 4]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          '비율 ${ratio.toStringAsFixed(2)}, 글자 $scale배: 불러오는 중 → 성공 → 실패 → 빈 자리의 칸 크기가 같다',
          (tester) async {
            final sizes = <String, Size>{};
            final loader = FakeLoader();
            await pump(
              tester,
              tile(
                loader: loader.call,
                aspectRatio: ratio,
                caption: '2026-11-11',
              ),
              scale: scale,
            );
            await tester.pump();
            sizes['불러오는 중'] = tester.getSize(tileFinder());
            loader.complete(await png(tester, 400, 300));
            await settle(tester);
            sizes['성공'] = tester.getSize(tileFinder());
            final failing = FakeLoader();
            await pump(
              tester,
              tile(photoKey: 'b', loader: failing.call, aspectRatio: ratio),
              scale: scale,
            );
            await tester.pump();
            failing.fail();
            await tester.pump();
            await tester.pump();
            sizes['실패'] = tester.getSize(tileFinder());
            await pump(
              tester,
              tile(photoKey: 'c', aspectRatio: ratio),
              scale: scale,
            );
            await tester.pump();
            sizes['빈 자리'] = tester.getSize(tileFinder());
            expect(tester.takeException(), isNull);
            for (final entry in sizes.entries) {
              expect(entry.value.width, 168, reason: entry.key);
              expect(
                entry.value.width / entry.value.height,
                closeTo(ratio, 0.001),
                reason: '비율 ${entry.key}',
              );
            }
          },
        );
      }
    }

    testWidgets(
      '실패 상태의 내용(아이콘, 다시 시도 버튼)이 글자 2.0배에서도 칸 안에 들어가고 눌린다 (폭 168, 100)',
      (tester) async {
        for (final width in [168.0, 100.0]) {
          var taps = 0;
          await pump(
            tester,
            tile(
              photoKey: 'f$width',
              loader: (c) => Future<Uint8List>.error(StateError('x')),
            ),
            width: width,
            scale: 2.0,
          );
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '넘침 없음 (폭 $width)');
          final box = tester.getRect(tileFinder());
          final button = tester.getRect(retry());
          expect(
            button.left,
            greaterThanOrEqualTo(box.left - 0.001),
            reason: '폭 $width',
          );
          expect(
            button.right,
            lessThanOrEqualTo(box.right + 0.001),
            reason: '폭 $width',
          );
          expect(button.top, greaterThanOrEqualTo(box.top - 0.001));
          expect(button.bottom, lessThanOrEqualTo(box.bottom + 0.001));
          expect(taps, 0);
        }
      },
    );

    testWidgets('다시 시도 버튼의 눌림 영역은 폭 168, 글자 1.0배에서 48 이상이다', (tester) async {
      await pump(
        tester,
        tile(loader: (c) => Future<Uint8List>.error(StateError('x'))),
      );
      await tester.pump();
      await tester.pump();
      final button = tester.getRect(
        find.ancestor(of: retry(), matching: find.byType(SmashButton)).first,
      );
      expect(button.height, greaterThanOrEqualTo(48));
    });
  });

  group('메모리와 성능', () {
    testWidgets('같은 사진은 다시 그려져도 로더를 다시 부르지 않는다 (로더 함수가 새로 만들어져도 같다)', (
      tester,
    ) async {
      var calls = 0;
      Future<Uint8List> make(SmashPhotoCancel c) {
        calls++;
        return Completer<Uint8List>().future;
      }

      for (var i = 0; i < 5; i++) {
        await pump(
          tester,
          tile(photoKey: 'same', loader: (c) => make(c), label: '라벨 $i'),
        );
        await tester.pump();
      }
      expect(calls, 1);
    });

    testWidgets('사진이 바뀌면(photoKey) 이전 요청은 취소되고 이전 결과는 버려지며 새 사진을 불러온다', (
      tester,
    ) async {
      final loader = FakeLoader();
      await pump(tester, tile(photoKey: 'one', loader: loader.call));
      await tester.pump();
      await pump(tester, tile(photoKey: 'two', loader: loader.call));
      await tester.pump();
      expect(loader.calls, 2);
      expect(loader.signals[0].isCancelled, isTrue);
      expect(loader.signals[1].isCancelled, isFalse);
      loader.complete(await png(tester, 400, 300), 0); // 이전 사진의 늦은 결과
      await settle(tester);
      expect(photo(), findsNothing, reason: '이전 사진의 결과는 버린다');
      expect(spinner(), findsOneWidget, reason: '새 사진은 아직 불러오는 중');
      loader.complete(await png(tester, 400, 300), 1);
      await settle(tester);
      expect(photo(), findsOneWidget);
    });

    testWidgets(
      '화면에서 사라지면 취소 신호가 가고, 늦게 돌아온 결과에도 오류가 없다 (dispose 뒤 setState 없음)',
      (tester) async {
        final loader = FakeLoader();
        await pump(tester, tile(loader: loader.call));
        await tester.pump();
        expect(loader.signals.single.isCancelled, isFalse);
        var cancelled = false;
        unawaited(
          loader.signals.single.whenCancelled.then((_) => cancelled = true),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(loader.signals.single.isCancelled, isTrue);
        expect(cancelled, isTrue, reason: 'whenCancelled가 완료된다');
        loader.complete(await png(tester, 400, 300));
        await settle(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('사라진 뒤에 늦게 실패해도 오류가 없다', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      loader.fail();
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('로더가 null ↔ 함수로 바뀌면 다시 불러오거나 빈 자리가 된다', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile());
      await tester.pump();
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      expect(loader.calls, 1);
      expect(spinner(), findsOneWidget);
      await pump(tester, tile());
      await tester.pump();
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(loader.signals.single.isCancelled, isTrue);
    });

    testWidgets('로더는 그리는 도중(initState, build)이 아니라 그 직후에 불린다', (tester) async {
      final duringBuild = <bool>[];
      await pump(
        tester,
        tile(
          loader: (c) {
            duringBuild.add(tester.binding.buildOwner!.debugBuilding);
            return Completer<Uint8List>().future;
          },
        ),
      );
      await tester.pump();
      expect(duringBuild, [false]);
    });

    testWidgets('로더가 부모의 상태를 바꿔도(setState) 그리는 도중에 오류가 나지 않는다', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        smashHarness(
          StatefulBuilder(
            builder: (context, setState) => tile(
              loader: (c) {
                setState(() => attempts++);
                return Completer<Uint8List>().future;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(attempts, 1);
    });

    testWidgets(
      '디코딩 크기: 칸에 맞춰 줄인 너비로 디코딩한다 (3000×2000, 칸 168, 화면 배율 3 → 768)',
      (tester) async {
        final loader = FakeLoader();
        await pump(tester, tile(loader: loader.call));
        await tester.pump();
        loader.complete(await png(tester, 3000, 2000));
        await settle(tester);
        final provider = tester.widget<Image>(photo()).image;
        expect(provider, isA<ResizeImage>());
        expect((provider as ResizeImage).width, 768);
        expect(provider.height, isNull);
      },
    );

    testWidgets('사진은 칸을 가득 채운다 (cover)이고 칸 전체 크기로 그려진다', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      final image = tester.widget<Image>(photo());
      expect(image.fit, BoxFit.cover);
      expect(tester.getSize(photo()), tester.getSize(tileFinder()));
    });

    testWidgets('원본이 칸보다 작으면 줄이지 않는다 (200×200, 칸 504px)', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(await png(tester, 200, 200));
      await settle(tester);
      expect(tester.widget<Image>(photo()).image, isA<MemoryImage>());
    });

    testWidgets('칸 크기가 같은 단위 안에서 조금 변해도 같은 디코딩 크기를 쓴다 (다시 디코딩하지 않는다)', (
      tester,
    ) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call), width: 168);
      await tester.pump();
      loader.complete(await png(tester, 3000, 2000));
      await settle(tester);
      final first = (tester.widget<Image>(photo()).image as ResizeImage).width;
      await pump(tester, tile(loader: loader.call), width: 164);
      await settle(tester);
      expect((tester.widget<Image>(photo()).image as ResizeImage).width, first);
      expect(loader.calls, 1, reason: '크기가 바뀌어도 다시 불러오지 않는다');
    });

    testWidgets('칸이 커지면 더 큰 크기로 디코딩한다 (폭 168 → 336)', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call), width: 168);
      await tester.pump();
      loader.complete(await png(tester, 3000, 2000));
      await settle(tester);
      final small = (tester.widget<Image>(photo()).image as ResizeImage).width!;
      await pump(tester, tile(loader: loader.call), width: 336);
      await settle(tester);
      expect(
        (tester.widget<Image>(photo()).image as ResizeImage).width!,
        greaterThan(small),
      );
    });
  });

  group('눌러서 크게 보기', () {
    Future<FakeLoader> loaded(
      WidgetTester tester, {
      VoidCallback? onTap,
      String? caption,
    }) async {
      final loader = FakeLoader();
      await pump(
        tester,
        tile(loader: loader.call, onTap: onTap, caption: caption),
      );
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      return loader;
    }

    testWidgets('사진이 보이면 누를 수 있고, 눌림 영역은 칸 전체다', (tester) async {
      var taps = 0;
      await loaded(tester, onTap: () => taps++);
      final rect = tester.getRect(tileFinder());
      for (final p in [
        rect.center,
        rect.topLeft + const Offset(8, 8),
        rect.bottomRight - const Offset(8, 8),
      ]) {
        await tester.tapAt(p);
      }
      expect(taps, 3);
    });

    testWidgets('불러오는 중, 실패, 빈 자리에서는 칸을 눌러도 onTap이 불리지 않는다', (tester) async {
      var taps = 0;
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call, onTap: () => taps++));
      await tester.pump();
      await tester.tap(tileFinder());
      expect(taps, 0, reason: '불러오는 중');
      loader.fail();
      await tester.pump();
      await tester.pump();
      await tester.tapAt(tester.getTopLeft(tileFinder()) + const Offset(6, 6));
      expect(taps, 0, reason: '실패 (버튼 밖)');
      await pump(tester, tile(photoKey: 'e', onTap: () => taps++));
      await tester.pump();
      await tester.tap(tileFinder());
      expect(taps, 0, reason: '빈 자리');
    });

    testWidgets('onTap이 없으면 사진이 보여도 누를 수 없다', (tester) async {
      await loaded(tester);
      expect(
        find.descendant(
          of: tileFinder(),
          matching: find.byType(SmashPressable),
        ),
        findsNothing,
      );
    });

    testWidgets('스크린리더: 사진이고 버튼이며 "크게 보기" 동작 안내가 있고, 탭 동작으로 onTap이 불린다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await loaded(tester, onTap: () => taps++);
      final node = semanticsNode(tester, (d) => d.label == _label)!;
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isImage, isTrue);
      expect(node.hintOverrides?.onTapHint, '크게 보기');
      semanticsOwner(tester).performAction(node.id, SemanticsAction.tap);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('onTap이 없는 사진은 버튼이 아니고 사진으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await loaded(tester);
      final data = semanticsNode(
        tester,
        (d) => d.label == _label,
      )!.getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isImage, isTrue);
      handle.dispose();
    });

    testWidgets('키보드 포커스가 오면 브랜드 색 굵은 테두리가 보인다', (tester) async {
      await loaded(tester, onTap: () {});
      Border? border() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: tileFinder(),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>()
          .firstOrNull;
      expect(border(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(border()!.top.width, 2);
      expect(border()!.top.color, SmashColors.brand);
    });

    testWidgets('실패 상태의 읽는 말, 다시 시도 읽는 말에는 호출자가 준 라벨이 들어간다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        tile(
          label: '활동 사진 4장 중 2번째',
          loader: (c) => Future<Uint8List>.error(StateError('x')),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(hasLabel(tester, '활동 사진 4장 중 2번째, 불러오지 못했어요'), isTrue);
      expect(hasLabel(tester, '활동 사진 4장 중 2번째, 다시 시도'), isTrue);
      handle.dispose();
    });
  });

  group('날짜 글자(caption)', () {
    testWidgets('사진이 보일 때만 오른쪽 아래에 보이고, 불러오는 중이나 실패에서는 없다', (tester) async {
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call, caption: '2026-11-11'));
      await tester.pump();
      expect(find.text('2026-11-11'), findsNothing);
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(find.text('2026-11-11'), findsOneWidget);
      final box = tester.getRect(tileFinder());
      final text = tester.getRect(find.text('2026-11-11'));
      expect(text.right, lessThanOrEqualTo(box.right));
      expect(text.bottom, lessThanOrEqualTo(box.bottom));
      expect(text.center.dx, greaterThan(box.center.dx), reason: '오른쪽');
      expect(text.center.dy, greaterThan(box.center.dy), reason: '아래쪽');
    });

    testWidgets('스크린리더가 따로 읽지 않는다 (읽혀야 하면 라벨에 넣는다)', (tester) async {
      final handle = tester.ensureSemantics();
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call, caption: '2026-11-11'));
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(hasLabel(tester, '2026-11-11'), isFalse);
      handle.dispose();
    });

    testWidgets('글자 2.0배에서도 칸 밖으로 나가지 않는다 (줄어들어 들어간다)', (tester) async {
      final loader = FakeLoader();
      await pump(
        tester,
        tile(loader: loader.call, caption: '2026-11-11'),
        scale: 2.0,
      );
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(tester.takeException(), isNull);
      final box = tester.getRect(tileFinder());
      final text = tester.getRect(find.text('2026-11-11'));
      expect(text.left, greaterThanOrEqualTo(box.left));
      expect(text.right, lessThanOrEqualTo(box.right));
    });

    test('날짜 배경 막: 흰 사진 위에서도 흰 글자 대비가 4.5:1 이상이다', () {
      final overWhite = Color.alphaBlend(
        SmashPhotoTile.captionScrim,
        const Color(0xFFFFFFFF),
      );
      expect(
        contrastRatio(SmashColors.onBrand, overWhite),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('격자 안에서', () {
    testWidgets('여러 칸이 서로 다른 상태여도 모두 같은 크기다 (2열 격자)', (tester) async {
      final ok = FakeLoader();
      await tester.pumpWidget(
        smashHarness(
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              tile(photoKey: '1', loader: ok.call, label: '사진 1'),
              tile(
                photoKey: '2',
                loader: (c) => Completer<Uint8List>().future,
                label: '사진 2',
              ),
              tile(
                photoKey: '3',
                loader: (c) => Future<Uint8List>.error(StateError('x')),
                label: '사진 3',
              ),
              tile(photoKey: '4', label: '사진 4'),
            ],
          ),
          width: 344,
        ),
      );
      await tester.pump();
      ok.complete(await png(tester, 400, 300));
      await settle(tester);
      final sizes = tester
          .widgetList(tileFinder())
          .map((w) => tester.getSize(find.byWidget(w)))
          .toSet();
      expect(sizes.length, 1, reason: '$sizes');
      expect(sizes.single, const Size(168, 168));
      expect(tester.takeException(), isNull);
    });
  });

  group('사라지는 순간', () {
    /// 크기 읽기를 붙잡아 두는 읽기 함수: 로더가 끝난 뒤 크기를 읽는 동안의 순간을 만든다
    Completer<Size> holdSizeReading(WidgetTester tester) {
      final held = Completer<Size>();
      final original = SmashPhotoTile.sizeReader;
      SmashPhotoTile.sizeReader = (bytes) => held.future;
      addTearDown(() => SmashPhotoTile.sizeReader = original);
      return held;
    }

    testWidgets(
      '로더가 끝난 직후 크기를 읽는 동안 화면이 사라져도 상태를 바꾸지 않는다 (setState 없음, 오류 없음)',
      (tester) async {
        final held = holdSizeReading(tester);
        final loader = FakeLoader();
        await pump(tester, tile(loader: loader.call));
        await tester.pump();
        loader.complete(await png(tester, 400, 300));
        await tester.pump(); // 로더 결과를 받아 크기 읽기를 시작한다 (붙잡혀 있다)
        await tester.pumpWidget(const SizedBox()); // 크기를 읽는 동안 사라진다
        held.complete(const Size(400, 300));
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('크기를 읽는 동안 사진이 바뀌면(photoKey) 이전 사진은 보이지 않고 새 사진만 다룬다', (
      tester,
    ) async {
      final held = holdSizeReading(tester);
      final loader = FakeLoader();
      await pump(tester, tile(photoKey: 'one', loader: loader.call));
      await tester.pump();
      loader.complete(await png(tester, 400, 300), 0);
      await tester.pump();
      await pump(tester, tile(photoKey: 'two', loader: loader.call));
      await tester.pump();
      held.complete(const Size(400, 300)); // 이전 사진의 크기 읽기가 이제 끝난다
      await tester.pump();
      await tester.pump();
      expect(photo(), findsNothing, reason: '이전 사진은 보이지 않는다');
      expect(spinner(), findsOneWidget, reason: '새 사진을 불러오는 중');
      expect(tester.takeException(), isNull);
    });

    testWidgets('크기 읽기가 실패해도(사진이 아님) 그동안 사라졌다면 아무 일도 없다', (tester) async {
      final held = holdSizeReading(tester);
      final loader = FakeLoader();
      await pump(tester, tile(loader: loader.call));
      await tester.pump();
      loader.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      held.completeError(StateError('사진이 아님'));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('실패 상태의 치수', () {
    Future<void> pumpFailed(
      WidgetTester tester, {
      double width = 168,
      double scale = 1.0,
    }) async {
      await pump(
        tester,
        tile(
          photoKey: 'f$width$scale',
          loader: (c) => Future<Uint8List>.error(StateError('x')),
        ),
        width: width,
        scale: scale,
      );
      await tester.pump();
      await tester.pump();
    }

    Rect buttonRect(WidgetTester tester) => tester.getRect(
      find.ancestor(of: retry(), matching: find.byType(SmashButton)).first,
    );

    testWidgets(
      '아이콘 24, 아이콘과 버튼 사이 4, 버튼 높이 48, 버튼 글자 좌우 여백 8 (폭 168, 글자 1.0배)',
      (tester) async {
        await pumpFailed(tester);
        final icon = tester.getRect(find.byIcon(Icons.broken_image_outlined));
        final button = buttonRect(tester);
        expect(icon.size, const Size(24, 24));
        expect(button.top - icon.bottom, 4);
        expect(button.height, 48);
        expect(
          button.width,
          closeTo(tester.getSize(retry()).width + 16 + 2, 0.01),
          reason: '글자 폭 + 좌우 여백 8씩 + 테두리 1씩',
        );
        expect(
          button.center.dx,
          closeTo(tester.getRect(tileFinder()).center.dx, 0.5),
          reason: '가운데',
        );
      },
    );

    testWidgets('칸이 좁아 내용이 줄어들어도 칸 가장자리에서 8 이상 떨어져 있다 (폭 100, 글자 2.0배)', (
      tester,
    ) async {
      await pumpFailed(tester, width: 100, scale: 2.0);
      final box = tester.getRect(tileFinder());
      final button = buttonRect(tester);
      final icon = tester.getRect(find.byIcon(Icons.broken_image_outlined));
      for (final r in [button, icon]) {
        expect(r.left, greaterThanOrEqualTo(box.left + 8 - 0.01));
        expect(r.right, lessThanOrEqualTo(box.right - 8 + 0.01));
        expect(r.top, greaterThanOrEqualTo(box.top + 8 - 0.01));
        expect(r.bottom, lessThanOrEqualTo(box.bottom - 8 + 0.01));
      }
    });
  });

  group('날짜 글자(caption) 보충', () {
    testWidgets('눌러서 크게 볼 수 있는 사진에서도 날짜가 따로 읽히지 않고, 읽는 말은 라벨 그대로다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final loader = FakeLoader();
      await pump(
        tester,
        tile(loader: loader.call, caption: '2026-11-11', onTap: () {}),
      );
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(find.text('2026-11-11'), findsOneWidget);
      expect(
        semanticsNode(tester, (d) => d.label == _label),
        isNotNull,
        reason: '읽는 말이 라벨 그대로다 (날짜가 섞이지 않는다)',
      );
      expect(hasLabel(tester, '2026-11-11'), isFalse);
      handle.dispose();
    });

    testWidgets('좁은 칸(폭 100)에서 글자 2.0배일 때 날짜가 줄어들어 칸 안(가장자리에서 8 이상)에 들어간다', (
      tester,
    ) async {
      final loader = FakeLoader();
      await pump(
        tester,
        tile(loader: loader.call, caption: '2026-11-11'),
        width: 100,
        scale: 2.0,
      );
      await tester.pump();
      loader.complete(await png(tester, 400, 300));
      await settle(tester);
      expect(tester.takeException(), isNull);
      final box = tester.getRect(tileFinder());
      final text = tester.getRect(find.text('2026-11-11'));
      expect(text.left, greaterThanOrEqualTo(box.left + 8 - 0.01));
      expect(text.right, lessThanOrEqualTo(box.right - 8 + 0.01));
      expect(text.bottom, lessThanOrEqualTo(box.bottom - 8 + 0.01));
      expect(
        lineCount(tester, find.text('2026-11-11')),
        1,
        reason: '여러 줄로 나뉘지 않고 한 줄로 줄어든다',
      );
    });
  });

  group('자리 배경과 아이콘', () {
    Color placeholderColor(WidgetTester tester) => tester
        .widgetList<ColoredBox>(
          find.descendant(of: tileFinder(), matching: find.byType(ColoredBox)),
        )
        .first
        .color;

    testWidgets('빈 자리: 자리 배경은 연한 회색이고 아이콘이 그 위에서 3:1 이상으로 보인다', (tester) async {
      await pump(tester, tile());
      await tester.pump();
      final background = placeholderColor(tester);
      final icon = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
      expect(
        background,
        SmashColors.fillDisabled,
        reason: '흰 페이지 위에서 자리가 보이는 회색',
      );
      expect(
        contrastRatio(icon.color!, background),
        greaterThanOrEqualTo(3.0),
        reason: '아이콘 비텍스트 대비',
      );
    });

    testWidgets('실패: 자리 배경 위에서 깨진 사진 아이콘이 3:1 이상으로 보인다', (tester) async {
      await pump(
        tester,
        tile(loader: (c) => Future<Uint8List>.error(StateError('x'))),
      );
      await tester.pump();
      await tester.pump();
      final background = placeholderColor(tester);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.broken_image_outlined),
      );
      expect(background, SmashColors.fillDisabled);
      expect(contrastRatio(icon.color!, background), greaterThanOrEqualTo(3.0));
    });

    testWidgets('불러오는 중: 진행 표시가 자리 배경 위에서 3:1 이상으로 보인다', (tester) async {
      await pump(tester, tile(loader: FakeLoader().call));
      await tester.pump();
      final background = placeholderColor(tester);
      expect(background, SmashColors.fillDisabled);
      expect(
        contrastRatio(SmashColors.brand, background),
        greaterThanOrEqualTo(3.0),
      );
      final indicator = tester.widget<CircularProgressIndicator>(spinner());
      expect(
        (indicator.valueColor! as AlwaysStoppedAnimation<Color?>).value,
        SmashColors.brand,
      );
    });
  });

  group('격자의 빈 자리', () {
    testWidgets('빈 자리는 "사진 없음"으로 읽히고 다시 시도 버튼이 없다. 실패 칸에는 다시 시도가 있다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        smashHarness(
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              tile(
                photoKey: '1',
                loader: (c) => Completer<Uint8List>().future,
                label: '사진 1',
              ),
              tile(
                photoKey: '2',
                loader: (c) => Future<Uint8List>.error(StateError('x')),
                label: '사진 2',
              ),
              tile(photoKey: '3', label: '사진 3'),
              tile(photoKey: '4', label: '사진 4'),
            ],
          ),
          width: 344,
        ),
      );
      await tester.pump();
      await tester.pump();
      Finder tileOf(String label) => find.byWidgetPredicate(
        (w) => w is SmashPhotoTile && w.semanticLabel == label,
      );
      for (final label in ['사진 3', '사진 4']) {
        expect(
          find.descendant(of: tileOf(label), matching: find.text('다시 시도')),
          findsNothing,
          reason: '$label: 빈 자리에는 다시 시도가 없다',
        );
        expect(
          find.descendant(
            of: tileOf(label),
            matching: find.byIcon(Icons.image_outlined),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tileOf(label),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsNothing,
        );
        expect(hasLabel(tester, '$label, 사진 없음'), isTrue);
      }
      expect(
        find.descendant(of: tileOf('사진 2'), matching: find.text('다시 시도')),
        findsOneWidget,
      );
      expect(hasLabel(tester, '사진 2, 불러오지 못했어요'), isTrue);
      expect(hasLabel(tester, '사진 1, 불러오는 중'), isTrue);
      handle.dispose();
    });
  });
}
