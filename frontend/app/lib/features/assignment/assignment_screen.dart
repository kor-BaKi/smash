import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assignment.dart';
import 'assignment_controller.dart';

class AssignmentScreen extends ConsumerWidget {
  const AssignmentScreen({super.key});

  Future<void> _showManualAssignDialog(BuildContext context, WidgetRef ref, UnassignedMember member) async {
    final controller = TextEditingController();
    final groupId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${member.name} 조 수동 지정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'groupId'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: const Text('지정'),
          ),
        ],
      ),
    );

    if (groupId != null) {
      await ref.read(unassignedMembersProvider.notifier).updateMemberGroup(member.userId, groupId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unassignedState = ref.watch(unassignedMembersProvider);
    final previewState = ref.watch(assignmentPreviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('조 배정')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('미배정자', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          unassignedState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (members) {
              if (members.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Text('미배정자가 없습니다.'));
              }
              return Column(
                children: members
                    .map((m) => ListTile(
                          title: Text(m.name),
                          subtitle: Text('가능한 조: ${m.availableGroupIds.join(', ')}'),
                          onTap: () => _showManualAssignDialog(context, ref, m),
                        ))
                    .toList(),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => ref.read(assignmentPreviewProvider.notifier).runPreview(),
              child: const Text('자동배정 미리보기'),
            ),
          ),
          previewState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (preview) {
              if (preview == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('배정 결과', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...preview.assignments.map(
                    (a) => ListTile(title: Text(a.name), trailing: Text('조 ${a.assignedGroupId}')),
                  ),
                  if (preview.unassigned.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('배정 불가', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...preview.unassigned.map((u) => ListTile(title: Text(u.name), trailing: Text(u.reason))),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('조별 인원 분포', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...preview.groupDistribution.map(
                    (g) => ListTile(title: Text(g.label), trailing: Text('${g.count}명')),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => ref.read(assignmentPreviewProvider.notifier).confirmAll(),
                            child: const Text('확정'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref.read(assignmentPreviewProvider.notifier).clear(),
                            child: const Text('취소'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
