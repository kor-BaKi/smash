import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SmashCardType { black, lime, green, coral }

class SmashCard extends StatelessWidget {
  final SmashCardType type;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SmashCard({
    super.key,
    required this.type,
    required this.child,
    this.padding,
    this.onTap,
  });

  Color get _bg {
    switch (type) {
      case SmashCardType.black:
        return AppColors.card;
      case SmashCardType.lime:
        return AppColors.lime;
      case SmashCardType.green:
        return AppColors.green;
      case SmashCardType.coral:
        return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: padding ?? const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
    );
  }
}
