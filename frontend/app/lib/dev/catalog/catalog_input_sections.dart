import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
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
