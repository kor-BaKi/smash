import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

const _signup = ['약관 동의', '이름 입력', '비밀번호'];
const _five = ['약관', '이름', '연락처', '조 선택', '비밀번호'];
const _long = ['개인정보 처리방침 동의', '이름과 연락처 입력', '비밀번호 설정'];

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

/// 이전/다음 버튼으로 단계를 옮겨 보는 틀: 단계가 바뀌어도 크기가 변하지 않는지 눈으로 확인한다
class _StepLab extends StatefulWidget {
  const _StepLab();

  @override
  State<_StepLab> createState() => _StepLabState();
}

class _StepLabState extends State<_StepLab> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmashStepIndicator(steps: _signup, current: _current),
        const SizedBox(height: SmashSpacing.md),
        Row(
          children: [
            Expanded(
              child: SmashButton(
                label: '이전',
                variant: SmashButtonVariant.secondary,
                size: SmashButtonSize.medium,
                onPressed: _current > 0
                    ? () => setState(() => _current--)
                    : null,
              ),
            ),
            const SizedBox(width: SmashSpacing.sm),
            Expanded(
              child: SmashButton(
                label: '다음',
                size: SmashButtonSize.medium,
                onPressed: _current < _signup.length - 1
                    ? () => setState(() => _current++)
                    : null,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: SmashSpacing.sm),
          child: Text(
            '현재 값: ${_current + 1}단계 (${_signup[_current]})',
            style: SmashText.caption,
          ),
        ),
      ],
    );
  }
}

final stepIndicatorEntry = CatalogEntry(
  name: 'SmashStepIndicator',
  description:
      '가입 같은 단계 흐름의 진행 표시. 현재는 채운 동그라미+숫자, 완료는 체크, 남은 단계는 빈 동그라미+숫자. 좁으면 세로로 바뀐다.',
  states: [
    CatalogState(
      '1단계 (3단계 중)',
      (_) => SmashStepIndicator(steps: _signup, current: 0),
    ),
    CatalogState(
      '2단계 (3단계 중)',
      (_) => SmashStepIndicator(steps: _signup, current: 1),
    ),
    CatalogState(
      '3단계 (3단계 중, 마지막)',
      (_) => SmashStepIndicator(steps: _signup, current: 2),
    ),
    CatalogState(
      '2단계 짜리 (2단계 중 1)',
      (_) => SmashStepIndicator(steps: ['정보 입력', '확인'], current: 0),
    ),
    CatalogState(
      '5단계 짜리 (3단계)',
      (_) => SmashStepIndicator(steps: _five, current: 2),
    ),
    CatalogState(
      '긴 이름 (가로로 안 들어가면 세로)',
      (_) => SmashStepIndicator(steps: _long, current: 1),
    ),
    CatalogState(
      '세로 전환 (3단계 이름, 폭 200, 글자 2.0배)',
      (_) => _fixed(
        SmashStepIndicator(steps: _signup, current: 1),
        width: 200,
        textScale: 2.0,
      ),
    ),
    CatalogState(
      '가로 (3단계, 폭 320, 글자 2.0배)',
      (_) => _fixed(
        SmashStepIndicator(steps: ['약관', '이름', '암호'], current: 1),
        width: 320,
        textScale: 2.0,
      ),
    ),
    const CatalogState(interactiveStateLabel, _lab),
  ],
);

Widget _lab(BuildContext context) => const _StepLab();
