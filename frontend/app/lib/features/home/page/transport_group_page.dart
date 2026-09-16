import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/activity_detail_model.dart';
import '../provider/activity_provider.dart';
import '../provider/transport_provider.dart';

class TransportGroupPage extends ConsumerStatefulWidget {
  final int activityId;

  const TransportGroupPage({super.key, required this.activityId});

  @override
  ConsumerState<TransportGroupPage> createState() =>
      _TransportGroupPageState();
}

class _TransportGroupPageState extends ConsumerState<TransportGroupPage> {
  final List<Set<int>> _groupSelections = [{}];
  bool _initialized = false;
  int? _activeGroupIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(activityProvider.notifier)
          .loadParticipants(widget.activityId);
      await ref
          .read(transportProvider.notifier)
          .loadGroups(widget.activityId);
      _initFromSaved();
    });
  }

  void _initFromSaved() {
    final groups = ref.read(transportProvider).groups;
    if (groups.isEmpty || _initialized) return;
    _initialized = true;
    setState(() {
      _groupSelections.clear();
      for (final group in groups) {
        _groupSelections.add(group.members.map((m) => m.userId).toSet());
      }
      if (_groupSelections.isEmpty) _groupSelections.add({});
    });
  }

  void _addGroup() => setState(() => _groupSelections.add({}));

  void _removeGroup(int index) {
    if (_groupSelections.length <= 1) return;
    setState(() {
      _groupSelections.removeAt(index);
      if (_activeGroupIndex == index) _activeGroupIndex = null;
    });
  }

  void _assignToGroup(int userId, int? groupIndex, {bool isMove = false}) {
    if (groupIndex != null) {
      final currentSize = _groupSelections[groupIndex].length;
      final isAlreadyInGroup = _groupSelections[groupIndex].contains(
        userId,
      );
      final effectiveSize = isAlreadyInGroup
          ? currentSize
          : currentSize + (isMove ? 0 : 1);
      if (effectiveSize > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${groupIndex + 1}호차는 이미 4명이 꽉 찼습니다.')),
        );
        return;
      }
    }
    setState(() {
      for (final g in _groupSelections) {
        g.remove(userId);
      }
      if (groupIndex != null) {
        _groupSelections[groupIndex].add(userId);
      }
    });
  }

  int? _getGroupIndex(int userId) {
    for (int i = 0; i < _groupSelections.length; i++) {
      if (_groupSelections[i].contains(userId)) return i;
    }
    return null;
  }

  Future<void> _submit() async {
    final nonEmpty = _groupSelections
        .where((g) => g.isNotEmpty)
        .map((g) => g.toList())
        .toList();

    if (nonEmpty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹에 최소 1명 이상 배정해주세요.')),
      );
      return;
    }

    await ref
        .read(transportProvider.notifier)
        .assign(widget.activityId, nonEmpty);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('택시 그룹이 배정되었습니다.')));
    }
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
          '배정 초기화',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          '모든 택시 그룹 배정을 초기화할까요?',
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
      await ref.read(transportProvider.notifier).reset(widget.activityId);
      setState(() {
        _groupSelections.clear();
        _groupSelections.add({});
        _activeGroupIndex = null;
        _initialized = false;
      });
    }
  }

  void _showGroupPicker(
    BuildContext context,
    ActivityParticipant participant,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${participant.name} 호차 배정',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '미배정',
                style: TextStyle(color: AppColors.gray),
              ),
              trailing: _getGroupIndex(participant.userId) == null
                  ? const Icon(Icons.check, color: AppColors.lime)
                  : null,
              onTap: () {
                _assignToGroup(participant.userId, null);
                Navigator.of(context).pop();
              },
            ),
            Container(height: 0.5, color: AppColors.border),
            ..._groupSelections.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${e.key + 1}호차',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                subtitle: Text(
                  '${e.value.length}명',
                  style: const TextStyle(color: AppColors.gray),
                ),
                trailing: _getGroupIndex(participant.userId) == e.key
                    ? const Icon(Icons.check, color: AppColors.lime)
                    : null,
                onTap: () {
                  _assignToGroup(participant.userId, e.key);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityProvider);
    final transportState = ref.watch(transportProvider);
    final participants = activityState.participants ?? [];
    final unassignedCount = participants
        .where((p) => _getGroupIndex(p.userId) == null)
        .length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('택시 그룹 배정'),
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
      ),
      body: activityState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : Column(
              children: [
                Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '호차 현황',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray,
                            ),
                          ),
                          const Spacer(),
                          if (unassignedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coralTag,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '미배정 $unassignedCount명',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coralTagText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_activeGroupIndex != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_activeGroupIndex! + 1}호차 선택됨 · 아래 이름을 탭해서 배정',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._groupSelections.asMap().entries.map(
                              (e) => GestureDetector(
                                onTap: () => setState(() {
                                  _activeGroupIndex =
                                      _activeGroupIndex == e.key
                                      ? null
                                      : e.key;
                                }),
                                child: _GroupCard(
                                  groupIndex: e.key,
                                  selectedIds: e.value,
                                  participants: participants,
                                  onRemove: () => _removeGroup(e.key),
                                  canRemove: _groupSelections.length > 1,
                                  isActive: _activeGroupIndex == e.key,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _addGroup,
                              child: Container(
                                width: 100,
                                height: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.card2,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: AppColors.gray),
                                    SizedBox(height: 4),
                                    Text(
                                      '호차 추가',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 0.5, color: AppColors.border),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 0.5, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      final groupIndex = _getGroupIndex(p.userId);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: groupIndex != null
                              ? AppColors.lime
                              : AppColors.card2,
                          child: Text(
                            p.name.characters.first,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: groupIndex != null
                                  ? const Color(0xFF111111)
                                  : AppColors.gray,
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: groupIndex != null
                                ? AppColors.white
                                : AppColors.gray,
                          ),
                        ),
                        subtitle: Text(
                          p.travelType == 'TOGETHER'
                              ? '같이'
                              : p.travelType == 'ALONE'
                              ? '따로'
                              : '미선택',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.travelType == 'TOGETHER'
                                ? AppColors.green
                                : p.travelType == 'ALONE'
                                ? AppColors.coral
                                : AppColors.darkGray,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: groupIndex != null
                                ? AppColors.lime.withValues(alpha: 0.15)
                                : AppColors.coralTag,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            groupIndex != null
                                ? '${groupIndex + 1}호차'
                                : '미배정',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: groupIndex != null
                                  ? AppColors.lime
                                  : AppColors.coralTagText,
                            ),
                          ),
                        ),
                        onTap: () {
                          if (_activeGroupIndex != null) {
                            final currentGroup = _getGroupIndex(p.userId);
                            if (currentGroup == _activeGroupIndex) {
                              _assignToGroup(p.userId, null);
                            } else if (currentGroup != null) {
                              showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      24,
                                    ),
                                  ),
                                  title: const Text(
                                    '호차 변경',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  content: Text(
                                    '${p.name}님을 ${currentGroup + 1}호차에서 ${_activeGroupIndex! + 1}호차로 옮기겠습니까?',
                                    style: const TextStyle(
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: AppColors.gray,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        '옮기기',
                                        style: TextStyle(
                                          color: AppColors.lime,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).then((confirmed) {
                                if (confirmed == true) {
                                  _assignToGroup(
                                    p.userId,
                                    _activeGroupIndex,
                                    isMove: true,
                                  );
                                }
                              });
                            } else {
                              _assignToGroup(p.userId, _activeGroupIndex);
                            }
                          } else {
                            _showGroupPicker(context, p);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ElevatedButton(
            onPressed: transportState.isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: transportState.isSubmitting
                ? const CircularProgressIndicator(color: Color(0xFF111111))
                : const Text(
                    '배정 완료',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final int groupIndex;
  final Set<int> selectedIds;
  final List<ActivityParticipant> participants;
  final VoidCallback onRemove;
  final bool canRemove;
  final bool isActive;

  const _GroupCard({
    required this.groupIndex,
    required this.selectedIds,
    required this.participants,
    required this.onRemove,
    required this.canRemove,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final members = participants
        .where((p) => selectedIds.contains(p.userId))
        .toList();

    return Container(
      width: 110,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.lime
            : AppColors.lime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.lime
              : AppColors.lime.withValues(alpha: 0.3),
          width: isActive ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${groupIndex + 1}호차',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? const Color(0xFF111111)
                      : AppColors.lime,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${members.length}명',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? const Color(0xFF111111).withValues(alpha: 0.6)
                      : AppColors.lime,
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isActive
                        ? const Color(0xFF111111).withValues(alpha: 0.5)
                        : AppColors.darkGray,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: members
                    .map(
                      (m) => Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF111111)
                              : AppColors.lime,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
