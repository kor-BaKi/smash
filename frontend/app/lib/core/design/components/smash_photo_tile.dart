import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';
import 'smash_label.dart';
import 'smash_pressable.dart';

/// 사진을 불러오는 중에 화면이 사라졌는지 알려 주는 신호.
///
/// 로더는 이 신호로 요청을 취소할 수 있다 (예: `cancel.whenCancelled.then((_) => token.cancel())`).
/// 취소를 쓰지 않아도 된다: 신호가 취소된 뒤에 돌아온 결과는 [SmashPhotoTile]이 버린다.
abstract interface class SmashPhotoCancel {
  /// 이 요청의 결과가 더 이상 필요 없는지 (화면에서 사라졌거나 다른 사진으로 바뀜)
  bool get isCancelled;

  /// 취소되는 순간 완료된다 (이미 취소됐으면 바로 완료)
  Future<void> get whenCancelled;
}

class _PhotoCancel implements SmashPhotoCancel {
  final Completer<void> _completer = Completer<void>();

  @override
  bool get isCancelled => _completer.isCompleted;

  @override
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// 사진 바이트를 가져오는 함수. 어디서 어떻게 가져오는지(네트워크, 인증, 파일)는 호출자가 정한다.
typedef SmashPhotoLoader = Future<Uint8List> Function(SmashPhotoCancel cancel);

/// 사진 한 칸. 불러오는 중, 성공, 실패(다시 시도), 빈 자리를 같은 크기와 비율로 보여준다.
///
/// - **디자인 계층은 네트워크와 인증을 모른다.** 사진은 호출자가 넘기는 [loader]로만 가져온다.
///   S9에서 연결할 때는 인증 헤더가 붙는 앱의 HTTP 클라이언트로 바이트를 받아 돌려주는 로더를 넘긴다
///   (예: `(cancel) => 클라이언트.getBytes(url, cancelToken: ...)`). 이 컴포넌트는 헤더 방식에 영향받지 않는다
/// - **같은 사진은 한 번만 불러온다**: [photoKey]가 같으면 다시 그려져도 [loader]를 다시 부르지 않는다 (로더 함수가 새로 만들어져도
///   같다). [photoKey]가 바뀌면(또는 [loader]가 null ↔ 함수로 바뀌면) 이전 요청은 버리고 새로 불러온다. 실패 뒤에는 "다시 시도" 버튼으로만 다시 부른다.
///   칸이 화면에서 사라졌다가 다시 만들어지면(스크롤) 다시 불러온다: 바이트를 캐시하려면 호출자가 로더 안에서 한다
/// - 로더는 그리는 도중이 아니라 그 직후(다음 마이크로태스크)에 불린다. **화면에서 사라지면** [SmashPhotoCancel]이 취소되고, 늦게 돌아온 결과는 버린다 (사라진 뒤에 상태를 바꾸지 않는다)
/// - **메모리**: 사진은 칸에 보이는 크기에 맞춰(화면 배율 포함) 디코딩한다. 원본이 칸보다 작으면 원본 크기 그대로 디코딩하고 늘리지 않는다.
///   디코딩 크기는 32px 단위로 올려서, 칸 크기가 조금씩 변해도 다시 디코딩하지 않는다. 사진이 아닌 바이트는 실패로 보여준다
/// - **상태가 바뀌어도 칸의 크기와 비율은 그대로다** ([aspectRatio]). 실패 상태의 내용은 칸보다 커지면(글자 확대) 줄어들어 칸 안에 들어간다
/// - **스크린리더**: [semanticLabel] (예: "활동 사진 3장 중 1번째")에 상태가 붙는다 — "불러오는 중", "불러오지 못했어요", "사진 없음".
///   [onTap]이 있고 사진이 보이면 버튼이고 "크게 보기" 동작 안내가 붙는다. 실패 상태에는 별도의 "…, 다시 시도" 버튼이 있다
/// - [caption](날짜 등)은 눈으로 보는 용도라 스크린리더가 따로 읽지 않는다: 읽혀야 하면 [semanticLabel]에 넣는다
///
/// 칸 크기를 알아야 해서 `LayoutBuilder`를 쓰므로 **고유 크기를 지원하지 않는다**: 격자나 폭이 정해진 곳에 둔다
/// (`SmashAdaptiveRow`, `IntrinsicHeight` 안에는 두지 않는다).
class SmashPhotoTile extends StatefulWidget {
  const SmashPhotoTile({
    super.key,
    required this.photoKey,
    required this.loader,
    required this.semanticLabel,
    this.onTap,
    this.caption,
    this.aspectRatio = 1,
  }) : assert(aspectRatio > 0);

  /// 어떤 사진인지 구분하는 값 (사진 id나 주소). 같으면 다시 불러오지 않는다
  final Object photoKey;

