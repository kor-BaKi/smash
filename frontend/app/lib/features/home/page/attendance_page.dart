import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/attendance_model.dart';
import '../provider/attendance_provider.dart';
import '../provider/availability_provider.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(availabilityProvider.notifier).loadGroups();
      ref
          .read(attendanceProvider.notifier)
          .loadShortfall(year: now.year, month: now.month);
      ref
          .read(attendanceProvider.notifier)
          .loadOtherGroup(year: now.year, month: now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('출석 현황'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '조별 현황'),
              Tab(text: '미달자'),
              Tab(text: '타조참'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GroupTab(), _ShortfallTab(), _OtherGroupTab()],
        ),
      ),
    );
  }
}

class _GroupTab extends ConsumerStatefulWidget {
  const _GroupTab();

  @override
  ConsumerState<_GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends ConsumerState<_GroupTab> {
  int? _selectedGroupId;
  final now = DateTime.now();

  void _onGroupSelected(int? groupId) {
    if (groupId == null) return;
    setState(() => _selectedGroupId = groupId);
    ref
        .read(attendanceProvider.notifier)
        .loadGroupAttendance(
          groupId: groupId,
          year: now.year,
          month: now.month,
        );
  }

  @override
  Widget build(BuildContext context) {
    final availabilityState = ref.watch(availabilityProvider);
    final attendanceState = ref.watch(attendanceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedGroupId,
            decoration: const InputDecoration(
              labelText: '조 선택',
              border: OutlineInputBorder(),
            ),
            items: availabilityState.groups.map((group) {
              return DropdownMenuItem(
                value: group.id,
                child: Text(group.label),
              );
            }).toList(),
            onChanged: _onGroupSelected,
          ),
        ),
        Expanded(
          child: attendanceState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : attendanceState.groupAttendance == null
              ? const Center(child: Text('조를 선택해주세요.'))
              : _GroupAttendanceList(
                  attendance: attendanceState.groupAttendance!,
                ),
        ),
      ],
    );
  }
}

class _GroupAttendanceList extends StatelessWidget {
  final GroupAttendance attendance;

  const _GroupAttendanceList({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${attendance.groupLabel} · 이번 달 정규활동 ${attendance.guaranteedCount}회',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...attendance.members.map(
          (member) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(member.name),
              subtitle: Text(
                '충족 ${member.fulfilled} / ${member.guaranteed}',
              ),
              trailing: member.isShortfall
                  ? Text(
                      '미달 ${member.shortfall}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortfallTab extends ConsumerWidget {
  const _ShortfallTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.shortfallMembers.isEmpty) {
      return const Center(child: Text('미달 부원이 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.shortfallMembers.length,
      itemBuilder: (context, index) {
        final member = state.shortfallMembers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(member.name),
            subtitle: Text(
              '${member.groupLabel} · 충족 ${member.fulfilled} / ${member.guaranteed}',
            ),
            trailing: Text(
              '미달 ${member.shortfall}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtherGroupTab extends ConsumerWidget {
  const _OtherGroupTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.otherGroupMembers.isEmpty) {
      return const Center(child: Text('타조참 기록이 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.otherGroupMembers.length,
      itemBuilder: (context, index) {
        final member = state.otherGroupMembers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(member.name),
            subtitle: Text('총 ${member.count}회'),
            children: member.activities.map((activity) {
              return ListTile(
                dense: true,
                title: Text(activity.date),
                subtitle: Text(activity.groupLabel),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
