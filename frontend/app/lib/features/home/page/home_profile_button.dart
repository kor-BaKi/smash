import 'package:flutter/material.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/haptics.dart';
import '../../../core/design/radius.dart';

/// 홈 셸 앱바 오른쪽 위의 프로필 버튼 (이름 첫 글자 원). 누르면 내 정보가 열린다.
///
/// 터치 영역은 48 이상이고, 스크린리더는 "내 정보"로 읽는다 (이름은 읽지 않는다: 이름은 화면 안에 이미 있다).
class HomeProfileButton extends StatelessWidget {
  const HomeProfileButton({super.key, required this.name, required this.onPressed});

  /// 사용자 이름 (첫 글자를 원 안에 보인다. 비어 있으면 사람 아이콘)
  final String name;
  final VoidCallback onPressed;

  /// 스크린리더가 읽는 말
  static const semanticLabel = '내 정보';

  @override
  Widget build(BuildContext context) {
    return SmashPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      haptic: SmashHaptic.selection,
      borderRadius: SmashRadius.circular(SmashRadius.full),
      builder: (context, states) => Center(child: SmashAvatar(name: name, size: 32)),
    );
  }
}