  /// 사진 바이트를 가져온다. null이면 빈 사진 자리다
  final SmashPhotoLoader? loader;

  /// 스크린리더가 읽는 말 (예: "활동 사진 3장 중 1번째")
  final String semanticLabel;

  /// 눌러서 크게 본다. null이면 누를 수 없다
  final VoidCallback? onTap;

  /// 사진 위 오른쪽 아래에 보이는 짧은 글자 (날짜 등)
  final String? caption;

  /// 가로 ÷ 세로
  final double aspectRatio;

  static const String loadingReading = '불러오는 중';
  static const String failedReading = '불러오지 못했어요';
  static const String emptyReading = '사진 없음';
  static const String retryLabel = '다시 시도';
  static const String tapHint = '크게 보기';

  /// 디코딩 단위: 이 크기(px) 단위로 올려서 정한다
  static const int decodeStep = 32;

  /// 사진 크기를 읽는 함수. 테스트에서 읽는 시간을 늘려 "읽는 동안 화면이 사라지는" 순간을 만들 때만 바꾼다
  @visibleForTesting
  static Future<Size> Function(Uint8List bytes) sizeReader = _readPhotoSize;

  /// 날짜 글자 뒤의 어두운 막 (약 70%): 어떤 사진 위에서도(흰 사진 포함) 흰 글자가 4.5:1 이상으로 읽힌다
  static const Color captionScrim = Color(0xB314171C);

  /// 칸([boxWidth] × [boxHeight] 논리 픽셀)을 가득 채우도록(cover) 사진([imageWidth] × [imageHeight] 픽셀)을 줄여 디코딩할 때의 너비.
  /// 늘릴 필요가 없으면(원본이 칸보다 작거나 같으면) null이다 (원본 크기로 디코딩)
  static int? decodeWidth({
    required int imageWidth,
    required int imageHeight,
    required double boxWidth,
    required double boxHeight,
    required double devicePixelRatio,
  }) {
    if (imageWidth <= 0 ||
        imageHeight <= 0 ||
        boxWidth <= 0 ||
        boxHeight <= 0) {
      return null;
    }
    final scale = math.max(
      boxWidth * devicePixelRatio / imageWidth,
      boxHeight * devicePixelRatio / imageHeight,
    );
    if (scale >= 1) return null;
    final width = (imageWidth * scale / decodeStep).ceil() * decodeStep;
    return width >= imageWidth ? null : width;
  }

  @override
  State<SmashPhotoTile> createState() => _SmashPhotoTileState();
}

/// 디코딩 없이 사진 크기만 읽는다. 사진이 아닌 바이트면 오류가 난다
Future<Size> _readPhotoSize(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = Size(
      descriptor.width.toDouble(),
      descriptor.height.toDouble(),
    );
    descriptor.dispose();
    return size;
  } finally {
    buffer.dispose();
  }
}

enum _Phase { loading, loaded, failed, empty }

class _SmashPhotoTileState extends State<SmashPhotoTile> {
  _Phase _phase = _Phase.loading;
  Uint8List? _bytes;
  Size? _imageSize;
  _PhotoCancel? _cancel;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(SmashPhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoKey != widget.photoKey ||
        (oldWidget.loader == null) != (widget.loader == null)) {
      _start();
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _generation++;
    super.dispose();
  }

  void _start() {
    _cancel?.cancel();
    final generation = ++_generation;
    _bytes = null;
    _imageSize = null;
    final loader = widget.loader;
    if (loader == null) {
      _phase = _Phase.empty;
      return;
    }
    _phase = _Phase.loading;
    final cancel = _cancel = _PhotoCancel();
    _load(loader, cancel, generation);
  }

  Future<void> _load(
    SmashPhotoLoader loader,
    _PhotoCancel cancel,
    int generation,
  ) async {
    Uint8List bytes;
    Size size;
    try {
      // 로더는 그리는 도중(initState, build)이 아니라 그 직후에 부른다: 로더가 부모의 상태를 바꿔도 안전하다
      await Future<void>.value();
      if (generation != _generation) return;
      bytes = await loader(cancel);
      if (generation != _generation) return;
      size = await SmashPhotoTile.sizeReader(bytes);
    } catch (_) {
      // 실패는 화면에 "다시 시도"로 보인다. 원인 기록은 로더 안에서 한다
      if (generation != _generation) return;
      setState(() => _phase = _Phase.failed);
      return;
    }
    // 상태를 바꾸는 곳은 try 밖이다: 사라진 뒤에 부르는 실수가 있으면 삼켜지지 않고 드러난다
    if (generation != _generation) return;
    setState(() {
      _bytes = bytes;
      _imageSize = size;
      _phase = _Phase.loaded;
    });
  }

