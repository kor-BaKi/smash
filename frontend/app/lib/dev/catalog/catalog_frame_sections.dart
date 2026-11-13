import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

const _tabs = [
  SmashNavDestination(label: '홈', icon: Icons.home_outlined, selectedIcon: Icons.home),
  SmashNavDestination(label: '일정', icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today),
  SmashNavDestination(label: '내 정보', icon: Icons.person_outline, selectedIcon: Icons.person),
];

const _fiveTabs = [
  SmashNavDestination(label: '홈', icon: Icons.home_outlined, selectedIcon: Icons.home),
  SmashNavDestination(label: '일정', icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today),
  SmashNavDestination(label: '투표', icon: Icons.how_to_vote_outlined, selectedIcon: Icons.how_to_vote),
  SmashNavDestination(label: '임원', icon: Icons.shield_outlined, selectedIcon: Icons.shield, badgeCount: 3),
  SmashNavDestination(label: '내 정보', icon: Icons.person_outline, selectedIcon: Icons.person),
];

/// 카탈로그 화면 안에 작은 "휴대폰 화면"을 그려 준다. 안전 영역과 키보드는 카탈로그 화면의 것을 받지 않는다.
/// (Navigator 없이 그린다: 상태가 바뀔 때마다 안쪽이 다시 그려져야 하기 때문)
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.child, this.height = 320});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero, viewInsets: EdgeInsets.zero),
          child: child,
        ),
      ),
    );
  }
}

final systemUiEntry = CatalogEntry(
  name: 'SmashSystemUi',
  description: '상태 표시줄과 내비게이션 바 모양. 밝은 배경용(어두운 아이콘). 화면이 떠 있는 동안만 적용된다.',
  states: [
    CatalogState(
      '적용값',
      (_) => Text(
        '상태 표시줄 아이콘: ${SmashSystemUi.light.statusBarIconBrightness?.name}, '
        'iOS: ${SmashSystemUi.light.statusBarBrightness?.name}, '
        '내비게이션 바 아이콘: ${SmashSystemUi.light.systemNavigationBarIconBrightness?.name}',
        style: SmashText.body,
      ),
    ),
  ],
);

final appBarEntry = CatalogEntry(
  name: 'SmashAppBar',
  description: '화면 위 막대. 높이 56, 제목 한 줄 말줄임, 뒤로 가기는 화면이 정한다.',
  states: [
    CatalogState('제목만(첫 화면)', (_) => const _AppBarDemo(SmashAppBar(title: '홈'))),
    CatalogState('뒤로 가기', (_) => _AppBarDemo(SmashAppBar(title: '활동 상세', onBack: () {}))),
    CatalogState(
      '오른쪽 동작',
      (_) => _AppBarDemo(SmashAppBar(
        title: '투표',
        onBack: () {},
        actions: [SmashIconButton(icon: Icons.add, semanticLabel: '투표 만들기', onPressed: () {})],
      )),
    ),
    CatalogState(
      '긴 제목',
      (_) => _AppBarDemo(SmashAppBar(
        title: '이번 달에 참여하지 못한 날을 이월로 채우는 활동 목록',
        onBack: () {},
        actions: [SmashIconButton(icon: Icons.more_vert, semanticLabel: '더 보기', onPressed: () {})],
      )),
    ),
    CatalogState('아래 선 없음', (_) => const _AppBarDemo(SmashAppBar(title: '홈', showDivider: false))),
  ],
);

class _AppBarDemo extends StatelessWidget {
  const _AppBarDemo(this.bar);

  final SmashAppBar bar;

  @override
  Widget build(BuildContext context) => SizedBox(height: SmashAppBar.height + 1, child: bar);
}

