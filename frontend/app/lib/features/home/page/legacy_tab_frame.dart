import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 아직 옛 디자인인 탭 내용(홈, 투표, 달력, 설정)의 바탕.
///
/// 옛 화면은 흰 글자를 어두운 바탕 위에 그린다. 홈 탭 내용(`MemberHomeView`, `NeedGroupNotice`)은 자기 Scaffold가 없어서
/// 예전에는 `HomePage`의 어두운 Scaffold가 바탕이었다. 밝은 셸 안에서는 이 틀이 어두운 바탕을 대신 깔아 준다.
/// 각 탭 화면이 새 디자인으로 바뀌면(S3~S6) 그 탭에서 이 틀을 쓰지 않는다. 모두 바뀌면 파일을 지운다.
class LegacyTabFrame extends StatelessWidget {
  const LegacyTabFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.bg, child: child);
  }
}
