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
    _tabController = TabController(length: 1, vsync: this);
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '전체 초기화',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          '모든 납부 기록을 초기화할까요?',
          style: TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.gray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '초기화',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
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

    if (_tabController.length != groups.length + 1) {
      _tabController.dispose();
      _tabController = TabController(
        length: groups.length + 1 > 1 ? groups.length + 1 : 1,
        vsync: this,
      );
    }

    final unassigned = duesState.members
        .where((m) => m.groupId == null)
        .toList();
    final paidCount = duesState.members.where((m) => m.isPaid).length;
    final totalCount = duesState.members.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('회비 관리'),
        actions: [
          TextButton(
            onPressed: _confirmReset,
            child: const Text(
              '초기화',
              style: TextStyle(
                color: AppColors.coral,
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
                labelColor: AppColors.lime,
                unselectedLabelColor: AppColors.darkGray,
                indicatorColor: AppColors.lime,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: AppColors.card,
                  child: Row(
                    children: [
                      const Text(
                        '납부 완료',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$paidCount / $totalCount명',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lime,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 6,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalCount == 0
                              ? 0
                              : paidCount / totalCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 0.5, color: AppColors.border),
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
        child: Text('부원이 없습니다.', style: TextStyle(color: AppColors.gray)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.members.length,
      separatorBuilder: (_, __) =>
          Container(height: 0.5, color: AppColors.border),
      itemBuilder: (context, index) {
        final member = widget.members[index];
        return Container(
          color: AppColors.bg,
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
                            ? AppColors.darkGray
                            : AppColors.white,
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
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: member.isPaid,
                activeColor: AppColors.green,
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
                  if (mounted) {
                    setState(() => _processingIds.remove(member.userId));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
