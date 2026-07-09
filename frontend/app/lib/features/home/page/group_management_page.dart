import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/group_model.dart';
import '../model/member_register_model.dart';
import '../provider/group_management_provider.dart';

const _dayLabels = {
  'MON': '월',
  'TUE': '화',
  'WED': '수',
  'THU': '목',
  'FRI': '금',
};

const _timeSlotLabels = {'SLOT_13_15': '1-3시', 'SLOT_15_17': '3-5시'};

class GroupManagementPage extends ConsumerStatefulWidget {
  const GroupManagementPage({super.key});

  @override
  ConsumerState<GroupManagementPage> createState() =>
      _GroupManagementPageState();
}

class _GroupManagementPageState
    extends ConsumerState<GroupManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupManagementProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('조 편성 관리')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
          ? const Center(child: Text('생성된 조가 없습니다.'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(groupManagementProvider.notifier).loadAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return _GroupTile(group: group, admins: state.admins);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _CreateGroupDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('조 생성'),
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  final GroupDetail group;
  final List<RegisteredMember> admins;

  const _GroupTile({required this.group, required this.admins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leader = admins
        .where((a) => a.id == group.leaderUserId)
        .toList();
    final leaderName = leader.isEmpty ? null : leader.first.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(group.label),
        subtitle: Text(
          leaderName == null
              ? '인원 ${group.memberCount}명 · 조장 미지정'
              : '인원 ${group.memberCount}명 · 조장: $leaderName',
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) =>
                _GroupDetailDialog(group: group, leaderName: leaderName),
          );
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'assign') {
              _showLeaderPicker(context, ref);
            } else if (value == 'remove') {
              ref
                  .read(groupManagementProvider.notifier)
                  .removeLeader(group.id);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'assign',
              child: Text(leaderName == null ? '조장 지정' : '조장 변경'),
            ),
            if (leaderName != null)
              const PopupMenuItem(
                value: 'remove',
                child: Text('조장 취소', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  void _showLeaderPicker(BuildContext context, WidgetRef ref) {
    if (admins.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('임원(ADMIN) 계정이 없습니다.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${group.label} 조장 지정'),
        children: admins.map((admin) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(groupManagementProvider.notifier)
                  .assignLeader(group.id, admin.id);
            },
            child: Text(admin.name),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupDetailDialog extends ConsumerStatefulWidget {
  final GroupDetail group;
  final String? leaderName;

  const _GroupDetailDialog({
    required this.group,
    required this.leaderName,
  });

  @override
  ConsumerState<_GroupDetailDialog> createState() =>
      _GroupDetailDialogState();
}

class _GroupDetailDialogState extends ConsumerState<_GroupDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(groupManagementProvider.notifier)
          .loadGroupMembers(widget.group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);

    return AlertDialog(
      title: Text(widget.group.label),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.leaderName == null
                  ? '조장: 미지정'
                  : '조장: ${widget.leaderName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            const Text('조원 목록', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            state.isLoadingMembers
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : state.selectedGroupMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('소속된 부원이 없습니다.'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: state.selectedGroupMembers
                        .map(
                          (m) => ListTile(
                            dense: true,
                            title: Text(m.name),
                            subtitle: Text(m.studentNo),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog();

  @override
  ConsumerState<_CreateGroupDialog> createState() =>
      _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final Set<String> _selected = {}; // "MON_SLOT_13_15" 형태의 키

  List<MapEntry<String, String>> _availableCombinations(
    List<GroupDetail> existing,
  ) {
    final existingKeys = existing
        .map((g) => '${g.dayOfWeek}_${g.timeSlot}')
        .toSet();

    final result = <MapEntry<String, String>>[];
    for (final day in _dayLabels.keys) {
      for (final slot in _timeSlotLabels.keys) {
        final key = '${day}_$slot';
        if (!existingKeys.contains(key)) {
          result.add(
            MapEntry(key, '${_dayLabels[day]} ${_timeSlotLabels[slot]}'),
          );
        }
      }
    }
    return result;
  }

  Future<void> _submit() async {
    final groups = _selected.map((key) {
      final parts = key.split('_SLOT_');
      return {'dayOfWeek': parts[0], 'timeSlot': 'SLOT_${parts[1]}'};
    }).toList();

    final success = await ref
        .read(groupManagementProvider.notifier)
        .createGroups(groups);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);
    final available = _availableCombinations(state.groups);

    return AlertDialog(
      title: const Text('조 생성'),
      content: SizedBox(
        width: double.maxFinite,
        child: available.isEmpty
            ? const Text('생성 가능한 조합이 없습니다. (이미 전부 생성됨)')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: available.map((entry) {
                    final isChecked = _selected.contains(entry.key);
                    return CheckboxListTile(
                      title: Text(entry.value),
                      value: isChecked,
                      onChanged: (_) {
                        setState(() {
                          if (isChecked) {
                            _selected.remove(entry.key);
                          } else {
                            _selected.add(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: state.isSubmitting || _selected.isEmpty
              ? null
              : _submit,
          child: state.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('생성 (${_selected.length}개)'),
        ),
      ],
    );
  }
}
