import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

const _all = [
  SmashParticipationAction.attend,
  SmashParticipationAction.absent,
  SmashParticipationAction.carryover,
  SmashParticipationAction.otherGroup,
];

void _ignore(SmashParticipationAction _) {}

Widget _buttons({
  List<SmashParticipationAction> actions = _all,
  SmashParticipationAction? loading,
  bool enabled = true,
}) {
  return SmashParticipationButtons(
    actions: actions,
    onAction: _ignore,
    loadingAction: loading,
    enabled: enabled,
  );
}

/// 폭과 글자 배율을 정해서 보여준다 (블록의 글자 배율과 상관없이 같은 모습)
Widget _fixed(
  Widget child, {
  required double width,
  required double textScale,
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

/// 누르면 1.5초 동안 처리 중이 되고, 끝나면 누른 행동을 보여 준다 (더블 탭, 다른 버튼 연타가 무시되는지 확인한다)
class _ParticipationLab extends StatefulWidget {
  const _ParticipationLab();

  @override
  State<_ParticipationLab> createState() => _ParticipationLabState();
}

class _ParticipationLabState extends State<_ParticipationLab> {
  String _last = '아직 누르지 않았어요';
  int _accepted = 0;

  Future<void> _onAction(SmashParticipationAction action) async {
    setState(() => _accepted++);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _last = action.label);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmashParticipationButtons(actions: _all, onAction: _onAction),
        Padding(
          padding: const EdgeInsets.only(top: SmashSpacing.sm),
          child: Text(
            '현재 값: $_last (받아들인 누름 $_accepted번)',
            style: SmashText.caption,
          ),
        ),
      ],
    );
  }
}

final participationButtonsEntry = CatalogEntry(
  name: 'SmashParticipationButtons',
  description: '참여, 불참, 이월, 타조참. 좁으면 4개는 2×2, 더 좁으면 세로로 쌓인다. 처리 중에는 누름이 무시된다.',
  states: [
    CatalogState('기본 (4개)', (_) => _buttons()),
    CatalogState(
      '2개 (참여, 불참)',
      (_) => _buttons(
        actions: const [
          SmashParticipationAction.attend,
          SmashParticipationAction.absent,
        ],
      ),
    ),
    CatalogState(
      '3개 (참여, 이월, 타조참)',
      (_) => _buttons(
        actions: const [
          SmashParticipationAction.attend,
          SmashParticipationAction.carryover,
          SmashParticipationAction.otherGroup,
        ],
      ),
    ),
    CatalogState(
      '처리 중 (참여)',
      (_) => _buttons(loading: SmashParticipationAction.attend),
    ),
    CatalogState('비활성', (_) => _buttons(enabled: false)),
    CatalogState(
      '2×2 전환 (폭 320, 글자 2.0배)',
      (_) => _fixed(_buttons(), width: 320, textScale: 2.0),
    ),
    CatalogState(
      '세로 전환 (폭 200, 글자 2.0배)',
      (_) => _fixed(_buttons(), width: 200, textScale: 2.0),
    ),
    const CatalogState(interactiveStateLabel, _lab),
  ],
);

Widget _lab(BuildContext context) => const _ParticipationLab();
