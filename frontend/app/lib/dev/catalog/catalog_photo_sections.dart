import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

/// 카탈로그용 가짜 사진: 색 그라데이션과 줄무늬 (서버 없이 사진처럼 보이는 바이트를 만든다)
final Map<String, Future<Uint8List>> _photos = {};

Future<Uint8List> _makePhoto(int width, int height, Color from, Color to) {
  return _photos.putIfAbsent('$width×$height|$from', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
          from,
          to,
        ]),
    );
    final stripe = Paint()..color = const Color(0x33FFFFFF);
    for (var i = -height; i < width; i += 120) {
      canvas.drawLine(
        Offset(i.toDouble(), height.toDouble()),
        Offset(i.toDouble() + height, 0),
        stripe..strokeWidth = 36,
      );
    }
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
}

Future<Uint8List> _landscape(SmashPhotoCancel _) =>
    _makePhoto(1200, 900, const Color(0xFF1F4FD8), const Color(0xFF7BC8F6));
Future<Uint8List> _portrait(SmashPhotoCancel _) =>
    _makePhoto(900, 1200, const Color(0xFF137A39), const Color(0xFFC8E6B0));
Future<Uint8List> _never(SmashPhotoCancel _) => Completer<Uint8List>().future;
Future<Uint8List> _fail(SmashPhotoCancel _) async =>
    throw StateError('불러오기 실패');

void _ignore() {}

Widget _tile({
  Object key = 'a',
  SmashPhotoLoader? loader,
  String label = '활동 사진 3장 중 1번째',
  String? caption,
  VoidCallback? onTap,
}) {
  return SmashPhotoTile(
    photoKey: key,
    loader: loader,
    semanticLabel: label,
    caption: caption,
    onTap: onTap,
  );
}

/// 폭과 글자 배율을 정해서 보여준다 (블록의 글자 배율과 상관없이 같은 모습)
Widget _fixed(
  Widget child, {
  required double width,
  required double textScale,
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

/// 처음 두 번은 실패하고 세 번째에 성공하는 로더: 다시 시도 버튼을 눌러 볼 수 있다
class _PhotoLab extends StatefulWidget {
  const _PhotoLab();

  @override
  State<_PhotoLab> createState() => _PhotoLabState();
}

class _PhotoLabState extends State<_PhotoLab> {
  int _attempts = 0;
  int _opened = 0;

  Future<Uint8List> _load(SmashPhotoCancel cancel) {
    setState(() => _attempts++);
    final attempt = _attempts;
    final completer = Completer<Uint8List>();
    // 서버 대신 0.7초 뒤에 답한다. 화면이 사라져 취소되면 타이머도 함께 끝낸다 (취소 신호를 쓰는 예)
    final timer = Timer(const Duration(milliseconds: 700), () async {
      if (attempt < 3) {
        completer.completeError(StateError('아직 실패'));
      } else {
        completer.complete(
          await _makePhoto(
            1200,
            900,
            const Color(0xFFB030D0),
            const Color(0xFFF1C0F5),
          ),
        );
      }
    });
    cancel.whenCancelled.then((_) => timer.cancel());
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmashPhotoTile(
          photoKey: 'lab',
          loader: _load,
          semanticLabel: '활동 사진 3장 중 1번째',
          caption: '2026-11-11',
          onTap: () => setState(() => _opened++),
        ),
        Padding(
          padding: const EdgeInsets.only(top: SmashSpacing.sm),
          child: Text(
            '현재 값: 불러오기 시도 $_attempts번, 크게 보기 $_opened번 (세 번째에 성공해요)',
            style: SmashText.caption,
          ),
        ),
      ],
    );
  }
}

final photoTileEntry = CatalogEntry(
  name: 'SmashPhotoTile',
  description:
      '사진은 호출자가 넘긴 로더로만 가져온다. 불러오는 중, 성공, 실패(다시 시도), 빈 자리가 같은 크기와 비율이다.',
  states: [
    CatalogState(
      '성공 (가로 사진)',
      (_) => _tile(key: 'landscape', loader: _landscape),
    ),
    CatalogState(
      '성공 (세로 사진)',
      (_) => _tile(key: 'portrait', loader: _portrait),
    ),
    CatalogState(
      '성공 + 날짜 + 눌러서 크게 보기',
      (_) => _tile(
        key: 'caption',
        loader: _landscape,
        caption: '2026-11-11',
        onTap: _ignore,
      ),
    ),
    CatalogState(
      '눌림',
      (_) => SmashForcePressed(
        child: _tile(
          key: 'pressed',
          loader: _landscape,
          caption: '2026-11-11',
          onTap: _ignore,
        ),
      ),
    ),
    CatalogState('불러오는 중', (_) => _tile(key: 'loading', loader: _never)),
    CatalogState('실패 (다시 시도)', (_) => _tile(key: 'failed', loader: _fail)),
    CatalogState('빈 사진 자리', (_) => _tile(key: 'empty', label: '사진 자리 4번째')),
    CatalogState(
      '2열 격자 (성공, 불러오는 중, 실패, 빈 자리: 같은 크기)',
      (_) => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: SmashSpacing.sm,
        mainAxisSpacing: SmashSpacing.sm,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _tile(
            key: 'g1',
            loader: _landscape,
            caption: '2026-11-11',
            onTap: _ignore,
            label: '활동 사진 4장 중 1번째',
          ),
          _tile(key: 'g2', loader: _never, label: '활동 사진 4장 중 2번째'),
          _tile(key: 'g3', loader: _fail, label: '활동 사진 4장 중 3번째'),
          _tile(key: 'g4', label: '활동 사진 4장 중 4번째'),
        ],
      ),
    ),
    CatalogState(
      '실패 (폭 168, 글자 2.0배)',
      (_) =>
          _fixed(_tile(key: 'f2', loader: _fail), width: 168, textScale: 2.0),
    ),
    const CatalogState(interactiveStateLabel, _lab),
  ],
);

Widget _lab(BuildContext context) => const _PhotoLab();