  String get _reading {
    final base = widget.semanticLabel;
    return switch (_phase) {
      _Phase.loading => '$base, ${SmashPhotoTile.loadingReading}',
      _Phase.failed => '$base, ${SmashPhotoTile.failedReading}',
      _Phase.empty => '$base, ${SmashPhotoTile.emptyReading}',
      _Phase.loaded => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tile = AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: SmashRadius.circular(SmashRadius.md),
        child: LayoutBuilder(builder: _buildFace),
      ),
    );
    final tappable = _phase == _Phase.loaded && widget.onTap != null;
    if (tappable) {
      return Semantics(
        label: _reading,
        image: true,
        onTapHint: SmashPhotoTile.tapHint,
        child: SmashPressable(
          onPressed: widget.onTap,
          borderRadius: SmashRadius.circular(SmashRadius.md),
          minSize: Size.zero,
          builder: (context, states) => DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: SmashRadius.circular(SmashRadius.md),
              border: states.contains(WidgetState.focused)
                  ? Border.all(color: SmashColors.brand, width: 2)
                  : null,
            ),
            child: tile,
          ),
        ),
      );
    }
    if (_phase == _Phase.failed) {
      // 다시 시도 버튼이 따로 읽히도록 칸 전체를 하나로 합치지 않는다
      return Semantics(container: true, label: _reading, child: tile);
    }
    return Semantics(
      label: _reading,
      image: true,
      excludeSemantics: true,
      child: tile,
    );
  }

  Widget _buildFace(BuildContext context, BoxConstraints constraints) {
    final face = switch (_phase) {
      _Phase.loaded => _buildPhoto(context, constraints),
      _Phase.failed => _buildFailed(),
      _Phase.loading => _placeholder(const _Spinner()),
      _Phase.empty => _placeholder(
        const Icon(
          Icons.image_outlined,
          size: 32,
          color: SmashColors.textSecondary,
        ),
      ),
    };
    final caption = widget.caption;
    if (caption == null || _phase != _Phase.loaded) return face;
    return Stack(
      fit: StackFit.expand,
      children: [
        face,
        Padding(
          padding: const EdgeInsets.all(SmashSpacing.sm),
          child: Align(
            alignment: AlignmentDirectional.bottomEnd,
            // 글자를 키워도 칸 밖으로 나가지 않게 줄어든다
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ExcludeSemantics(child: _CaptionBadge(caption)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(Widget child) => ColoredBox(
    color: SmashColors.fillDisabled,
    child: Center(child: child),
  );

  Widget _buildPhoto(BuildContext context, BoxConstraints constraints) {
    final size = _imageSize!;
    final cacheWidth = SmashPhotoTile.decodeWidth(
      imageWidth: size.width.round(),
      imageHeight: size.height.round(),
      boxWidth: constraints.maxWidth,
      boxHeight: constraints.maxHeight,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      width: double.infinity,
      height: double.infinity,
      // 디코딩이 끝나기 전에는 불러오는 중 모양을 그대로 보여 준다 (칸이 비어 보이지 않는다)
      frameBuilder: (context, child, frame, synchronous) =>
          frame == null && !synchronous
          ? _placeholder(const _Spinner())
          : child,
      errorBuilder: (context, error, stack) => _buildFailed(),
    );
  }

  Widget _buildFailed() {
    return _placeholder(
      Padding(
        padding: const EdgeInsets.all(SmashSpacing.sm),
        // 글자를 키우면 내용이 칸보다 커질 수 있다: 칸은 그대로 두고 내용이 줄어들어 들어간다
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                size: 24,
                color: SmashColors.textSecondary,
              ),
              const SizedBox(height: SmashSpacing.xs),
              // 칸 전체와 합쳐지지 않게 따로 읽히는 버튼으로 둔다
              Semantics(
                container: true,
                child: SmashButton(
                  label: SmashPhotoTile.retryLabel,
                  semanticLabel:
                      '${widget.semanticLabel}, ${SmashPhotoTile.retryLabel}',
                  variant: SmashButtonVariant.secondary,
                  size: SmashButtonSize.medium,
                  expanded: false,
                  horizontalPadding: SmashSpacing.sm,
                  onPressed: () => setState(_start),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(SmashColors.brand),
    ),
  );
}

/// 사진 위 글자 배경: 어떤 사진 위에서도(흰 사진 포함) 흰 글자가 4.5:1 이상으로 읽히는 어두운 막
class _CaptionBadge extends StatelessWidget {
  const _CaptionBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SmashPhotoTile.captionScrim,
        borderRadius: SmashRadius.circular(SmashRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmashSpacing.sm,
          vertical: SmashSpacing.xs,
        ),
        child: SmashLabel(
          text,
          style: SmashText.caption.copyWith(color: SmashColors.onBrand),
        ),
      ),
    );
  }
}
