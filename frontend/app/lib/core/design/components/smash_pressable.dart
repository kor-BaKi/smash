import 'package:flutter/material.dart';

import '../haptics.dart';
import '../motion.dart';
import '../motion_context.dart';
import '../smash_haptics.dart';
import '../spacing.dart';
import 'smash_force_pressed.dart';

typedef SmashPressableBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// 누를 수 있는 모든 컴포넌트의 바탕.
///
/// - 터치 영역은 최소 [minSize] (기본 48dp)
/// - 누르는 동안 [SmashMotion.pressedScale]까지 작아진다 (모션 줄이기가 켜져 있으면 크기 변화 없음)
/// - 키보드 포커스와 스크린리더의 버튼 역할, 활성/비활성 상태를 제공한다
/// - 누른 모양은 [builder]가 `states`를 보고 그린다
class SmashPressable extends StatefulWidget {
  const SmashPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.haptic,
    this.borderRadius = BorderRadius.zero,
    this.minSize = const Size.square(SmashSpacing.minTouchTarget),
    this.autofocus = false,
  });

  /// null이면 비활성
  final VoidCallback? onPressed;
  final SmashPressableBuilder builder;

  /// 지정하면 안쪽 글자 대신 이 문구를 읽는다 (아이콘 버튼은 필수로 넘긴다)
  final String? semanticLabel;

  /// 누르는 순간의 햅틱. 보통은 null이다 (성공 결과가 정해진 뒤에 화면이 부른다)
  final SmashHaptic? haptic;
  final BorderRadius borderRadius;
  final Size minSize;

  /// true이면 화면(대화상자 등)이 열릴 때 이 버튼에 포커스가 간다. 키보드, 스위치 접근 사용자가 Enter를 누르면 이 버튼이 실행된다
  final bool autofocus;

  @override
  State<SmashPressable> createState() => _SmashPressableState();
}

class _SmashPressableState extends State<SmashPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    final haptic = widget.haptic;
    if (haptic != null) SmashHaptics.fire(haptic);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final forced = SmashForcePressed.of(context);
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_enabled && (_pressed || forced)) WidgetState.pressed,
      if (_enabled && _focused) WidgetState.focused,
    };
    final scale = states.contains(WidgetState.pressed) && !context.reduceMotion
        ? SmashMotion.pressedScale
        : 1.0;

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minSize.width,
        minHeight: widget.minSize.height,
      ),
      child: AnimatedScale(
        scale: scale,
        duration: context.moveDuration(SmashMotion.fast),
        curve: SmashMotion.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _enabled ? _activate : null,
            autofocus: widget.autofocus,
            borderRadius: widget.borderRadius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            onFocusChange: (value) => setState(() {
              // 터치로 눌렀을 때는 링을 보이지 않고, 키보드 이동일 때만 보인다
              _focused = value &&
                  FocusManager.instance.highlightMode ==
                      FocusHighlightMode.traditional;
            }),
            child: widget.builder(context, states),
          ),
        ),
      ),
    );

    final label = widget.semanticLabel;
    if (label != null) {
      content = Semantics(
        button: true,
        enabled: _enabled,
        label: label,
        onTap: _enabled ? _activate : null,
        excludeSemantics: true,
        child: content,
      );
    } else {
      content = Semantics(button: true, enabled: _enabled, child: content);
    }
    return content;
  }
}
