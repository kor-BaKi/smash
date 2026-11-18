import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';

/// 안쪽의 [SmashSkeleton]들이 함께 깜빡이게 하는 틀. 시스템의 "동작 줄이기"가 켜져 있으면 깜빡이지 않는다.
class SmashSkeletonPulse extends StatefulWidget {
  const SmashSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SmashSkeletonPulse> createState() => _SmashSkeletonPulseState();
}

class _SmashSkeletonPulseState extends State<SmashSkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PulseScope(animation: _controller, child: widget.child);
  }
}

class _PulseScope extends InheritedWidget {
  const _PulseScope({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PulseScope>()?.animation;

  @override
  bool updateShouldNotify(_PulseScope oldWidget) => animation != oldWidget.animation;
}

/// 내용이 불러와지기 전에 자리를 잡아 주는 회색 막대. 스크린리더는 읽지 않는다
/// (묶음 전체의 "불러오는 중"은 [SmashSkeletonList]가 알린다).
class SmashSkeleton extends StatelessWidget {
  const SmashSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = SmashRadius.sm,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final animation = _PulseScope.maybeOf(context);
    final box = animation == null
        ? _bar(SmashColors.fillDisabled)
        : AnimatedBuilder(
            animation: animation,
            builder: (context, _) => _bar(
              Color.lerp(SmashColors.fillDisabled, SmashColors.line, animation.value)!,
            ),
          );
    return ExcludeSemantics(child: box);
  }

  Widget _bar(Color color) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : SmashRadius.circular(radius),
        ),
        child: SizedBox(width: circle ? height : width, height: height),
      );
}

/// 목록이 불러와지는 동안 보여주는 자리표시. 줄 높이는 [SmashListRow]와 비슷하다.
/// 스크린리더에는 "불러오는 중" 하나만 알린다.
class SmashSkeletonList extends StatelessWidget {
  const SmashSkeletonList({super.key, this.itemCount = 6, this.showAvatar = true});

  final int itemCount;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '불러오는 중',
      liveRegion: true,
      container: true,
      child: SmashSkeletonPulse(
        child: ListView.builder(
          // padding을 안 주면 화면의 안전 영역(노치, 홈 인디케이터)이 위아래 여백으로 암묵적으로 더해져서, 상자 안에 둔 스켈레톤의 위에 큰 빈 공간이 생긴다
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: SmashSpacing.md, vertical: SmashSpacing.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  if (showAvatar) ...[
                    const SmashSkeleton(height: 40, circle: true),
                    const SizedBox(width: SmashSpacing.md),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FractionallySizedBox(widthFactor: 0.6, child: SmashSkeleton(height: 16)),
                        SizedBox(height: SmashSpacing.sm),
                        FractionallySizedBox(widthFactor: 0.4, child: SmashSkeleton(height: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
