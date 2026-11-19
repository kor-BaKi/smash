import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

const _sentence = '같이 이동하고 싶어요 오늘도 함께 가요';

/// 같은 글자를 같은 폭의 상자에 일반 Text와 SmashLabel로 나란히 놓아 줄바꿈을 비교한다
class _Compare extends StatelessWidget {
  const _Compare({
    required this.text,
    required this.width,
    this.maxLines,
    this.style = SmashText.body,
  });

  final String text;
  final double width;
  final int? maxLines;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    Widget box(String caption, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: SmashText.caption),
        const SizedBox(height: SmashSpacing.xs),
        // 글자 영역의 폭이 [width]다 (테두리와 여백은 그 바깥에 붙는다)
        Container(
          padding: const EdgeInsets.all(SmashSpacing.xs),
          decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
          child: SizedBox(width: width, child: child),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        box(
          '일반 Text (낱말 중간에서 끊길 수 있다)',
          Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: SmashSpacing.sm),
        box(
          'SmashLabel (공백에서만 줄바꿈)',
          SmashLabel(
            text,
            style: style,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

final labelEntry = CatalogEntry(
  name: 'SmashLabel',
  description:
      '한글이 낱말 중간에서 줄바꿈되지 않는 Text. 일반 Text와 같은 인자를 받고(Text의 하위 클래스), 스크린리더는 원문을 읽는다. 낱말 하나가 상자보다 길면 글자 단위로 끊기는 한계는 그대로다. 아래 "직접 눌러 보기"에서 상자 폭을 바꿔 가며 비교해 보세요.',
  states: [
    CatalogState(
      '좁은 상자 (폭 150)',
      (_) => const _Compare(text: _sentence, width: 150),
    ),
    CatalogState(
      '폭 120, 글자가 더 긴 문장',
      (_) => const _Compare(
        text: '이번 달에 참여하지 못한 날을 다음 주에 이월해서 보충할 수 있어요',
        width: 120,
      ),
    ),
    CatalogState(
      '말줄임 (최대 2줄 + …)',
      (_) => const _Compare(
        text: '아주 긴 안내 문구가 두 줄을 넘어가면 말줄임으로 줄여요 정말로 그렇게 해요',
        width: 150,
        maxLines: 2,
      ),
    ),
    CatalogState(
      '숫자와 한글이 섞인 글 (숫자끼리는 그대로)',
      (_) => const _Compare(text: '11월 11일 (수) 3명이 12분 늦게 도착했어요', width: 130),
    ),
    CatalogState(
      '낱말이 상자보다 긴 경우 (한계: 글자 단위로 끊긴다)',
      (_) => const _Compare(text: '신청하기 정규참여신청서', width: 60),
    ),
    CatalogState(
      '글자 스타일이 그대로 전달됨 (색, 굵기, 가운데 정렬)',
      (_) => const _Compare(
        text: '오늘 활동에 참여해요',
        width: 150,
        style: TextStyle(
          fontFamily: SmashText.family,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F4FD8),
          height: 1.5,
        ),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<double>(
        initial: 150,
        describe: (width) => '상자 폭 ${width.round()}',
        builder: (context, width, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Slider(
              min: 60,
              max: 300,
              divisions: 24,
              value: width,
              label: '${width.round()}',
              onChanged: onChanged,
            ),
            _Compare(text: _sentence, width: width),
          ],
        ),
      ),
    ),
  ],
);
