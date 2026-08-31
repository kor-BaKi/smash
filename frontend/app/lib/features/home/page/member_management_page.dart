import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/assignment_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/group_model.dart';
import '../model/member_register_model.dart';
import '../provider/group_management_provider.dart';
import '../provider/member_register_provider.dart';
import 'assignment_page.dart';
import 'member_detail_dialog.dart';

class MemberManagementPage extends ConsumerStatefulWidget {
  const MemberManagementPage({super.key});

  @override
  ConsumerState<MemberManagementPage> createState() =>
      _MemberManagementPageState();
}

class _MemberManagementPageState
    extends ConsumerState<MemberManagementPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(memberRegisterProvider.notifier).loadAllMembers();
      ref.read(groupManagementProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberState = ref.watch(memberRegisterProvider);
    final groupState = ref.watch(groupManagementProvider);

    final filtered = memberState.allMembers
        .where(
          (m) =>
              m.name.contains(_searchQuery) ||
              m.studentNo.contains(_searchQuery),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('부원 관리'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '부원 목록'),
            Tab(text: '조 편성'),
            Tab(text: '자동 배정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭1: 부원 목록
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '이름 또는 학번 검색',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '총 ${filtered.length}명',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final member = filtered[index];
                          final group = groupState.groups
                              .where((g) => g.id == member.groupId)
                              .toList();
                          final groupLabel = group.isEmpty
                              ? '미배정'
                              : group.first.label;
                          return GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  MemberDetailDialog(userId: member.id),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          member.studentNo,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showGroupPicker(
                                      context,
                                      member,
                                      groupState.groups,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: member.groupId == null
                                            ? AppColors.amberBg
                                            : AppColors.primaryBg,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            groupLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: member.groupId == null
                                                  ? AppColors.amber
                                                  : AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: member.groupId == null
                                                ? AppColors.amber
                                                : AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // 탭2: 조 편성
          const _GroupOverviewTab(),
          // 탭3: 자동 배정
          const AssignmentPage(),
        ],
      ),
    );
  }

  void _showGroupPicker(
    BuildContext context,
    RegisteredMember member,
    List<GroupDetail> groups,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('${member.name} 조 변경'),
        children: [
          ...groups.map(
            (group) => SimpleDialogOption(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await AssignmentApi.assignMember(member.id, group.id);
                  await ref
                      .read(memberRegisterProvider.notifier)
                      .loadAllMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${member.name}님을 ${group.label}로 변경했습니다.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('조 변경에 실패했습니다.')),
                    );
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  group.label,
                  style: TextStyle(
                    fontWeight: member.groupId == group.id
                        ? FontWeight.w800
                        : FontWeight.w400,
                    color: member.groupId == group.id
                        ? AppColors.primary
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupOverviewTab extends ConsumerWidget {
  const _GroupOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupManagementProvider);
    final memberState = ref.watch(memberRegisterProvider);

    if (groupState.isLoading || memberState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // groupId로 멤버 그룹핑
    final Map<int, List<RegisteredMember>> membersByGroup = {};
    final List<RegisteredMember> unassigned = [];

    for (final member in memberState.allMembers) {
      if (member.groupId == null) {
        unassigned.add(member);
      } else {
        membersByGroup.putIfAbsent(member.groupId!, () => []).add(member);
      }
    }

    // 이름순 정렬
    for (final list in membersByGroup.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    // 각 조에서 최대 멤버 수
    final maxMembers = membersByGroup.values.isEmpty
        ? 0
        : membersByGroup.values
              .map((m) => m.length)
              .reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(groupManagementProvider.notifier).loadAll();
        await ref.read(memberRegisterProvider.notifier).loadAllMembers();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _GroupTable(
            groups: groupState.groups,
            membersByGroup: membersByGroup,
            unassigned: unassigned,
            maxMembers: maxMembers,
            allMembers: memberState.allMembers,
          ),
        ),
      ),
    );
  }
}

class _GroupTable extends ConsumerWidget {
  final List<GroupDetail> groups;
  final Map<int, List<RegisteredMember>> membersByGroup;
  final List<RegisteredMember> unassigned;
  final int maxMembers;
  final List<RegisteredMember> allMembers;

  const _GroupTable({
    required this.groups,
    required this.membersByGroup,
    required this.unassigned,
    required this.maxMembers,
    required this.allMembers,
  });

  String _getMemberName(List<RegisteredMember> members, int? userId) {
    if (userId == null) return '-';
    final member = members.where((m) => m.id == userId).toList();
    return member.isEmpty ? '-' : member.first.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double cellWidth = 90;
    const double labelWidth = 60;
    const double rowHeight = 40;

    final headerStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );
    final labelStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textTertiary,
    );
    final cellStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    );

    return Table(
      defaultColumnWidth: const FixedColumnWidth(cellWidth),
      columnWidths: {
        0: const FixedColumnWidth(labelWidth),
        for (int i = 1; i <= groups.length; i++)
          i: const FixedColumnWidth(cellWidth),
      },
      border: TableBorder.all(
        color: AppColors.neutralBg,
        width: 1,
        borderRadius: BorderRadius.circular(12),
      ),
      children: [
        // 헤더 행
        TableRow(
          decoration: const BoxDecoration(color: AppColors.primaryBg),
          children: [
            _TableCell(child: const SizedBox(), height: rowHeight),
            ...groups.map(
              (g) => _TableCell(
                child: Text(
                  g.label,
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
                height: rowHeight,
              ),
            ),
          ],
        ),

        // 조장 행
        TableRow(
          children: [
            _TableCell(
              child: Text('조장', style: labelStyle),
              height: rowHeight,
            ),
            ...groups.map(
              (g) => _TableCell(
                child: Text(
                  _getMemberName(allMembers, g.leaderUserId),
                  style: cellStyle,
                  textAlign: TextAlign.center,
                ),
                height: rowHeight,
              ),
            ),
          ],
        ),

        // 부조장 행
        TableRow(
          children: [
            _TableCell(
              child: Text('부조장', style: labelStyle),
              height: rowHeight,
            ),
            ...groups.map(
              (g) => _TableCell(
                child: Text(
                  _getMemberName(allMembers, g.viceLeaderUserId),
                  style: cellStyle,
                  textAlign: TextAlign.center,
                ),
                height: rowHeight,
              ),
            ),
          ],
        ),

        // 부원 행
        for (int i = 0; i < maxMembers; i++)
          TableRow(
            children: [
              _TableCell(
                child: Text(i == 0 ? '부원' : '', style: labelStyle),
                height: rowHeight,
              ),
              ...groups.map((g) {
                final members = membersByGroup[g.id] ?? [];
                final member = i < members.length ? members[i] : null;
                return _TableCell(
                  child: Text(
                    member?.name ?? '',
                    style: cellStyle,
                    textAlign: TextAlign.center,
                  ),
                  height: rowHeight,
                );
              }),
            ],
          ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;
  final double height;

  const _TableCell({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(child: child),
      ),
    );
  }
}
