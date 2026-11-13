import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

enum SmashSectionHeaderStyle {
  /// 화면의 큰 구역 제목 (오늘 활동, 진행 중인 투표)
  title,

  /// 목록 위의 작은 이름표 (정규, 이월 등)
  label,
}

/// 구역 제목. 문장형으로 쓰고 대문자나 장식은 쓰지 않는다.
/// 스크린리더는 제목(heading)으로 읽어 구역 사이를 건너뛸 수 있다.
class SmashSectionHeader extends StatelessWidget {
  const SmashSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.style = SmashSectionHeaderStyle.title,
    this.padding = const EdgeInsets.symmetric(
      horizontal: SmashSpacing.md,
      vertical: SmashSpacing.sm,
    ),
  });

  final String title;

  /// 오른쪽 동작 (예: "전체 보기" 텍스트 버튼). 터치 영역 48dp는 넘기는 쪽이 지킨다.
  /// 폭은 자기 내용만큼으로 줄여서 놓는다. SmashButton을 기본값(expanded: true, 폭 무한)으로 넘겨도
  /// 레이아웃 오류가 나지 않고 글자 폭만큼만 차지한다.
  final Widget? trailing;
  final SmashSectionHeaderStyle style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textStyle = switch (style) {
      SmashSectionHeaderStyle.title => SmashText.heading,
      SmashSectionHeaderStyle.label => SmashText.caption.copyWith(
          color: SmashColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
    };

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: textStyle),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: SmashSpacing.sm),
            // 폭이 무한한 위젯(SmashButton 기본값 등)이 와도 Row가 깨지지 않게 내용 폭으로 줄인다
            IntrinsicWidth(child: trailing!),
          ],
        ],
      ),
    );
  }
}
