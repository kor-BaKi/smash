import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/group_model.dart';
import '../model/member_register_model.dart';
import '../provider/group_management_provider.dart';

const _dayLabels = {'MON': '월', 'TUE': '화', 'WED': '수', 'THU': '목', 'FRI': '금'};
const _timeSlotLabels = {'SLOT_13_15': '1-3시', 'SLOT_15_17': '3-5시'};

class GroupManagementPage extends ConsumerStatefulWidget {
  const GroupManagementPage({super.key});

  @override
  ConsumerState<GroupManagementPage> createState() =>
      _GroupManagementPageState();
}

class _GroupManagementPageState extends ConsumerState<GroupManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(groupManagementProvider.notifier).loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('조 편성 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.lime),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const _CreateGroupDialog(),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : state.groups.isEmpty
          ? const Center(
              child: Text(
                '생성된 조가 없습니다.',
                style: TextStyle(color: AppColors.gray),
              ),
            )
          : RefreshIndicator(
              color: AppColors.lime,
              backgroundColor: AppColors.card,
              onRefresh: () =>
                  ref.read(groupManagementProvider.notifier).loadAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return _GroupTile(group: group, admins: state.admins);
                },
              ),
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
    final leader = admins.where((a) => a.id == group.leaderUserId).toList();
    final leaderName = leader.isEmpty ? null : leader.first.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog(
          context: context,
          builder: (context) =>
              _GroupDetailDialog(group: group, leaderName: leaderName),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: AppColors.gray),
                    color: AppColors.card2,
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
                        child: Text(
                          leaderName == null ? '조장 지정' : '조장 변경',
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ),
                      if (leaderName != null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            '조장 취소',
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    leaderName == null ? '조장 미지정' : '조장 $leaderName',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: leaderName == null
                          ? AppColors.coral
                          : AppColors.lime,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${group.memberCount}명',
                    style: const TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                ],
              ),
            ],
          ),
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '${group.label} 조장 지정',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: admins.map((admin) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(groupManagementProvider.notifier)
                  .assignLeader(group.id, admin.id);
            },
            child: Text(
              admin.name,
              style: const TextStyle(color: AppColors.white),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupDetailDialog extends ConsumerStatefulWidget {
  final GroupDetail group;
  final String? leaderName;

  const _GroupDetailDialog({required this.group, required this.leaderName});

  @override
  ConsumerState<_GroupDetailDialog> createState() => _GroupDetailDialogState();
}

class _GroupDetailDialogState extends ConsumerState<_GroupDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(groupManagementProvider.notifier)
          .loadGroupMembers(widget.group.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.leaderName == null
                  ? '조장: 미지정'
                  : '조장: ${widget.leaderName}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: widget.leaderName == null
                    ? AppColors.coral
                    : AppColors.lime,
              ),
            ),
            Container(
              height: 0.5,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
            const Text(
              '조원 목록',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 8),
            state.isLoadingMembers
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    ),
                  )
                : state.selectedGroupMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '소속된 부원이 없습니다.',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.selectedGroupMembers.length,
                      itemBuilder: (context, index) {
                        final m = state.selectedGroupMembers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.lime.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  m.name.substring(0, 1),
                                  style: const TextStyle(
                                    color: AppColors.lime,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.card2,
                  foregroundColor: AppColors.gray,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog();

  @override
  ConsumerState<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final Set<String> _selected = {};

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
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupManagementProvider);
    final available = _availableCombinations(state.groups);

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '조 생성',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.maxFinite,
              child: available.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '생성 가능한 조합이 없습니다. (이미 전부 생성됨)',
                        style: TextStyle(color: AppColors.gray),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: available.map((entry) {
                          final isChecked = _selected.contains(entry.key);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              entry.value,
                              style: const TextStyle(color: AppColors.white),
                            ),
                            value: isChecked,
                            activeColor: AppColors.lime,
                            checkColor: AppColors.onPrimary,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isSubmitting || _selected.isEmpty
                        ? null
                        : _submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text('생성 (${_selected.length}개)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
