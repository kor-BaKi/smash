import 'package:flutter/material.dart';

import '../colors.dart';
import '../typography.dart';
import 'smash_label.dart';

/// 이름의 첫 글자를 보여주는 동그란 표시. 이름은 옆에 글자로 따로 있으므로 스크린리더는 읽지 않는다.
///
/// 장식이라 시스템 글자 확대를 따라가지 않고 [size]에 비례해 고정된다 (확대돼도 원 밖으로 넘치지 않는다).
/// 이름이 비어 있으면 사람 아이콘을 보여준다.
class SmashAvatar extends StatelessWidget {
  const SmashAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  /// 첫 글자(자모가 합쳐진 한 글자 단위). 비어 있으면 null
  static String? initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final initial = initialOf(name);

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          // brandTint는 const가 아니므로 const를 붙이지 않는다
          decoration: BoxDecoration(shape: BoxShape.circle, color: SmashColors.brandTint),
          child: Center(
            child: MediaQuery.withNoTextScaling(
              child: initial == null
                  ? Icon(Icons.person_outline, size: size * 0.55, color: SmashColors.brand)
                  : SmashLabel(
                      initial,
                      style: SmashText.bodyStrong.copyWith(
                        fontSize: size * 0.4,
                        height: 1,
                        color: SmashColors.brand,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
