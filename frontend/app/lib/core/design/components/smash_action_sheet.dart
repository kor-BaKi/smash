import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_button.dart';
import 'smash_pressable.dart';
import 'smash_sheet.dart';

/// [showSmashActionSheet]의 행동 하나
///
/// [destructive]인 행동(삭제, 탈퇴, 마감 등 되돌리기 어려운 일)은 빨간 글자와 **아이콘**으로 구분한다.
/// 색을 못 보는 사람도 알 수 있어야 하므로 [icon]이 꼭 필요하다 (assert)
class SmashAction<T extends Object> {
  const SmashAction({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  }) : assert(
         !destructive || icon != null,
         '위험한 행동(destructive)은 색만으로 구분되지 않게 icon이 필요합니다',
       );

  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;

  /// false이면 보이지만 누를 수 없다
  final bool enabled;
}

/// 아래에서 올라오는 행동 목록(메뉴)을 열고, 고른 행동의 `value`를 돌려준다. 취소하거나 닫으면 null이다.
///
/// - 행은 높이 56 이상, 아이콘 + 글자이다. 맨 아래에 따로 "취소" 버튼이 있다
/// - 입력 중인 값이 없는 시트라서 바깥 누르기, 끌어서 닫기, 뒤로 가기로 닫을 수 있다 (모두 null)
/// - **위험한 행동이 하나라도 있으면** 시트가 열릴 때 포커스가 취소 버튼에 간다. 키보드나 스위치 접근으로 Enter를 눌러도
///   위험한 일이 바로 실행되지 않는다. 위험한 행동은 고른 뒤 화면이 `showSmashConfirm`으로 한 번 더 확인하는 것을 권한다
/// - [message]는 제목 아래의 짧은 설명이다
Future<T?> showSmashActionSheet<T extends Object>({
  required BuildContext context,
  required List<SmashAction<T>> actions,
  String? title,
  String? message,
  String cancelLabel = '취소',
}) {
  assert(actions.isNotEmpty, '행동은 하나 이상');
  final hasDestructive = actions.any((action) => action.destructive);
  return showSmashSheet<T>(
    context: context,
    title: title,
    // 취소 버튼이 따로 있으므로 제목줄의 닫기 버튼은 두지 않는다
    showCloseButton: false,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          _text(message, style: SmashText.body),
          const SizedBox(height: SmashSpacing.sm),
        ],
        for (var i = 0; i < actions.length; i++)
          _ActionRow<T>(
            action: actions[i],
            showDivider: i < actions.length - 1,
            onPick: () => Navigator.of(sheetContext).pop(actions[i].value),
          ),
        const SizedBox(height: SmashSpacing.md),
        SmashButton(
          label: cancelLabel,
          variant: SmashButtonVariant.secondary,
          autofocus: hasDestructive,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      ],
    ),
  );
}

/// 이 파일의 글자 위젯은 여기서만 만든다 (한 곳에서 글자 정책을 바꿀 수 있게)
Widget _text(String data, {TextStyle? style}) => Text(data, style: style);

class _ActionRow<T extends Object> extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.showDivider,
    required this.onPick,
  });

  final SmashAction<T> action;
  final bool showDivider;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final color = !action.enabled
        ? SmashColors.textDisabled
        : (action.destructive ? SmashColors.danger : SmashColors.text);

    return Semantics(
      hint: action.destructive ? '되돌리기 어려울 수 있는 작업이에요' : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SmashPressable(
            onPressed: action.enabled ? onPick : null,
            semanticLabel: action.label,
            minSize: const Size(0, 56),
            builder: (context, states) => Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: SmashSpacing.xs,
                vertical: SmashSpacing.sm,
              ),
              color:
                  states.contains(WidgetState.pressed) ||
                      states.contains(WidgetState.focused)
                  ? SmashColors.brandTintSoft
                  : Colors.transparent,
              child: Row(
                children: [
                  if (action.icon != null) ...[
                    Icon(action.icon, size: 24, color: color),
                    const SizedBox(width: SmashSpacing.md),
                  ],
                  Expanded(
                    child: _text(
                      action.label,
                      style: SmashText.body.copyWith(
                        color: color,
                        fontWeight: action.destructive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider)
            const Divider(height: 1, thickness: 1, color: SmashColors.line),
        ],
      ),
    );
  }
}
