import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

const _longName = '아주아주아주긴이름을가진동아리회원김철수';

final chipEntry = CatalogEntry(
  name: 'SmashChip',
  description: '필터, 선택용 칩. 눈에 보이는 높이 40, 터치 영역 48. 선택은 체크 아이콘과 굵은 글자로도 구분한다.',
  states: [
    CatalogState('기본', (_) => SmashChip(label: '이번 주', onPressed: () {})),
    CatalogState('선택됨', (_) => SmashChip(label: '이번 주', selected: true, onPressed: () {})),
    CatalogState('눌림', (_) => SmashForcePressed(child: SmashChip(label: '이번 주', onPressed: () {}))),
    CatalogState('비활성', (_) => const SmashChip(label: '이번 주', onPressed: null)),
    CatalogState(
      '아이콘',
      (_) => SmashChip(label: '내 활동', icon: Icons.person_outline, onPressed: () {}),
    ),
    CatalogState('긴 글자', (_) => SmashChip(label: '이번 달에 참여하지 못한 활동만 보기', onPressed: () {})),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<String>(
        initial: '이번 주',
        describe: (value) => value,
        builder: (context, value, onChanged) => Wrap(
          spacing: SmashSpacing.sm,
          children: [
            for (final label in const ['이번 주', '이번 달', '전체'])
              SmashChip(
                label: label,
                selected: value == label,
                onPressed: () => onChanged(label),
              ),
          ],
        ),
      ),
    ),
  ],
);

final badgeEntry = CatalogEntry(
  name: 'SmashBadge',
  description: '상태를 알리는 알약. 색과 함께 아이콘과 문구로 전달한다. 눌러지지 않는다.',
  states: [
    CatalogState('중립', (_) => const SmashBadge(label: '대기')),
    CatalogState('정보', (_) => const SmashBadge(label: '진행 중', tone: SmashBadgeTone.info)),
    CatalogState('성공', (_) => const SmashBadge(label: '납부 완료', tone: SmashBadgeTone.success)),
    CatalogState('주의', (_) => const SmashBadge(label: '마감 임박', tone: SmashBadgeTone.warning)),
    CatalogState('위험', (_) => const SmashBadge(label: '미납', tone: SmashBadgeTone.danger)),
    CatalogState(
      '아이콘 없이',
      (_) => const SmashBadge(label: '납부 완료', tone: SmashBadgeTone.success, showIcon: false),
    ),
    CatalogState(
      '긴 글자',
      (_) => const SizedBox(
        width: 160,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SmashBadge(label: '이번 달에 참여하지 못한 날이 있어요', tone: SmashBadgeTone.warning),
        ),
      ),
    ),
  ],
);

