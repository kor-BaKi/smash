import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

void _ignore() {}

Widget _row({
  String label = '목요일 저녁 7시',
  SmashPollResult? result,
  bool isMine = false,
  bool selectable = false,
  bool isLoading = false,
}) {
  return SmashPollOptionRow(
    label: label,
    result: result,
    isMine: isMine,
    isLoading: isLoading,
    onSelect: selectable ? _ignore : null,
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

const _options = ['목요일 저녁 7시', '토요일 오전 10시', '둘 다 어려워요'];

/// 투표 → 결과 → 다시 투표를 눌러 볼 수 있는 틀 (서버 대신 1초 뒤에 결과가 나온다)
class _PollLab extends StatefulWidget {
  const _PollLab();

  @override
  State<_PollLab> createState() => _PollLabState();
}

class _PollLabState extends State<_PollLab> {
  final List<int> _votes = [3, 2, 1];
  int? _mine;
  int? _sending;

  int get _total => _votes.fold(0, (a, b) => a + b);

  Future<void> _vote(int index) async {
    setState(() => _sending = index);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _votes[index]++;
      _mine = index;
      _sending = null;
    });
  }

  void _cancel() {
    setState(() {
      _votes[_mine!]--;
      _mine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voted = _mine != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: SmashSpacing.sm),
            child: SmashPollOptionRow(
              label: _options[i],
              isMine: _mine == i,
              isLoading: _sending == i,
              result: voted
                  ? SmashPollResult(votes: _votes[i], totalVotes: _total)
                  : null,
              onSelect: (voted || _sending != null) ? null : () => _vote(i),
            ),
          ),
        if (voted)
          SmashButton(
            label: '다시 투표',
            variant: SmashButtonVariant.text,
            onPressed: _cancel,
          ),
        Text(
          '현재 값: ${_mine == null ? '아직 투표하지 않았어요' : '${_options[_mine!]}에 투표'}',
          style: SmashText.caption,
        ),
      ],
    );
  }
}

final pollOptionRowEntry = CatalogEntry(
  name: 'SmashPollOptionRow',
  description:
      '투표 전에는 눌러서 고르고, 투표 후와 마감 후에는 비율 막대, 비율, 득표 수를 보여준다. 폭이 좁으면 결과가 이름 아래로 내려간다.',
  states: [
    CatalogState('투표 전 (선택 가능)', (_) => _row(selectable: true)),
    CatalogState(
      '눌림 (투표 전)',
      (_) => SmashForcePressed(child: _row(selectable: true)),
    ),
    CatalogState(
      '처리 중 (보내는 중)',
      (_) => _row(selectable: true, isLoading: true),
    ),
    CatalogState(
      '결과: 내가 고른 선택지 (익명)',
      (_) => _row(
        isMine: true,
        result: const SmashPollResult(votes: 6, totalVotes: 10),
      ),
    ),
    CatalogState(
      '결과: 다른 선택지 (익명)',
      (_) => _row(
        label: '토요일 오전 10시',
        result: const SmashPollResult(votes: 3, totalVotes: 10),
      ),
    ),
    CatalogState(
      '결과: 기명 (투표한 사람)',
      (_) => _row(
        isMine: true,
        result: const SmashPollResult(
          votes: 3,
          totalVotes: 8,
          voters: ['김하늘', '이도윤', '박서준'],
        ),
      ),
    ),
    CatalogState(
      '결과: 0표',
      (_) => _row(result: const SmashPollResult(votes: 0, totalVotes: 8)),
    ),
    CatalogState(
      '결과: 전체 0표',
      (_) => _row(result: const SmashPollResult(votes: 0, totalVotes: 0)),
    ),
    CatalogState(
      '마감: 결과만 (누를 수 없음)',
      (_) => _row(result: const SmashPollResult(votes: 5, totalVotes: 8)),
    ),
    CatalogState(
      '긴 이름 (여러 줄)',
      (_) => _row(
        label: '정규 활동을 목요일 저녁 7시에서 토요일 오전 10시로 옮기는 것에 찬성해요',
        selectable: true,
      ),
    ),
    CatalogState(
      '좁은 폭 전환 (폭 200, 글자 2.0배)',
      (_) => _fixed(
        _row(
          isMine: true,
          result: const SmashPollResult(votes: 6, totalVotes: 10),
        ),
        width: 200,
        textScale: 2.0,
      ),
    ),
    const CatalogState(interactiveStateLabel, _lab),
  ],
);

Widget _lab(BuildContext context) => const _PollLab();
