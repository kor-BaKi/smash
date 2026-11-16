import 'package:flutter/material.dart';

import '../colors.dart';
import '../motion.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_icon_button.dart';

/// 아래에서 올라오는 시트를 연다. 닫으면 null, [Navigator.pop]에 값을 넘기면 그 값이 돌아온다.
///
/// - [isDismissible]: 바깥을 눌러 닫기. [enableDrag]: 아래로 끌어 닫기 (끄면 손잡이도 숨긴다)
/// - 입력 중인 내용이 있는 시트(날짜, 시간 고르기 등)는 둘 다 끈다. 실수로 닫혀 값이 사라지는 것을 막는다
/// - 키보드가 올라오면 시트가 키보드 위로 올라오고, 내용이 길면 시트 안에서 스크롤된다 (화면의 90%까지)
Future<T?> showSmashSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showCloseButton = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: SmashColors.scrim,
    sheetAnimationStyle: AnimationStyle(
      duration: SmashMotion.slow,
      reverseDuration: SmashMotion.exit,
      curve: SmashMotion.easeOut,
    ),
    builder: (context) => SmashSheetFrame(
      title: title,
      showCloseButton: showCloseButton,
      showHandle: enableDrag,
      child: builder(context),
    ),
  );
}

/// [showSmashSheet]가 감싸 주는 시트의 겉모양 (둥근 위쪽, 손잡이, 제목줄, 스크롤되는 내용).
class SmashSheetFrame extends StatelessWidget {
  const SmashSheetFrame({
    super.key,
    required this.child,
    this.title,
    this.showCloseButton = true,
    this.showHandle = true,
  });

  final Widget child;
  final String? title;
  final bool showCloseButton;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final hasHeader = title != null || showCloseButton;

    // 아래 맞춤은 showModalBottomSheet가 해 준다. 여기서 화면 전체를 차지하면 시트 바깥(스크림)을 눌러도 닫히지 않는다
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (media.size.height - keyboard) * 0.9,
        ),
        child: Semantics(
          namesRoute: title != null,
          // 자식(닫기 버튼, 내용)이 시트 노드 하나로 합쳐지지 않고 각각 읽히게 한다
          explicitChildNodes: true,
          label: title,
          child: Material(
            color: SmashColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SmashRadius.xl),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              // 키보드가 올라와 있으면 홈 인디케이터 영역은 키보드가 덮고 있다
              bottom: keyboard == 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHandle)
                    ExcludeSemantics(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: SmashSpacing.sm),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: SmashColors.textDisabled,
                            borderRadius: SmashRadius.circular(
                              SmashRadius.full,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (hasHeader)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        SmashSpacing.md,
                        showHandle ? SmashSpacing.xs : SmashSpacing.sm,
                        SmashSpacing.xs,
                        0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: SmashSpacing.minTouchTarget,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: title == null
                                  ? const SizedBox.shrink()
                                  : Semantics(
                                      header: true,
                                      child: Text(
                                        title!,
                                        style: SmashText.heading,
                                      ),
                                    ),
                            ),
                            if (showCloseButton)
                              SmashIconButton(
                                icon: Icons.close,
                                semanticLabel: '닫기',
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        SmashSpacing.md,
                        SmashSpacing.sm,
                        SmashSpacing.md,
                        SmashSpacing.md,
                      ),
                      child: child,
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
