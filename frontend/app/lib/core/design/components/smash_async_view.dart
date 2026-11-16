import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'smash_empty.dart';
import 'smash_error_view.dart';
import 'smash_skeleton.dart';

/// [AsyncValue] 하나를 로딩, 오류, 비어 있음, 내용으로 나누어 그려 준다. (Riverpod의 AsyncValue에만 의존한다)
///
/// - 처음 불러오는 중: [loading] (없으면 [SmashSkeletonList])
/// - 불러오지 못함(이전 내용 없음): [SmashErrorView]. 다시 시도해서 불러오는 중이면 다시 로딩을 보여준다
/// - 이전 내용이 있는 채로 새로고침 중이거나 새로고침에 실패: 이전 내용을 그대로 보여주고,
///   실패했으면 위에 [SmashErrorBanner]를 붙인다 (화면이 갑자기 오류 화면으로 바뀌지 않는다)
/// - [isEmpty]가 true를 돌려주면 [empty]를 보여준다
class SmashAsyncView<T> extends StatelessWidget {
  const SmashAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final current = value.requireValue;
      final showEmpty = isEmpty?.call(current) ?? false;
      final content = showEmpty
          ? (empty ?? const SmashEmpty(title: '아직 아무것도 없어요', scrollable: true))
          : data(context, current);

      // 새로고침에 실패했지만 이전 내용이 있다: 내용은 그대로 두고 위에 안내만 붙인다
      if (value.hasError && !value.isLoading) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmashErrorBanner(error: value.error, onRetry: onRetry),
            Expanded(child: content),
          ],
        );
      }
      return content;
    }

    // 다시 시도해서 불러오는 중이면(이전 오류만 남아 있어도) 오류 화면이 아니라 로딩을 보여준다
    if (value.isLoading) return loading ?? const SmashSkeletonList();

    return SmashErrorView(error: value.error, onRetry: onRetry, scrollable: true);
  }
}