final listRowEntry = CatalogEntry(
  name: 'SmashListRow',
  description: '목록 한 줄. 높이 56 이상, 제목과 부제는 최대 2줄. 선택은 막대와 배경, 스크린리더의 "선택됨"으로 구분한다.',
  states: [
    CatalogState('제목만', (_) => const SmashListRow(title: '김민수')),
    CatalogState('제목 + 부제', (_) => const SmashListRow(title: '김민수', subtitle: '20240001 · 2조')),
    CatalogState(
      '앞뒤 요소',
      (_) => SmashListRow(
        title: '김민수',
        subtitle: '조장',
        leading: const SmashAvatar(name: '김민수'),
        trailing: const SmashBadge(label: '참석', tone: SmashBadgeTone.success),
        onTap: () {},
      ),
    ),
    CatalogState(
      '눌림',
      (_) => SmashForcePressed(child: SmashListRow(title: '김민수', onTap: () {})),
    ),
    CatalogState('선택됨', (_) => SmashListRow(title: '김민수', selected: true, onTap: () {})),
    CatalogState(
      '긴 이름',
      (_) => const SmashListRow(
        title: _longName,
        subtitle: '메모가 아주 길어서 두 줄을 넘어가는 경우에도 줄여서 보여줘야 합니다. 이 문장은 일부러 길게 적었습니다.',
        trailing: SmashBadge(label: '대기'),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<String?>(
        initial: null,
        describe: (value) => value ?? '선택 없음',
        builder: (context, value, onChanged) => Column(
          children: [
            for (final name in const ['김민수', '이서연', '박지훈'])
              SmashListRow(
                title: name,
                subtitle: '20240001',
                leading: SmashAvatar(name: name),
                selected: value == name,
                showDivider: name != '박지훈',
                onTap: () => onChanged(value == name ? null : name),
              ),
          ],
        ),
      ),
    ),
  ],
);

final sectionHeaderEntry = CatalogEntry(
  name: 'SmashSectionHeader',
  description: '구역 제목. 스크린리더는 제목(heading)으로 읽는다. 오른쪽 동작은 터치 영역 48을 지킨다.',
  states: [
    CatalogState('제목', (_) => const SmashSectionHeader(title: '오늘 활동')),
    CatalogState('작은 이름표', (_) => const SmashSectionHeader(title: '정규', style: SmashSectionHeaderStyle.label)),
    CatalogState(
      '오른쪽 동작',
      (_) => SmashSectionHeader(
        title: '진행 중인 투표',
        trailing: SmashButton(
          label: '전체 보기',
          variant: SmashButtonVariant.text,
          size: SmashButtonSize.medium,
          expanded: false,
          onPressed: () {},
        ),
      ),
    ),
    CatalogState(
      '긴 제목',
      (_) => SmashSectionHeader(
        title: '이번 달에 참여하지 못한 날을 이월로 채울 수 있는 활동 목록',
        trailing: SmashButton(
          label: '전체 보기',
          variant: SmashButtonVariant.text,
          size: SmashButtonSize.medium,
          expanded: false,
          onPressed: () {},
        ),
      ),
    ),
  ],
);

final panelEntry = CatalogEntry(
  name: 'SmashPanel',
  description: '내용을 묶는 면. 안에 면을 또 넣지 않는다. onTap이 있으면 눌림 모양과 버튼 역할이 붙는다.',
  states: [
    CatalogState(
      '묶음(outlined)',
      (_) => const SmashPanel(child: Text('이번 주 활동 3개', style: SmashText.body)),
    ),
    CatalogState(
      '강조(filled)',
      (_) => const SmashPanel(
        variant: SmashPanelVariant.filled,
        child: Text('오늘 19:00 정기 활동'),
      ),
    ),
    CatalogState(
      '안내(tinted)',
      (_) => const SmashPanel(
        variant: SmashPanelVariant.tinted,
        child: Text('이번 달에 참여하지 못한 날이 2일 있어요', style: SmashText.body),
      ),
    ),
    CatalogState(
      '눌림',
      (_) => SmashForcePressed(
        child: SmashPanel(
          variant: SmashPanelVariant.filled,
          onTap: () {},
          child: const Text('오늘 19:00 정기 활동'),
        ),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<int>(
        initial: 0,
        describe: (value) => '$value번 눌렀어요',
        builder: (context, value, onChanged) => SmashPanel(
          variant: SmashPanelVariant.filled,
          onTap: () => onChanged(value + 1),
          child: const Text('눌러 보세요'),
        ),
      ),
    ),
  ],
);

final avatarEntry = CatalogEntry(
  name: 'SmashAvatar',
  description: '이름 첫 글자를 보여주는 원. 이름은 옆에 글자로 있으므로 스크린리더는 읽지 않는다. 글자 확대를 따라가지 않는다.',
  states: [
    CatalogState('기본(40)', (_) => const SmashAvatar(name: '김민수')),
    CatalogState('작게(28)', (_) => const SmashAvatar(name: '김민수', size: 28)),
    CatalogState('크게(64)', (_) => const SmashAvatar(name: '김민수', size: 64)),
    CatalogState('영문', (_) => const SmashAvatar(name: 'Alex')),
    CatalogState('이름 없음', (_) => const SmashAvatar(name: '  ')),
  ],
);
