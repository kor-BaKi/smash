import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

const _groups = [
  SmashOption(value: 'g1', label: '1조'),
  SmashOption(value: 'g2', label: '2조'),
  SmashOption(value: 'g3', label: '3조'),
  SmashOption(value: 'none', label: '미배정'),
];

final _manyOptions = [
  for (var i = 1; i <= 30; i++)
    SmashOption(
      value: i,
      label: '참여자 $i',
      subtitle: i % 5 == 0 ? '다른 조 활동 중' : null,
    ),
];

String _groupName(String? value) => switch (value) {
  'g1' => '1조',
  'g2' => '2조',
  'g3' => '3조',
  'none' => '미배정',
  _ => '고르지 않았어요',
};

/// 탭 줄과 본문을 함께 보여 주는 시연 틀. [interactive]가 false이면 눌러도 반응하지 않는 모양 확인용이다
class _TabBarDemo extends StatefulWidget {
  const _TabBarDemo({
    required this.tabs,
    this.interactive = false,
    this.isScrollable,
    this.initialIndex = 0,
  });

  final List<SmashTab> tabs;
  final bool interactive;
  final bool? isScrollable;
  final int initialIndex;

  @override
  State<_TabBarDemo> createState() => _TabBarDemoState();
}

class _TabBarDemoState extends State<_TabBarDemo>
    with SingleTickerProviderStateMixin {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 동작 줄이기가 켜져 있으면 탭이 즉시 바뀌도록 컨트롤러를 만든다 (처음 한 번)
    _controller ??= TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
      animationDuration: SmashTabBar.animationDurationOf(context),
    )..addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final bar = SmashTabBar(
      controller: controller,
      tabs: widget.tabs,
      isScrollable: widget.isScrollable,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.interactive ? bar : IgnorePointer(child: bar),
        if (widget.interactive) ...[
          SizedBox(
            height: 88,
            child: TabBarView(
              controller: controller,
              children: [
                for (final tab in widget.tabs)
                  Center(
                    child: Text(
                      '${tab.label} 화면 (옆으로 밀어도 바뀌어요)',
                      style: SmashText.body,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '현재 값: ${controller.index + 1}번째 탭 (${widget.tabs[controller.index].label})',
            style: SmashText.caption,
          ),
        ],
      ],
    );
  }
}

final tabBarEntry = CatalogEntry(
  name: 'SmashTabBar',
  description:
      '화면 안의 탭 줄. 선택은 색과 밑줄로 구분하고, 글자는 항상 한 줄이다. 모든 탭이 같은 폭으로 안 들어가면 자동으로 스크롤형이 되고 선택된 탭이 화면 안으로 스크롤된다. 개수는 라벨 오른쪽에 숫자만(배경 모양 없이, 간격 8, 굵기 고정, 자릿수 폭이 같은 숫자) 보이고 스크린리더는 "12건"으로 읽는다.',
  states: [
    CatalogState(
      '고정 3탭 (같은 폭)',
      (_) => const _TabBarDemo(
        tabs: [
          SmashTab(label: '진행 중'),
          SmashTab(label: '종료된 투표'),
          SmashTab(label: '내 투표'),
        ],
      ),
    ),
    CatalogState(
      '개수 숫자 (미처리 12 | 합격 3 | 불합격 0: 0도 보인다)',
      (_) => const _TabBarDemo(
        tabs: [
          SmashTab(label: '미처리', badgeCount: 12),
          SmashTab(label: '합격', badgeCount: 3),
          SmashTab(label: '불합격', badgeCount: 0),
        ],
      ),
    ),
    CatalogState(
      '개수 3자리 + 2번째 선택 (미처리 120 | 합격 45 | 불합격 7: 선택이 바뀌어도 폭이 같다)',
      (_) => const _TabBarDemo(
        initialIndex: 1,
        tabs: [
          SmashTab(label: '미처리', badgeCount: 120),
          SmashTab(label: '합격', badgeCount: 45),
          SmashTab(label: '불합격', badgeCount: 7),
        ],
      ),
    ),
    CatalogState(
      '스크롤형 (조 이름 7개, 3번째 선택)',
      (_) => const _TabBarDemo(
        initialIndex: 2,
        tabs: [
          SmashTab(label: '1조'),
          SmashTab(label: '2조'),
          SmashTab(label: '3조'),
          SmashTab(label: '4조'),
          SmashTab(label: '5조'),
          SmashTab(label: '6조'),
          SmashTab(label: '미배정'),
        ],
      ),
    ),
    CatalogState(
      '스크롤형 마지막 탭 선택 (선택된 탭이 화면 안으로)',
      (_) => const _TabBarDemo(
        initialIndex: 6,
        tabs: [
          SmashTab(label: '1조'),
          SmashTab(label: '2조'),
          SmashTab(label: '3조'),
          SmashTab(label: '4조'),
          SmashTab(label: '5조'),
          SmashTab(label: '6조'),
          SmashTab(label: '미배정'),
        ],
      ),
    ),
    CatalogState(
      '긴 라벨 (자동 스크롤형: 글자 배율이 커지면 고정 → 스크롤로 바뀐다)',
      (_) => const _TabBarDemo(
        tabs: [
          SmashTab(label: '조별 현황'),
          SmashTab(label: '미달자 보기'),
          SmashTab(label: '다른 조 참여'),
        ],
      ),
    ),
    CatalogState(
      '강제 스크롤형 (isScrollable: true, 탭 2개는 왼쪽부터 놓인다)',
      (_) => const _TabBarDemo(
        isScrollable: true,
        tabs: [
          SmashTab(label: '진행 중'),
          SmashTab(label: '종료'),
        ],
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => const _TabBarDemo(
        interactive: true,
        tabs: [
          SmashTab(label: '미처리', badgeCount: 12),
          SmashTab(label: '합격', badgeCount: 3),
          SmashTab(label: '불합격', badgeCount: 0),
        ],
      ),
    ),
  ],
);

final selectFieldEntry = CatalogEntry(
  name: 'SmashSelectField',
  description:
      '여러 선택지 중 하나를 고르는 입력칸. 누르면 시트에 선택지(체크 표시)가 나오고, 하나를 고르면 닫힌다. 다른 값을 골랐을 때만 값이 바뀌고, 시트를 닫기만 하면 그대로다. 닫히면 포커스가 칸으로 돌아온다.',
  states: [
    CatalogState(
      '값 없음 (안내 문구)',
      (_) => SmashSelectField<String>(
        label: '조',
        value: null,
        options: _groups,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '값 있음',
      (_) => SmashSelectField<String>(
        label: '조',
        value: 'g2',
        options: _groups,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '도움말',
      (_) => SmashSelectField<String>(
        label: '조',
        value: 'g1',
        helper: '조를 바꾸면 이번 달 출석부터 적용돼요',
        options: _groups,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '오류',
      (_) => SmashSelectField<String>(
        label: '조',
        value: null,
        errorText: '조를 골라 주세요',
        options: _groups,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '비활성',
      (_) => SmashSelectField<String>(
        label: '조',
        value: 'g1',
        enabled: false,
        options: _groups,
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '선택지 없음 (비활성)',
      (_) => SmashSelectField<String>(
        label: '조',
        value: null,
        options: const [],
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      '선택지 30개 + 고를 수 없는 항목 (눌러서 열어 보세요: 고른 항목이 보이는 위치에서 열림)',
      (_) => SmashSelectField<int>(
        label: '참여자',
        value: 24,
        options: [
          ..._manyOptions.take(3),
          const SmashOption(value: 99, label: '고를 수 없는 참여자', enabled: false),
          ..._manyOptions.skip(3),
        ],
        onChanged: (_) {},
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<String?>(
        initial: null,
        describe: _groupName,
        builder: (context, value, onChanged) => SmashSelectField<String>(
          label: '조',
          value: value,
          options: _groups,
          errorText: value == null ? '조를 골라 주세요' : null,
          onChanged: onChanged,
        ),
      ),
    ),
  ],
);

final actionSheetEntry = CatalogEntry(
  name: 'showSmashActionSheet',
  description:
      '아래에서 올라오는 행동 목록(메뉴). 고른 행동을 돌려주고, 취소하거나 닫으면 null이다. 위험한 행동은 빨간 글자와 아이콘으로 구분하고, 위험한 행동이 있으면 처음 포커스가 취소에 간다. 눌러서 열어 보세요.',
  states: [
    for (final s
        in <
          ({
            String label,
            String button,
            List<SmashAction<String>> actions,
            String? title,
            String? message,
          })
        >[
          (
            label: '기본 (행동 둘 + 취소)',
            button: '메뉴 열기',
            title: null,
            message: null,
            actions: const [
              SmashAction(
                value: 'edit',
                label: '이름 바꾸기',
                icon: Icons.edit_outlined,
              ),
              SmashAction(
                value: 'move',
                label: '다른 조로 옮기기',
                icon: Icons.swap_horiz,
              ),
            ],
          ),
          (
            label: '제목과 설명 + 위험한 행동 (처음 포커스가 취소에)',
            button: '조 관리 메뉴 열기',
            title: '2조',
            message: '조를 지우면 소속 부원은 미배정이 돼요.',
            actions: const [
              SmashAction(
                value: 'rename',
                label: '이름 바꾸기',
                icon: Icons.edit_outlined,
              ),
              SmashAction(
                value: 'delete',
                label: '조 삭제',
                icon: Icons.delete_outline,
                destructive: true,
              ),
            ],
          ),
          (
            label: '고를 수 없는 행동 포함',
            button: '비활성 행 메뉴 열기',
            title: '사진',
            message: null,
            actions: const [
              SmashAction(
                value: 'save',
                label: '저장하기',
                icon: Icons.download_outlined,
              ),
              SmashAction(
                value: 'delete',
                label: '삭제 (권한 없음)',
                icon: Icons.delete_outline,
                destructive: true,
                enabled: false,
              ),
            ],
          ),
        ])
      CatalogState(
        s.label,
        (_) => CatalogStateHost<String>(
          initial: '아직 열지 않았어요',
          describe: (v) => v,
          builder: (context, value, onChanged) => SmashButton(
            label: s.button,
            variant: SmashButtonVariant.secondary,
            onPressed: () async {
              final picked = await showSmashActionSheet<String>(
                context: context,
                title: s.title,
                message: s.message,
                actions: s.actions,
              );
              onChanged(picked == null ? '닫았어요 (고른 행동 없음)' : '고른 행동: $picked');
            },
          ),
        ),
      ),
    CatalogState(
      '긴 목록 (행동 8개: 시트 안에서 스크롤)',
      (_) => CatalogStateHost<String>(
        initial: '아직 열지 않았어요',
        describe: (v) => v,
        builder: (context, value, onChanged) => SmashButton(
          label: '긴 메뉴 열기',
          variant: SmashButtonVariant.secondary,
          onPressed: () async {
            final picked = await showSmashActionSheet<String>(
              context: context,
              title: '부원 관리',
              actions: [
                for (var i = 1; i <= 8; i++)
                  SmashAction(
                    value: '행동 $i',
                    label: '행동 $i',
                    icon: Icons.chevron_right,
                  ),
              ],
            );
            onChanged(picked == null ? '닫았어요 (고른 행동 없음)' : '고른 행동: $picked');
          },
        ),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<String>(
        initial: '아직 열지 않았어요',
        describe: (v) => v,
        builder: (context, value, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmashButton(
              label: '행동 고르기',
              variant: SmashButtonVariant.secondary,
              onPressed: () async {
                final picked = await showSmashActionSheet<String>(
                  context: context,
                  title: '조 관리',
                  actions: const [
                    SmashAction(
                      value: '이름 바꾸기',
                      label: '이름 바꾸기',
                      icon: Icons.edit_outlined,
                    ),
                    SmashAction(
                      value: '조 삭제',
                      label: '조 삭제',
                      icon: Icons.delete_outline,
                      destructive: true,
                    ),
                  ],
                );
                onChanged(
                  picked == null ? '닫았어요 (고른 행동 없음)' : '고른 행동: $picked',
                );
              },
            ),
            const SizedBox(height: SmashSpacing.xs),
            Text(
              '고른 행동이 아래 "현재 값"에 나온다. ✕나 취소, 바깥, 뒤로 가기로 닫으면 "닫았어요".',
              style: SmashText.caption,
            ),
          ],
        ),
      ),
    ),
  ],
);
