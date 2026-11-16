import 'package:flutter/material.dart';

import '../colors.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';

/// 가운데 뜨는 대화상자를 연다. [builder]에는 보통 [SmashDialog]를 돌려준다.
/// 닫으면 null, [Navigator.pop]에 값을 넘기면 그 값이 돌아온다.
Future<T?> showSmashDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: SmashColors.scrim,
    animationStyle: AnimationStyle(
      duration: SmashMotion.base,
      reverseDuration: SmashMotion.exit,
      curve: SmashMotion.easeOut,
    ),
    builder: builder,
  );
}

/// 위험한 확인(destructive)의 확인 버튼 글자로 쓸 수 없는 모호한 말. 무엇을 하는 버튼인지 글자만 읽어도 알 수 있어야 한다
const _vagueConfirmLabels = {'확인', '예', '네'};

/// 예/아니오 확인. 확인을 눌렀을 때만 true이고, 취소와 바깥 누르기, 뒤로 가기는 모두 false다.
///
/// - [confirmLabel]은 꼭 적어야 한다 (기본값이 없다). "보내기", "삭제"처럼 하는 일이 드러나게 쓴다
/// - [destructive]가 true이면 되돌리기 어려운 일(삭제, 탈퇴, 마감)이다:
///   - 확인 버튼이 빨간색이고, [confirmLabel]이 '확인', '예', '네'이면 안 된다 (assert). 색을 못 보는 사람도 글자로 알 수 있어야 한다
///   - 처음 포커스는 취소 버튼에 간다. 키보드나 스위치 접근으로 Enter를 눌러도 위험한 일이 바로 실행되지 않는다
///     (화면의 버튼 순서는 그대로다)
/// - 버튼은 세로로 쌓는다: 확인(주 행동)이 위, 취소가 아래. 글자가 길어지거나 확대돼도 깨지지 않는다
Future<bool> showSmashConfirm({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = '취소',
  bool destructive = false,
  bool barrierDismissible = true,
}) {
  // async 함수 안에서 assert가 터지면 호출한 자리가 아니라 Future 오류가 되어 놓치기 쉽다. 그래서 async를 쓰지 않는다
  assert(
    !destructive || !_vagueConfirmLabels.contains(confirmLabel.trim()),
    "destructive 확인의 confirmLabel은 '확인', '예', '네'일 수 없습니다. 하는 일이 드러나게 쓰세요 (예: '삭제'): '$confirmLabel'",
  );
  return showSmashDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => SmashDialog(
      title: title,
      message: message,
      actions: [
        SmashButton(
          label: confirmLabel,
          variant: destructive
              ? SmashButtonVariant.danger
              : SmashButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SmashButton(
          label: cancelLabel,
          variant: SmashButtonVariant.secondary,
          autofocus: destructive,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  ).then((result) => result ?? false);
}

/// 알림 하나와 버튼 하나("확인")만 있는 대화상자.
Future<void> showSmashAlert({
  required BuildContext context,
  required String title,
  String? message,
  String okLabel = '확인',
}) {
  return showSmashDialog<void>(
    context: context,
    builder: (context) => SmashDialog(
      title: title,
      message: message,
      actions: [
        SmashButton(
          label: okLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// 대화상자의 겉모양: 제목, 설명, 필요하면 [content](입력창 등), 세로로 쌓이는 [actions].
/// 내용이 길면 제목과 버튼은 고정되고 가운데만 스크롤된다.
class SmashDialog extends StatelessWidget {
  const SmashDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final Widget? content;

  /// 세로로 쌓인다. 첫 번째가 주 행동이다
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Dialog(
        backgroundColor: SmashColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(SmashSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: SmashRadius.circular(SmashRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(SmashSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: SmashText.heading),
                ),
                if (message != null || content != null)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: SmashSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (message != null)
                            Text(message!, style: SmashText.body),
                          if (message != null && content != null)
                            const SizedBox(height: SmashSpacing.md),
                          ?content,
                        ],
                      ),
                    ),
                  ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: SmashSpacing.lg),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: SmashSpacing.sm),
                    actions[i],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
