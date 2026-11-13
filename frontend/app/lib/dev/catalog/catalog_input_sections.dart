import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

/// 컨트롤러를 만들고 정리해 주는 카탈로그용 입력창 틀
class _FieldHost extends StatefulWidget {
  const _FieldHost({required this.builder, this.initialText = ''});

  final Widget Function(BuildContext context, TextEditingController controller) builder;
  final String initialText;

  @override
  State<_FieldHost> createState() => _FieldHostState();
}

class _FieldHostState extends State<_FieldHost> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// 값을 들고 있다가 컴포넌트가 바꾸면 그대로 반영하는 카탈로그용 틀.
/// 현재 값을 글자로도 보여 주어, 모양 변화와 실제 값이 맞는지 눈으로 확인할 수 있다.
class _StateHost<T> extends StatefulWidget {
  const _StateHost({
    required this.initial,
    required this.builder,
    required this.describe,
  });

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> onChanged) builder;
  final String Function(T value) describe;

  @override
  State<_StateHost<T>> createState() => _StateHostState<T>();
}

class _StateHostState<T> extends State<_StateHost<T>> {
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

Widget _field(
  Widget Function(BuildContext, TextEditingController) builder, {
  String text = '',
}) =>
    _FieldHost(initialText: text, builder: builder);

final textFieldEntry = CatalogEntry(
  name: 'SmashTextField',
  description: '라벨은 위에 항상 보이고, 오류는 아이콘과 문구로 아래에 보인다. 눌러서 포커스와 입력도 확인할 수 있다.',
  states: [
    CatalogState(
      '기본 (힌트)',
      (_) => _field((_, c) => SmashTextField(label: '학번', hint: '예: 20250001', controller: c)),
    ),
    CatalogState(
      '입력됨',
      (_) => _field(
        (_, c) => SmashTextField(label: '학번', controller: c),
        text: '20250001',
      ),
    ),
    CatalogState(
      '도움말',
      (_) => _field(
        (_, c) => SmashTextField(label: '학번', helper: '숫자만 입력해 주세요', controller: c),
      ),
    ),
    CatalogState(
      '에러',
      (_) => _field(
        (_, c) => SmashTextField(label: '학번', errorText: '등록되지 않은 학번이에요', controller: c),
        text: '20259999',
      ),
    ),
    CatalogState(
      '비활성',
      (_) => _field(
        (_, c) => SmashTextField(label: '학번', enabled: false, controller: c),
        text: '20250001',
      ),
    ),
    CatalogState(
      '읽기 전용',
      (_) => _field(
        (_, c) => SmashTextField(label: '이름', readOnly: true, controller: c),
        text: '김스매시',
      ),
    ),
    CatalogState(
      '긴 라벨과 긴 오류',
      (_) => _field(
        (_, c) => SmashTextField(
          label: '정산 계좌번호를 입력해 주세요',
          hint: '예: 123-456-789012',
          errorText: '계좌번호는 숫자와 하이픈만 입력할 수 있어요',
          controller: c,
        ),
      ),
    ),
    CatalogState(
      '여러 줄',
      (_) => _field(
        (_, c) => SmashTextField(
          label: '메모',
          hint: '부원에 대한 메모를 남겨 주세요',
          minLines: 3,
          maxLines: 5,
          controller: c,
        ),
      ),
    ),
  ],
);

final passwordFieldEntry = CatalogEntry(
  name: 'SmashPasswordField',
  description: '기본은 가림. 눈 아이콘으로 보기/숨기기. 복사, 공유는 막고 붙여넣기는 허용.',
  states: [
    CatalogState(
      '기본 (가림)',
      (_) => _field((_, c) => SmashPasswordField(label: '비밀번호', controller: c)),
    ),
    CatalogState(
      '입력됨 (가림)',
      (_) => _field(
        (_, c) => SmashPasswordField(label: '비밀번호', controller: c),
        text: 'abc12345',
      ),
    ),
    CatalogState(
      '에러',
      (_) => _field(
        (_, c) => SmashPasswordField(
          label: '비밀번호',
          errorText: '비밀번호가 맞지 않아요',
          controller: c,
        ),
        text: 'abc12345',
      ),
    ),
    CatalogState(
      '비활성',
      (_) => _field(
        (_, c) => SmashPasswordField(label: '비밀번호', enabled: false, controller: c),
        text: 'abc12345',
      ),
    ),
  ],
);

enum _Travel { together, alone }

Widget _segmented({
  _Travel selected = _Travel.together,
  bool disabled = false,
  bool partial = false,
}) {
  return SmashSegmentedControl<_Travel>(
    semanticLabel: '이동 방식',
    segments: [
      const SmashSegment(value: _Travel.together, label: '같이 가요'),
      SmashSegment(value: _Travel.alone, label: '따로 가요', enabled: !partial),
    ],
    selected: selected,
    onChanged: disabled ? null : (_) {},
  );
}

final segmentedEntry = CatalogEntry(
  name: 'SmashSegmentedControl',
  description: '선택은 색, 체크 아이콘, 굵은 글자로 구분한다. 조각은 같은 너비.',
  states: [
    CatalogState('기본 (첫째 선택)', (_) => _segmented()),
    CatalogState('둘째 선택', (_) => _segmented(selected: _Travel.alone)),
    CatalogState('일부 비활성', (_) => _segmented(partial: true)),
    CatalogState('전체 비활성', (_) => _segmented(disabled: true)),
    CatalogState(
      interactiveStateLabel,
      (_) => _StateHost<_Travel>(
        initial: _Travel.together,
        describe: (value) => value == _Travel.together ? '같이 가요' : '따로 가요',
        builder: (context, value, onChanged) => SmashSegmentedControl<_Travel>(
          semanticLabel: '이동 방식',
          segments: const [
            SmashSegment(value: _Travel.together, label: '같이 가요'),
            SmashSegment(value: _Travel.alone, label: '따로 가요'),
          ],
          selected: value,
          onChanged: onChanged,
        ),
      ),
    ),
    CatalogState(
      '조각 3개',
      (_) => SmashSegmentedControl<int>(
        semanticLabel: '참석 구분',
        segments: const [
          SmashSegment(value: 0, label: '정규'),
          SmashSegment(value: 1, label: '이월'),
          SmashSegment(value: 2, label: '다른 조'),
        ],
        selected: 0,
        onChanged: (_) {},
      ),
    ),
  ],
);

void _noop(bool _) {}

final switchRowEntry = CatalogEntry(
  name: 'SmashSwitchRow',
  description: '줄 어디를 눌러도 바뀐다. 높이 56 이상. 라벨, 설명, 켜짐 여부를 한 번에 읽는다.',
  states: [
    const CatalogState(
      '꺼짐',
      _switchOff,
    ),
    const CatalogState(
      '켜짐',
      _switchOn,
    ),
    const CatalogState(
      '설명 포함',
      _switchWithDescription,
    ),
    const CatalogState(
      '비활성',
      _switchDisabled,
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => _StateHost<bool>(
        initial: false,
        describe: (value) => value ? '켜짐' : '꺼짐',
        builder: (context, value, onChanged) => SmashSwitchRow(
          label: '투표 알림',
          description: '새 투표가 올라오면 알려드려요',
          value: value,
          onChanged: onChanged,
        ),
      ),
    ),
  ],
);

Widget _switchOff(BuildContext context) =>
    const SmashSwitchRow(label: '투표 알림', value: false, onChanged: _noop);
Widget _switchOn(BuildContext context) =>
    const SmashSwitchRow(label: '투표 알림', value: true, onChanged: _noop);
Widget _switchWithDescription(BuildContext context) => const SmashSwitchRow(
      label: '정산 알림',
      description: '택시비 정산 요청이 오면 알려드려요',
      value: true,
      onChanged: _noop,
    );
Widget _switchDisabled(BuildContext context) =>
    const SmashSwitchRow(label: '활동 알림', value: true, onChanged: null);

final checkboxRowEntry = CatalogEntry(
  name: 'SmashCheckboxRow',
  description: '줄 어디를 눌러도 바뀐다. 높이 48 이상. 라벨, 설명, 체크 여부를 한 번에 읽는다.',
  states: [
    const CatalogState('해제', _checkOff),
    const CatalogState('체크', _checkOn),
    const CatalogState('설명 포함', _checkWithDescription),
    const CatalogState('비활성', _checkDisabled),
    CatalogState(
      interactiveStateLabel,
      (_) => _StateHost<bool>(
        initial: false,
        describe: (value) => value ? '체크' : '해제',
        builder: (context, value, onChanged) => SmashCheckboxRow(
          label: '개인정보 처리방침에 동의해요',
          description: '가입을 위해 꼭 필요해요',
          value: value,
          onChanged: onChanged,
        ),
      ),
    ),
  ],
);

Widget _checkOff(BuildContext context) =>
    const SmashCheckboxRow(label: '개인정보 처리방침에 동의해요', value: false, onChanged: _noop);
Widget _checkOn(BuildContext context) =>
    const SmashCheckboxRow(label: '개인정보 처리방침에 동의해요', value: true, onChanged: _noop);
Widget _checkWithDescription(BuildContext context) => const SmashCheckboxRow(
      label: '개인정보 처리방침에 동의해요',
      description: '가입을 위해 꼭 필요해요',
      value: false,
      onChanged: _noop,
    );
Widget _checkDisabled(BuildContext context) =>
    const SmashCheckboxRow(label: '개인정보 처리방침에 동의해요', value: true, onChanged: null);
