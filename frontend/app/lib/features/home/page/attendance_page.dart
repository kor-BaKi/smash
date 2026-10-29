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
  late DateTime _month;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    Future.microtask(() {
      ref.read(availabilityProvider.notifier).loadGroups();
      _loadMonthData();
    });
  }

  // 미달자, 타조참을 선택된 월 기준으로 불러오기
  void _loadMonthData() {
    final notifier = ref.read(attendanceProvider.notifier);
    notifier.loadShortfall(year: _month.year, month: _month.month);
    notifier.loadOtherGroup(year: _month.year, month: _month.month);
  }

  void _changeMonth(int delta) {
    // DateTime은 월이 범위를 넘으면 연도를 자동 보정함 (13월 -> 다음 해 1월)
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadMonthData();
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
        body: Column(
          children: [
            _MonthSelector(
              month: _month,
              canGoNext: !_isCurrentMonth,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _GroupTab(year: _month.year, month: _month.month),
                  const _ShortfallTab(),
                  const _OtherGroupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
          ),
          Text(
            '${month.year}년 ${month.month}월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? onNext : null, // null이면 비활성화
          ),
        ],
      ),
    );
  }
}

class _GroupTab extends ConsumerStatefulWidget {
  final int year;
  final int month;

  const _GroupTab({required this.year, required this.month});

  @override
  ConsumerState<_GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends ConsumerState<_GroupTab> {
  int? _selectedGroupId;

  void _loadGroup() {
    final groupId = _selectedGroupId;
    if (groupId == null) return;
    ref
        .read(attendanceProvider.notifier)
        .loadGroupAttendance(
          groupId: groupId,
          year: widget.year,
          month: widget.month,
        );
  }

  void _onGroupSelected(int? groupId) {
    if (groupId == null) return;
    setState(() => _selectedGroupId = groupId);
    _loadGroup();
  }

  // 부모가 월을 바꾸면 선택된 조의 데이터를 새 월로 다시 불러옴
  @override
  void didUpdateWidget(covariant _GroupTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _loadGroup();
    }
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
              : (_selectedGroupId == null ||
                    attendanceState.groupAttendance == null)
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
          '${attendance.groupLabel} · 정규활동 ${attendance.guaranteedCount}회',
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
