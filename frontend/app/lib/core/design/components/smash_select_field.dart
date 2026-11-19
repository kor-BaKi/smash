import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';
import 'smash_list_row.dart';
import 'smash_pressable.dart';
import 'smash_sheet.dart';

/// [SmashSelectField]의 선택지 하나
class SmashOption<T> {
  const SmashOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? subtitle;

  /// false이면 보이지만 고를 수 없다 (스크린리더에는 비활성으로 읽힌다)
  final bool enabled;
}

class _Pick<T> {
  const _Pick(this.value);

  /// 값이 null일 수도 있어서(예: "미배정") 시트가 닫혀서 null인 것과 구분하려고 감싼다
  final T value;
}

/// 여러 선택지 중 하나를 고르는 입력칸. 누르면 시트가 열려 선택지 목록(체크 표시)이 나오고, 하나를 고르면 닫힌다.
/// 모양은 [SmashTextField], [SmashDateField]와 같다 (라벨은 칸 위, 오류는 칸 아래 아이콘과 함께).
///
/// - 값이 선택지에 없으면 [placeholder]를 보여준다
/// - 고르면 시트가 닫히고, 지금 값과 **다른** 것을 골랐을 때만 [onChanged]가 불린다. 시트를 닫기만 하면 불리지 않는다
/// - 입력 중인 값이 없는 시트라서 바깥 누르기, 끌어서 닫기, 뒤로 가기로 닫을 수 있다 (닫아도 값은 그대로)
/// - 시트가 닫히면 포커스가 이 칸으로 돌아온다. 선택지가 많으면 시트 안에서 스크롤되고, 열릴 때 고른 선택지가 보이는 위치에 놓인다
/// - 선택지가 없으면 비활성이다. 스크린리더는 "라벨, 값(또는 선택 안 함)"을 읽고 버튼으로 읽는다
class SmashSelectField<T> extends StatefulWidget {
  const SmashSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = '선택해 주세요',
    this.helper,
    this.errorText,
    this.enabled = true,
    this.sheetTitle,
  });

  final String label;
  final T? value;
  final List<SmashOption<T>> options;
  final ValueChanged<T> onChanged;
  final String placeholder;
  final String? helper;
  final String? errorText;
  final bool enabled;

  /// 시트 제목. 기본은 라벨이다
  final String? sheetTitle;

  @override
  State<SmashSelectField<T>> createState() => _SmashSelectFieldState<T>();
}

class _SmashSelectFieldState<T> extends State<SmashSelectField<T>> {
  final _focus = FocusNode(debugLabel: '선택 입력칸');

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;
  bool get _canOpen => widget.enabled && widget.options.isNotEmpty;

  SmashOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final picked = await showSmashSheet<_Pick<T>>(
      context: context,
      title: widget.sheetTitle ?? widget.label,
      builder: (sheetContext) => _OptionList<T>(
        options: widget.options,
        value: widget.value,
        onPick: (value) => Navigator.of(sheetContext).pop(_Pick<T>(value)),
      ),
    );
    if (!mounted) return;
    _focus.requestFocus();
    if (picked != null && picked.value != widget.value) {
      widget.onChanged(picked.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueText = _selected?.label;
    final enabled = _canOpen;
    final borderColor = !enabled
        ? SmashColors.line
        : (_hasError ? SmashColors.danger : SmashColors.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨은 칸과 하나로 묶어 읽으므로 따로 읽지 않는다
        ExcludeSemantics(
          child: _text(
            widget.label,
            style: SmashText.caption.copyWith(
              color: SmashColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: SmashSpacing.xs),
        Semantics(
          hint:
              widget.helper ??
              (widget.options.isEmpty ? '선택할 항목이 없어요' : '눌러서 선택해요'),
          child: SmashPressable(
            onPressed: enabled ? _open : null,
            focusNode: _focus,
            semanticLabel: '${widget.label}, ${valueText ?? '선택 안 함'}',
            borderRadius: SmashRadius.circular(SmashRadius.md),
            minSize: const Size(0, 52),
            builder: (context, states) {
              final focused = states.contains(WidgetState.focused);
              final thick = focused || _hasError;
              return Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: SmashSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: enabled
                      ? SmashColors.surface
                      : SmashColors.fillDisabled,
                  borderRadius: SmashRadius.circular(SmashRadius.md),
                  border: Border.all(
                    color: focused && !_hasError
                        ? SmashColors.brand
                        : borderColor,
                    width: thick ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _text(
                        valueText ?? widget.placeholder,
                        style: SmashText.body.copyWith(
                          color: !enabled
                              ? SmashColors.textDisabled
                              : (valueText == null
                                    ? SmashColors.textSecondary
                                    : SmashColors.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: SmashSpacing.sm),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: enabled
                          ? SmashColors.textSecondary
                          : SmashColors.textDisabled,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: Semantics(
              liveRegion: true,
              label: '오류: ${widget.errorText}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: SmashColors.danger,
                    ),
                  ),
                  const SizedBox(width: SmashSpacing.xs),
                  Expanded(
                    child: _text(
                      widget.errorText!,
                      style: SmashText.caption.copyWith(
                        color: SmashColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (widget.helper != null && widget.helper!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: ExcludeSemantics(
              child: _text(widget.helper!, style: SmashText.caption),
            ),
          ),
      ],
    );
  }
}

/// 이 파일의 글자 위젯은 여기서만 만든다 (한 곳에서 글자 정책을 바꿀 수 있게)
Widget _text(String data, {TextStyle? style}) => SmashLabel(data, style: style);

/// 시트 안의 선택지 목록. 시트가 이미 스크롤되므로 `ListView`가 아니라 `Column`이다
/// (`ListView`는 padding을 안 주면 화면의 안전 영역이 위아래 여백으로 새어 들어온다)
class _OptionList<T> extends StatefulWidget {
  const _OptionList({
    required this.options,
    required this.value,
    required this.onPick,
  });

  final List<SmashOption<T>> options;
  final T? value;
  final ValueChanged<T> onPick;

  @override
  State<_OptionList<T>> createState() => _OptionListState<T>();
}

class _OptionListState<T> extends State<_OptionList<T>> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 선택지가 많으면 고른 선택지가 보이는 위치에서 열린다 (애니메이션 없이)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _selectedKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.4,
          duration: Duration.zero,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++)
          _row(options[i], showDivider: i < options.length - 1),
      ],
    );
  }

  Widget _row(SmashOption<T> option, {required bool showDivider}) {
    final selected = option.value == widget.value;
    Widget row = SmashListRow(
      key: selected ? _selectedKey : null,
      title: option.label,
      subtitle: option.subtitle,
      selected: selected,
      trailing: selected
          ? const Icon(Icons.check, size: 20, color: SmashColors.brand)
          : null,
      onTap: option.enabled ? () => widget.onPick(option.value) : null,
      showDivider: showDivider,
    );
    if (!option.enabled) {
      // 글자(목록 행의 노드)와 비활성 상태, 이유를 한 노드로 합쳐서 "불가, 비활성, 지금은 고를 수 없어요"로 읽힌다
      row = MergeSemantics(
        child: Semantics(
          enabled: false,
          hint: '지금은 고를 수 없어요',
          child: Opacity(opacity: 0.45, child: row),
        ),
      );
    }
    return row;
  }
}
