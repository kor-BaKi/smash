import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/assignment_model.dart';
import '../provider/assignment_provider.dart';

class AssignmentPage extends ConsumerWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
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
              icon: const Icon(Icons.auto_awesome),
              label: const Text('자동 배정 미리보기 실행'),
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
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 12),
          Text('배정이 확정되었습니다.'),
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '조별 배정 인원',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preview.groupDistribution.map((g) {
                  return Chip(label: Text('${g.label} ${g.count}명'));
                }).toList(),
              ),
              const Divider(height: 32),
              Text(
                '배정 결과 (${preview.assignments.length}명)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
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
                const Divider(height: 32),
                Text(
                  '미배정 (${preview.unassigned.length}명)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
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
            ],
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isConfirming
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isConfirming
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('배정 확정', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignmentTile extends ConsumerWidget {
  final AssignmentItem item;
  final Map<int, String> groupLabels;

  const _AssignmentTile({required this.item, required this.groupLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '배정: ${groupLabels[item.assignedGroupId] ?? '알 수 없음'}',
        ),
        trailing: DropdownButton<int>(
          value: item.assignedGroupId,
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
    );
  }
}

class _UnassignedTile extends ConsumerWidget {
  final UnassignedItem item;
  final Map<int, String> groupLabels;

  const _UnassignedTile({required this.item, required this.groupLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          item.reason == 'NO_AVAILABILITY' ? '가능 요일 미제출' : item.reason,
        ),
        trailing: TextButton(
          onPressed: () => _showGroupPicker(context, ref),
          child: const Text('조 배정'),
        ),
      ),
    );
  }

  void _showGroupPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
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
