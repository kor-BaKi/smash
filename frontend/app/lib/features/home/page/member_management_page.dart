import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/assignment_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/group_model.dart';
import '../model/member_register_model.dart';
import '../provider/group_management_provider.dart';
import '../provider/member_register_provider.dart';
import 'assignment_page.dart';
import 'group_management_page.dart';
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

    // 디버그용
    print('=== groups: ${groupState.groups.length}');
    print('=== allMembers: ${memberState.allMembers.length}');
    if (memberState.allMembers.isNotEmpty) {
      print(
        '=== first member groupId: ${memberState.allMembers.first.groupId}',
      );
    }

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
          const GroupManagementPage(),
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
