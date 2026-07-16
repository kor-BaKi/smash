import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/assignment_model.dart';
import '../provider/assignment_provider.dart';

class AssignmentPage extends ConsumerWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('자동 배정')),
      body: state.confirmed
          ? const _ConfirmedView()
          : state.preview == null
          ? _StartView(isLoading: state.isLoadingPreview)
          : _PreviewView(preview: state.preview!),
    );
  }
}

class _StartView extends ConsumerWidget {
  final bool isLoading;
  const _StartView({required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton.icon(
              onPressed: () =>
                  ref.read(assignmentProvider.notifier).loadPreview(),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('자동 배정 미리보기 실행'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
    );
  }
}

class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.freeActivity,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            '배정이 확정되었습니다.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends ConsumerWidget {
  final AssignmentPreview preview;
  const _PreviewView({required this.preview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  count: preview.assignments.length,
                  label: '배정됨',
                  accent: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  count: preview.unassigned.length,
                  label: '미배정',
                  accent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  count: preview.groupDistribution.length,
                  label: '조',
                  accent: false,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...preview.assignments.map(
                (item) => _AssignmentTile(
                  item: item,
                  groupLabels: {
                    for (final g in preview.groupDistribution)
                      g.groupId: g.label,
                  },
                ),
              ),
              if (preview.unassigned.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...preview.unassigned.map(
                  (u) => _UnassignedTile(
                    item: u,
                    groupLabels: {
                      for (final g in preview.groupDistribution)
                        g.groupId: g.label,
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ElevatedButton(
                onPressed: state.isConfirming
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('배정 확정'),
                            content: Text(
                              '${preview.assignments.length}명의 배정을 확정할까요?\n확정 후에는 되돌릴 수 없습니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('확정'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(assignmentProvider.notifier)
                              .confirm();
                        }
                      },
                child: state.isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('배정 확정하기'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final bool accent;
  const _StatCard({
    required this.count,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: accent ? AppColors.amberBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent ? AppColors.amber : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent ? AppColors.amber : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends ConsumerWidget {
  final AssignmentItem item;
  final Map<int, String> groupLabels;
  const _AssignmentTile({required this.item, required this.groupLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: item.assignedGroupId,
                isDense: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                items: item.availableGroupIds.map((groupId) {
                  return DropdownMenuItem(
                    value: groupId,
                    child: Text(groupLabels[groupId] ?? '#$groupId'),
                  );
                }).toList(),
                onChanged: (newGroupId) {
                  if (newGroupId == null) return;
                  ref
                      .read(assignmentProvider.notifier)
                      .changeAssignedGroup(item.userId, newGroupId);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnassignedTile extends ConsumerWidget {
  final UnassignedItem item;
  final Map<int, String> groupLabels;
  const _UnassignedTile({required this.item, required this.groupLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amberBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amberBg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.name} · 미배정',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.amber,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showGroupPicker(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.amberBg,
              foregroundColor: AppColors.amber,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
            child: const Text(
              '수동 배정',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('${item.name} 조 배정'),
        children: groupLabels.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(assignmentProvider.notifier)
                  .assignUnassignedMember(item.userId, entry.key);
            },
            child: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }
}
