import 'package:flutter/material.dart';

import '../colors.dart';
import 'smash_system_ui.dart';

/// 모든 화면의 바탕. 배경색, 상태 표시줄 모양, 안전 영역, 키보드 처리를 한 곳에서 정한다.
///
/// - [appBar]가 있으면 위쪽 안전 영역은 앱바가 처리하고, 없으면 본문이 피한다
/// - [bottom]에는 [SmashBottomBar]나 [SmashBottomNav]를 넣는다. 화면 폭 전체로 펼쳐지고,
///   키보드가 올라오면 키보드 위로 올라가며, 스낵바는 이 막대 위에 뜬다
///   (탭 막대를 키보드 위에 두고 싶지 않으면 [SmashTabShell]을 쓴다)
/// - 본문 아래 안전 영역은 [bottom]이 없을 때만 본문이 피한다. [bottom]이 있으면 막대가 맡으므로 본문 안쪽의 `MediaQuery.padding` 아래쪽도 0이다
///   (본문 안의 `SafeArea`나 기본 여백의 `ListView`가 같은 영역을 또 비우지 않는다)
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
    // Scaffold 안쪽에서는 키보드 높이(viewInsets)가 이미 빠져 있어서 안쪽 위젯은 키보드가 올라온 줄 모른다.
    // 키보드 정보가 있는 이곳에서 판단한다
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final hasBottom = bottom != null;

    return SmashSystemUiRegion(
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        // 막대 쪽에 키보드 높이를 padding으로 얹어서 막대와 본문이 함께 키보드 위로 올라가게 한다.
        // (Scaffold.bottomNavigationBar 자리라서 스낵바도 막대 위에 뜬다. 본문은 Scaffold가
        // max(키보드 높이, 막대 높이)만큼만 줄이므로, 막대가 키보드 높이를 가진 경우에도 이중으로 줄지 않는다)
        bottomNavigationBar: hasBottom
            ? Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: MediaQuery.removePadding(
                  context: context,
                  // 키보드가 올라와 있으면 홈 인디케이터 영역은 키보드가 덮고 있으므로 여백을 또 남기지 않는다
                  removeBottom: keyboard > 0,
                  child: bottom!,
                ),
              )
            : null,
        body: MediaQuery.removeViewInsets(
          context: context,
          // 막대가 키보드 높이를 이미 반영했으므로 본문은 같은 높이를 또 빼지 않는다
          removeBottom: hasBottom,
          child: SafeArea(
            top: appBar == null,
            bottom: !hasBottom,
            // 막대가 아래 안전 영역(홈 인디케이터)을 이미 맡고 있으므로 본문은 그 값을 받지 않는다.
            // (위의 removeViewInsets가 바깥 MediaQuery로 다시 만들기 때문에, Scaffold가 지워 둔 아래 값이 되살아나 있다.)
            // 받으면 본문 안의 SafeArea나 ListView의 기본 여백이 같은 영역을 또 비운다. 위쪽은 건드리지 않는다
            child: hasBottom
                ? Builder(
                    builder: (inner) => MediaQuery.removePadding(
                      context: inner,
                      removeBottom: true,
                      child: body,
                    ),
                  )
                : body,
          ),
        ),
      ),
    );
  }
}
