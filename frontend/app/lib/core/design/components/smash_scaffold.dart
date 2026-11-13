import 'package:flutter/material.dart';

import '../colors.dart';
import 'smash_system_ui.dart';

/// 모든 화면의 바탕. 배경색, 상태 표시줄 모양, 안전 영역, 키보드 처리를 한 곳에서 정한다.
///
/// - [appBar]가 있으면 위쪽 안전 영역은 앱바가 처리하고, 없으면 본문이 피한다
/// - [bottom]에는 [SmashBottomBar]나 [SmashBottomNav]를 넣는다. 키보드가 올라오면 키보드 위로 올라간다
///   (탭 막대를 키보드 위에 두고 싶지 않으면 [SmashTabShell]을 쓴다)
/// - 본문 아래 안전 영역은 [bottom]이 없을 때만 본문이 피한다
class SmashScaffold extends StatelessWidget {
  const SmashScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottom,
    this.backgroundColor = SmashColors.background,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottom;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    // Scaffold 안쪽에서는 키보드 높이(viewInsets)가 이미 빠져 있고 아래 안전 영역만 남아 있어서
    // bottom 안에서는 키보드가 올라온 줄 알 수 없다. 키보드 정보가 있는 이곳에서 판단한다
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SmashSystemUiRegion(
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        resizeToAvoidBottomInset: true,
        // Scaffold.bottomNavigationBar는 키보드가 올라와도 올라오지 않고 키보드에 가려진다.
        // 그래서 bottom을 본문 아래 Column에 두어, 키보드로 줄어든 본문 영역과 함께 올라가게 한다
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                top: appBar == null,
                bottom: bottom == null,
                child: body,
              ),
            ),
            if (bottom != null)
              // 키보드가 올라와 있으면 홈 인디케이터 영역은 키보드가 덮고 있으므로 여백을 또 남기지 않는다
              MediaQuery.removePadding(
                context: context,
                removeBottom: keyboardOpen,
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }
}
