import 'package:flutter/material.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';

/// 값이 바뀌는 컴포넌트를 카탈로그에서 직접 눌러 볼 수 있게 상태를 들고 있는 틀.
/// 바뀐 값을 글자로도 보여줘서, 눌렀을 때 실제로 값이 바뀌는지 기기에서 확인할 수 있다.
class CatalogStateHost<T> extends StatefulWidget {
  const CatalogStateHost({
    super.key,
    required this.initial,
    required this.builder,
    required this.describe,
  });

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> onChanged) builder;
  final String Function(T value) describe;

  @override
  State<CatalogStateHost<T>> createState() => CatalogStateHostState<T>();
}

class CatalogStateHostState<T> extends State<CatalogStateHost<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.builder(context, _value, (next) => setState(() => _value = next)),
        Padding(
          padding: const EdgeInsets.only(top: SmashSpacing.sm),
          child: Text('현재 값: ${widget.describe(_value)}', style: SmashText.caption),
        ),
      ],
    );
  }
}
