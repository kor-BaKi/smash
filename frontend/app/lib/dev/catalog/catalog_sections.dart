import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import 'catalog_entry.dart';

const _noop = _doNothing;
void _doNothing() {}

final buttonEntry = CatalogEntry(
  name: 'SmashButton',
  description: '주 버튼, 보조 버튼, 텍스트 버튼, 위험 버튼. 높이 52(large) 또는 48(medium).',
  states: [
    CatalogState('기본 (primary)', (_) => SmashButton(label: '참여할게요', onPressed: _noop)),
    CatalogState(
      '눌림 (primary)',
      (_) => SmashForcePressed(
        child: SmashButton(label: '참여할게요', onPressed: _noop),
      ),
    ),
    const CatalogState(
      '비활성 (primary)',
      _disabledButton,
    ),
    CatalogState(
      '로딩 (primary)',
      (_) => SmashButton(label: '참여할게요', isLoading: true, onPressed: _noop),
    ),
    CatalogState(
      '기본 (secondary, medium)',
      (_) => SmashButton(
        label: '불참해요',
        variant: SmashButtonVariant.secondary,
        size: SmashButtonSize.medium,
        onPressed: _noop,
      ),
    ),
    CatalogState(
      '기본 (text)',
      (_) => SmashButton(
        label: '나중에 할게요',
        variant: SmashButtonVariant.text,
        size: SmashButtonSize.medium,
        onPressed: _noop,
      ),
    ),
    CatalogState(
      '기본 (danger)',
      (_) => SmashButton(
        label: '탈퇴하기',
        variant: SmashButtonVariant.danger,
        onPressed: _noop,
      ),
    ),
    CatalogState(
      '긴 글자 줄바꿈',
      (_) => SmashButton(label: '참여 여부를 선택해 주세요', onPressed: _noop),
    ),
  ],
);

Widget _disabledButton(BuildContext context) =>
    const SmashButton(label: '참여할게요', onPressed: null);

final iconButtonEntry = CatalogEntry(
  name: 'SmashIconButton',
  description: '터치 영역 48x48, 아이콘 24. 스크린리더용 문구가 필수.',
  states: [
    CatalogState(
      '기본',
      (_) => Align(
        alignment: Alignment.centerLeft,
        child: SmashIconButton(icon: Icons.close, semanticLabel: '닫기', onPressed: _noop),
      ),
    ),
    CatalogState(
      '눌림',
      (_) => Align(
        alignment: Alignment.centerLeft,
        child: SmashForcePressed(
          child: SmashIconButton(icon: Icons.close, semanticLabel: '닫기', onPressed: _noop),
        ),
      ),
    ),
    const CatalogState(
      '비활성',
      _disabledIconButton,
    ),
  ],
);

Widget _disabledIconButton(BuildContext context) => const Align(
      alignment: Alignment.centerLeft,
      child: SmashIconButton(icon: Icons.close, semanticLabel: '닫기', onPressed: null),
    );