final bottomBarEntry = CatalogEntry(
  name: 'SmashBottomBar',
  description: '화면 아래 행동 영역. 위에 선, 홈 인디케이터 영역을 피한다. SmashScaffold.bottom에 넣으면 키보드 위에 붙는다.',
  states: [
    CatalogState(
      '버튼 하나',
      (_) => SmashBottomBar(child: SmashButton(label: '저장', onPressed: () {})),
    ),
    CatalogState(
      '버튼 둘',
      (_) => SmashBottomBar(
        child: Row(
          children: [
            Expanded(child: SmashButton(label: '취소', variant: SmashButtonVariant.secondary, onPressed: () {})),
            const SizedBox(width: SmashSpacing.sm),
            Expanded(child: SmashButton(label: '저장', onPressed: () {})),
          ],
        ),
      ),
    ),
  ],
);

final bottomNavEntry = CatalogEntry(
  name: 'SmashBottomNav',
  description: '하단 탭 (2~5개). 라벨 항상 표시, 선택은 알약+굵은 글자+아이콘, 라벨은 1.3배까지만 확대.',
  states: [
    CatalogState(
      '탭 3개',
      (_) => SmashBottomNav(destinations: _tabs, selectedIndex: 0, onSelected: (_) {}),
    ),
    CatalogState(
      '탭 5개 + 배지',
      (_) => SmashBottomNav(destinations: _fiveTabs, selectedIndex: 3, onSelected: (_) {}),
    ),
    CatalogState(
      '눌림',
      (_) => SmashForcePressed(
        child: SmashBottomNav(destinations: _tabs, selectedIndex: 0, onSelected: (_) {}),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<int>(
        initial: 0,
        describe: (value) => _fiveTabs[value].label,
        builder: (context, value, onChanged) =>
            SmashBottomNav(destinations: _fiveTabs, selectedIndex: value, onSelected: onChanged),
      ),
    ),
  ],
);

final scaffoldEntry = CatalogEntry(
  name: 'SmashScaffold',
  description: '모든 화면의 바탕. 배경색, 상태 표시줄, 안전 영역, 키보드 처리. (작은 화면 안에 그려서 보여준다)',
  states: [
    CatalogState(
      '본문만',
      (_) => const _MiniScreen(child: SmashScaffold(body: Center(child: Text('본문')))),
    ),
    CatalogState(
      '앱바 + 아래 행동 영역',
      (_) => _MiniScreen(
        child: SmashScaffold(
          appBar: SmashAppBar(title: '활동 만들기', onBack: () {}),
          body: const Center(child: Text('본문')),
          bottom: SmashBottomBar(child: SmashButton(label: '저장', onPressed: () {})),
        ),
      ),
    ),
    CatalogState(
      '입력창 + 아래 행동 영역 (키보드가 올라오면 막대가 키보드 위에 붙는지 확인)',
      (_) => _MiniScreen(
        height: 360,
        child: SmashScaffold(
          appBar: SmashAppBar(title: '메모', onBack: () {}),
          body: const Padding(
            padding: EdgeInsets.all(SmashSpacing.md),
            child: SmashTextField(label: '메모', hint: '내용을 적어 주세요'),
          ),
          bottom: SmashBottomBar(child: SmashButton(label: '저장', onPressed: () {})),
        ),
      ),
    ),
  ],
);

final tabShellEntry = CatalogEntry(
  name: 'SmashTabShell',
  description: '하단 탭이 있는 화면 틀. 선택은 화면(라우터)이 정하고 이 위젯은 그리기만 한다. 키보드가 올라오면 탭 막대를 숨긴다.',
  states: [
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<int>(
        initial: 0,
        describe: (value) => _fiveTabs[value].label,
        builder: (context, value, onChanged) => _MiniScreen(
          height: 380,
          child: SmashTabShell(
            destinations: _fiveTabs,
            selectedIndex: value,
            onSelected: onChanged,
            appBar: SmashAppBar(title: _fiveTabs[value].label),
            body: Center(child: Text('${_fiveTabs[value].label} 탭 내용', style: SmashText.body)),
          ),
        ),
      ),
    ),
  ],
);
