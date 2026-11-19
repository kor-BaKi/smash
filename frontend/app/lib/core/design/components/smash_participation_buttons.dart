import 'dart:async';

import 'package:flutter/widgets.dart';

import '../spacing.dart';
import 'smash_adaptive_row.dart';
import 'smash_button.dart';

/// 활동에 응답하는 행동. 라벨은 현행 화면과 같다 (참여 / 불참 / 이월 / 타조참).
///
/// 서버의 버튼 종류(`ATTEND`, `REGULAR`, `FREE_ATTEND` → [attend], `ABSENT` → [absent], `CARRYOVER` → [carryover],
/// `OTHER_GROUP` → [otherGroup])를 이 값으로 바꾸는 일은 화면의 몫이다.
enum SmashParticipationAction {
  attend('참여', '참여, 이 활동에 참여'),
  absent('불참', '불참, 이 활동에 불참'),
  carryover('이월', '이월, 이월할 날짜를 고르기'),
  otherGroup('타조참', '타조참, 다른 조 활동에 참여');

  const SmashParticipationAction(this.label, this.readAs);

  /// 버튼에 보이는 글자
  final String label;

  /// 스크린리더가 읽는 말: 짧은 라벨만으로는 무엇을 하는지 알 수 없어서 풀어서 읽는다
  final String readAs;
}

/// 활동 카드의 응답 버튼 줄 (참여 / 불참 / 이월 / 타조참).
///
/// - 어떤 버튼을 보일지는 [actions]가 정한다 (서버가 준 순서 그대로). 1~4개, 중복 없음
/// - 눌린 행동은 [onAction] 하나로 전달된다. 참여만 주된(primary) 버튼이고 나머지는 보조 버튼이다
/// - **좁으면 배치가 바뀐다** ([SmashAdaptiveRow]): 가장 긴 낱말이 칸보다 넓어지면 4개는 2×2, 그래도 좁으면 세로로 쌓인다.
///   읽는 순서와 포커스 순서는 배치와 상관없이 [actions] 순서다
/// - 스크린리더는 라벨을 풀어서 읽는다 (예: "타조참, 다른 조 활동에 참여")
/// - **처리 중**: [onAction]이 `Future`를 돌려주면 끝날 때까지 그 버튼은 진행 표시를 보이고 모든 버튼의 누름이 무시된다
///   (더블 탭, 다른 버튼 연타로 응답이 두 번 가지 않는다). 화면이 요청을 직접 관리한다면 [loadingAction]으로 같은 상태를 보인다
/// - **비활성**: [onAction]이 null이거나 [enabled]가 false이면 모든 버튼이 비활성이다
///
/// 행 수가 적은 고정 영역에만 쓴다 ([SmashAdaptiveRow]의 제한과 같다).
class SmashParticipationButtons extends StatefulWidget {
  const SmashParticipationButtons({
    super.key,
    required this.actions,
    required this.onAction,
    this.loadingAction,
    this.enabled = true,
    this.semanticLabel = '참여 방법',
  }) : assert(actions.length >= 1 && actions.length <= 4, '행동은 1~4개');

  final List<SmashParticipationAction> actions;

  /// 눌린 행동을 받는다. `Future`를 돌려주면 끝날 때까지 처리 중으로 보인다. null이면 전체 비활성
  final FutureOr<void> Function(SmashParticipationAction action)? onAction;

  /// 화면이 요청을 직접 관리할 때 처리 중인 행동 (null이면 처리 중 아님)
  final SmashParticipationAction? loadingAction;

  final bool enabled;

  /// 이 버튼 줄이 무엇인지 (스크린리더가 먼저 읽는다)
  final String semanticLabel;

  /// 버튼 좌우 여백: 한 줄에 4개가 들어갈 수 있게 기본(24)보다 좁다
  static const double buttonPadding = SmashSpacing.sm;

  @override
  State<SmashParticipationButtons> createState() =>
      _SmashParticipationButtonsState();
}

class _SmashParticipationButtonsState extends State<SmashParticipationButtons> {
  SmashParticipationAction? _pending;

  /// 화면이 보여 주는 처리 중 행동 (화면이 준 값이 우선)
  SmashParticipationAction? get _loading => widget.loadingAction ?? _pending;

  void _press(SmashParticipationAction action) {
    final onAction = widget.onAction;
    if (onAction == null || !widget.enabled || _loading != null) return;
    final result = onAction(action);
    if (result is! Future) return;
    setState(() => _pending = action);
    result
        .catchError((Object error, StackTrace stack) {
          // 오류 처리는 부르는 쪽의 몫이다. 여기서는 처리 중 표시만 끝내고, 삼키지 않고 보고한다
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'SmashParticipationButtons',
            ),
          );
        })
        .whenComplete(() {
          if (mounted) setState(() => _pending = null);
        });
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.actions.toSet().length == widget.actions.length,
      '같은 행동이 두 번 들어 있다: ${widget.actions}',
    );
    final loading = _loading;
    final interactive = widget.onAction != null && widget.enabled;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SmashAdaptiveRow(
        spacing: SmashSpacing.sm,
        runSpacing: SmashSpacing.sm,
        children: [
          for (final action in widget.actions)
            SmashButton(
              // 같은 행동의 버튼은 배치가 바뀌어도 같은 요소로 이어진다
              key: ValueKey(action),
              label: action.label,
              semanticLabel: action.readAs,
              variant: action == SmashParticipationAction.attend
                  ? SmashButtonVariant.primary
                  : SmashButtonVariant.secondary,
              expanded: false,
              horizontalPadding: SmashParticipationButtons.buttonPadding,
              isLoading: loading == action,
              // 처리 중에는 다른 버튼도 비활성으로 보인다 (누름은 어차피 무시)
              onPressed: interactive && (loading == null || loading == action)
                  ? () => _press(action)
                  : null,
            ),
        ],
      ),
    );
  }
}
