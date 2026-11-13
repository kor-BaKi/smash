import 'package:flutter/material.dart';

import 'smash_app_bar.dart';
import 'smash_bottom_nav.dart';
import 'smash_scaffold.dart';

/// 하단 탭이 있는 화면의 틀. 어느 탭이 선택됐는지와 탭 바꾸기는 화면(라우터)이 정하고,
/// 이 위젯은 그리기만 한다. [body]에는 지금 탭의 내용을 넘긴다.
///
/// 키보드가 올라오면 탭 막대를 숨겨서 입력 공간을 지킨다.
class SmashTabShell extends StatelessWidget {
  const SmashTabShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.appBar,
  });

  final List<SmashNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final SmashAppBar? appBar;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SmashScaffold(
      appBar: appBar,
      body: body,
      bottom: keyboardOpen
          ? null
          : SmashBottomNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
    );
  }
}
