import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/dues_model.dart';
import '../model/group_model.dart';
import '../provider/dues_provider.dart';
import '../provider/group_management_provider.dart';

class DuesPage extends ConsumerStatefulWidget {
  const DuesPage({super.key});

  @override
  ConsumerState<DuesPage> createState() => _DuesPageState();
}

class _DuesPageState extends ConsumerState<DuesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // 초기값
    Future.microtask(() {
      ref.read(duesProvider.notifier).load();
      ref.read(groupManagementProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('전체 초기화'),
        content: const Text('모든 납부 기록을 초기화할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '초기화',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(duesProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesProvider);
    final groupState = ref.watch(groupManagementProvider);
    final groups = groupState.groups;

    // TabController를 groups 개수 기준으로 초기화
    if (_tabController.length != groups.length + 1) {
      _tabController.dispose();
      _tabController = TabController(
        length: groups.length + 1 > 1 ? groups.length + 1 : 1,
        vsync: this,
      );
    }

    // 미배정 부원
    final unassigned = duesState.members
        .where((m) => m.groupId == null)
        .toList();

    // 납부 완료 수
    final paidCount = duesState.members.where((m) => m.isPaid).length;
    final totalCount = duesState.members.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('회비 관리'),
        actions: [
          TextButton(
            onPressed: _confirmReset,
            child: const Text(
              '초기화',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        bottom: groups.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  ...groups.map((g) => Tab(text: g.label)),
                  const Tab(text: '미배정'),
                ],
              ),
      ),
      body: duesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 납부 현황 요약
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: AppColors.cardBg,
                  child: Row(
                    children: [
                      Text(
                        '납부 완료',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$paidCount / $totalCount명',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 6,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.neutralBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalCount == 0
                              ? 0
                              : paidCount / totalCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.freeActivity,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.neutralBg),
                Expanded(
                  child: groups.isEmpty
                      ? _DuesTabView(
                          members: duesState.members,
                          groups: groups,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            ...groups.map(
                              (group) => _DuesTabView(
                                members: duesState.members
                                    .where((m) => m.groupId == group.id)
                                    .toList(),
                                groups: groups,
                              ),
                            ),
                            _DuesTabView(
                              members: unassigned,
                              groups: groups,
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

class _DuesTabView extends ConsumerStatefulWidget {
  final List<DuesMember> members;
  final List<GroupDetail> groups;

  const _DuesTabView({required this.members, required this.groups});

  @override
  ConsumerState<_DuesTabView> createState() => _DuesTabViewState();
}

class _DuesTabViewState extends ConsumerState<_DuesTabView> {
  final Set<int> _processingIds = {};

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return const Center(
        child: Text(
          '부원이 없습니다.',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.members.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.neutralBg),
      itemBuilder: (context, index) {
        final member = widget.members[index];
        return Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: member.isPaid
                            ? AppColors.textTertiary
                            : AppColors.ink,
                        decoration: member.isPaid
                            ? TextDecoration.lineThrough
                            : null,
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
              Checkbox(
                value: member.isPaid,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (_) async {
                  if (_processingIds.contains(member.userId)) return;
                  setState(() => _processingIds.add(member.userId));
                  if (member.isPaid) {
                    await ref
                        .read(duesProvider.notifier)
                        .cancel(member.userId);
                  } else {
                    await ref
                        .read(duesProvider.notifier)
                        .pay(member.userId);
                  }
                  if (mounted)
                    setState(() => _processingIds.remove(member.userId));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
