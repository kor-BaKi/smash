import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/group.dart';
import '../provider/group_controller.dart';

class GroupPage extends ConsumerWidget {
  const GroupPage({super.key});

  Future<void> _showAssignLeaderDialog(BuildContext context, WidgetRef ref, Group group) async {
    final controller = TextEditingController(text: group.leaderUserId?.toString() ?? '');
    final leaderUserId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${group.label} 조장 지정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '조장 userId'),
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

    if (leaderUserId != null) {
      await ref.read(groupControllerProvider.notifier).assignLeader(group.id, leaderUserId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('조 관리')),
      body: groupsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => ref.read(groupControllerProvider.notifier).createDefaultGroups(),
                child: const Text('기본 10개 조 생성'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(groupControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  title: Text(group.label),
                  subtitle: Text('조장: ${group.leaderUserId ?? '미지정'} / 인원: ${group.memberCount}명'),
                  onTap: () => _showAssignLeaderDialog(context, ref, group),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
