import 'package:flutter/material.dart';

import 'smash_icon_button.dart';
import 'smash_text_field.dart';

/// 비밀번호 입력창. 기본은 가려 두고, 눈 아이콘으로 보기/숨기기를 바꾼다.
///
/// 보안 규칙
/// - 앱이 비활성이 되면(다른 앱으로 전환, 화면 잠금, 앱 전환 화면) 보이던 비밀번호를 다시 가린다.
///   앱 전환 화면의 미리보기나 화면 녹화에 비밀번호 글자가 남지 않게 하려는 것이다.
/// - 복사, 잘라내기, 공유는 보기 상태에서도 막는다 (길게 눌러 나오는 메뉴와 단축키 모두).
///   붙여넣기와 전체 선택은 막지 않는다 (비밀번호 관리자와 함께 쓸 수 있어야 한다).
/// - 자동 교정, 추천어, 키보드의 개인화 학습을 끈다.
/// - 자동완성 힌트는 기본이 로그인용 [AutofillHints.password]이고,
///   새 비밀번호를 만드는 화면에서는 [AutofillHints.newPassword]를 넘긴다.
///   화면은 이 입력창을 [AutofillGroup]으로 감싸고 성공하면 `TextInput.finishAutofillContext()`를 부른다.
class SmashPasswordField extends StatefulWidget {
  const SmashPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;
  final String? errorText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmashPasswordField> createState() => _SmashPasswordFieldState();
}

class _SmashPasswordFieldState extends State<SmashPasswordField>
    with WidgetsBindingObserver {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _visible) {
      setState(() => _visible = false);
    }
  }

  // 길게 눌렀을 때 나오는 메뉴에서 붙여넣기와 전체 선택만 남긴다.
  // 복사, 잘라내기뿐 아니라 공유, 찾아보기(iOS), 웹 검색처럼 선택한 글자가 밖으로 나가는 항목도 뺀다.
  static Widget _menuWithoutCopy(BuildContext context, EditableTextState state) {
    final items = state.contextMenuButtonItems
        .where((item) =>
            item.type == ContextMenuButtonType.paste ||
            item.type == ContextMenuButtonType.selectAll)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      // 하드웨어 키보드의 복사(Ctrl/Cmd+C), 잘라내기(Ctrl/Cmd+X)도 막는다
      // (복사와 잘라내기는 같은 Intent를 쓴다. 타입을 맞춘 Action이어야 처리된다)
      actions: <Type, Action<Intent>>{
        CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
          onInvoke: (_) => null,
        ),
      },
      child: SmashTextField(
        label: widget.label,
        controller: widget.controller,
        focusNode: widget.focusNode,
        hint: widget.hint,
        helper: widget.helper,
        errorText: widget.errorText,
        obscureText: !_visible,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        contextMenuBuilder: _menuWithoutCopy,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        suffix: SmashIconButton(
          icon: _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          semanticLabel: _visible ? '비밀번호 숨기기' : '비밀번호 보기',
          onPressed: widget.enabled ? () => setState(() => _visible = !_visible) : null,
        ),
      ),
    );
  }
}
