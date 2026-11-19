import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 한글 입력기(IME)가 글자를 조합하는 중인지.
///
/// 한글은 "ㅎ → 하 → 한"처럼 입력 도중에 글자가 바뀐다. 조합 중인 값으로 검증하거나
/// 글자를 잘라 내면 오류가 깜빡이거나 입력이 끊기므로, 검증과 정리(공백 제거 등)는
/// 조합이 끝난 뒤(이 값이 false일 때)에만 한다. 검색처럼 입력과 함께 걸러 내는 곳은 조합 중에도 쓴다.
extension SmashTextEditingValue on TextEditingValue {
  bool get isComposing => composing.isValid && !composing.isCollapsed;
}

/// SMASH 입력창.
///
/// - 라벨은 입력창 위에 항상 보인다 (힌트만으로 라벨을 대신하지 않는다)
/// - 오류는 아이콘과 문구로 입력창 아래에 보이고, 스크린리더는 "오류: …"로 읽는다
/// - 입력창 바깥을 누르면 키보드가 내려간다 (숫자 키패드에는 완료 키가 없는 기기가 있어서)
/// - 모양은 테마에 의존하지 않고 토큰으로 직접 정한다
class SmashTextField extends StatelessWidget {
  const SmashTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.autofocus = false,
    this.prefix,
    this.suffix,
    this.contextMenuBuilder,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 입력 예시. 라벨을 대신하지 않는다 (예: "예: 20250001")
  final String? hint;

  /// 입력창 아래 보조 설명. 오류가 있으면 오류가 대신 보인다
  final String? helper;
  final String? errorText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// 자동완성 힌트 (학번은 username, 비밀번호는 password 등). 비밀번호 관리자 연동에 쓰인다.
  /// 생략(null)하면 이 입력창은 자동완성을 쓰지 않는다 (Flutter 기본값은 빈 목록이지만
  /// 이름, 메모, 가입코드처럼 자동완성이 필요 없는 곳이 대부분이라 끄는 쪽을 기본으로 했다)
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  /// 글자 수 제한. 한글 조합 중에는 자르지 않고 조합이 끝난 뒤에 자른다.
  /// (Flutter 기본값은 Android에서 조합 중에도 바로 자르고 iOS에서는 조합이 끝난 뒤에 자른다.
  /// 플랫폼마다 입력감이 달라지지 않도록 항상 "조합이 끝난 뒤"로 통일했다)
  /// 글자 수 표시는 하지 않는다
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;

  /// 학번, 가입코드처럼 자동 교정이 필요 없는 곳은 false
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableIMEPersonalizedLearning;
  final bool autofocus;
  final Widget? prefix;

  /// 입력창 안쪽 오른쪽 위젯. 누르는 동안 입력창의 포커스를 유지한다
  final Widget? suffix;

  /// 길게 눌렀을 때 나오는 메뉴(복사, 붙여넣기, 전체 선택 등).
  /// null이면 Flutter 기본 메뉴를 쓴다. (TextField에 null을 그대로 넘기면 메뉴가 사라진다)
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  // Flutter TextField의 기본 메뉴와 같다. TextField는 인자를 생략하면 이 메뉴를 쓰지만
  // null을 직접 넘기면 메뉴가 없어지므로, 우리가 기본값을 대신 채워 넘긴다.
  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: SmashRadius.circular(SmashRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      hintText: hint,
      hintStyle: SmashText.body.copyWith(color: SmashColors.textSecondary),
      counterText: '',
      filled: true,
      fillColor: enabled ? SmashColors.surface : SmashColors.fillDisabled,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SmashSpacing.md,
        vertical: 14,
      ),
      constraints: const BoxConstraints(minHeight: 52),
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: _border(SmashColors.border, 1),
      enabledBorder: _border(_hasError ? SmashColors.danger : SmashColors.border, 1),
      focusedBorder: _border(_hasError ? SmashColors.danger : SmashColors.brand, 2),
      disabledBorder: _border(SmashColors.line, 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨은 입력창과 하나로 묶어 읽으므로 따로 읽지 않는다
        ExcludeSemantics(
          child: SmashLabel(
            label,
            style: SmashText.caption.copyWith(
              color: SmashColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: SmashSpacing.xs),
        Semantics(
          label: label,
          hint: helper,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: decoration,
            style: SmashText.body,
            cursorColor: SmashColors.brand,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            maxLength: maxLength,
            maxLengthEnforcement: maxLength == null
                ? null
                : MaxLengthEnforcement.truncateAfterCompositionEnds,
            maxLines: obscureText ? 1 : maxLines,
            minLines: obscureText ? null : minLines,
            enabled: enabled,
            readOnly: readOnly,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions,
            enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
            autofocus: autofocus,
            contextMenuBuilder: contextMenuBuilder ?? _defaultContextMenuBuilder,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: Semantics(
              liveRegion: true,
              label: '오류: $errorText',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.error_outline, size: 16, color: SmashColors.danger),
                  ),
                  const SizedBox(width: SmashSpacing.xs),
                  Expanded(
                    child: SmashLabel(
                      errorText!,
                      style: SmashText.caption.copyWith(color: SmashColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (helper != null && helper!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: ExcludeSemantics(child: SmashLabel(helper!, style: SmashText.caption)),
          ),
      ],
    );
  }
}
