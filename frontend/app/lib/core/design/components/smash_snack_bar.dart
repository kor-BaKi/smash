import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';

/// 스낵바의 종류. 색뿐 아니라 아이콘과 스크린리더 문구로도 구분한다.
/// - progress: 진행 중 (끝나면 [SmashSnackHandle.replace]로 결과로 바꾼다)
enum SmashSnackTone { info, success, error, progress }

/// 앱 전체에서 스낵바를 띄우는 유일한 함수. (ScaffoldMessenger.showSnackBar를 직접 부르지 않는다)
///
/// - 한 번에 하나만 보인다. 새로 띄우면 이전 것은 바로 사라진다 (쌓이지 않는다)
/// - 입력창 하나에 대한 오류는 스낵바가 아니라 입력창의 오류 문구로 보여준다
/// - 반환된 [SmashSnackHandle]로 진행 중 안내를 완료나 실패로 바꾼다
SmashSnackHandle showSmashSnackBar(
  BuildContext context,
  String message, {
  SmashSnackTone tone = SmashSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  return SmashSnackHandle._(ScaffoldMessenger.of(context))
    .._show(message, tone, actionLabel, onAction, duration);
}

class SmashSnackHandle {
  SmashSnackHandle._(this._messenger);

  final ScaffoldMessengerState _messenger;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _controller;
  bool _active = false;

  /// 이 핸들이 띄운 스낵바가 지금 화면에 있는지
  bool get isActive => _active;

  static Duration defaultDuration(SmashSnackTone tone) => switch (tone) {
        SmashSnackTone.info => const Duration(seconds: 4),
        SmashSnackTone.success => const Duration(seconds: 3),
        SmashSnackTone.error => const Duration(seconds: 6), // 읽고 대응할 시간
        SmashSnackTone.progress => const Duration(minutes: 10), // replace나 dismiss로 끝낸다
      };

  /// 지금 스낵바를 다른 내용으로 바꾼다. 사라졌다 나타나지 않고 바로 교체된다.
  /// (진행 중 → 완료/실패. 이미 사라졌어도 결과는 새로 보여준다)
  void replace(
    String message, {
    SmashSnackTone tone = SmashSnackTone.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _show(message, tone, actionLabel, onAction, duration);
  }

  void dismiss() {
    if (_active) _controller?.close();
  }

  void _show(
    String message,
    SmashSnackTone tone,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  ) {
    _messenger.removeCurrentSnackBar(); // 한 번에 하나만. 퇴장 애니메이션 없이 바로 교체한다
    final controller = _messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SmashColors.text,
        elevation: 0,
        margin: const EdgeInsets.all(SmashSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: SmashSpacing.md, vertical: SmashSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: SmashRadius.circular(SmashRadius.md)),
        duration: duration ?? defaultDuration(tone),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: SmashColors.brandTint,
                onPressed: onAction ?? () {},
              ),
        content: _SnackContent(message: message, tone: tone),
      ),
    );
    _controller = controller;
    _active = true;
    controller.closed.then((_) {
      if (identical(_controller, controller)) _active = false;
    });
  }
}

class _SnackContent extends StatelessWidget {
  const _SnackContent({required this.message, required this.tone});

  final String message;
  final SmashSnackTone tone;

  @override
  Widget build(BuildContext context) {
    final (icon, color, spoken) = switch (tone) {
      SmashSnackTone.info => (Icons.info_outline, SmashColors.brandTint, ''),
      SmashSnackTone.success => (Icons.check_circle_outline, SmashColors.successBg, '완료, '),
      SmashSnackTone.error => (Icons.error_outline, SmashColors.dangerBg, '오류, '),
      SmashSnackTone.progress => (null, SmashColors.onBrand, '진행 중, '),
    };

    // 나타날 때 바로 읽히는 liveRegion은 Flutter의 SnackBar가 이미 감싸 준다 (테스트로 고정). 여기서는 종류를 말로 붙인다
    return Semantics(
      label: '$spoken$message',
      excludeSemantics: true,
      child: Row(
        children: [
          if (tone == SmashSnackTone.progress)
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: SmashColors.onBrand),
            )
          else
            Icon(icon, size: 20, color: color),
          const SizedBox(width: SmashSpacing.sm),
          Expanded(
            child: Text(message, style: SmashText.body.copyWith(color: SmashColors.onBrand)),
          ),
        ],
      ),
    );
  }
}
